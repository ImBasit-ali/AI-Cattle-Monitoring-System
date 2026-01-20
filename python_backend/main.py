"""FastAPI Backend for Cattle AI Monitoring System."""
import asyncio
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
from typing import List, Dict, Any
import cv2
import numpy as np
from datetime import datetime
import logging

from config import settings
from services.detection_service import DetectionService
from services.tracking_service import TrackingService
from services.milking_service import MilkingService
from services.lameness_service import LamenessService
from services.database_service import DatabaseService
from services.video_processing_service import VideoProcessingService
from models.schemas import (
    AnimalDetection,
    TrackingInfo,
    MilkingStatus,
    LamenessStatus,
    CameraStream
)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="Cattle AI Monitoring API",
    description="Real-time cattle detection, tracking, and health monitoring",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure based on your Flutter app domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize services
detection_service = DetectionService()
tracking_service = TrackingService()
milking_service = MilkingService()
lameness_service = LamenessService()
db_service = DatabaseService()
video_processing_service = VideoProcessingService()


# ==================== STARTUP & SHUTDOWN ====================

@app.on_event("startup")
async def startup_event():
    """Initialize services on startup."""
    logger.info("🚀 Starting Cattle AI Backend...")
    
    try:
        # Initialize ML models
        await detection_service.initialize()
        await milking_service.initialize()
        await lameness_service.initialize()
        
        # Initialize database connection
        await db_service.initialize()
        
        logger.info("✅ All services initialized successfully")
    except Exception as e:
        logger.error(f"❌ Startup failed: {e}")
        raise


