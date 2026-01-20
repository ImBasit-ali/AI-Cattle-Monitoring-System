-- ============================================
-- COMPLETE DATABASE SETUP FOR VIDEO PROCESSING
-- Run this in Supabase SQL Editor to fix all errors
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. ENSURE ANIMALS TABLE EXISTS WITH CORRECT COLUMNS
-- ============================================

-- Check and add milking_status column if missing
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'animals' AND column_name = 'milking_status'
    ) THEN
        ALTER TABLE animals ADD COLUMN milking_status VARCHAR(20) DEFAULT 'unknown' 
        CHECK (milking_status IN ('milking', 'dry', 'unknown'));
    END IF;
END $$;

-- Check and add lameness_level column if missing
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'animals' AND column_name = 'lameness_level'
    ) THEN
        ALTER TABLE animals ADD COLUMN lameness_level VARCHAR(20) DEFAULT 'normal' 
        CHECK (lameness_level IN ('normal', 'mild', 'moderate', 'severe', 'unknown'));
    END IF;
END $$;

-- Check and add last_detection column if missing
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'animals' AND column_name = 'last_detection'
    ) THEN
        ALTER TABLE animals ADD COLUMN last_detection TIMESTAMP WITH TIME ZONE;
    END IF;
END $$;

-- ============================================
-- 2. CREATE MILKING_STATUS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS milking_status (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cow_id VARCHAR(20) NOT NULL,
    is_being_milked BOOLEAN DEFAULT FALSE,
    milking_confidence DECIMAL(5, 2) CHECK (milking_confidence >= 0 AND milking_confidence <= 100),
    udder_detected BOOLEAN DEFAULT FALSE,
    udder_size VARCHAR(20),
    behavioral_score DECIMAL(5, 2),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_milking_status_cow_id ON milking_status(cow_id);
CREATE INDEX IF NOT EXISTS idx_milking_status_timestamp ON milking_status(timestamp);
CREATE INDEX IF NOT EXISTS idx_milking_status_is_being_milked ON milking_status(is_being_milked);

-- Enable RLS
ALTER TABLE milking_status ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view milking status" ON milking_status;
DROP POLICY IF EXISTS "Users can insert milking status" ON milking_status;

-- RLS Policies (allow authenticated users)
CREATE POLICY "Users can view milking status"
    ON milking_status FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "Users can insert milking status"
    ON milking_status FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- ============================================
-- 3. CREATE STORAGE BUCKETS
-- ============================================

-- Create videos bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('videos', 'videos', true)
ON CONFLICT (id) DO NOTHING;

-- Videos bucket policies
DROP POLICY IF EXISTS "Videos are publicly accessible" ON storage.objects;
CREATE POLICY "Videos are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'videos');

DROP POLICY IF EXISTS "Authenticated users can upload videos" ON storage.objects;
CREATE POLICY "Authenticated users can upload videos"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'videos' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users can update videos" ON storage.objects;
CREATE POLICY "Users can update videos"
ON storage.objects FOR UPDATE
USING (bucket_id = 'videos' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users can delete videos" ON storage.objects;
CREATE POLICY "Users can delete videos"
ON storage.objects FOR DELETE
USING (bucket_id = 'videos' AND auth.role() = 'authenticated');

-- Create cattle_images bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('cattle_images', 'cattle_images', true)
ON CONFLICT (id) DO NOTHING;

-- Cattle images bucket policies
DROP POLICY IF EXISTS "Cattle images are publicly accessible" ON storage.objects;
CREATE POLICY "Cattle images are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'cattle_images');

DROP POLICY IF EXISTS "Authenticated users can upload cattle images" ON storage.objects;
CREATE POLICY "Authenticated users can upload cattle images"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'cattle_images' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users can update cattle images" ON storage.objects;
CREATE POLICY "Users can update cattle images"
ON storage.objects FOR UPDATE
USING (bucket_id = 'cattle_images' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users can delete cattle images" ON storage.objects;
CREATE POLICY "Users can delete cattle images"
ON storage.objects FOR DELETE
USING (bucket_id = 'cattle_images' AND auth.role() = 'authenticated');

-- ============================================
-- 4. VERIFICATION QUERIES
-- ============================================

-- Verify animals table has required columns
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'animals'
  AND column_name IN ('animal_id', 'milking_status', 'lameness_level', 'last_detection')
ORDER BY column_name;

-- Verify milking_status table exists
SELECT table_name, table_type
FROM information_schema.tables
WHERE table_name = 'milking_status';

-- Verify storage buckets exist
SELECT id, name, public
FROM storage.buckets
WHERE id IN ('videos', 'cattle_images');

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Database setup complete!';
    RAISE NOTICE '   - animals table updated with milking_status, lameness_level';
    RAISE NOTICE '   - milking_status table created';
    RAISE NOTICE '   - Storage buckets created: videos, cattle_images';
    RAISE NOTICE '';
    RAISE NOTICE 'Your Flutter app should now work without table errors!';
END $$;
