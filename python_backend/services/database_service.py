"""Database service for Supabase integration."""
import logging
from typing import Dict, List, Optional, Any
from datetime import datetime, timedelta
from supabase import create_client, Client
import asyncio

from config import settings
from models.schemas import (
    AnimalDetection,
    TrackingInfo,
    MilkingStatus,
    LamenessStatus
)

logger = logging.getLogger(__name__)


class DatabaseService:
    """Service for database operations with Supabase."""
    
    def __init__(self):
        self.client: Optional[Client] = None
        self._ready = False
    
    async def initialize(self):
        """Initialize Supabase client."""
        try:
            self.client = create_client(
                settings.SUPABASE_URL,
                settings.SUPABASE_SERVICE_KEY
            )
            
            # Test connection
            await self.health_check()
            
            self._ready = True
            logger.info("✅ Database service initialized")
            
        except Exception as e:
            logger.error(f"Failed to initialize database service: {e}")
            raise
    
    async def health_check(self) -> bool:
        """Check database connection health."""
        try:
            if self.client is None:
                return False
            
            # Simple query to test connection
            result = self.client.table('animals').select('count').limit(1).execute()
            return True
            
        except Exception as e:
            logger.error(f"Database health check failed: {e}")
            return False
    
    async def close(self):
        """Close database connections."""
        self._ready = False
        logger.info("Database service closed")
    
    # ==================== DETECTIONS ====================
    
    async def save_detection(self, detection: AnimalDetection) -> Dict:
        """
        Save animal detection to database.
        
        Args:
            detection: AnimalDetection object
            
        Returns:
            Saved record
        """
        try:
            data = {
                "detection_id": detection.detection_id,
                "animal_type": detection.animal_type.value,
                "confidence": detection.confidence,
                "bbox_x1": detection.bounding_box.x1,
                "bbox_y1": detection.bounding_box.y1,
                "bbox_x2": detection.bounding_box.x2,
                "bbox_y2": detection.bounding_box.y2,
                "detected_at": detection.timestamp.isoformat()
            }
            
            result = self.client.table('detections').insert(data).execute()
            return result.data[0] if result.data else {}
            
        except Exception as e:
            logger.error(f"Failed to save detection: {e}")
            return {}
    
    # ==================== TRACKING ====================
    
    async def save_tracking(self, tracking: TrackingInfo) -> Dict:
        """Save tracking information."""
        try:
            data = {
                "track_id": tracking.track_id,
                "animal_type": tracking.animal_type.value,
                "first_seen": tracking.first_seen.isoformat(),
                "last_seen": tracking.last_seen.isoformat(),
                "confidence_avg": tracking.confidence_avg,
                "frame_count": tracking.frame_count
            }
            
            result = self.client.table('animal_tracks').upsert(data).execute()
            return result.data[0] if result.data else {}
            
        except Exception as e:
            logger.error(f"Failed to save tracking: {e}")
            return {}
    
    # ==================== MILKING STATUS ====================
    
    async def save_milking_status(self, animal_id: str, status: MilkingStatus) -> Dict:
        """Save milking status for an animal."""
        try:
            data = {
                "animal_id": animal_id,
                "status": status.status.value,
                "confidence": status.confidence,
                "udder_detected": status.udder_detection.detected if status.udder_detection else False,
                "udder_size": status.udder_detection.udder_size if status.udder_detection else None,
                "behavioral_score": status.behavioral_score,
                "detected_at": status.timestamp.isoformat()
            }
            
            result = self.client.table('milking_status').insert(data).execute()
            
            # Update animal record
            self.client.table('animals').update({
                "milking_status": status.status.value,
                "last_milking_check": status.timestamp.isoformat()
            }).eq("animal_id", animal_id).execute()
            
            return result.data[0] if result.data else {}
            
        except Exception as e:
            logger.error(f"Failed to save milking status: {e}")
            return {}
    
    # ==================== LAMENESS STATUS ====================
    
    async def save_video_processing_results(self, cattle_id: str, results: Dict[str, Any]) -> Dict:
        """Save complete video processing results to database."""
        try:
            # Generate ear tag number if needed
            ear_tag_number = f"TAG-{cattle_id[-8:]}" if len(cattle_id) > 8 else f"TAG-{cattle_id}"
            
            # Save to ear_tag_camera table for cattle detection
            detection_data = {
                "cow_id": cattle_id,
                "animal_id": cattle_id,
                "ear_tag_number": ear_tag_number,
                "species": "Cow" if results.get('cattle_count', 0) > 0 else "Buffalo",
                "confidence": results.get('avg_confidence', 0.0) * 100,  # Convert to percentage
                "detection_timestamp": datetime.utcnow().isoformat(),
                "timestamp": datetime.utcnow().isoformat(),
            }
            
            detection_result = self.client.table('ear_tag_camera').insert(detection_data).execute()
            logger.info(f"✅ Saved detection to ear_tag_camera for {cattle_id}")
            
            # Save milking status if detected
            if results.get('is_being_milked') is not None:
                milking_data = {
                    "cow_id": cattle_id,
                    "is_being_milked": results.get('is_being_milked', False),
                    "milking_confidence": results.get('milking_confidence', 0.0) * 100,
                    "udder_detected": results.get('udder_detected', False),
                    "behavioral_score": results.get('behavioral_score', 0.0),
                    "timestamp": datetime.utcnow().isoformat(),
                }
                self.client.table('milking_status').insert(milking_data).execute()
                logger.info(f"✅ Saved milking status for {cattle_id}")
            
            # Save lameness status if detected
            if results.get('lameness_score') is not None:
                lameness_data = {
                    "cow_id": cattle_id,
                    "lameness_score": int(results.get('lameness_score', 0)),
                    "lameness_severity": self._get_lameness_severity(results.get('lameness_score', 0)),
                    "timestamp": datetime.utcnow().isoformat(),
                }
                self.client.table('depth_camera').insert(lameness_data).execute()
                logger.info(f"✅ Saved lameness data for {cattle_id}")
            
            # Update or create in animals table
            animal_update = {
                "updated_at": datetime.utcnow().isoformat(),
                "last_detection": datetime.utcnow().isoformat(),
            }
            
            if results.get('is_being_milked') is not None:
                animal_update["milking_status"] = "milking" if results.get('is_being_milked') else "dry"
                animal_update["last_milking_check"] = datetime.utcnow().isoformat()
            
            if results.get('lameness_score') is not None:
                animal_update["lameness_level"] = self._get_lameness_level(results.get('lameness_score', 0))
                animal_update["lameness_score"] = results.get('lameness_score', 0)
                animal_update["last_health_check"] = datetime.utcnow().isoformat()
            
            # Check if animal exists, if not create
            existing = self.client.table('animals').select('id').eq('animal_id', cattle_id).execute()
            
            if existing.data:
                self.client.table('animals').update(animal_update).eq('animal_id', cattle_id).execute()
                logger.info(f"✅ Updated animal record for {cattle_id}")
            else:
                animal_update["animal_id"] = cattle_id
                animal_update["species"] = detection_data["species"]
                animal_update["health_status"] = "Healthy" if results.get('lameness_score', 0) <= 1 else "Sick"
                self.client.table('animals').insert(animal_update).execute()
                logger.info(f"✅ Created new animal record for {cattle_id}")
            
            logger.info(f"🎯 All video processing results saved for {cattle_id}")
            return detection_result.data[0] if detection_result.data else {}
            
        except Exception as e:
            logger.error(f"Failed to save video processing results: {e}")
            import traceback
            traceback.print_exc()
            return {}
    
    def _get_lameness_severity(self, score: float) -> str:
        """Convert lameness score to severity level."""
        if score <= 1:
            return "normal"
        elif score <= 2:
            return "mild"
        elif score <= 3:
            return "moderate"
        else:
            return "severe"
    
    def _get_lameness_level(self, score: float) -> str:
        """Convert lameness score to level."""
        if score <= 1:
            return "normal"
        elif score <= 2:
            return "mild"
        elif score <= 3:
            return "moderate"
        else:
            return "severe"
    
    async def save_lameness_status(self, animal_id: str, status: LamenessStatus) -> Dict:
        """Save lameness detection result."""
        try:
            data = {
                "animal_id": animal_id,
                "lameness_level": status.level.value,
                "confidence": status.confidence,
                "step_length": status.gait_features.step_length,
                "step_symmetry": status.gait_features.step_symmetry,
                "walking_speed": status.gait_features.walking_speed,
                "back_curvature": status.gait_features.back_curvature,
                "affected_leg": status.affected_leg,
                "detected_at": status.timestamp.isoformat()
            }
            
            result = self.client.table('lameness_detections').insert(data).execute()
            
            # Update animal health status
            if status.level.value in ["moderate", "severe"]:
                self.client.table('animals').update({
                    "health_status": "attention_required",
                    "lameness_level": status.level.value,
                    "last_health_check": status.timestamp.isoformat()
                }).eq("animal_id", animal_id).execute()
            
            return result.data[0] if result.data else {}
            
        except Exception as e:
            logger.error(f"Failed to save lameness status: {e}")
            return {}
    
    # ==================== CAMERAS ====================
    
    async def get_camera(self, camera_id: str) -> Optional[Dict]:
        """Get camera information."""
        try:
            result = self.client.table('cameras').select('*').eq('camera_id', camera_id).execute()
            return result.data[0] if result.data else None
            
        except Exception as e:
            logger.error(f"Failed to get camera: {e}")
            return None
    
    async def get_all_cameras(self) -> List[Dict]:
        """Get all active cameras."""
        try:
            result = self.client.table('cameras').select('*').eq('is_active', True).execute()
            return result.data if result.data else []
            
        except Exception as e:
            logger.error(f"Failed to get cameras: {e}")
            return []
    
    # ==================== STATISTICS ====================
    
    async def get_daily_stats(self) -> Dict:
        """Get daily statistics."""
        try:
            today = datetime.utcnow().date()
            tomorrow = today + timedelta(days=1)
            
            # Total animals
            animals_result = self.client.table('animals').select('count').execute()
            total_animals = len(animals_result.data) if animals_result.data else 0
            
            # Today's detections
            detections_result = self.client.table('detections').select('count') \
                .gte('detected_at', today.isoformat()) \
                .lt('detected_at', tomorrow.isoformat()) \
                .execute()
            
            today_detections = len(detections_result.data) if detections_result.data else 0
            
            # Milking animals
            milking_result = self.client.table('animals').select('count') \
                .eq('milking_status', 'milking').execute()
            
            milking_count = len(milking_result.data) if milking_result.data else 0
            
            # Health alerts
            alerts_result = self.client.table('animals').select('count') \
                .eq('health_status', 'attention_required').execute()
            
            alerts_count = len(alerts_result.data) if alerts_result.data else 0
            
            return {
                "total_animals": total_animals,
                "today_detections": today_detections,
                "milking_animals": milking_count,
                "health_alerts": alerts_count,
                "date": today.isoformat()
            }
            
        except Exception as e:
            logger.error(f"Failed to get daily stats: {e}")
            return {
                "total_animals": 0,
                "today_detections": 0,
                "milking_animals": 0,
                "health_alerts": 0,
                "date": datetime.utcnow().date().isoformat()
            }
    
    async def get_health_stats(self) -> Dict:
        """Get health monitoring statistics."""
        try:
            # Lameness distribution
            lameness_result = self.client.table('animals').select('lameness_level').execute()
            
            lameness_counts = {
                "normal": 0,
                "mild": 0,
                "moderate": 0,
                "severe": 0
            }
            
            if lameness_result.data:
                for animal in lameness_result.data:
                    level = animal.get('lameness_level', 'normal')
                    if level in lameness_counts:
                        lameness_counts[level] += 1
            
            # Milking distribution
            milking_result = self.client.table('animals').select('milking_status').execute()
            
            milking_counts = {
                "milking": 0,
                "dry": 0,
                "unknown": 0
            }
            
            if milking_result.data:
                for animal in milking_result.data:
                    status = animal.get('milking_status', 'unknown')
                    if status in milking_counts:
                        milking_counts[status] += 1
            
            return {
                "lameness": lameness_counts,
                "milking": milking_counts,
                "timestamp": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Failed to get health stats: {e}")
            return {
                "lameness": {"normal": 0, "mild": 0, "moderate": 0, "severe": 0},
                "milking": {"milking": 0, "dry": 0, "unknown": 0},
                "timestamp": datetime.utcnow().isoformat()
            }
    
    # ==================== ANIMALS ====================
    
    async def get_animal(self, animal_id: str) -> Optional[Dict]:
        """Get animal by ID."""
        try:
            result = self.client.table('animals').select('*').eq('animal_id', animal_id).execute()
            return result.data[0] if result.data else None
            
        except Exception as e:
            logger.error(f"Failed to get animal: {e}")
            return None
    
    async def update_animal(self, animal_id: str, data: Dict) -> Dict:
        """Update animal information."""
        try:
            result = self.client.table('animals').update(data).eq('animal_id', animal_id).execute()
            return result.data[0] if result.data else {}
            
        except Exception as e:
            logger.error(f"Failed to update animal: {e}")
            return {}
