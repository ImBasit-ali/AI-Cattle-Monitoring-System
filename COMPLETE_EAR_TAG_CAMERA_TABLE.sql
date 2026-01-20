-- ============================================
-- COMPLETE ear_tag_camera TABLE SCHEMA
-- With ALL columns that Flutter app needs
-- ============================================

-- Drop the old table if you want to recreate from scratch
-- DROP TABLE IF EXISTS ear_tag_camera CASCADE;

-- Create ear_tag_camera table with ALL required columns
CREATE TABLE IF NOT EXISTS ear_tag_camera (
    -- Primary columns
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cow_id VARCHAR(20) NOT NULL,  -- Maps to animal_id in animals table
    animal_id VARCHAR(20),  -- Alternative column name (for compatibility)
    
    -- Ear tag detection
    ear_tag_number VARCHAR(50),
    confidence DECIMAL(5, 2) CHECK (confidence >= 0 AND confidence <= 100),
    detection_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    detection_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),  -- Alternative column
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),  -- Generic timestamp column
    
    -- Camera info
    camera_id VARCHAR(50),
    camera_number INTEGER CHECK (camera_number IN (1, 2, 3, 4, 5)),
    functional_zone VARCHAR(100) DEFAULT 'Milking Parlor',
    
    -- Images
    image_url TEXT,
    head_image_url TEXT,
    ear_tag_crop_url TEXT,
    
    -- Detection data
    bounding_box JSONB,
    bbox_x1 DECIMAL(10, 2),
    bbox_y1 DECIMAL(10, 2),
    bbox_x2 DECIMAL(10, 2),
    bbox_y2 DECIMAL(10, 2),
    
    -- OCR/Recognition data
    detected_characters JSONB,
    recognition_method VARCHAR(100) DEFAULT 'CRAFT+ResNet18',
    
    -- Milking session data
    milking_session_start TIMESTAMP WITH TIME ZONE,
    milking_session_end TIMESTAMP WITH TIME ZONE,
    milking_position INTEGER,
    
    -- Species
    species VARCHAR(50),
    
    -- User reference
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_ear_tag_cow_id ON ear_tag_camera(cow_id);
CREATE INDEX IF NOT EXISTS idx_ear_tag_animal_id ON ear_tag_camera(animal_id);
CREATE INDEX IF NOT EXISTS idx_ear_tag_camera_id ON ear_tag_camera(camera_id);
CREATE INDEX IF NOT EXISTS idx_ear_tag_camera_number ON ear_tag_camera(camera_number);
CREATE INDEX IF NOT EXISTS idx_ear_tag_time ON ear_tag_camera(detection_time DESC);
CREATE INDEX IF NOT EXISTS idx_ear_tag_timestamp ON ear_tag_camera(detection_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_ear_tag_user_id ON ear_tag_camera(user_id);
CREATE INDEX IF NOT EXISTS idx_ear_tag_ear_tag_number ON ear_tag_camera(ear_tag_number);

-- Row Level Security
ALTER TABLE ear_tag_camera ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own ear tag detections" ON ear_tag_camera;
CREATE POLICY "Users can view their own ear tag detections"
    ON ear_tag_camera FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert ear tag detections" ON ear_tag_camera;
CREATE POLICY "Users can insert ear tag detections"
    ON ear_tag_camera FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their ear tag detections" ON ear_tag_camera;
CREATE POLICY "Users can update their ear tag detections"
    ON ear_tag_camera FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their ear tag detections" ON ear_tag_camera;
CREATE POLICY "Users can delete their ear tag detections"
    ON ear_tag_camera FOR DELETE
    USING (auth.uid() = user_id);

-- Enable realtime (only if not already added)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'ear_tag_camera'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE ear_tag_camera;
    END IF;
END $$;

-- Auto-update timestamp trigger
CREATE OR REPLACE FUNCTION update_ear_tag_camera_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_ear_tag_camera_updated_at ON ear_tag_camera;
CREATE TRIGGER set_ear_tag_camera_updated_at
    BEFORE UPDATE ON ear_tag_camera
    FOR EACH ROW
    EXECUTE FUNCTION update_ear_tag_camera_updated_at();

-- Verify table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'ear_tag_camera'
ORDER BY ordinal_position;
