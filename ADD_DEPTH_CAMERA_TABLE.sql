-- ============================================
-- FIX: Add missing depth_camera table
-- Fixes error: "Could not find the table 'public.depth_camera'"
-- ============================================

-- Create depth_camera table
CREATE TABLE IF NOT EXISTS depth_camera (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    cow_id VARCHAR(20),
    
    -- Lameness Classification (Extra Trees Classifier)
    lameness_score INTEGER CHECK (lameness_score >= 0 AND lameness_score <= 5),
    lameness_severity VARCHAR(30) CHECK (lameness_severity IN ('Normal', 'Mild Lameness', 'Severe Lameness')),
    lameness_confidence DECIMAL(5, 2),
    
    -- Detection Method
    detection_method VARCHAR(100) DEFAULT 'Detectron2 + Extra Trees',
    time_of_day VARCHAR(20) CHECK (time_of_day IN ('Morning', 'Evening')),
    
    -- Camera Information
    camera_number INTEGER CHECK (camera_number = 3),
    functional_zone VARCHAR(50) DEFAULT 'Return Lane',
    
    -- Depth Features
    depth_image_url TEXT,
    back_depth_features JSONB,
    segmentation_mask_url TEXT,
    
    -- Tracking Information
    tracking_id INTEGER,
    frame_number INTEGER,
    
    -- Milking Information
    post_milking_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    related_milking_session_id UUID,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_depth_cow_id ON depth_camera(cow_id);
CREATE INDEX IF NOT EXISTS idx_depth_lameness_score ON depth_camera(lameness_score);
CREATE INDEX IF NOT EXISTS idx_depth_timestamp ON depth_camera(post_milking_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_depth_user_id ON depth_camera(user_id);

-- Enable Row Level Security
ALTER TABLE depth_camera ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
DROP POLICY IF EXISTS "Users can view their own depth camera records" ON depth_camera;
CREATE POLICY "Users can view their own depth camera records"
    ON depth_camera FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert depth camera records" ON depth_camera;
CREATE POLICY "Users can insert depth camera records"
    ON depth_camera FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their depth camera records" ON depth_camera;
CREATE POLICY "Users can update their depth camera records"
    ON depth_camera FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their depth camera records" ON depth_camera;
CREATE POLICY "Users can delete their depth camera records"
    ON depth_camera FOR DELETE
    USING (auth.uid() = user_id);

-- Add to realtime publication (only if not already added)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'depth_camera'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE depth_camera;
    END IF;
END $$;

-- Verify table was created
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'depth_camera'
ORDER BY ordinal_position;
