-- ============================================
-- SUPABASE DATABASE SCHEMA
-- Cattle AI Monitor - IoT-Based Monitoring System
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- TABLE: animals
-- Stores cattle/animal information
-- ============================================

CREATE TABLE animals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    animal_id VARCHAR(20) UNIQUE NOT NULL,
    species VARCHAR(50) NOT NULL CHECK (species IN ('Cow', 'Buffalo')),
    age INTEGER NOT NULL CHECK (age >= 0),
    health_status VARCHAR(50) NOT NULL CHECK (health_status IN ('Healthy', 'Under Observation', 'Sick', 'Critical')),
    image_url TEXT,
    breed VARCHAR(100),
    weight DECIMAL(10, 2) CHECK (weight > 0),
    notes TEXT,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for animals table
CREATE INDEX idx_animals_user_id ON animals(user_id);
CREATE INDEX idx_animals_animal_id ON animals(animal_id);
CREATE INDEX idx_animals_species ON animals(species);
CREATE INDEX idx_animals_health_status ON animals(health_status);

-- ============================================
-- TABLE: movement_data
-- Stores daily movement and activity data
-- ============================================

CREATE TABLE movement_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    animal_id UUID NOT NULL REFERENCES animals(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    step_count INTEGER NOT NULL CHECK (step_count >= 0),
    activity_duration_hours DECIMAL(5, 2) NOT NULL CHECK (activity_duration_hours >= 0 AND activity_duration_hours <= 24),
    rest_duration_hours DECIMAL(5, 2) NOT NULL CHECK (rest_duration_hours >= 0 AND rest_duration_hours <= 24),
    movement_score DECIMAL(5, 2) NOT NULL CHECK (movement_score >= 0 AND movement_score <= 100),
    movement_level VARCHAR(20) NOT NULL CHECK (movement_level IN ('Normal', 'Reduced', 'Abnormal')),
    average_speed DECIMAL(10, 2) CHECK (average_speed >= 0),
    distance_covered INTEGER CHECK (distance_covered >= 0),
    raw_sensor_data JSONB,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(animal_id, date)
);

-- Indexes for movement_data table
CREATE INDEX idx_movement_animal_id ON movement_data(animal_id);
CREATE INDEX idx_movement_date ON movement_data(date DESC);
CREATE INDEX idx_movement_timestamp ON movement_data(timestamp DESC);
CREATE INDEX idx_movement_level ON movement_data(movement_level);

-- ============================================
-- TABLE: lameness_records
-- Stores lameness detection results
-- ============================================

CREATE TABLE lameness_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    animal_id UUID NOT NULL REFERENCES animals(id) ON DELETE CASCADE,
    detection_date DATE NOT NULL,
    severity VARCHAR(50) NOT NULL CHECK (severity IN ('Normal', 'Mild Lameness', 'Severe Lameness')),
    confidence_score DECIMAL(5, 4) NOT NULL CHECK (confidence_score >= 0 AND confidence_score <= 1),
    detection_method VARCHAR(20) NOT NULL CHECK (detection_method IN ('Rule-Based', 'ML-Based')),
    step_count INTEGER CHECK (step_count >= 0),
    activity_hours DECIMAL(5, 2) CHECK (activity_hours >= 0 AND activity_hours <= 24),
    rest_hours DECIMAL(5, 2) CHECK (rest_hours >= 0 AND rest_hours <= 24),
    ml_input_features JSONB,
    ml_output_probabilities JSONB,
    video_url TEXT,
    notes TEXT,
    requires_attention BOOLEAN DEFAULT FALSE,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for lameness_records table
CREATE INDEX idx_lameness_animal_id ON lameness_records(animal_id);
CREATE INDEX idx_lameness_date ON lameness_records(detection_date DESC);
CREATE INDEX idx_lameness_severity ON lameness_records(severity);
CREATE INDEX idx_lameness_attention ON lameness_records(requires_attention);
CREATE INDEX idx_lameness_method ON lameness_records(detection_method);

-- ============================================
-- TABLE: video_records
-- Stores uploaded video information
-- ============================================

CREATE TABLE video_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    animal_id UUID NOT NULL REFERENCES animals(id) ON DELETE CASCADE,
    video_url TEXT NOT NULL,
    thumbnail_url TEXT,
    upload_date DATE NOT NULL,
    duration_seconds INTEGER NOT NULL CHECK (duration_seconds > 0),
    file_size_bytes BIGINT NOT NULL CHECK (file_size_bytes > 0),
    purpose VARCHAR(50) NOT NULL CHECK (purpose IN ('Identification', 'Movement Analysis', 'Lameness Detection')),
    processing_status VARCHAR(20) NOT NULL CHECK (processing_status IN ('Pending', 'Processing', 'Completed', 'Failed')),
    analysis_results JSONB,
    error_message TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for video_records table
CREATE INDEX idx_video_animal_id ON video_records(animal_id);
CREATE INDEX idx_video_status ON video_records(processing_status);
CREATE INDEX idx_video_upload_date ON video_records(upload_date DESC);
CREATE INDEX idx_video_purpose ON video_records(purpose);

-- ============================================
-- TABLE: user_profiles
-- Extended user information
-- ============================================

