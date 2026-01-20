"""Configuration management for the backend."""
import os
from pathlib import Path
from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    """Application settings."""
    
    # Supabase
    SUPABASE_URL: str = os.getenv("SUPABASE_URL", "")
    SUPABASE_KEY: str = os.getenv("SUPABASE_KEY", "")
    SUPABASE_SERVICE_KEY: str = os.getenv("SUPABASE_SERVICE_KEY", "")
    
    # FastAPI
    API_HOST: str = os.getenv("API_HOST", "0.0.0.0")
    API_PORT: int = int(os.getenv("API_PORT", "8000"))
    API_RELOAD: bool = os.getenv("API_RELOAD", "True").lower() == "true"
    
    # Models
    MODELS_DIR: Path = Path(os.getenv("MODELS_DIR", "./models"))
    COW_BUFFALO_MODEL: str = os.getenv("COW_BUFFALO_MODEL", "cow_buffalo_detector.pt")
    UDDER_MODEL: str = os.getenv("UDDER_MODEL", "udder_detector.pt")
    POSE_MODEL: str = os.getenv("POSE_MODEL", "yolov8n-pose.pt")
    LAMENESS_MODEL: str = os.getenv("LAMENESS_MODEL", "lameness_classifier.pkl")
    
    # Camera
    CAMERA_RTSP_URL: Optional[str] = os.getenv("CAMERA_RTSP_URL", None)
    CAMERA_FPS: int = int(os.getenv("CAMERA_FPS", "30"))
    DETECTION_CONFIDENCE: float = float(os.getenv("DETECTION_CONFIDENCE", "0.5"))
    
    # Database
    DB_POOL_SIZE: int = int(os.getenv("DB_POOL_SIZE", "10"))
    DB_MAX_OVERFLOW: int = int(os.getenv("DB_MAX_OVERFLOW", "20"))
    
    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
