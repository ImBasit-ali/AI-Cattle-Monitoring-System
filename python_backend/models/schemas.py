"""Pydantic models for API request/response schemas."""
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime
from enum import Enum


class AnimalType(str, Enum):
    """Animal classification."""
    COW = "cow"
    BUFFALO = "buffalo"
    UNKNOWN = "unknown"


class MilkingStatusEnum(str, Enum):
    """Milking status classification."""
    MILKING = "milking"
    DRY = "dry"
    UNKNOWN = "unknown"


class LamenessLevel(str, Enum):
    """Lameness severity levels."""
    NORMAL = "normal"
    MILD = "mild"
    MODERATE = "moderate"
    SEVERE = "severe"


class BoundingBox(BaseModel):
    """Bounding box coordinates."""
    x1: float
    y1: float
    x2: float
    y2: float
    
    @property
    def center(self):
        return ((self.x1 + self.x2) / 2, (self.y1 + self.y2) / 2)
    
    @property
    def area(self):
        return (self.x2 - self.x1) * (self.y2 - self.y1)


class AnimalDetection(BaseModel):
    """Animal detection result."""
    detection_id: str = Field(..., description="Unique detection ID")
    animal_type: AnimalType
    confidence: float = Field(..., ge=0.0, le=1.0)
    bounding_box: BoundingBox
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class TrackingInfo(BaseModel):
    """Animal tracking information."""
    track_id: int = Field(..., description="Unique tracking ID")
    animal_type: AnimalType
    first_seen: datetime
    last_seen: datetime
    positions: List[BoundingBox]
    confidence_avg: float
    frame_count: int = 0
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class UdderDetection(BaseModel):
    """Udder detection result."""
    detected: bool
    confidence: float
    bounding_box: Optional[BoundingBox] = None
    udder_size: Optional[float] = None  # Area in pixels
    

class MilkingStatus(BaseModel):
    """Milking status result."""
    status: MilkingStatusEnum
    confidence: float
    udder_detection: Optional[UdderDetection] = None
    behavioral_score: Optional[float] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class GaitFeatures(BaseModel):
    """Gait analysis features."""
    step_length: float
    step_symmetry: float
    walking_speed: float
    back_curvature: Optional[float] = None
    rest_time: float = 0.0


class LamenessStatus(BaseModel):
    """Lameness detection result."""
    level: LamenessLevel
    confidence: float
    gait_features: GaitFeatures
    affected_leg: Optional[str] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class CameraStream(BaseModel):
    """Camera stream configuration."""
    camera_id: str
    name: str
    rtsp_url: str
    location: str
    is_active: bool = True
    fps: int = 30


class DetectionStats(BaseModel):
    """Detection statistics."""
    total_detections: int
    cows_count: int
    buffaloes_count: int
    avg_confidence: float
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class HealthStats(BaseModel):
    """Health monitoring statistics."""
    total_animals: int
    milking_count: int
    dry_count: int
    lame_animals: int
    healthy_animals: int
    alerts_count: int
    timestamp: datetime = Field(default_factory=datetime.utcnow)
