# 🚀 Deploy to Supabase - Step by Step Guide

## ✅ What This Does

This creates ALL the database tables, policies, and configurations your Cattle AI app needs in your Supabase account.

## 📋 Tables That Will Be Created

### Core Tables
1. **animals** - Store your cattle information
2. **ear_tag_camera** - Camera detection records ← **This fixes your error**
3. **detections** - ML detection results from Python backend
4. **animal_tracks** - Tracking and counting data
5. **milking_status** - Lactation status records
6. **lameness_detections** - Lameness analysis results
7. **lameness_records** - Historical lameness data
8. **cameras** - Camera configurations
9. **movement_data** - Daily activity data
10. **video_records** - Uploaded videos
11. **user_profiles** - User information

## 🎯 Deployment Steps

### Step 1: Login to Supabase

1. Go to https://supabase.com
2. Login to your account
3. Open your Cattle AI project

### Step 2: Open SQL Editor

1. Click on **SQL Editor** in the left sidebar
2. Click **"New Query"** button

### Step 3: Run the Schema

1. Open the file: `COMPLETE_SUPABASE_SCHEMA.sql`
2. **Copy ALL** the contents (Ctrl+A, Ctrl+C)
3. **Paste** into Supabase SQL Editor
4. Click **"Run"** button (or press Ctrl+Enter)

**Wait for it to complete** (should take 5-10 seconds)

### Step 4: Verify Tables Were Created

1. Click **"Table Editor"** in left sidebar
2. You should see all these tables:
   - ✅ animals
   - ✅ ear_tag_camera ← **The missing table!**
   - ✅ detections
   - ✅ animal_tracks
   - ✅ milking_status
   - ✅ lameness_detections
   - ✅ cameras
   - ✅ movement_data
   - ✅ video_records
   - ✅ user_profiles

### Step 5: Create Storage Buckets

1. Click **"Storage"** in left sidebar
2. Click **"New bucket"**

Create these 3 buckets:

**Bucket 1: animal-images**
- Name: `animal-images`
- Public bucket: ✅ **Yes** (enable)
- Click "Create bucket"

**Bucket 2: videos**
- Name: `videos`
- Public bucket: ❌ **No**
- Click "Create bucket"

**Bucket 3: ml-models**
- Name: `ml-models`
- Public bucket: ❌ **No**
- Click "Create bucket"

### Step 6: Set Storage Policies

For each bucket, click the bucket → "Policies" tab → "New Policy"

**For animal-images bucket:**
```sql
-- Policy name: Allow authenticated uploads
-- Operation: INSERT
CREATE POLICY "Allow authenticated uploads"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'animal-images');

-- Policy name: Public read access
-- Operation: SELECT
CREATE POLICY "Public read access"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'animal-images');
```

**For videos bucket:**
```sql
-- Policy name: Allow authenticated users
-- Operation: ALL
CREATE POLICY "Allow authenticated users"
ON storage.objects FOR ALL
TO authenticated
USING (bucket_id = 'videos');
```

**For ml-models bucket:**
```sql
-- Policy name: Allow authenticated users
-- Operation: ALL
CREATE POLICY "Allow authenticated users"
ON storage.objects FOR ALL
TO authenticated
USING (bucket_id = 'ml-models');
```

### Step 7: Get Your Credentials

1. Click **"Settings"** in left sidebar
2. Click **"API"** tab
3. Copy these values:

```
Project URL: https://xxxxx.supabase.co
anon public key: eyJhbGc...
service_role key: eyJhbGc... (click "Reveal" to see)
```

### Step 8: Update Your App Configuration

**Flutter App** (`lib/core/constants/app_constants.dart`):
```dart
static const String supabaseUrl = 'https://xxxxx.supabase.co';
static const String supabaseAnonKey = 'eyJhbGc...';
```

**Python Backend** (`python_backend/.env`):
```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_KEY=eyJhbGc...  (anon key)
SUPABASE_SERVICE_KEY=eyJhbGc...  (service_role key)
```

### Step 9: Test the Connection

**Test from Flutter:**
```bash
flutter run
```

The error **"Could not find the table 'public.ear_tag_camera'"** should now be gone! ✅

**Test from Python:**
```bash
cd python_backend
./start.sh
```

Visit http://localhost:8000/health - should show database: true

## ✅ Success Checklist

After deployment, verify:

- [ ] All 11 tables are created in Table Editor
- [ ] 3 storage buckets exist (animal-images, videos, ml-models)
- [ ] Storage policies are set
- [ ] Credentials updated in Flutter app
- [ ] Credentials updated in Python backend
- [ ] Flutter app runs without table errors
- [ ] Python backend connects successfully

## 🐛 Troubleshooting

### Error: "relation already exists"
**Solution:** Some tables already exist. This is OK, the schema uses `CREATE TABLE IF NOT EXISTS`

### Error: "permission denied"
**Solution:** Make sure you're running in SQL Editor as the project owner

### Tables not showing up
**Solution:** 
1. Refresh the page
2. Check "Table Editor" not "SQL Editor"
3. Make sure query ran successfully (check for errors at bottom)

### Storage bucket creation failed
**Solution:** 
1. Bucket names must be lowercase
2. Try creating manually: Storage → New bucket → Enter name → Create

### App still shows "table not found"
**Solution:**
1. Verify table exists in Supabase Table Editor
2. Check RLS policies are enabled
3. Restart your Flutter app
4. Clear app cache and rebuild

## 📊 Sample Data (Optional)

To test with sample data, run this in SQL Editor:

```sql
-- Insert sample animals
INSERT INTO animals (animal_id, species, age, health_status, milking_status, lameness_level)
VALUES 
    ('COW001', 'Cow', 24, 'Healthy', 'milking', 'normal'),
    ('COW002', 'Cow', 36, 'Healthy', 'dry', 'normal'),
    ('BUF001', 'Buffalo', 48, 'Under Observation', 'milking', 'mild')
ON CONFLICT (animal_id) DO NOTHING;

-- Insert sample camera
INSERT INTO cameras (camera_id, name, location, is_active)
VALUES 
    ('CAM001', 'Barn Camera 1', 'Main Barn', true),
    ('CAM002', 'Field Camera', 'Grazing Field', true)
ON CONFLICT (camera_id) DO NOTHING;

-- Insert sample detection
INSERT INTO ear_tag_camera (animal_id, camera_id, confidence, species)
VALUES 
    ('COW001', 'CAM001', 0.95, 'Cow'),
    ('COW002', 'CAM001', 0.92, 'Cow'),
    ('BUF001', 'CAM002', 0.88, 'Buffalo');
```

## 🎉 You're Done!

Your Supabase database is now fully configured and ready to use with your Cattle AI app!

The error **"Could not find the table 'public.ear_tag_camera'"** is now fixed because the table exists.

## 📞 Need Help?

- **Supabase Docs**: https://supabase.com/docs
- **SQL Reference**: Click any table in Table Editor to see its structure
- **Logs**: Check Supabase Dashboard → Logs for errors

---

**Quick Reference:**
- Schema file: `COMPLETE_SUPABASE_SCHEMA.sql`
- Tables created: 11
- Storage buckets: 3
- Time needed: ~10 minutes
