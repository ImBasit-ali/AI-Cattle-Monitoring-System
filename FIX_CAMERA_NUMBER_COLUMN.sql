-- ============================================
-- FIX: Add missing columns to ear_tag_camera
-- Fixes errors: 
-- - "Could not find the 'camera_number' column"
-- - "Could not find the 'timestamp' column"
-- ============================================

-- Add camera_number column to ear_tag_camera table
ALTER TABLE ear_tag_camera 
ADD COLUMN IF NOT EXISTS camera_number INTEGER CHECK (camera_number IN (1, 2, 3, 4, 5));

-- Add timestamp column to ear_tag_camera table
ALTER TABLE ear_tag_camera 
ADD COLUMN IF NOT EXISTS timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Create indexes for new columns
CREATE INDEX IF NOT EXISTS idx_ear_tag_camera_number ON ear_tag_camera(camera_number);
CREATE INDEX IF NOT EXISTS idx_ear_tag_timestamp ON ear_tag_camera(timestamp DESC);

-- Verify the columns were added
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'ear_tag_camera'
  AND column_name IN ('camera_number', 'timestamp');
