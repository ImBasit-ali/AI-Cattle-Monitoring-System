-- ============================================
-- COMPLETE FIX: Add missing tables and fix numeric overflow
-- Fixes errors:
-- 1. "Could not find the table 'public.rgbd_camera'"
-- 2. "numeric field overflow" - confidence field precision issue
-- ============================================

-- ============================================
-- FIX 1: Fix confidence field precision in ear_tag_camera
-- Change from DECIMAL(5,4) to DECIMAL(5,2) to allow values 0-100
-- ============================================

-- Alter existing ear_tag_camera table to fix confidence field
ALTER TABLE ear_tag_camera 
ALTER COLUMN confidence TYPE DECIMAL(5, 2);

-- Drop old constraint and add new one
ALTER TABLE ear_tag_camera 
DROP CONSTRAINT IF EXISTS ear_tag_camera_confidence_check;

ALTER TABLE ear_tag_camera 
ADD CONSTRAINT ear_tag_camera_confidence_check 
CHECK (confidence >= 0 AND confidence <= 100);

-- ============================================
-- FIX 2: Create rgbd_camera table
-- ============================================

CREATE TABLE IF NOT EXISTS rgbd_camera (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    cow_id VARCHAR(20),
    
    -- Body Condition Score (Random Forest Classifier)
    bcs_score DECIMAL(2, 1) CHECK (bcs_score >= 1.0 AND bcs_score <= 5.0),
    bcs_confidence DECIMAL(5, 2),
    bcs_tolerance_level DECIMAL(3, 2),
    bcs_accuracy_at_tolerance DECIMAL(5, 2),
    
    -- Detection Method
    detection_method VARCHAR(100) DEFAULT 'Detectron2 + Random Forest',
    identification_method VARCHAR(100) DEFAULT 'PointNet++ Siamese Network',
    identification_confidence DECIMAL(5, 2),
    
    -- Camera Information
    camera_number INTEGER CHECK (camera_number = 4),
    functional_zone VARCHAR(50) DEFAULT 'Return Lane',
    
    -- Point Cloud Data
    point_cloud_url TEXT,
    point_cloud_features JSONB,
    downsampled_points INTEGER DEFAULT 2048,
    
    -- Geometric Features
    normal_vectors JSONB,
    curvature_values JSONB,
    point_density DECIMAL(10, 4),
    planarity DECIMAL(6, 4),
    linearity DECIMAL(6, 4),
    sphericity DECIMAL(6, 4),
    fpfh_descriptor JSONB,
    triangle_mesh_area DECIMAL(10, 4),
    convex_hull_area DECIMAL(10, 4),
    
    -- Body Weight Estimation
    estimated_body_weight DECIMAL(6, 2),
    weight_estimation_confidence DECIMAL(5, 2),
    
    -- Tracking Information
    tracking_id INTEGER,
    
    -- Temporal Data
    assessment_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    depth_image_url TEXT,
    rgb_image_url TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for rgbd_camera
CREATE INDEX IF NOT EXISTS idx_rgbd_cow_id ON rgbd_camera(cow_id);
CREATE INDEX IF NOT EXISTS idx_rgbd_bcs_score ON rgbd_camera(bcs_score);
CREATE INDEX IF NOT EXISTS idx_rgbd_timestamp ON rgbd_camera(assessment_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_rgbd_user_id ON rgbd_camera(user_id);

-- Enable Row Level Security for rgbd_camera
ALTER TABLE rgbd_camera ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for rgbd_camera
DROP POLICY IF EXISTS "Users can view their own rgbd camera records" ON rgbd_camera;
CREATE POLICY "Users can view their own rgbd camera records"
    ON rgbd_camera FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert rgbd camera records" ON rgbd_camera;
CREATE POLICY "Users can insert rgbd camera records"
    ON rgbd_camera FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their rgbd camera records" ON rgbd_camera;
CREATE POLICY "Users can update their rgbd camera records"
    ON rgbd_camera FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their rgbd camera records" ON rgbd_camera;
CREATE POLICY "Users can delete their rgbd camera records"
    ON rgbd_camera FOR DELETE
    USING (auth.uid() = user_id);

-- Add to realtime publication
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'rgbd_camera'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE rgbd_camera;
    END IF;
END $$;

-- ============================================
-- FIX 3: Fix lameness_detections confidence if exists
-- ============================================

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'lameness_detections'
    ) THEN
        -- Alter confidence_score field
        ALTER TABLE lameness_detections 
        ALTER COLUMN confidence_score TYPE DECIMAL(5, 2);
        
        -- Update constraint
        ALTER TABLE lameness_detections 
        DROP CONSTRAINT IF EXISTS lameness_detections_confidence_score_check;
        
        ALTER TABLE lameness_detections 
        ADD CONSTRAINT lameness_detections_confidence_score_check 
        CHECK (confidence_score >= 0 AND confidence_score <= 100);
    END IF;
END $$;

-- ============================================
-- VERIFICATION
-- ============================================

-- Verify rgbd_camera table
SELECT 'rgbd_camera table' AS table_name,
       COUNT(*) AS column_count
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'rgbd_camera';

-- Verify ear_tag_camera confidence field
SELECT column_name, data_type, numeric_precision, numeric_scale
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'ear_tag_camera'
  AND column_name = 'confidence';

-- Show all camera tables
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name LIKE '%camera%'
ORDER BY table_name;
