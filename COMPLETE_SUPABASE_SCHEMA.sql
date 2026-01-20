-- ============================================
-- COMPLETE SUPABASE DATABASE SCHEMA
-- Cattle AI Monitor - ML-Powered Monitoring System
-- ============================================
-- Run this entire file in Supabase SQL Editor
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- TABLE: animals
-- Stores cattle/animal information
-- ============================================

CREATE TABLE IF NOT EXISTS animals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    animal_id VARCHAR(20) UNIQUE NOT NULL,
    species VARCHAR(50) NOT NULL CHECK (species IN ('Cow', 'Buffalo', 'cow', 'buffalo')),
    age INTEGER CHECK (age >= 0),
    health_status VARCHAR(50) DEFAULT 'Healthy' CHECK (health_status IN ('Healthy', 'Under Observation', 'Sick', 'Critical', 'attention_required')),
    image_url TEXT,
    breed VARCHAR(100),
    weight DECIMAL(10, 2) CHECK (weight > 0),
    notes TEXT,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- ML Detection fields
    milking_status VARCHAR(20) DEFAULT 'unknown' CHECK (milking_status IN ('milking', 'dry', 'unknown')),
    lameness_level VARCHAR(20) DEFAULT 'normal' CHECK (lameness_level IN ('normal', 'mild', 'moderate', 'severe', 'unknown')),
    lameness_score DECIMAL(5, 2) DEFAULT 0 CHECK (lameness_score >= 0),
    last_milking_check TIMESTAMP WITH TIME ZONE,
    last_health_check TIMESTAMP WITH TIME ZONE,
    last_detection TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for animals table
CREATE INDEX IF NOT EXISTS idx_animals_user_id ON animals(user_id);
CREATE INDEX IF NOT EXISTS idx_animals_animal_id ON animals(animal_id);
CREATE INDEX IF NOT EXISTS idx_animals_species ON animals(species);
CREATE INDEX IF NOT EXISTS idx_animals_health_status ON animals(health_status);
CREATE INDEX IF NOT EXISTS idx_animals_milking_status ON animals(milking_status);
CREATE INDEX IF NOT EXISTS idx_animals_lameness_level ON animals(lameness_level);

-- ============================================
-- TABLE: ear_tag_camera
-- Camera-based animal detections
-- ============================================
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


-- ============================================
-- TABLE: detections
-- ML detection results
-- ============================================

