# ✅ Supabase Deployment Checklist

## 🎯 Goal
Fix: **"Could not find the table 'public.ear_tag_camera'"** error

## 📝 Step-by-Step Checklist

### Phase 1: Database Setup (15 minutes)

- [ ] **Step 1.1**: Login to https://supabase.com
- [ ] **Step 1.2**: Open your Cattle AI project
- [ ] **Step 1.3**: Click "SQL Editor" → "New Query"
- [ ] **Step 1.4**: Open `COMPLETE_SUPABASE_SCHEMA.sql` file
- [ ] **Step 1.5**: Copy ALL contents (524 lines)
- [ ] **Step 1.6**: Paste into SQL Editor
- [ ] **Step 1.7**: Click "Run" button
- [ ] **Step 1.8**: Wait for "Success. No rows returned" message

**✅ Verify**: Click "Table Editor" → Should see 11 tables

### Phase 2: Storage Buckets (5 minutes)

- [ ] **Step 2.1**: Click "Storage" in sidebar
- [ ] **Step 2.2**: Create bucket: `animal-images` (Public: YES)
- [ ] **Step 2.3**: Create bucket: `videos` (Public: NO)
- [ ] **Step 2.4**: Create bucket: `ml-models` (Public: NO)

**✅ Verify**: Should see 3 buckets in Storage

### Phase 3: Get Credentials (2 minutes)

- [ ] **Step 3.1**: Click "Settings" → "API"
- [ ] **Step 3.2**: Copy Project URL: `https://xxxxx.supabase.co`
- [ ] **Step 3.3**: Copy anon key: `eyJhbGc...`
- [ ] **Step 3.4**: Copy service_role key: `eyJhbGc...` (click Reveal)

### Phase 4: Update Flutter App (3 minutes)

- [ ] **Step 4.1**: Open `lib/core/constants/app_constants.dart`
- [ ] **Step 4.2**: Update `supabaseUrl` with your Project URL
- [ ] **Step 4.3**: Update `supabaseAnonKey` with your anon key
- [ ] **Step 4.4**: Save file

### Phase 5: Update Python Backend (3 minutes)

- [ ] **Step 5.1**: Open `python_backend/.env`
- [ ] **Step 5.2**: Set `SUPABASE_URL=https://xxxxx.supabase.co`
- [ ] **Step 5.3**: Set `SUPABASE_KEY=your_anon_key`
- [ ] **Step 5.4**: Set `SUPABASE_SERVICE_KEY=your_service_role_key`
- [ ] **Step 5.5**: Save file

### Phase 6: Test Everything (5 minutes)

- [ ] **Step 6.1**: Start Python backend:
  ```bash
  cd python_backend
  ./start.sh
  ```
- [ ] **Step 6.2**: Visit http://localhost:8000/health
- [ ] **Step 6.3**: Check `"database": true` in response
- [ ] **Step 6.4**: Run Flutter app:
  ```bash
  flutter run
  ```
- [ ] **Step 6.5**: Open app → Dashboard
- [ ] **Step 6.6**: Verify NO error: "Could not find the table"

## ✅ Success Criteria

### Database
- [x] 11 tables exist in Table Editor
- [x] ear_tag_camera table exists ← **Main fix**
- [x] All tables have RLS policies enabled

### Storage
- [x] animal-images bucket (Public)
- [x] videos bucket (Private)
- [x] ml-models bucket (Private)

### Connections
- [x] Python backend connects (database: true)
- [x] Flutter app connects (no table errors)
- [x] Dashboard loads successfully

## 🚨 Common Issues

### Issue 1: "relation already exists"
**Cause**: Table already created
**Fix**: This is fine! Skip and continue

### Issue 2: "table not found" still appears
**Cause**: Credentials not updated or wrong
**Fix**: 
1. Double-check Project URL in both apps
2. Verify anon key is correct
3. Restart both apps

### Issue 3: "insufficient_privilege"
**Cause**: Using anon key instead of service_role key
**Fix**: Python backend needs service_role key in SUPABASE_SERVICE_KEY

### Issue 4: Storage bucket creation fails
**Cause**: Name already exists or invalid characters
**Fix**: Use exact names: animal-images, videos, ml-models (lowercase, hyphens only)

## 📊 Tables Created (11 Total)

| Table | Purpose | Records |
|-------|---------|---------|
| animals | Cattle information | Core data |
| ear_tag_camera | Camera detections | **← Missing table** |
| detections | ML detection results | AI data |
| animal_tracks | Tracking & counting | AI data |
| milking_status | Lactation status | AI data |
| lameness_detections | Lameness analysis | AI data |
| lameness_records | Historical lameness | Historical |
| cameras | Camera configs | Setup |
| movement_data | Daily activity | Metrics |
| video_records | Uploaded videos | Media |
| user_profiles | User information | Auth |

## 📦 Storage Buckets (3 Total)

| Bucket | Public | Purpose |
|--------|--------|---------|
| animal-images | ✅ Yes | Animal photos (public access) |
| videos | ❌ No | Uploaded videos (auth required) |
| ml-models | ❌ No | YOLOv8 models (system only) |

## 🎉 Final Verification

Run this query in SQL Editor to verify:

```sql
-- Count all tables
SELECT 
    schemaname, 
    tablename 
FROM pg_tables 
WHERE schemaname = 'public' 
    AND tablename IN (
        'animals', 'ear_tag_camera', 'detections', 
        'animal_tracks', 'milking_status', 'lameness_detections',
        'cameras', 'movement_data', 'video_records', 
        'user_profiles', 'lameness_records'
    )
ORDER BY tablename;
```

**Expected Result**: 11 rows

## 📞 Help

- Full guide: [DEPLOY_TO_SUPABASE.md](DEPLOY_TO_SUPABASE.md)
- Schema file: [COMPLETE_SUPABASE_SCHEMA.sql](COMPLETE_SUPABASE_SCHEMA.sql)
- Supabase Docs: https://supabase.com/docs

---

**Time Estimate**: 30-35 minutes total
**Difficulty**: Easy (copy-paste mostly)
**Result**: ✅ All table errors fixed!
