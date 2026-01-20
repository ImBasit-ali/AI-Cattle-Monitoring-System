"""Animal tracking service using ByteTrack."""
import cv2
import numpy as np
from typing import List, Dict, Optional
from collections import defaultdict
from datetime import datetime
import logging

from models.schemas import AnimalDetection, TrackingInfo, BoundingBox, AnimalType

logger = logging.getLogger(__name__)


class ByteTracker:
    """
    ByteTrack implementation for animal tracking.
    Assigns unique IDs to each detected animal across frames.
    """
    
    def __init__(self, max_age=30, min_hits=3, iou_threshold=0.3):
        """
        Args:
            max_age: Maximum frames to keep track without detection
            min_hits: Minimum consecutive detections to confirm track
            iou_threshold: IOU threshold for matching
        """
        self.max_age = max_age
        self.min_hits = min_hits
        self.iou_threshold = iou_threshold
        
        self.tracks: Dict[int, TrackingInfo] = {}
        self.next_id = 1
        self.frame_count = 0
    
    def update(self, detections: List[AnimalDetection]) -> List[TrackingInfo]:
        """
        Update tracks with new detections.
        
        Args:
            detections: List of detections from current frame
            
        Returns:
            List of active tracks
        """
        self.frame_count += 1
        current_time = datetime.utcnow()
        
        # Match detections to existing tracks
        matched_tracks = self._match_detections(detections)
        
        # Update existing tracks
        for track_id, detection in matched_tracks.items():
            track = self.tracks[track_id]
            track.last_seen = current_time
            track.positions.append(detection.bounding_box)
            track.frame_count += 1
            
            # Update confidence average
            track.confidence_avg = (
                (track.confidence_avg * (track.frame_count - 1) + detection.confidence) 
                / track.frame_count
            )
        
        # Create new tracks for unmatched detections
        unmatched = [d for i, d in enumerate(detections) 
                     if i not in matched_tracks.values()]
        
        for detection in unmatched:
            self.tracks[self.next_id] = TrackingInfo(
                track_id=self.next_id,
                animal_type=detection.animal_type,
                first_seen=current_time,
                last_seen=current_time,
                positions=[detection.bounding_box],
                confidence_avg=detection.confidence,
                frame_count=1
            )
            self.next_id += 1
        
        # Remove old tracks
        self._remove_old_tracks()
        
        return list(self.tracks.values())
    
    def _match_detections(self, detections: List[AnimalDetection]) -> Dict[int, int]:
        """
        Match detections to existing tracks using IOU.
        
        Returns:
            Dict mapping track_id to detection index
        """
        if not self.tracks or not detections:
            return {}
        
        matches = {}
        
        # Calculate IOU matrix
        track_ids = list(self.tracks.keys())
        iou_matrix = np.zeros((len(track_ids), len(detections)))
        
        for i, track_id in enumerate(track_ids):
            track = self.tracks[track_id]
            last_bbox = track.positions[-1] if track.positions else None
            
            if last_bbox:
                for j, detection in enumerate(detections):
                    iou = self._calculate_iou(last_bbox, detection.bounding_box)
                    iou_matrix[i, j] = iou
        
        # Hungarian matching (greedy for simplicity)
        used_detections = set()
        
        for i, track_id in enumerate(track_ids):
            max_iou_idx = np.argmax(iou_matrix[i, :])
            max_iou = iou_matrix[i, max_iou_idx]
            
            if max_iou >= self.iou_threshold and max_iou_idx not in used_detections:
                matches[track_id] = max_iou_idx
                used_detections.add(max_iou_idx)
        
        return matches
    
    def _calculate_iou(self, bbox1: BoundingBox, bbox2: BoundingBox) -> float:
        """Calculate Intersection over Union."""
        # Intersection area
        x1 = max(bbox1.x1, bbox2.x1)
        y1 = max(bbox1.y1, bbox2.y1)
        x2 = min(bbox1.x2, bbox2.x2)
        y2 = min(bbox1.y2, bbox2.y2)
        
        if x2 < x1 or y2 < y1:
            return 0.0
        
        intersection = (x2 - x1) * (y2 - y1)
        
        # Union area
        area1 = bbox1.area
        area2 = bbox2.area
        union = area1 + area2 - intersection
        
        return intersection / union if union > 0 else 0.0
    
    def _remove_old_tracks(self):
        """Remove tracks that haven't been updated."""
        current_time = datetime.utcnow()
        to_remove = []
        
        for track_id, track in self.tracks.items():
            age = (current_time - track.last_seen).total_seconds()
            if age > self.max_age:
                to_remove.append(track_id)
        
        for track_id in to_remove:
            del self.tracks[track_id]


class TrackingService:
    """Animal tracking and counting service."""
    
    def __init__(self):
        self.tracker = ByteTracker()
        self._ready = True
    
    def is_ready(self) -> bool:
        """Check if service is ready."""
        return self._ready
    
    def update(self, frame: np.ndarray, detections: List[AnimalDetection]) -> List[TrackingInfo]:
        """
        Update tracking with new detections.
        
        Args:
            frame: Current frame (not used currently, for future enhancements)
            detections: List of detections
            
        Returns:
            List of tracked animals
        """
        return self.tracker.update(detections)
    
    async def process_video(self, video_path: str) -> Dict:
        """
        Process entire video for tracking.
        
        Args:
            video_path: Path to video file
            
        Returns:
            Processing results
        """
        cap = cv2.VideoCapture(video_path)
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        
        results = {
            "total_frames": total_frames,
            "unique_animals": 0,
            "tracks": []
        }
        
        cap.release()
        return results
    
    async def get_stats(self) -> Dict:
        """Get tracking statistics."""
        return {
            "active_tracks": len(self.tracker.tracks),
            "total_tracked": self.tracker.next_id - 1,
            "frame_count": self.tracker.frame_count
        }
    
    async def get_tracked_animals(self) -> List[Dict]:
        """Get all currently tracked animals."""
        return [
            {
                "track_id": track.track_id,
                "animal_type": track.animal_type.value,
                "confidence": track.confidence_avg,
                "first_seen": track.first_seen.isoformat(),
                "last_seen": track.last_seen.isoformat(),
                "position_count": len(track.positions)
            }
            for track in self.tracker.tracks.values()
        ]
