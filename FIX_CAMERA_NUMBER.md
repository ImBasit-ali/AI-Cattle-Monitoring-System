# 🔧 Quick Fix: Add camera_number Column

## 🐛 Error You're Seeing
```
Error: Could not find the 'camera_number' column of 'ear_tag_camera'
```

## ✅ Solution: Add Missing Column

You have TWO options:

---

## Option 1: Quick Fix (1 minute) ⚡

**If you already created the ear_tag_camera table:**

### Step 1: Open Supabase SQL Editor
1. Go to https://supabase.com
2. Open your project
3. Click **SQL Editor** → **New Query**

### Step 2: Add the Missing Column
Copy and paste this:

```sql
ALTER TABLE ear_tag_camera 
ADD COLUMN IF NOT EXISTS camera_number INTEGER CHECK (camera_number IN (1, 2, 3, 4, 5));

CREATE INDEX IF NOT EXISTS idx_ear_tag_camera_number ON ear_tag_camera(camera_number);
```

### Step 3: Click "Run"

✅ Done! The error is fixed.

---

## Option 2: Complete Fresh Install (5 minutes) 🔄

**If you want to recreate everything from scratch:**

### Step 1: Delete Old Table
```sql
DROP TABLE IF EXISTS ear_tag_camera CASCADE;
```

### Step 2: Run Complete Schema
1. Open the file: `COMPLETE_SUPABASE_SCHEMA.sql` (I updated it!)
2. Copy ALL contents
3. Paste into Supabase SQL Editor
4. Click "Run"

This will create the table WITH the `camera_number` column included.

---

## 🧪 Test the Fix

Run your Flutter app:
```bash
flutter run
```

The error should be GONE! ✅

---

## 📋 What This Does

The `camera_number` column stores which camera detected the animal (1-5):
- Camera 1 & 2: Milking parlor cameras
- Camera 3: Ear tag reader
- Camera 4: Lameness detection
- Camera 5: Body condition scoring

Your Flutter app is trying to save this information but the column didn't exist.

---

## 🚨 Still Getting Errors?

If you see other missing column errors, you likely need to:
1. Drop all tables
2. Run the COMPLETE_SUPABASE_SCHEMA.sql from scratch
3. This ensures ALL columns match what your app expects

---

**Quick Fix SQL File**: [FIX_CAMERA_NUMBER_COLUMN.sql](FIX_CAMERA_NUMBER_COLUMN.sql)
**Updated Complete Schema**: [COMPLETE_SUPABASE_SCHEMA.sql](COMPLETE_SUPABASE_SCHEMA.sql)
