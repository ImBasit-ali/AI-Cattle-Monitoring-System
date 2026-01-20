"""Lameness detection service using pose estimation and gait analysis."""
import cv2
import numpy as np
from ultralytics import YOLO
from typing import List, Dict, Optional, Tuple
import logging
from pathlib import Path
import pickle
from sklearn.ensemble import RandomForestClassifier
from datetime import datetime

from config import settings
from models.schemas import LamenessStatus, LamenessLevel, GaitFeatures

logger = logging.getLogger(__name__)


class LamenessService:
    """
    Lameness detection service using gait analysis.
    
    Method:
    1. YOLOv8-Pose for keypoint detection
    2. Gait feature extraction (step length, symmetry, speed)
    3. ML classifier (Random Forest) for lameness classification
    """
    
    def __init__(self):
        self.pose_model = None
        self.lameness_classifier = None
        self._ready = False
        
        # Keypoint indices (COCO format)
        self.LEFT_FRONT_LEG = [5, 7, 9]   # shoulder, elbow, wrist
        self.RIGHT_FRONT_LEG = [6, 8, 10]
        self.LEFT_BACK_LEG = [11, 13, 15] # hip, knee, ankle
        self.RIGHT_BACK_LEG = [12, 14, 16]
    
    async def initialize(self):
        """Load pose model and lameness classifier."""
        try:
            # Load YOLOv8-Pose model
            pose_model_path = settings.MODELS_DIR / settings.POSE_MODEL
            
            if pose_model_path.exists():
                logger.info(f"Loading pose model from {pose_model_path}")
                self.pose_model = YOLO(str(pose_model_path))
            else:
                logger.info("Loading default YOLOv8-Pose model")
                self.pose_model = YOLO("yolov8n-pose.pt")
            
            # Load lameness classifier
            classifier_path = settings.MODELS_DIR / settings.LAMENESS_MODEL
            
            if classifier_path.exists():
                logger.info(f"Loading lameness classifier from {classifier_path}")
                with open(classifier_path, 'rb') as f:
                    self.lameness_classifier = pickle.load(f)
            else:
                logger.warning("Lameness classifier not found, using rule-based fallback")
                self.lameness_classifier = None
            
            self._ready = True
            logger.info("✅ Lameness service initialized")
            
        except Exception as e:
            logger.error(f"Failed to initialize lameness service: {e}")
            raise
    
    def is_ready(self) -> bool:
        """Check if service is ready."""
        return self._ready and self.pose_model is not None
    
    async def analyze_gait(self, video_path: str) -> LamenessStatus:
        """
        Analyze gait from video and detect lameness.
        
        Args:
            video_path: Path to video showing animal walking
            
        Returns:
            LamenessStatus object
        """
        try:
            # Extract gait features from video
            gait_features = self._extract_gait_features(video_path)
            
            if gait_features is None:
                return LamenessStatus(
                    level=LamenessLevel.UNKNOWN,
                    confidence=0.0,
                    gait_features=GaitFeatures(
                        step_length=0.0,
                        step_symmetry=0.0,
                        walking_speed=0.0
                    )
                )
            
            # Classify lameness
            if self.lameness_classifier:
                # Use ML classifier
                level, confidence = self._classify_with_ml(gait_features)
            else:
                # Use rule-based classification
                level, confidence = self._classify_rule_based(gait_features)
            
            # Detect affected leg
            affected_leg = self._detect_affected_leg(gait_features)
            
            return LamenessStatus(
                level=level,
                confidence=confidence,
                gait_features=gait_features,
                affected_leg=affected_leg
            )
            
        except Exception as e:
            logger.error(f"Gait analysis error: {e}")
            return LamenessStatus(
                level=LamenessLevel.UNKNOWN,
                confidence=0.0,
                gait_features=GaitFeatures(
                    step_length=0.0,
                    step_symmetry=0.0,
                    walking_speed=0.0
                )
            )
    
    def _extract_gait_features(self, video_path: str) -> Optional[GaitFeatures]:
        """
        Extract gait features from video.
        
        Features extracted:
        - Step length
        - Step symmetry (left vs right)
        - Walking speed
        - Back curvature (if visible)
        
        Args:
            video_path: Path to video
            
        Returns:
            GaitFeatures object or None
        """
        cap = cv2.VideoCapture(video_path)
        
        if not cap.isOpened():
            logger.error(f"Failed to open video: {video_path}")
            return None
        
        fps = cap.get(cv2.CAP_PROP_FPS)
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        
        # Storage for keypoints across frames
        all_keypoints = []
        
        while True:
            ret, frame = cap.read()
            if not ret:
                break
            
            # Run pose detection
            results = self.pose_model(frame, verbose=False)
            
            for result in results:
                if result.keypoints is not None:
                    keypoints = result.keypoints.xy[0].cpu().numpy()
                    all_keypoints.append(keypoints)
        
        cap.release()
        
        if len(all_keypoints) < 10:
            logger.warning("Insufficient keypoints detected")
            return None
        
        # Calculate gait features
        step_length = self._calculate_step_length(all_keypoints)
        step_symmetry = self._calculate_step_symmetry(all_keypoints)
        walking_speed = self._calculate_walking_speed(all_keypoints, fps)
        back_curvature = self._calculate_back_curvature(all_keypoints)
        
        return GaitFeatures(
            step_length=step_length,
            step_symmetry=step_symmetry,
            walking_speed=walking_speed,
            back_curvature=back_curvature,
            rest_time=0.0
        )
    
    def _calculate_step_length(self, keypoints_sequence: List[np.ndarray]) -> float:
        """Calculate average step length."""
        if len(keypoints_sequence) < 2:
            return 0.0
        
        step_lengths = []
        
        for i in range(1, len(keypoints_sequence)):
            prev_kp = keypoints_sequence[i-1]
            curr_kp = keypoints_sequence[i]
            
            # Use ankle keypoints (index 15 and 16)
            if len(prev_kp) > 16 and len(curr_kp) > 16:
                # Calculate movement of back legs
                left_movement = np.linalg.norm(curr_kp[15] - prev_kp[15])
                right_movement = np.linalg.norm(curr_kp[16] - prev_kp[16])
                
                step_lengths.append((left_movement + right_movement) / 2)
        
        return float(np.mean(step_lengths)) if step_lengths else 0.0
    
    def _calculate_step_symmetry(self, keypoints_sequence: List[np.ndarray]) -> float:
        """
        Calculate step symmetry (0-1, where 1 is perfectly symmetric).
        
        Lower values indicate asymmetric gait (potential lameness).
        """
        if len(keypoints_sequence) < 2:
            return 1.0
        
        left_steps = []
        right_steps = []
        
        for i in range(1, len(keypoints_sequence)):
            prev_kp = keypoints_sequence[i-1]
            curr_kp = keypoints_sequence[i]
            
            if len(prev_kp) > 16 and len(curr_kp) > 16:
                left_movement = np.linalg.norm(curr_kp[15] - prev_kp[15])
                right_movement = np.linalg.norm(curr_kp[16] - prev_kp[16])
                
                left_steps.append(left_movement)
                right_steps.append(right_movement)
        
        if not left_steps or not right_steps:
            return 1.0
        
        left_avg = np.mean(left_steps)
        right_avg = np.mean(right_steps)
        
        # Symmetry score (1.0 = perfect symmetry)
        if max(left_avg, right_avg) == 0:
            return 1.0
        
        symmetry = min(left_avg, right_avg) / max(left_avg, right_avg)
        return float(symmetry)
    
    def _calculate_walking_speed(self, keypoints_sequence: List[np.ndarray], fps: float) -> float:
        """Calculate average walking speed in pixels/second."""
        if len(keypoints_sequence) < 2 or fps == 0:
            return 0.0
        
        total_distance = 0.0
        
        for i in range(1, len(keypoints_sequence)):
            prev_kp = keypoints_sequence[i-1]
            curr_kp = keypoints_sequence[i]
            
            # Use center of mass (average of hip keypoints)
            if len(prev_kp) > 12 and len(curr_kp) > 12:
                prev_center = (prev_kp[11] + prev_kp[12]) / 2
                curr_center = (curr_kp[11] + curr_kp[12]) / 2
                
                distance = np.linalg.norm(curr_center - prev_center)
                total_distance += distance
        
        # Speed in pixels per second
        duration = len(keypoints_sequence) / fps
        speed = total_distance / duration if duration > 0 else 0.0
        
        return float(speed)
    
    def _calculate_back_curvature(self, keypoints_sequence: List[np.ndarray]) -> Optional[float]:
        """
        Calculate back curvature.
        
        Lame animals often show irregular back posture.
        """
        if len(keypoints_sequence) == 0:
            return None
        
        curvatures = []
        
        for keypoints in keypoints_sequence:
            if len(keypoints) > 12:
                # Use shoulder and hip keypoints to estimate back line
                shoulder = keypoints[5:7].mean(axis=0)
                hip = keypoints[11:13].mean(axis=0)
                
                # Simple curvature measure (y-axis deviation)
                curvature = abs(shoulder[1] - hip[1])
                curvatures.append(curvature)
        
        return float(np.mean(curvatures)) if curvatures else None
    
    def _classify_with_ml(self, features: GaitFeatures) -> Tuple[LamenessLevel, float]:
        """Classify lameness using ML model."""
        # Prepare features for classifier
        X = np.array([[
            features.step_length,
            features.step_symmetry,
            features.walking_speed,
            features.back_curvature or 0.0,
            features.rest_time
        ]])
        
        # Predict
        prediction = self.lameness_classifier.predict(X)[0]
        confidence = self.lameness_classifier.predict_proba(X).max()
        
        # Map prediction to LamenessLevel
        level_map = {
            0: LamenessLevel.NORMAL,
            1: LamenessLevel.MILD,
            2: LamenessLevel.MODERATE,
            3: LamenessLevel.SEVERE
        }
        
        return level_map.get(prediction, LamenessLevel.UNKNOWN), float(confidence)
    
    def _classify_rule_based(self, features: GaitFeatures) -> Tuple[LamenessLevel, float]:
        """
        Rule-based lameness classification (fallback when ML model not available).
        
        Rules:
        - Symmetry < 0.7 → Mild/Moderate
        - Symmetry < 0.5 → Severe
        - Speed significantly reduced → Moderate/Severe
        """
        confidence = 0.8
        
        # Check symmetry
        if features.step_symmetry < 0.5:
            return LamenessLevel.SEVERE, confidence
        elif features.step_symmetry < 0.7:
            return LamenessLevel.MODERATE, confidence * 0.9
        elif features.step_symmetry < 0.85:
            return LamenessLevel.MILD, confidence * 0.85
        else:
            return LamenessLevel.NORMAL, confidence
    
    def _detect_affected_leg(self, features: GaitFeatures) -> Optional[str]:
        """
        Detect which leg is affected.
        
        This is a placeholder. In production, you would analyze
        individual leg movements to determine which leg shows lameness.
        """
        if features.step_symmetry < 0.85:
            # Placeholder: would need per-leg analysis
            return "Unknown - requires detailed analysis"
        
        return None
