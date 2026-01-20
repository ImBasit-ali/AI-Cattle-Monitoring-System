-- ============================================
-- SUPABASE STORAGE BUCKET POLICIES
-- Run these after creating the buckets
-- ============================================

-- ============================================
-- BUCKET 1: animal-images (PUBLIC BUCKET)
-- Used for: Animal photos accessible to all users
-- ============================================

-- Allow authenticated users to upload images
CREATE POLICY "Allow authenticated uploads to animal-images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'animal-images');

-- Allow public read access to animal images
CREATE POLICY "Public read access to animal-images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'animal-images');

-- Allow authenticated users to update their images
CREATE POLICY "Allow authenticated updates to animal-images"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'animal-images');

-- Allow authenticated users to delete their images
CREATE POLICY "Allow authenticated deletes from animal-images"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'animal-images');

-- ============================================
-- BUCKET 2: videos (PRIVATE BUCKET)
-- Used for: Uploaded video recordings
-- ============================================

-- Allow authenticated users full access to videos
CREATE POLICY "Allow authenticated access to videos"
ON storage.objects FOR ALL
TO authenticated
USING (bucket_id = 'videos')
WITH CHECK (bucket_id = 'videos');

-- ============================================
-- BUCKET 3: ml-models (PRIVATE BUCKET)
-- Used for: YOLOv8 model files, ML checkpoints
-- ============================================

-- Allow authenticated users full access to models
CREATE POLICY "Allow authenticated access to ml-models"
ON storage.objects FOR ALL
TO authenticated
USING (bucket_id = 'ml-models')
WITH CHECK (bucket_id = 'ml-models');

-- Allow service role (Python backend) full access
CREATE POLICY "Allow service role access to ml-models"
ON storage.objects FOR ALL
TO service_role
USING (bucket_id = 'ml-models')
WITH CHECK (bucket_id = 'ml-models');

-- ============================================
-- VERIFICATION QUERIES
-- Run to verify policies are set correctly
-- ============================================

-- Check all storage policies
SELECT 
    policyname,
    tablename,
    roles,
    cmd
FROM pg_policies
WHERE schemaname = 'storage'
ORDER BY policyname;

-- Check bucket configurations
SELECT 
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets
ORDER BY name;

-- ============================================
-- MANUAL BUCKET CREATION (Alternative)
-- If SQL approach doesn't work, create via Dashboard
-- ============================================

/*
OPTION 1: Via Supabase Dashboard
1. Go to Storage → New Bucket
2. Create these buckets:

   Bucket 1:
   - Name: animal-images
   - Public: ✅ YES
   - File size limit: 50 MB (optional)
   - Allowed MIME types: image/jpeg, image/png, image/jpg

   Bucket 2:
   - Name: videos
   - Public: ❌ NO
   - File size limit: 500 MB (optional)
   - Allowed MIME types: video/mp4, video/avi, video/mov

   Bucket 3:
   - Name: ml-models
   - Public: ❌ NO
   - File size limit: 1000 MB (optional)
   - Allowed MIME types: application/octet-stream

3. After creating buckets, add policies via SQL above
*/

-- ============================================
-- TESTING STORAGE
-- Upload test files to verify
-- ============================================

-- Test from Python backend:
/*
from supabase import create_client

supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

# Test upload to ml-models
with open("test.txt", "w") as f:
    f.write("test")

with open("test.txt", "rb") as f:
    supabase.storage.from_("ml-models").upload("test/test.txt", f)
*/

-- Test from Flutter:
/*
final file = File('path/to/image.jpg');
final bytes = await file.readAsBytes();

await Supabase.instance.client.storage
    .from('animal-images')
    .uploadBinary(
      'animals/test.jpg',
      bytes,
    );
*/

-- ============================================
-- CLEANUP (if needed)
-- Delete all policies and buckets to start fresh
-- ============================================

-- WARNING: This will delete ALL data in buckets!
-- Uncomment only if you want to reset everything

/*
-- Delete all storage policies
DROP POLICY IF EXISTS "Allow authenticated uploads to animal-images" ON storage.objects;
DROP POLICY IF EXISTS "Public read access to animal-images" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated updates to animal-images" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated deletes from animal-images" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated access to videos" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated access to ml-models" ON storage.objects;
DROP POLICY IF EXISTS "Allow service role access to ml-models" ON storage.objects;

-- Delete buckets (via dashboard or API, not SQL)
-- DELETE FROM storage.buckets WHERE name IN ('animal-images', 'videos', 'ml-models');
*/
