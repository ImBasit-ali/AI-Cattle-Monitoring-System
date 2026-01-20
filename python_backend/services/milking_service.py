"""Milking status detection service."""
import cv2
import numpy as np
from ultralytics import YOLO
from typing import Optional
import logging
from pathlib import Path

from config import settings
from models.schemas import MilkingStatus, MilkingStatusEnum, UdderDetection, BoundingBox

logger = logging.getLogger(__name__)


class MilkingService:
    """
    Milking (lactation) status detection service.
    
    Methods:
    1. Udder detection + size analysis (primary)
    2. Behavior-based analysis (secondary)
    """
    
    def __init__(self):
        self.udder_model = None
        self.udder_size_threshold = 5000  # pixels, adjust based on camera distance
        self._ready = False
    
    async def initialize(self):
        """Load udder detection model."""
        try:
            model_path = settings.MODELS_DIR / settings.UDDER_MODEL
            
            if model_path.exists():
                logger.info(f"Loading udder model from {model_path}")
                self.udder_model = YOLO(str(model_path))
            else:
                logger.warning(f"Udder model not found at {model_path}")
                logger.info("Creating placeholder for udder detection")
                # For testing without custom model
                self.udder_model = None
            
            self._ready = True
            logger.info("✅ Milking service initialized")
            
        except Exception as e:
            logger.error(f"Failed to initialize milking service: {e}")
            raise
    
    def is_ready(self) -> bool:
        """Check if service is ready."""
        return self._ready
    
    def detect_milking_status(self, image: np.ndarray) -> MilkingStatus:
        """
        Detect if animal is milking (lactating) or dry.
        
        Args:
            image: Input image showing the animal
            
        Returns:
            MilkingStatus object
        """
        try:
            # Method 1: Udder detection and size analysis
            udder_detection = self._detect_udder(image)
            
            # Determine status based on udder
            if udder_detection.detected:
                if udder_detection.udder_size and udder_detection.udder_size > self.udder_size_threshold:
                    status = MilkingStatusEnum.MILKING
                    confidence = udder_detection.confidence
                else:
                    status = MilkingStatusEnum.DRY
                    confidence = udder_detection.confidence * 0.8
            else:
                # Method 2: Fallback to behavior analysis (placeholder)
                behavioral_score = self._analyze_behavior(image)
                
                if behavioral_score > 0.6:
                    status = MilkingStatusEnum.MILKING
                    confidence = behavioral_score
                else:
                    status = MilkingStatusEnum.UNKNOWN
                    confidence = 0.5
            
            return MilkingStatus(
                status=status,
                confidence=confidence,
                udder_detection=udder_detection if udder_detection.detected else None,
                behavioral_score=self._analyze_behavior(image)
            )
            
        except Exception as e:
            logger.error(f"Milking detection error: {e}")
            return MilkingStatus(
                status=MilkingStatusEnum.UNKNOWN,
                confidence=0.0
            )
    
    def _detect_udder(self, image: np.ndarray) -> UdderDetection:
        """
        Detect udder in image.
        
        Args:
            image: Input image
            
        Returns:
            UdderDetection object
        """
        if self.udder_model is None:
            # Placeholder when model not available
            return UdderDetection(
                detected=False,
                confidence=0.0
            )
        
        try:
            # Run udder detection
            results = self.udder_model(image, conf=0.5, verbose=False)
            
            for result in results:
                boxes = result.boxes
                
                if len(boxes) > 0:
                    # Get first (highest confidence) detection
                    box = boxes[0]
                    x1, y1, x2, y2 = box.xyxy[0].cpu().numpy()
                    confidence = float(box.conf[0])
                    
                    # Calculate udder size
                    udder_size = (x2 - x1) * (y2 - y1)
                    
                    return UdderDetection(
                        detected=True,
                        confidence=confidence,
                        bounding_box=BoundingBox(
                            x1=float(x1),
                            y1=float(y1),
                            x2=float(x2),
                            y2=float(y2)
                        ),
                        udder_size=float(udder_size)
                    )
            
            return UdderDetection(detected=False, confidence=0.0)
            
        except Exception as e:
            logger.error(f"Udder detection error: {e}")
            return UdderDetection(detected=False, confidence=0.0)
    
    def _analyze_behavior(self, image: np.ndarray) -> float:
        """
        Analyze behavioral patterns for milking status.
        
        This is a placeholder. In production, you would:
        - Track animal movement patterns
        - Monitor time spent near milking stations
        - Analyze posture during milking times
        
        Args:
            image: Input image
            
        Returns:
            Behavioral score (0-1)
        """
        # Placeholder implementation
        # In real system, this would analyze:
        # - Zone detection (is animal in milking area?)
        # - Time-based patterns
        # - Posture analysis
        
        return 0.5  # Neutral score
    
    def analyze_zone(self, image: np.ndarray, zones: dict) -> dict:
        """
        Analyze if animal is in milking zone.
        
        Args:
            image: Input image
            zones: Dictionary of zone definitions
            
        Returns:
            Zone analysis results
        """
        # Placeholder for zone-based detection
        # In production: detect if animal is in designated milking area
        return {
            "in_milking_zone": False,
            "confidence": 0.0
        }
