"""Animal detection service using YOLOv8."""
import cv2
import numpy as np
from ultralytics import YOLO
from typing import List, Tuple
import logging
from pathlib import Path
import uuid
from datetime import datetime

from config import settings
from models.schemas import AnimalDetection, AnimalType, BoundingBox

logger = logging.getLogger(__name__)


class DetectionService:
    """
    YOLOv8-based animal detection service.
    Detects only Cow and Buffalo (rejects other animals).
    """
    
    def __init__(self):
        self.model = None
        self.class_names = {
            0: AnimalType.COW,
            1: AnimalType.BUFFALO
        }
        self.confidence_threshold = settings.DETECTION_CONFIDENCE
        self._ready = False
    
    async def initialize(self):
        """Load YOLOv8 model."""
        try:
            model_path = settings.MODELS_DIR / settings.COW_BUFFALO_MODEL
            
            # Check if custom model exists
            if model_path.exists():
                logger.info(f"Loading custom model from {model_path}")
                self.model = YOLO(str(model_path))
            else:
                logger.warning(f"Custom model not found at {model_path}")
                logger.info("Loading default YOLOv8 model (use for testing only)")
                # For testing, use default model (you'll need to train custom one)
                self.model = YOLO("yolov8n.pt")
                logger.warning("⚠️ Using default model - train custom model for production!")
            
            # Warm up the model
            dummy_img = np.zeros((640, 640, 3), dtype=np.uint8)
            self.model(dummy_img, verbose=False)
            
            self._ready = True
            logger.info("✅ Detection service initialized")
            
        except Exception as e:
            logger.error(f"Failed to initialize detection service: {e}")
            raise
    
    def is_ready(self) -> bool:
        """Check if service is ready."""
        return self._ready and self.model is not None
    
    def detect(self, image: np.ndarray) -> List[AnimalDetection]:
        """
        Detect animals in image.
        
        Args:
            image: Input image (BGR format)
            
        Returns:
            List of AnimalDetection objects
        """
        if not self.is_ready():
            logger.error("Detection service not initialized")
            return []
        
        try:
            # Run inference
            results = self.model(image, conf=self.confidence_threshold, verbose=False)
            
            detections = []
            
            for result in results:
                boxes = result.boxes
                
                for box in boxes:
                    cls_id = int(box.cls[0])
                    
                    # Only process cow (0) and buffalo (1)
                    # Reject all other classes (dog, cat, goat, etc.)
                    if cls_id not in [0, 1]:
                        continue
                    
                    # Extract bounding box
                    x1, y1, x2, y2 = box.xyxy[0].cpu().numpy()
                    confidence = float(box.conf[0])
                    
                    # Create detection object
                    detection = AnimalDetection(
                        detection_id=str(uuid.uuid4()),
                        animal_type=self.class_names.get(cls_id, AnimalType.UNKNOWN),
                        confidence=confidence,
                        bounding_box=BoundingBox(
                            x1=float(x1),
                            y1=float(y1),
                            x2=float(x2),
                            y2=float(y2)
                        ),
                        timestamp=datetime.utcnow()
                    )
                    
                    detections.append(detection)
            
            logger.info(f"Detected {len(detections)} animals")
            return detections
            
        except Exception as e:
            logger.error(f"Detection error: {e}")
            return []
    
    def draw_detections(self, image: np.ndarray, detections: List[AnimalDetection]) -> np.ndarray:
        """
        Draw bounding boxes on image.
        
        Args:
            image: Input image
            detections: List of detections
            
        Returns:
            Annotated image
        """
        annotated = image.copy()
        
        for det in detections:
            bbox = det.bounding_box
            
            # Color based on animal type
            color = (0, 255, 0) if det.animal_type == AnimalType.COW else (255, 0, 0)
            
            # Draw rectangle
            cv2.rectangle(
                annotated,
                (int(bbox.x1), int(bbox.y1)),
                (int(bbox.x2), int(bbox.y2)),
                color,
                2
            )
            
            # Draw label
            label = f"{det.animal_type.value}: {det.confidence:.2f}"
            cv2.putText(
                annotated,
                label,
                (int(bbox.x1), int(bbox.y1) - 10),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.5,
                color,
                2
            )
        
        return annotated
