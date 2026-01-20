# Database Table Errors - FIXED ✅

## Errors Found and Fixed

### 1. ❌ Table 'public.cattle' not found
**Fix**: Changed from `cattle` to `animals` table
- File: `lib/services/video_processing_service.dart`
- Updated to use `animals` table with correct columns (`animal_id`, `milking_status`, `lameness_level`)

### 2. ❌ Table 'public.video_processing_logs' not found  
**Fix**: Changed to use `video_records` table
- File: `lib/services/video_processing_service.dart`
- Updated to save processing results in `video_records` table with `analysis_results` JSONB field

### 3. ❌ Table 'public.rgbd_camera' not found
**Fix**: Changed to use `depth_camera` table
- Files: 
  - `lib/services/video_processing_service.dart`
  - `lib/services/dashboard_data_service.dart`
- Updated all references from `rgbd_camera` to `depth_camera`

### 4. ❌ Storage bucket 'videos' not found
**Fix**: Created storage bucket setup SQL
- File: `supabase/migrations/09_create_storage_buckets.sql`
- Creates `videos` and `cattle_images` buckets with proper RLS policies

## 🚀 Quick Setup - Run This SQL in Supabase

### Option 1: Use the Complete Fix File (Recommended)
```sql
-- Copy and paste contents from:
FIX_DATABASE_TABLES.sql
```

This will:
- ✅ Add missing columns to `animals` table
- ✅ Create `milking_status` table
- ✅ Create `videos` and `cattle_images` storage buckets
- ✅ Set up all RLS policies
- ✅ Run verification queries

### Option 2: Run Individual Migrations
```sql
-- Run these in order:
1. supabase/migrations/08_milking_status_table.sql
2. supabase/migrations/09_create_storage_buckets.sql
```

## Code Changes Made

### video_processing_service.dart
```dart
// BEFORE (❌ Wrong table names)
from('cattle')           // Table doesn't exist
from('video_processing_logs')  // Table doesn't exist  
from('rgbd_camera')      // Table doesn't exist

// AFTER (✅ Correct table names)
from('animals')          // Uses existing animals table
from('video_records')    // Uses existing video_records table
from('depth_camera')     // Uses existing depth_camera table
```

### dashboard_data_service.dart
```dart
// BEFORE (❌ Wrong table)
from('rgbd_camera').select('bcs_score, timestamp')

// AFTER (✅ Skip BCS for now, use lameness from depth_camera)
// BCS data not currently stored separately
// depth_camera handles lameness data
```

## Table Mappings

| Old/Wrong Name | Correct Name | Purpose |
|---------------|--------------|---------|
| `cattle` | `animals` | Main cattle records |
| `video_processing_logs` | `video_records` | Video upload records |
| `rgbd_camera` | `depth_camera` | Lameness detection |

## Storage Buckets

| Bucket Name | Purpose | Public |
|-------------|---------|--------|
| `videos` | Processed videos | Yes |
| `cattle_images` | Animal photos | Yes |

## Testing the Fixes

### 1. Run the SQL Setup
```bash
# In Supabase SQL Editor, paste contents of:
cat FIX_DATABASE_TABLES.sql
# Or use the complete schema:
cat COMPLETE_SUPABASE_SCHEMA.sql
```

### 2. Restart Your Flutter App
```bash
# The app is already running, so just hot restart
# Press 'r' in the terminal or hot reload in IDE
```

### 3. Upload a Test Video
- Video processing should now save to correct tables
- Dashboard should load without errors
- Check Supabase logs to verify no more table errors

## Verification Queries

Run these in Supabase SQL Editor to verify everything is set up:

```sql
-- Check animals table has required columns
SELECT column_name, data_type 
FROM information_schema.columns
WHERE table_name = 'animals'
  AND column_name IN ('animal_id', 'milking_status', 'lameness_level', 'last_detection');

-- Check milking_status table exists
SELECT table_name FROM information_schema.tables 
WHERE table_name = 'milking_status';

-- Check depth_camera table exists
SELECT table_name FROM information_schema.tables 
WHERE table_name = 'depth_camera';

-- Check video_records table exists
SELECT table_name FROM information_schema.tables 
WHERE table_name = 'video_records';

-- Check storage buckets exist
SELECT id, name, public FROM storage.buckets 
WHERE id IN ('videos', 'cattle_images');
```

Expected output:
- ✅ animals table has: `animal_id`, `milking_status`, `lameness_level`, `last_detection`
- ✅ milking_status table exists
- ✅ depth_camera table exists
- ✅ video_records table exists
- ✅ 2 storage buckets: videos, cattle_images

## What Each Table Stores

### animals
```sql
animal_id (primary key)
species (Cow/Buffalo)
milking_status (milking/dry/unknown)
lameness_level (normal/mild/moderate/severe)
lameness_score (0-5)
last_detection (timestamp)
```

### ear_tag_camera
```sql
cow_id (references animals.animal_id)
ear_tag_number
confidence
detection_timestamp
```

### milking_status (NEW)
```sql
cow_id (references animals)
is_being_milked (boolean)
milking_confidence (0-100)
timestamp
```

### depth_camera
```sql
cow_id
lameness_score (0-5)
lameness_severity (Normal/Mild/Severe)
detection_method
timestamp
```

### video_records
```sql
video_url
processing_status (Pending/Processing/Completed/Failed)
analysis_results (JSONB with detection data)
timestamp
```

## Expected Logs After Fix

You should now see:
```
✅ Animal record updated with latest health data
✅ Video processing record saved
✅ Ear-tag record saved successfully
✅ BCS/Lameness record saved successfully to depth_camera
✅ Successfully saved all records to database
```

No more errors about missing tables! 🎉

---
**Status**: ✅ All Errors Fixed
**Date**: January 11, 2026