@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown."""
    logger.info("🛑 Shutting down Cattle AI Backend...")
    await db_service.close()


# ==================== HEALTH CHECK ====================

@app.get("/")
async def root():
    """API health check."""
    return {
        "status": "online",
        "service": "Cattle AI Monitoring API",
        "version": "1.0.0",
        "timestamp": datetime.utcnow().isoformat()
    }


@app.get("/health")
async def health_check():
    """Detailed health check."""
    return {
        "status": "healthy",
        "services": {
            "detection": detection_service.is_ready(),
            "tracking": tracking_service.is_ready(),
            "milking": milking_service.is_ready(),
            "lameness": lameness_service.is_ready(),
            "database": await db_service.health_check()
        },
        "timestamp": datetime.utcnow().isoformat()
    }


# ==================== DETECTION ENDPOINTS ====================

@app.post("/api/detect")
async def detect_animals(file: UploadFile = File(...)):
    """
    Detect cows and buffaloes in an uploaded image.
    
    - **file**: Image file (JPEG, PNG)
    
    Returns:
        List of detected animals with bounding boxes and confidence
    """
    try:
        # Read image
        contents = await file.read()
        nparr = np.frombuffer(contents, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        # Run detection
        detections = detection_service.detect(image)
        
        # Save to database
        for detection in detections:
            await db_service.save_detection(detection)
        
        return {
            "success": True,
            "count": len(detections),
            "detections": [d.dict() for d in detections],
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Detection error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/detect-video")
async def detect_video(file: UploadFile = File(...)):
    """
    Process video for animal detection and tracking.
    
    - **file**: Video file (MP4, AVI)
    
    Returns:
        Detection and tracking results for the entire video
    """
    try:
        # Save uploaded video temporarily
        video_path = f"/tmp/{file.filename}"
        contents = await file.read()
        with open(video_path, "wb") as f:
            f.write(contents)
        
        # Process video
        results = await tracking_service.process_video(video_path)
        
        return {
            "success": True,
            "results": results,
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Video processing error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==================== TRACKING ENDPOINTS ====================

@app.get("/api/tracking/stats")
async def get_tracking_stats():
    """Get current tracking statistics."""
    try:
        stats = await tracking_service.get_stats()
        return {
            "success": True,
            "stats": stats,
            "timestamp": datetime.utcnow().isoformat()
        }
    except Exception as e:
        logger.error(f"Tracking stats error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/tracking/animals")
async def get_tracked_animals():
    """Get all currently tracked animals."""
    try:
        animals = await tracking_service.get_tracked_animals()
        return {
            "success": True,
            "count": len(animals),
            "animals": animals,
            "timestamp": datetime.utcnow().isoformat()
        }
    except Exception as e:
        logger.error(f"Get tracked animals error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==================== MILKING DETECTION ENDPOINTS ====================

@app.post("/api/milking/detect")
async def detect_milking_status(file: UploadFile = File(...), animal_id: str = None):
    """
    Detect milking status (lactating or dry) from image.
    
    - **file**: Image file showing the animal's udder
    - **animal_id**: Optional animal ID for tracking
    """
    try:
        # Read image
        contents = await file.read()
        nparr = np.frombuffer(contents, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        # Detect milking status
        status = milking_service.detect_milking_status(image)
        
        # Save to database if animal_id provided
        if animal_id:
            await db_service.save_milking_status(animal_id, status)
        
        return {
            "success": True,
            "status": status.dict(),
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Milking detection error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==================== LAMENESS DETECTION ENDPOINTS ====================

@app.post("/api/lameness/detect")
async def detect_lameness(file: UploadFile = File(...), animal_id: str = None):
    """
    Detect lameness from video showing animal walking.
    
    - **file**: Video file showing the animal walking
    - **animal_id**: Optional animal ID for tracking
    """
    try:
        # Save video temporarily
        video_path = f"/tmp/{file.filename}"
        contents = await file.read()
        with open(video_path, "wb") as f:
            f.write(contents)
        
        # Analyze gait and detect lameness
        lameness_result = await lameness_service.analyze_gait(video_path)
        
        # Save to database if animal_id provided
        if animal_id:
            await db_service.save_lameness_status(animal_id, lameness_result)
        
        return {
            "success": True,
            "lameness": lameness_result.dict(),
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Lameness detection error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==================== REAL-TIME CAMERA STREAM ====================

class ConnectionManager:
    """Manages WebSocket connections for real-time streaming."""
    
    def __init__(self):
        self.active_connections: List[WebSocket] = []
    
    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)
    
    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)
    
    async def broadcast(self, message: dict):
        for connection in self.active_connections:
            try:
                await connection.send_json(message)
            except:
                pass


manager = ConnectionManager()


@app.websocket("/ws/camera/{camera_id}")
async def camera_stream(websocket: WebSocket, camera_id: str):
    """
    Real-time camera stream with ML processing.
    
    Processes frames and sends detection results via WebSocket.
    """
    await manager.connect(websocket)
    
    try:
        # Get camera stream URL from database
        camera_info = await db_service.get_camera(camera_id)
        
        if not camera_info:
            await websocket.send_json({"error": "Camera not found"})
            return
        
        # Initialize video capture
        cap = cv2.VideoCapture(camera_info.get("rtsp_url", 0))
        
        while True:
            ret, frame = cap.read()
            if not ret:
                break
            
            # Run detection
            detections = detection_service.detect(frame)
            
            # Track animals
            tracked = tracking_service.update(frame, detections)
            
            # Send results
            await websocket.send_json({
                "camera_id": camera_id,
                "detections": [d.dict() for d in detections],
                "tracking": tracked,
                "timestamp": datetime.utcnow().isoformat()
            })
            
            # Control frame rate
            await asyncio.sleep(1.0 / settings.CAMERA_FPS)
    
    except WebSocketDisconnect:
        manager.disconnect(websocket)
        logger.info(f"Camera {camera_id} stream disconnected")
    
    except Exception as e:
        logger.error(f"Camera stream error: {e}")
    
    finally:
        if 'cap' in locals():
            cap.release()


# ==================== VIDEO PROCESSING ENDPOINTS ====================

@app.post("/api/video/process")
async def process_video_upload(file: UploadFile = File(...), cattle_id: str = ""):
    """
    Process uploaded video with YOLOv8 for complete analysis:
    1. Animal detection and counting (cattle, buffalo filtering)
    2. Milking status assessment
    3. Lameness detection
    
    Returns comprehensive results and saves to database for real-time updates.
    """
    import tempfile
    import os
    import uuid
    
    try:
        # Save uploaded file temporarily
        with tempfile.NamedTemporaryFile(delete=False, suffix='.mp4') as tmp_file:
            content = await file.read()
            tmp_file.write(content)
            video_path = tmp_file.name
        
        # Process video through ML pipeline
        results = await video_processing_service.process_video(video_path)
        
        # Generate unique cattle ID if not provided
        if not cattle_id or cattle_id.strip() == "":
            cattle_id = f"COW-{uuid.uuid4().hex[:8].upper()}"
        
        # Save results to database for real-time dashboard updates
        try:
            await db_service.save_video_processing_results(cattle_id, results)
            logger.info(f"✅ Video processing results saved to database for {cattle_id}")
        except Exception as db_error:
            logger.error(f"⚠️ Failed to save to database: {db_error}")
            # Continue even if DB save fails
        
        # Clean up temp file
        os.unlink(video_path)
        
        return {
            **results,
            "cattle_id": cattle_id,
            "timestamp": datetime.utcnow().isoformat(),
            "saved_to_database": True
        }
        
    except Exception as e:
        logger.error(f"Video processing error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/video/detect-animals")
async def detect_animals_in_video(file: UploadFile = File(...)):
    """
    Detect and classify animals in video using YOLOv8.
    Returns cattle count, buffalo count, and filters out other animals.
    """
    import tempfile
    import os
    
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix='.mp4') as tmp_file:
            content = await file.read()
            tmp_file.write(content)
            video_path = tmp_file.name
        
        results = await video_processing_service.detect_animals(video_path)
        os.unlink(video_path)
        
        return {
            "success": True,
            **results,
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Animal detection error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==================== STATISTICS & ANALYTICS ====================

@app.get("/api/stats/daily")
async def get_daily_stats():
    """Get daily statistics."""
    try:
        stats = await db_service.get_daily_stats()
        return {
            "success": True,
            "stats": stats,
            "timestamp": datetime.utcnow().isoformat()
        }
    except Exception as e:
        logger.error(f"Daily stats error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/stats/health")
async def get_health_stats():
    """Get health monitoring statistics."""
    try:
        health_stats = await db_service.get_health_stats()
        return {
            "success": True,
            "health": health_stats,
            "timestamp": datetime.utcnow().isoformat()
        }
    except Exception as e:
        logger.error(f"Health stats error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==================== MAIN ====================

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=settings.API_HOST,
        port=settings.API_PORT,
        reload=settings.API_RELOAD
    )