CREATE TABLE user_profiles (
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
CREATE INDEX idx_user_profiles_id ON user_profiles(id);

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE animals ENABLE ROW LEVEL SECURITY;
ALTER TABLE movement_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE lameness_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE video_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Animals RLS Policies
CREATE POLICY "Users can view their own animals"
    ON animals FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own animals"
    ON animals FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own animals"
    ON animals FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own animals"
    ON animals FOR DELETE
    USING (auth.uid() = user_id);

-- Movement Data RLS Policies
CREATE POLICY "Users can view movement data for their animals"
    ON movement_data FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM animals
        WHERE animals.id = movement_data.animal_id
        AND animals.user_id = auth.uid()
    ));

CREATE POLICY "Users can insert movement data for their animals"
    ON movement_data FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM animals
        WHERE animals.id = movement_data.animal_id
        AND animals.user_id = auth.uid()
    ));

-- Lameness Records RLS Policies
CREATE POLICY "Users can view lameness records for their animals"
    ON lameness_records FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM animals
        WHERE animals.id = lameness_records.animal_id
        AND animals.user_id = auth.uid()
    ));

CREATE POLICY "Users can insert lameness records for their animals"
    ON lameness_records FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM animals
        WHERE animals.id = lameness_records.animal_id
        AND animals.user_id = auth.uid()
    ));

-- Video Records RLS Policies
CREATE POLICY "Users can view video records for their animals"
    ON video_records FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM animals
        WHERE animals.id = video_records.animal_id
        AND animals.user_id = auth.uid()
    ));

CREATE POLICY "Users can insert video records for their animals"
    ON video_records FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM animals
        WHERE animals.id = video_records.animal_id
        AND animals.user_id = auth.uid()
    ));

CREATE POLICY "Users can update video records for their animals"
    ON video_records FOR UPDATE
    USING (EXISTS (
        SELECT 1 FROM animals
        WHERE animals.id = video_records.animal_id
        AND animals.user_id = auth.uid()
    ));

-- User Profiles RLS Policies
CREATE POLICY "Users can view their own profile"
    ON user_profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
    ON user_profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
    ON user_profiles FOR UPDATE
    USING (auth.uid() = id);

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

-- Trigger for animals table
CREATE TRIGGER update_animals_updated_at
    BEFORE UPDATE ON animals
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for user_profiles table
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, name, created_at)
    VALUES (NEW.id, NEW.raw_user_meta_data->>'name', NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create user profile automatically
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- STORAGE BUCKETS
-- Run these in Supabase Dashboard > Storage
-- ============================================

-- Create buckets:
-- 1. animal-images (public)
-- 2. videos (private)
-- 3. ml-models (private)

-- Storage Policies Example (for animal-images bucket):
-- Allow authenticated users to upload:
-- INSERT: auth.role() = 'authenticated'
-- SELECT: true (public read)
-- UPDATE: auth.uid() = owner
-- DELETE: auth.uid() = owner

-- ============================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================

-- Insert sample animal (replace user_id with actual UUID)
-- INSERT INTO animals (animal_id, species, age, health_status, user_id)
-- VALUES ('COW001', 'Cow', 24, 'Healthy', 'YOUR-USER-UUID');

-- ============================================
-- USEFUL QUERIES
-- ============================================

-- Get all animals with latest movement data
-- SELECT a.*, 
--        m.step_count, 
--        m.movement_score,
--        m.movement_level
-- FROM animals a
-- LEFT JOIN LATERAL (
--     SELECT * FROM movement_data
--     WHERE animal_id = a.id
--     ORDER BY date DESC
--     LIMIT 1
-- ) m ON true
-- WHERE a.user_id = auth.uid();

-- Get lameness trend for an animal
-- SELECT detection_date, severity, confidence_score, detection_method
-- FROM lameness_records
-- WHERE animal_id = 'ANIMAL-UUID'
-- ORDER BY detection_date DESC
-- LIMIT 30;

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

-- Composite indexes for common queries
CREATE INDEX idx_movement_animal_date ON movement_data(animal_id, date DESC);
CREATE INDEX idx_lameness_animal_date ON lameness_records(animal_id, detection_date DESC);
CREATE INDEX idx_video_animal_upload ON video_records(animal_id, upload_date DESC);

-- ============================================
-- REAL-TIME SUBSCRIPTIONS
-- ============================================

-- Enable realtime for tables
ALTER PUBLICATION supabase_realtime ADD TABLE animals;
ALTER PUBLICATION supabase_realtime ADD TABLE movement_data;
ALTER PUBLICATION supabase_realtime ADD TABLE lameness_records;
ALTER PUBLICATION supabase_realtime ADD TABLE video_records;

-- ============================================
-- MAINTENANCE QUERIES
-- ============================================

-- Delete old movement data (older than 90 days)
-- DELETE FROM movement_data
-- WHERE date < CURRENT_DATE - INTERVAL '90 days';

-- Vacuum analyze for performance
-- VACUUM ANALYZE animals;
-- VACUUM ANALYZE movement_data;
-- VACUUM ANALYZE lameness_records;
-- VACUUM ANALYZE video_records;

-- ============================================
-- END OF SCHEMA
-- ============================================
