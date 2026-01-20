# Research Paper Implementation Guide

## AI-Powered Cattle Health Monitoring System
**Based on:** Smart Agricultural Technology 12 (2025) 101300  
**Published:** August 11, 2025  
**Citation:** Moe et al., University of Miyazaki, Japan

---

## 📋 Table of Contents

1. [System Overview](#system-overview)
2. [Architecture](#architecture)
3. [Camera System](#camera-system)
4. [AI Functions](#ai-functions)
5. [Database Schema](#database-schema)
6. [Technology Stack](#technology-stack)
7. [Implementation Details](#implementation-details)
8. [Deployment Guide](#deployment-guide)
9. [Performance Metrics](#performance-metrics)
10. [Future Enhancements](#future-enhancements)

---

## 🎯 System Overview

This system implements a **real-time, AI-powered, multi-modal cattle health monitoring platform** that integrates five key functionalities across four functional zones using 22 cameras.

### Key Features

1. **Multi-Method Cattle Identification**
   - Ear-tag recognition (94.00% accuracy)
   - Facial recognition (93.66% accuracy)
   - Body recognition (92.80% accuracy)
   - Point cloud identification (99.55% accuracy)

2. **Health Monitoring**
   - Body Condition Scoring - BCS (86.21% accuracy)
   - Lameness Detection (88.88% accuracy)

3. **Behavior Analysis**
   - Feeding time estimation
   - Real-time localization across barn zones

4. **System Performance**
   - Average latency: 0.62s per frame per camera
   - 24-hour continuous operation
   - Multiprocessing architecture for parallel camera processing

---

## 🏗️ Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────────┐
│                    User Side Application                │
│              (Flutter Mobile App - Clean Architecture)  │
└──────────────────┬──────────────────────────────────────┘
                   │
                   │ RESTful API (FastAPI)
                   │
┌──────────────────▼──────────────────────────────────────┐
│                   Local Server                           │
│  ┌──────────────┬──────────────┬────────────────────┐   │
│  │ MySQL DB     │ Vector DB    │ File Server (NAS)  │   │
│  │ (7 tables)   │ (Embeddings) │ (Videos/Images)    │   │
│  └──────────────┴──────────────┴────────────────────┘   │
└──────────────────┬──────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────┐
│              Farm Side Application                       │
│        (Python Desktop App - Multiprocessing)            │
│                                                          │
│  Process 1    Process 2    ...    Process 22            │
│  Camera 1     Camera 2           Camera 22              │
└──────────────────┬──────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────┐
│                 Camera System                            │
│  22 Cameras: 7×4K RGB, 13×Full HD, 1×ToF, 1×RGB-D      │
│  Zones: Milking | Return | Feeding | Resting            │
└─────────────────────────────────────────────────────────┘
```

---

## 📹 Camera System

### Camera Distribution

| Zone | Cameras | Types | Purpose |
|------|---------|-------|---------|
| **Milking Parlor** | 1-2 | 4K RGB | Ear-tag & face identification |
| **Return Lane** | 3-5 | Depth, RGB-D, RGB | Lameness, BCS, body ID |
| **Feeding Area** | 7-10 | 4K RGB | Face ID & feeding time |
| **Resting/Feeding** | 11-23 | Full HD RGB | Body ID & localization |

### Camera Specifications

```dart
// Camera Types
- 7× 4K RGB Cameras (1920×1080 resolution)
- 13× Full HD RGB Cameras  
- 1× Time-of-Flight (ToF) Depth Camera
- 1× RGB-D Camera (Color + Depth)

// Network Configuration
- IP-based streaming
- Centralized design with distributed processing
- Real-time video processing
```

---

## 🤖 AI Functions

### 1. Ear-Tag Identification (Cameras 1-2)

**Accuracy:** 94.00%  
**Method:** CRAFT + ResNet18

```
Pipeline:
1. YOLOv8 → Detect cattle head
2. IoU Tracking → Track individual heads
3. Color-based → Extract ear-tag region
4. CRAFT → Detect characters
5. Otsu Thresholding → Binarize characters
6. ResNet18 → Classify 12 characters (0-9, J, M)
```

**Data Attribute:** Attribute 4.2 (Ear-tag RGB images)

### 2. Lameness Detection - Depth (Camera 3)

**Accuracy:** 88.2% (morning), 89.0% (evening)  
**Method:** Detectron2 + Extra Trees

```
Pipeline:
1. Detectron2 → Segment cattle body from depth
2. IoU Tracking → Track depth regions
3. Feature Extraction → Back depth features
4. Extra Trees Classifier → Classify lameness (0-5 scale)
```

**Severity Levels:**
- 0-1: Normal
- 2-3: Mild Lameness
- 4-5: Severe Lameness

**Data Attribute:** Attribute 2 (Depth data)

### 3. Lameness Detection - RGB (Camera 5)

**Method:** YOLOv9 + SVM

```
Pipeline:
1. YOLOv9 → Detect cattle
2. Keypoint Tracking → Track leg keypoints
3. Temporal Analysis → Extract gait patterns
4. SVM → Classify lameness from movement
```

**Data Attribute:** Attribute 1 (Side-view RGB images)

### 4. Body Condition Scoring (Camera 4)

**Accuracy:** 86.21% (tolerance 0.25)  
**Method:** PointNet++ + Random Forest

```
Pipeline:
1. Detectron2 → Detect from 2D depth
2. Convert to Point Cloud → 2048 downsampled points
3. Extract Features:
   - Normal vectors, curvature, density
   - Planarity, linearity, sphericity
   - FPFH descriptors
   - Triangle mesh & convex hull areas
4. Random Forest → Classify BCS (1.0-5.0 scale)
```

**BCS Categories:**
- 1.0-2.0: Thin
- 2.5-3.5: Optimal
- 4.0-5.0: Overweight

**Data Attribute:** Attribute 5 (Point cloud data)

### 5. Point Cloud Identification (Camera 4)

**Accuracy:** 99.55%  
**Method:** PointNet++ Siamese Network

```
Pipeline:
1. Detectron2 → Detect body from depth
2. Custom IoU Tracker → Track individuals
3. PointNet++ Siamese → Extract embeddings (256-dim)
4. Triplet Loss Training → Discriminative features
5. Database Matching → Predict ID without retraining
```

**Data Attribute:** Attribute 5 (Point cloud data)

### 6. Face Identification (Cameras 7-10)

**Accuracy:** 93.66%  
**Method:** Mask R-CNN + ArcFace

```
Pipeline:
1. Mask R-CNN → Detect head regions
2. IoU + Siamese → Enhanced tracking
3. ArcFace Model → Generate facial embeddings (512-dim)
4. Database Matching → Identify individual
```

**Data Attributes:** Attribute 4.1 (Cow head RGB images)

### 7. Feeding Time Calculation (Cameras 7-10)

```
Pipeline:
1. Face Identification → Identify cattle
2. Define Feeding Line → Virtual line in image
3. Position Detection → Track head Y-coordinate
4. Time Accumulation → Sum frames when head below line
5. Database Storage → Record total feeding time
```

**Data Attribute:** Attribute 4.1 (Cow head RGB images)

### 8. Body Identification & Localization (Cameras 11-23)

**Accuracy:** 92.80%  
**Method:** Mask R-CNN + ByteTrack + ResNet-101

```
Pipeline:
1. Mask R-CNN → Detect & segment body
2. ByteTrack → Multi-object tracking
3. ResNet-101 → Extract body embeddings (512-dim)
4. Record Position → Store (x,y) coordinates
5. Zone Tracking → Monitor zone transitions
6. One-Minute Intervals → Database updates
```

**Data Attribute:** Attribute 3 (Back-view RGB images)

---

## 🗄️ Database Schema

### 7-Table Structure

#### Table 1: `cow` - Main Registry

```sql
- General info: cattle_id, ear_tag_number, species, breed
- Current status: health_status, current_zone, last_seen
- Latest scores: bcs_score, lameness_score, severity
- Body measurements: estimated_body_weight
- Feeding stats: total_daily_feeding_time_hours
- Embeddings: face_embedding, body_embedding, point_cloud_embedding
```

#### Table 2: `ear_tag_camera` - Milking Parlor

```sql
- Recognition: ear_tag_number, confidence (CRAFT+ResNet18)
- Camera: camera_number (1-2), functional_zone
- Images: head_image_url, ear_tag_crop_url
- Characters: detected_characters (JSON array)
- Milking: session_start, session_end, position
```

#### Table 3: `depth_camera` - Lameness (Depth)

```sql
- Classification: lameness_score (0-5), severity, confidence
- Method: Detectron2 + Extra Trees
- Time: time_of_day (Morning/Evening)
- Features: back_depth_features, segmentation_mask
- Tracking: tracking_id, frame_number
- Link: related_milking_session_id
```

#### Table 4: `side_view_camera` - Lameness (RGB)

```sql
- Classification: lameness_score (0-5), severity, confidence
- Method: YOLOv9 + SVM
- Gait: leg_keypoints, gait_features, trajectory
- Sequence: start_frame, end_frame, total_frames
- Video: video_clip_url
```

#### Table 5: `rgbd_camera` - BCS & Identification

```sql
- BCS: bcs_score (1.0-5.0), confidence, tolerance
- Point Cloud: point_cloud_url, 2048 points
- Geometric Features: normal_vectors, curvature, density,
  planarity, linearity, sphericity, FPFH, mesh_area
- Body Weight: estimated_body_weight, confidence
- Method: PointNet++ (99.55%) + Random Forest (86.21%)
```

#### Table 6: `head_view_camera` - Feeding

```sql
- Identification: cattle_id_predicted, confidence (ArcFace 93.66%)
- Camera: camera_number (7-10), 4K RGB
- Face: facial_embedding (512-dim), features
- Feeding: feeding_line_y, head_position_y, is_feeding
- Time: session_start, session_end, duration_seconds
- Cumulative: cumulative_daily_feeding_seconds
```

#### Table 7: `back_view_camera` - Localization

```sql
- Identification: cattle_id_predicted, confidence (ResNet-101 92.80%)
- Camera: camera_number (11-23), Full HD
- Body: body_embedding (512-dim), color_features, shape_features
- Position: position_x, position_y, current_zone
- Tracking: tracking_id, ByteTrack algorithm
- Transitions: previous_camera, next_camera, transition_time
- Recording: one-minute interval markers
```

### Automatic Updates via Triggers

```sql
- update_cow_latest_bcs() → From rgbd_camera
- update_cow_latest_lameness() → From depth_camera
- update_cow_current_zone() → From back_view_camera (minute markers)
- update_cow_feeding_time() → From head_view_camera (session end)
```

---

## 💻 Technology Stack

### Farm-Side Application (Desktop)

```python
Language: Python 3.9
Framework: PyQt5 (GUI)
Deep Learning: PyTorch 2.0.1
Accelerator: CUDA 11.7
IDE: PyCharm

Detection Models:
- YOLOv8, YOLOv9 (object detection)
- Mask R-CNN, Detectron2 (instance segmentation)

Tracking:
- IoU-based custom tracker
- ByteTrack (multi-object)

Identification Models:
- CRAFT (character detection)
- ResNet18 (character classification)
- ResNet-101 (body features)
- ArcFace (facial embeddings)
- PointNet++ Siamese (point cloud)

Classification:
- Extra Trees (lameness from depth)
- SVM (lameness from gait)
- Random Forest (BCS)

Hardware:
- CPU: Intel Core i9-9900KF @ 3.60GHz
- GPU: NVIDIA Quadro RTX 8000
- OS: Windows 10 Pro
```

### User-Side Application (Mobile)

```dart
Language: Dart
Framework: Flutter
Architecture: Clean Architecture
IDE: Android Studio

Features:
- Real-time camera streams
- Dashboard with health metrics
- Individual cattle profiles
- Zone-based localization
- Feeding time reports
- BCS & lameness history
```

### Backend

```python
Database: MySQL
API: FastAPI (RESTful)
Vector Database: For embeddings storage
File Server: NAS for videos/images

Additional Storage:
- Relational DB: Health records (7 tables)
- Vector DB: Face/body/point cloud embeddings
- NAS: Raw video data for training
```

---

## 🔧 Implementation Details

### Multiprocessing Architecture

```python
# Farm-side application workflow

Process per Camera:
- Each camera = separate process
- Parallel execution of all functions
- Real-time visualization support

Main Process:
├─ Process 1  → Camera 1 (Ear-tag)
├─ Process 2  → Camera 2 (Ear-tag)
├─ Process 3  → Camera 3 (Depth lameness)
├─ Process 4  → Camera 4 (RGB-D: BCS + ID)
├─ Process 5  → Camera 5 (Side view lameness)
├─ Process 7-10 → Feeding cameras
└─ Process 11-23 → Localization cameras

Queue System:
- Shared queues for data exchange
- Database write queue
- API request queue
```

### Data Flow

```
1. Camera Stream → Camera Process
2. AI Processing → Detection/Tracking/Classification
3. Feature Extraction → Embeddings/Scores
4. Database Write → MySQL via queue
5. API Update → Real-time data push
6. Mobile App → Fetch via REST API
```

### Recording Intervals

```
Continuous:
- Video streaming (all cameras)
- Real-time detection & tracking

Event-driven:
- Ear-tag detection: When cattle enters milking
- Lameness: Post-milking (immediate)
- BCS: Post-milking (immediate)
- Feeding: Session start/end events

Scheduled:
- Feeding time: Frame-by-frame accumulation
- Localization: One-minute interval snapshots
- Daily reset: Feeding time counter at midnight
```

---

## 🚀 Deployment Guide

### Step 1: Database Setup

```sql
-- Run migrations in Supabase SQL Editor:

1. supabase/migrations/06_research_paper_schema.sql
   - Creates 7 tables
   - Sets up triggers
   - Creates materialized view

2. supabase/migrations/07_research_paper_rls.sql
   - Enables Row Level Security
   - Creates user-specific policies
```

### Step 2: Enable Vector Extension (if using Supabase)

```sql
-- For embedding storage
CREATE EXTENSION IF NOT EXISTS vector;
```

### Step 3: Flutter App Configuration

```dart
// lib/core/constants/app_constants_enhanced.dart
// Already includes research-based constants

Key Constants:
- totalCameras = 22
- averageLatencyPerFrame = 0.62
- Camera types, zones, accuracies
- All model configurations
```

### Step 4: Test Data

```sql
-- Insert sample cow
INSERT INTO cow (cattle_id, ear_tag_number, species) 
VALUES ('A-001', 'J1234', 'Dairy Cattle');

-- Insert sample ear-tag detection
INSERT INTO ear_tag_camera (cow_id, ear_tag_number, confidence, camera_number)
VALUES ('<cow_id>', 'J1234', 94.0, 1);
```

---

## 📊 Performance Metrics

### Identification Accuracies (Research Results)

| Method | Accuracy | Model |
|--------|----------|-------|
| **Point Cloud** | **99.55%** | PointNet++ Siamese |
| **Ear Tag** | 94.00% | CRAFT + ResNet18 |
| **Face** | 93.66% | ArcFace |
| **Body** | 92.80% | ResNet-101 |

### Health Monitoring Accuracies

| Function | Accuracy | Model |
|----------|----------|-------|
| **Lameness (Depth)** | 88.2% (AM), 89.0% (PM) | Detectron2 + Extra Trees |
| **BCS (Tol 0.25)** | 86.21% | Random Forest |
| **BCS (Tol 0.5)** | 97.83% | Random Forest |
| **BCS (Exact)** | 51.36% | Random Forest |

### System Performance

```
Average Latency: 0.62s per frame per camera
Total Cameras: 22
Concurrent Processing: Multiprocessing (one process per camera)
Uptime: 24-hour continuous operation
Network: IP-based centralized camera system
```

---

## 🔮 Future Enhancements

### Current Limitations (from Research Paper)

1. **Computational Demands**
   - Processing 22 cameras requires high-end GPU
   - Recommended: NVIDIA Quadro RTX 8000 or better

2. **Model Robustness**
   - Performance can degrade under varying lighting
   - Occlusion affects ear-tag and face recognition

3. **Network Latency**
   - Remote farms may experience higher latency
   - Requires stable network infrastructure

### Planned Improvements

1. **Edge TPU Acceleration**
   - Move inference to edge devices
   - Reduce server load and latency

2. **Advanced Behavior Prediction**
   - Predict health issues before symptoms
   - Machine learning on temporal patterns

3. **Integration with Farm Management Systems**
   - Connect with existing farm software
   - Unified data platform

4. **Offline Mode with Sync**
   - Continue operation during network outages
   - Automatic synchronization when online

5. **Export & Reporting**
   - PDF, Excel, CSV report generation
   - Veterinary-formatted health reports
   - Historical trend analysis

---

## 📚 Research Citation

```bibtex
@article{moe2025cattle,
  title={AI-powered cattle health monitoring system combining real-time computer vision, edge computing, and mobile applications},
  author={Moe, A.S.T. and Tin, P. and Aikawa, M. and Kobayashi, I. and Zin, T.T.},
  journal={Smart Agricultural Technology},
  volume={12},
  pages={101300},
  year={2025},
  publisher={Elsevier},
  doi={10.1016/j.atech.2025.101300}
}
```

---

## 🤝 Alignment with National Goals

This system supports **Japan's Green and Digital Transformation (GX/DX) initiatives** [28]:

✅ **Green Transformation (GX)**
- Non-invasive monitoring (no wearables)
- Reduced farm labor requirements
- Early disease detection reduces treatment costs
- Sustainable livestock management

✅ **Digital Transformation (DX)**
- Digitized health records
- Real-time mobile access
- AI-driven decision support
- Cloud-based data platform
- Scalable multi-farm deployment

---

## 📞 Support & Documentation

- **Main Documentation:** [AI_SYSTEM_DOCUMENTATION.md](AI_SYSTEM_DOCUMENTATION.md)
- **Database Schema:** [supabase/migrations/06_research_paper_schema.sql](supabase/migrations/06_research_paper_schema.sql)
- **Models:** [lib/models/research_models.dart](lib/models/research_models.dart)
- **AI Monitoring Screen:** [lib/screens/monitoring/ai_monitoring_screen.dart](lib/screens/monitoring/ai_monitoring_screen.dart)

---

**Last Updated:** January 10, 2026  
**Implementation Status:** ✅ Complete (Database Schema, Models, UI)  
**Deployment Status:** 🟡 Awaiting SQL Migration Execution