CREATE TABLE IF NOT EXISTS detections (
    id BIGSERIAL PRIMARY KEY,
    detection_id TEXT UNIQUE NOT NULL,
    animal_type TEXT NOT NULL CHECK (animal_type IN ('cow', 'buffalo', 'unknown')),
    confidence FLOAT NOT NULL CHECK (confidence >= 0 AND confidence <= 1),
    bbox_x1 FLOAT,
    bbox_y1 FLOAT,
    bbox_x2 FLOAT,
    bbox_y2 FLOAT,
    image_url TEXT,
    camera_id TEXT,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    detected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for detections
CREATE INDEX IF NOT EXISTS idx_detections_detected_at ON detections(detected_at DESC);
CREATE INDEX IF NOT EXISTS idx_detections_animal_type ON detections(animal_type);
CREATE INDEX IF NOT EXISTS idx_detections_user_id ON detections(user_id);
CREATE INDEX IF NOT EXISTS idx_detections_camera_id ON detections(camera_id);

-- ============================================
-- TABLE: animal_tracks
-- Tracking information
-- ============================================

CREATE TABLE IF NOT EXISTS animal_tracks (
    id BIGSERIAL PRIMARY KEY,
    track_id INTEGER UNIQUE NOT NULL,
    animal_type TEXT NOT NULL CHECK (animal_type IN ('cow', 'buffalo', 'unknown')),
    first_seen TIMESTAMP WITH TIME ZONE,
    last_seen TIMESTAMP WITH TIME ZONE,
    confidence_avg FLOAT CHECK (confidence_avg >= 0 AND confidence_avg <= 1),
    frame_count INTEGER DEFAULT 0,
    camera_id TEXT,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for animal_tracks
CREATE INDEX IF NOT EXISTS idx_tracks_track_id ON animal_tracks(track_id);
CREATE INDEX IF NOT EXISTS idx_tracks_user_id ON animal_tracks(user_id);
CREATE INDEX IF NOT EXISTS idx_tracks_camera_id ON animal_tracks(camera_id);

-- ============================================
-- TABLE: milking_status
-- Milking/lactation status records
-- ============================================

CREATE TABLE IF NOT EXISTS milking_status (
    id BIGSERIAL PRIMARY KEY,
    animal_id TEXT REFERENCES animals(animal_id),
    status TEXT NOT NULL CHECK (status IN ('milking', 'dry', 'unknown')),
    confidence FLOAT CHECK (confidence >= 0 AND confidence <= 1),
    udder_detected BOOLEAN DEFAULT FALSE,
    udder_size FLOAT,
    behavioral_score FLOAT,
    image_url TEXT,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    detected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for milking_status
CREATE INDEX IF NOT EXISTS idx_milking_animal_id ON milking_status(animal_id);
CREATE INDEX IF NOT EXISTS idx_milking_status ON milking_status(status);
CREATE INDEX IF NOT EXISTS idx_milking_detected_at ON milking_status(detected_at DESC);
CREATE INDEX IF NOT EXISTS idx_milking_user_id ON milking_status(user_id);

-- ============================================
-- TABLE: lameness_detections
-- Lameness analysis results
-- ============================================

CREATE TABLE IF NOT EXISTS lameness_detections (
    id BIGSERIAL PRIMARY KEY,
    animal_id TEXT REFERENCES animals(animal_id),
    lameness_level TEXT NOT NULL CHECK (lameness_level IN ('normal', 'mild', 'moderate', 'severe', 'unknown')),
    confidence FLOAT CHECK (confidence >= 0 AND confidence <= 1),
    step_length FLOAT,
    step_symmetry FLOAT CHECK (step_symmetry >= 0 AND step_symmetry <= 1),
    walking_speed FLOAT,
    back_curvature FLOAT,
    affected_leg TEXT,
    video_url TEXT,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    detected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for lameness_detections
CREATE INDEX IF NOT EXISTS idx_lameness_animal_id ON lameness_detections(animal_id);
CREATE INDEX IF NOT EXISTS idx_lameness_level ON lameness_detections(lameness_level);
CREATE INDEX IF NOT EXISTS idx_lameness_detected_at ON lameness_detections(detected_at DESC);
CREATE INDEX IF NOT EXISTS idx_lameness_user_id ON lameness_detections(user_id);

-- ============================================
-- TABLE: lameness_records
-- Historical lameness records
-- ============================================

CREATE TABLE IF NOT EXISTS lameness_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    animal_id UUID REFERENCES animals(id) ON DELETE CASCADE,
    detection_date DATE NOT NULL,
    severity VARCHAR(50) NOT NULL CHECK (severity IN ('Normal', 'Mild Lameness', 'Severe Lameness')),
    confidence_score DECIMAL(5, 2) CHECK (confidence_score >= 0 AND confidence_score <= 100),
    detection_method VARCHAR(20) CHECK (detection_method IN ('Rule-Based', 'ML-Based')),
    step_count INTEGER CHECK (step_count >= 0),
    activity_hours DECIMAL(5, 2) CHECK (activity_hours >= 0 AND activity_hours <= 24),
    rest_hours DECIMAL(5, 2) CHECK (rest_hours >= 0 AND rest_hours <= 24),
    ml_input_features JSONB,
    ml_output_probabilities JSONB,
    video_url TEXT,
    notes TEXT,
    requires_attention BOOLEAN DEFAULT FALSE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for lameness_records
CREATE INDEX IF NOT EXISTS idx_lameness_records_animal_id ON lameness_records(animal_id);
CREATE INDEX IF NOT EXISTS idx_lameness_records_date ON lameness_records(detection_date DESC);
CREATE INDEX IF NOT EXISTS idx_lameness_records_severity ON lameness_records(severity);
CREATE INDEX IF NOT EXISTS idx_lameness_records_user_id ON lameness_records(user_id);

-- ============================================
-- TABLE: cameras
-- Camera configurations
-- ============================================

CREATE TABLE IF NOT EXISTS cameras (
    id BIGSERIAL PRIMARY KEY,
    camera_id TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    rtsp_url TEXT,
    location TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for cameras
CREATE INDEX IF NOT EXISTS idx_cameras_camera_id ON cameras(camera_id);
CREATE INDEX IF NOT EXISTS idx_cameras_user_id ON cameras(user_id);
CREATE INDEX IF NOT EXISTS idx_cameras_is_active ON cameras(is_active);

-- ============================================
-- TABLE: depth_camera
-- Return Lane - Lameness & Milking Info from Depth Camera
-- ============================================

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

-- Indexes for depth_camera
CREATE INDEX IF NOT EXISTS idx_depth_cow_id ON depth_camera(cow_id);
CREATE INDEX IF NOT EXISTS idx_depth_lameness_score ON depth_camera(lameness_score);
CREATE INDEX IF NOT EXISTS idx_depth_timestamp ON depth_camera(post_milking_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_depth_user_id ON depth_camera(user_id);

-- Row Level Security for depth_camera
ALTER TABLE depth_camera ENABLE ROW LEVEL SECURITY;

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

-- ============================================
-- TABLE: rgbd_camera
-- Return Lane - BCS & Identification from RGB-D Camera
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

-- Indexes for rgbd_camera
CREATE INDEX IF NOT EXISTS idx_rgbd_cow_id ON rgbd_camera(cow_id);
CREATE INDEX IF NOT EXISTS idx_rgbd_bcs_score ON rgbd_camera(bcs_score);
CREATE INDEX IF NOT EXISTS idx_rgbd_timestamp ON rgbd_camera(assessment_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_rgbd_user_id ON rgbd_camera(user_id);

-- Row Level Security for rgbd_camera
ALTER TABLE rgbd_camera ENABLE ROW LEVEL SECURITY;

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

-- ============================================
-- TABLE: movement_data
-- Daily movement and activity data
-- ============================================

CREATE TABLE IF NOT EXISTS movement_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    animal_id UUID REFERENCES animals(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    step_count INTEGER CHECK (step_count >= 0),
    activity_duration_hours DECIMAL(5, 2) CHECK (activity_duration_hours >= 0 AND activity_duration_hours <= 24),
    rest_duration_hours DECIMAL(5, 2) CHECK (rest_duration_hours >= 0 AND rest_duration_hours <= 24),
    movement_score DECIMAL(5, 2) CHECK (movement_score >= 0 AND movement_score <= 100),
    movement_level VARCHAR(20) CHECK (movement_level IN ('Normal', 'Reduced', 'Abnormal')),
    average_speed DECIMAL(10, 2) CHECK (average_speed >= 0),
    distance_covered INTEGER CHECK (distance_covered >= 0),
    raw_sensor_data JSONB,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(animal_id, date)
);

-- Indexes for movement_data
CREATE INDEX IF NOT EXISTS idx_movement_animal_id ON movement_data(animal_id);
CREATE INDEX IF NOT EXISTS idx_movement_date ON movement_data(date DESC);
CREATE INDEX IF NOT EXISTS idx_movement_user_id ON movement_data(user_id);

-- ============================================
-- TABLE: video_records
-- Uploaded video information
-- ============================================

CREATE TABLE IF NOT EXISTS video_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    animal_id UUID REFERENCES animals(id) ON DELETE CASCADE,
    video_url TEXT NOT NULL,
    thumbnail_url TEXT,
    upload_date DATE NOT NULL,
    duration_seconds INTEGER CHECK (duration_seconds > 0),
    file_size_bytes BIGINT CHECK (file_size_bytes > 0),
    purpose VARCHAR(50) CHECK (purpose IN ('Identification', 'Movement Analysis', 'Lameness Detection')),
    processing_status VARCHAR(20) CHECK (processing_status IN ('Pending', 'Processing', 'Completed', 'Failed')),
    analysis_results JSONB,
    error_message TEXT,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for video_records
CREATE INDEX IF NOT EXISTS idx_video_animal_id ON video_records(animal_id);
CREATE INDEX IF NOT EXISTS idx_video_status ON video_records(processing_status);
CREATE INDEX IF NOT EXISTS idx_video_user_id ON video_records(user_id);

-- ============================================
-- TABLE: user_profiles
-- Extended user information
-- ============================================

CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255),
    phone_number VARCHAR(20),
    farm_name VARCHAR(255),
    farm_location VARCHAR(255),
    preferences JSONB,
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for user_profiles
CREATE INDEX IF NOT EXISTS idx_user_profiles_id ON user_profiles(id);

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE animals ENABLE ROW LEVEL SECURITY;
ALTER TABLE ear_tag_camera ENABLE ROW LEVEL SECURITY;
ALTER TABLE detections ENABLE ROW LEVEL SECURITY;
ALTER TABLE animal_tracks ENABLE ROW LEVEL SECURITY;
ALTER TABLE milking_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE lameness_detections ENABLE ROW LEVEL SECURITY;
ALTER TABLE lameness_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE cameras ENABLE ROW LEVEL SECURITY;
ALTER TABLE movement_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE video_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own animals" ON animals;
DROP POLICY IF EXISTS "Users can insert their own animals" ON animals;
DROP POLICY IF EXISTS "Users can update their own animals" ON animals;
DROP POLICY IF EXISTS "Users can delete their own animals" ON animals;

-- Animals RLS Policies
CREATE POLICY "Users can view their own animals"
    ON animals FOR SELECT
    USING (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Users can insert their own animals"
    ON animals FOR INSERT
    WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Users can update their own animals"
    ON animals FOR UPDATE
    USING (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Users can delete their own animals"
    ON animals FOR DELETE
    USING (auth.uid() = user_id OR user_id IS NULL);

-- ear_tag_camera RLS Policies
DROP POLICY IF EXISTS "Users can view their own detections" ON ear_tag_camera;
DROP POLICY IF EXISTS "Users can insert their own detections" ON ear_tag_camera;

CREATE POLICY "Users can view their own detections"
    ON ear_tag_camera FOR SELECT
    USING (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Users can insert their own detections"
    ON ear_tag_camera FOR INSERT
    WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

-- detections RLS Policies
DROP POLICY IF EXISTS "Users can view their detections" ON detections;
DROP POLICY IF EXISTS "Users can insert detections" ON detections;

CREATE POLICY "Users can view their detections"
    ON detections FOR SELECT
    USING (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Users can insert detections"
    ON detections FOR INSERT
    WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

-- Similar policies for other tables
DROP POLICY IF EXISTS "Users can view their tracks" ON animal_tracks;
DROP POLICY IF EXISTS "Users can insert tracks" ON animal_tracks;

CREATE POLICY "Users can view their tracks"
    ON animal_tracks FOR SELECT
    USING (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Users can insert tracks"
    ON animal_tracks FOR INSERT
    WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

-- milking_status policies
DROP POLICY IF EXISTS "Users can view milking status" ON milking_status;
DROP POLICY IF EXISTS "Users can insert milking status" ON milking_status;

CREATE POLICY "Users can view milking status"
    ON milking_status FOR SELECT
    USING (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Users can insert milking status"
    ON milking_status FOR INSERT
    WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

-- lameness_detections policies
DROP POLICY IF EXISTS "Users can view lameness detections" ON lameness_detections;
DROP POLICY IF EXISTS "Users can insert lameness detections" ON lameness_detections;

CREATE POLICY "Users can view lameness detections"
    ON lameness_detections FOR SELECT
    USING (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Users can insert lameness detections"
    ON lameness_detections FOR INSERT
    WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

-- cameras policies
DROP POLICY IF EXISTS "Users can view their cameras" ON cameras;
DROP POLICY IF EXISTS "Users can manage their cameras" ON cameras;

CREATE POLICY "Users can view their cameras"
    ON cameras FOR SELECT
    USING (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Users can manage their cameras"
    ON cameras FOR ALL
    USING (auth.uid() = user_id OR user_id IS NULL);

-- Movement Data, Video Records, Lameness Records, User Profiles policies remain same as before
-- (Add based on original schema)

-- ============================================
-- FUNCTIONS AND TRIGGERS
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
DROP TRIGGER IF EXISTS update_animals_updated_at ON animals;
CREATE TRIGGER update_animals_updated_at
    BEFORE UPDATE ON animals
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, name, created_at)
    VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'name', ''), NOW())
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create user profile automatically
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- REAL-TIME SUBSCRIPTIONS
-- ============================================

-- Enable realtime for tables (only if not already added)
DO $$
BEGIN
    -- Add animals to realtime
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'animals'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE animals;
    END IF;
    
    -- Add ear_tag_camera to realtime
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'ear_tag_camera'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE ear_tag_camera;
    END IF;
    
    -- Add detections to realtime
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'detections'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE detections;
    END IF;
    
    -- Add milking_status to realtime
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'milking_status'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE milking_status;
    END IF;
    
    -- Add lameness_detections to realtime
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'lameness_detections'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE lameness_detections;
    END IF;
    
    -- Add depth_camera to realtime
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'depth_camera'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE depth_camera;
    END IF;
    
    -- Add rgbd_camera to realtime
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
-- GRANT PERMISSIONS
-- ============================================

-- Grant permissions to authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Grant permissions to anon users for reading
GRANT USAGE ON SCHEMA public TO anon;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;

-- ============================================
-- SAMPLE DATA (for testing)
-- ============================================

-- Uncomment to insert sample data
/*
-- Sample animal
INSERT INTO animals (animal_id, species, age, health_status, milking_status, lameness_level)
VALUES 
    ('COW001', 'Cow', 24, 'Healthy', 'milking', 'normal'),
    ('COW002', 'Cow', 36, 'Healthy', 'dry', 'normal'),
    ('BUF001', 'Buffalo', 48, 'Under Observation', 'milking', 'mild')
ON CONFLICT (animal_id) DO NOTHING;

-- Sample camera
INSERT INTO cameras (camera_id, name, location, is_active)
VALUES 
    ('CAM001', 'Barn Camera 1', 'Main Barn', true),
    ('CAM002', 'Field Camera', 'Grazing Field', true)
ON CONFLICT (camera_id) DO NOTHING;
*/

-- ============================================
-- NOTES
-- ============================================

-- After running this schema:
-- 1. Go to Supabase Dashboard > Storage
-- 2. Create buckets:
--    - animal-images (public)
--    - videos (private)
--    - ml-models (private)
--
-- 3. Set storage policies:
--    - Allow authenticated users to upload
--    - Configure read permissions as needed
--
-- 4. Update your .env file with credentials
-- 5. Test the connection from your app

-- ============================================
-- END OF SCHEMA
-- ============================================
