# Real-Time Data Implementation Guide

## Overview
This document explains how the Cattle AI app has been updated to use **real-time data from Supabase** instead of default/mock data. All data now flows from video processing through the database to live dashboard updates.

## Data Flow

```
Video Upload → AI Processing → Supabase Database → Real-time Dashboard
                                     ↓
                              Supabase Storage
```

### 1. Video Processing & Storage

**File**: `lib/services/video_processing_service.dart`

When a user uploads a video:

1. **AI Analysis** - Extracts frames and simulates AI detection:
   - Ear tag detection
   - Lameness detection (depth + side view cameras)
   - Body Condition Score (BCS) assessment

2. **Database Storage** - Saves results to Supabase tables:
   - `ear_tag_camera` - Ear tag detections with cow IDs
   - `depth_camera` - Lameness scores from depth camera
   - `side_view_camera` - Lameness scores from side view
   - `rgbd_camera` - BCS scores with confidence levels

3. **Video Upload** - Uploads processed video to Supabase Storage:
   - Bucket: `videos`
   - Returns public URL for video playback

### 2. Dashboard Data Service

**File**: `lib/services/dashboard_data_service.dart`

This service aggregates data from the database:

#### Statistics Aggregation
```dart
// Get overall statistics
DashboardStats stats = await DashboardDataService.instance.getDashboardStats();

// Returns:
// - totalCattle: Unique cattle count from ear_tag_camera
// - healthyCattle: Cattle with lameness score ≤ 1
// - lamenessCattle: Cattle with lameness score > 1
// - dailyCounts: Last 7 days of detections
// - lamenessCount: Total lameness cases by date
// - avgBCS: Average BCS by date
```

#### Real-time Updates
```dart
// Subscribe to database changes
DashboardDataService.instance.subscribeToUpdates((stats) {
  // Dashboard automatically updates when new data arrives
  setState(() => _stats = stats);
});
```

The service listens to PostgreSQL change events on:
- `ear_tag_camera` (new cattle detections)
- `depth_camera` (lameness updates)
- `rgbd_camera` (BCS updates)

### 3. Dashboard Screen

**File**: `lib/screens/dashboard/dashboard_screen.dart`

The dashboard displays real-time data:

#### Statistics Cards
- **Total Cattle**: Count of unique cattle detected
- **Healthy Cattle**: Cattle with normal gait (lameness ≤ 1)
- **Lameness Cattle**: Cattle requiring attention (lameness > 1)

#### Daily Health Chart
- Shows last 7 days of data
- Two trend lines:
  - **Pink**: Total cattle detections per day
  - **Blue**: Lameness cases per day
- Empty state when no data available

#### Today's Cattle Table
Displays cattle detected today with:
- Cow ID
- Ear Tag
- Lameness Score (color-coded: green = healthy, red = lame)
- BCS Score
- Status (Healthy/Lame)

## Database Schema

### Required Tables

```sql
-- Ear Tag Camera (Camera 1)
CREATE TABLE ear_tag_camera (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  cow_id VARCHAR NOT NULL,
  ear_tag VARCHAR NOT NULL,
  detection_confidence DECIMAL,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Depth Camera (Camera 2)
CREATE TABLE depth_camera (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  cow_id VARCHAR NOT NULL,
  lameness_score INTEGER,
  lameness_severity VARCHAR,
  lameness_confidence DECIMAL,
  time_of_day VARCHAR,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Side View Camera (Camera 5)
CREATE TABLE side_view_camera (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  cow_id VARCHAR NOT NULL,
  lameness_score INTEGER,
  lameness_severity VARCHAR,
  classification_confidence DECIMAL,
  detection_method VARCHAR,
  camera_number INTEGER DEFAULT 5,
  functional_zone VARCHAR DEFAULT 'Return Lane',
  analysis_timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- RGBD Camera (Camera 4)
CREATE TABLE rgbd_camera (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  cow_id VARCHAR NOT NULL,
  bcs_score DECIMAL,
  bcs_confidence DECIMAL,
  identification_confidence DECIMAL,
  detection_method VARCHAR,
  identification_method VARCHAR,
  camera_number INTEGER DEFAULT 4,
  functional_zone VARCHAR DEFAULT 'Return Lane',
  assessment_timestamp TIMESTAMPTZ DEFAULT NOW()
);
```

### Storage Bucket

```sql
-- Create videos bucket for processed video uploads
INSERT INTO storage.buckets (id, name, public)
VALUES ('videos', 'videos', true);

-- Enable public access
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING (bucket_id = 'videos');

-- Allow authenticated uploads
CREATE POLICY "Authenticated Upload"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'videos' AND auth.role() = 'authenticated');
```

## Key Features

### ✅ No Default/Mock Data
- All counts come from database queries
- Empty states shown when no data available
- Charts only display actual detections

### ✅ Real-time Updates
- Dashboard automatically refreshes when new videos processed
- PostgreSQL LISTEN/NOTIFY mechanism
- No manual refresh required

### ✅ Day-wise Tracking
- All records timestamped
- Charts show daily trends
- Today's cattle table filtered by date

### ✅ Lameness Detection
- Multiple camera sources (depth + side view)
- Score-based severity (0-3 scale)
- Color-coded indicators

### ✅ BCS Assessment
- Point cloud analysis simulation
- Confidence scoring
- Historical tracking

## Testing the Implementation

1. **Upload a Video**:
   - Go to Dashboard → Camera icon
   - Upload a video file
   - Wait for processing

2. **Verify Database**:
   ```sql
   -- Check ear tag detections
   SELECT * FROM ear_tag_camera ORDER BY timestamp DESC LIMIT 10;
   
   -- Check lameness records
   SELECT * FROM depth_camera ORDER BY timestamp DESC LIMIT 10;
   
   -- Check BCS records
   SELECT * FROM rgbd_camera ORDER BY timestamp DESC LIMIT 10;
   ```

3. **Check Dashboard**:
   - Cattle count should increase
   - Chart should show new data points
   - Table should list detected cattle
   - Real-time update happens automatically

## Future Enhancements

- [ ] Real camera integration (currently simulated)
- [ ] Advanced ML models for detection
- [ ] Historical data export
- [ ] Cattle health alerts
- [ ] Multi-farm support
- [ ] Detailed cattle profiles

## Troubleshooting

### Dashboard shows "No data"
- Check Supabase connection
- Verify tables exist
- Upload a test video

### Real-time updates not working
- Check Supabase Realtime is enabled
- Verify database policies allow subscriptions
- Check browser console for errors

### Video upload fails
- Verify `videos` bucket exists
- Check storage policies
- Ensure file size is within limits

## Migration from Old System

**Removed**:
- ❌ `animalProvider.animals` mock data
- ❌ Hardcoded chart data (MAR, APR, MAY)
- ❌ Mock cattle counts
- ❌ Default "Milking Cows" list

**Added**:
- ✅ `DashboardDataService` for real data
- ✅ Real-time Supabase subscriptions
- ✅ Dynamic charts from database
- ✅ Today's cattle from actual detections
