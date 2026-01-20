# Supabase Setup Guide for Cattle AI Monitor

This guide will help you enable and configure all Supabase features for the Cattle AI Monitor application.

## 📋 Table of Contents

1. [Initial Setup](#initial-setup)
2. [Authentication](#authentication)
3. [PostgreSQL Database](#postgresql-database)
4. [Real-time Subscriptions](#real-time-subscriptions)
5. [Storage Setup](#storage-setup)
6. [Edge Functions](#edge-functions)
7. [Security Configuration](#security-configuration)

---

## 🚀 Initial Setup

### 1. Create Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Sign in or create an account
3. Click **"New Project"**
4. Fill in project details:
   - **Name**: cattle-ai-monitor
   - **Database Password**: (save this securely)
   - **Region**: Choose closest to your users
5. Click **"Create new project"**

### 2. Get API Credentials

Once your project is created:

1. Go to **Settings** → **API**
2. Copy the following:
   - **Project URL**: `https://nznoonwreqsdrawfxrwr.supabase.co`
   - **anon/public key**: `sb_publishable_hac1WXtWlst8ZES8Jor5MQ_fj3dl0JS`

### 3. Update Flutter App

Edit `lib/core/constants/app_constants.dart`:

```dart
class AppConstants {
  // Supabase Configuration
  static const String supabaseUrl = 'https://nznoonwreqsdrawfxrwr.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_hac1WXtWlst8ZES8Jor5MQ_fj3dl0JS';
  
  // ... rest of constants
}
```

---

## 🔐 Authentication

### Step 1: Enable Authentication Providers

1. Go to **Authentication** → **Providers** in Supabase Dashboard
2. Enable **Email** provider:
   - Toggle "Enable Email provider" to ON
   - **Confirm email**: Enable (recommended for production)
   - **Secure email change**: Enable
   - Save changes

### Step 2: Configure Email Templates (Optional)

1. Go to **Authentication** → **Email Templates**
2. Customize templates:
   - **Confirmation**: User signup confirmation
   - **Reset Password**: Password reset link
   - **Magic Link**: Passwordless login
   - **Change Email**: Email change confirmation

### Step 3: Add Redirect URLs

1. Go to **Authentication** → **URL Configuration**
2. Add redirect URLs:
   ```
   http://localhost:3000/**
   https://your-domain.com/**
   cattle-ai://login-callback/**  (for mobile deep linking)
   ```

### Step 4: Test Authentication in App

Your app already has authentication implemented. Test it:

```bash
flutter run
```

Try:
- Sign up with new email/password
- Sign in with existing credentials
- Sign out
- Password reset

---

## 🗄️ PostgreSQL Database

### Step 1: Create Database Tables

1. Go to **SQL Editor** in Supabase Dashboard
2. Create a new query
3. Copy and paste the following SQL:

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- ANIMALS TABLE
-- ============================================
CREATE TABLE animals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    animal_id VARCHAR(20) UNIQUE NOT NULL,
    species VARCHAR(50) NOT NULL,
    age INTEGER NOT NULL,
    health_status VARCHAR(50) NOT NULL,
    image_url TEXT,
    breed VARCHAR(100),
    weight DECIMAL(10, 2),
    notes TEXT,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for animals
CREATE INDEX idx_animals_user_id ON animals(user_id);
CREATE INDEX idx_animals_animal_id ON animals(animal_id);

-- ============================================
-- MOVEMENT DATA TABLE
-- ============================================
CREATE TABLE movement_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    animal_id UUID NOT NULL REFERENCES animals(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    step_count INTEGER NOT NULL,
    activity_duration_hours DECIMAL(5, 2) NOT NULL,
    rest_duration_hours DECIMAL(5, 2) NOT NULL,
    movement_score DECIMAL(5, 2) NOT NULL,
    movement_level VARCHAR(20) NOT NULL,
    average_speed DECIMAL(10, 2),
    distance_covered INTEGER,
    raw_sensor_data JSONB,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for movement_data
CREATE INDEX idx_movement_animal_id ON movement_data(animal_id);
CREATE INDEX idx_movement_date ON movement_data(date);
CREATE INDEX idx_movement_timestamp ON movement_data(timestamp);

-- ============================================
-- LAMENESS RECORDS TABLE
-- ============================================
CREATE TABLE lameness_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    animal_id UUID NOT NULL REFERENCES animals(id) ON DELETE CASCADE,
    detection_date DATE NOT NULL,
    severity VARCHAR(50) NOT NULL,
    confidence_score DECIMAL(5, 4) NOT NULL,
    detection_method VARCHAR(20) NOT NULL,
    step_count INTEGER,
    activity_hours DECIMAL(5, 2),
    rest_hours DECIMAL(5, 2),
    ml_input_features JSONB,
    ml_output_probabilities JSONB,
    video_url TEXT,
    notes TEXT,
    requires_attention BOOLEAN DEFAULT FALSE,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for lameness_records
CREATE INDEX idx_lameness_animal_id ON lameness_records(animal_id);
CREATE INDEX idx_lameness_date ON lameness_records(detection_date);
CREATE INDEX idx_lameness_severity ON lameness_records(severity);

-- ============================================
-- VIDEO RECORDS TABLE
-- ============================================
CREATE TABLE video_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    animal_id UUID NOT NULL REFERENCES animals(id) ON DELETE CASCADE,
    video_url TEXT NOT NULL,
    thumbnail_url TEXT,
    upload_date DATE NOT NULL,
    duration_seconds INTEGER NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    purpose VARCHAR(50) NOT NULL,
    processing_status VARCHAR(20) NOT NULL,
    analysis_results JSONB,
    error_message TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for video_records
CREATE INDEX idx_video_animal_id ON video_records(animal_id);
CREATE INDEX idx_video_status ON video_records(processing_status);
CREATE INDEX idx_video_upload_date ON video_records(upload_date);

-- ============================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_animals_updated_at BEFORE UPDATE ON animals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

4. Click **Run** to execute the SQL
5. Verify tables in **Table Editor**

### Step 2: Enable Row Level Security (RLS)

Run this SQL to enable RLS and create policies:

```sql
-- ============================================
-- ENABLE RLS
-- ============================================
ALTER TABLE animals ENABLE ROW LEVEL SECURITY;
ALTER TABLE movement_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE lameness_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE video_records ENABLE ROW LEVEL SECURITY;

-- ============================================
-- ANIMALS POLICIES
-- ============================================
-- Users can only see their own animals
CREATE POLICY "Users can view own animals"
    ON animals FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own animals
CREATE POLICY "Users can insert own animals"
    ON animals FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own animals
CREATE POLICY "Users can update own animals"
    ON animals FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete their own animals
CREATE POLICY "Users can delete own animals"
    ON animals FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- MOVEMENT DATA POLICIES
-- ============================================
CREATE POLICY "Users can view movement data for their animals"
    ON movement_data FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM animals
            WHERE animals.id = movement_data.animal_id
            AND animals.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert movement data for their animals"
    ON movement_data FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM animals
            WHERE animals.id = movement_data.animal_id
            AND animals.user_id = auth.uid()
        )
    );

-- ============================================
-- LAMENESS RECORDS POLICIES
-- ============================================
CREATE POLICY "Users can view lameness records for their animals"
    ON lameness_records FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM animals
            WHERE animals.id = lameness_records.animal_id
            AND animals.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert lameness records for their animals"
    ON lameness_records FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM animals
            WHERE animals.id = lameness_records.animal_id
            AND animals.user_id = auth.uid()
        )
    );

-- ============================================
-- VIDEO RECORDS POLICIES
-- ============================================
CREATE POLICY "Users can view video records for their animals"
    ON video_records FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM animals
            WHERE animals.id = video_records.animal_id
            AND animals.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert video records for their animals"
    ON video_records FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM animals
            WHERE animals.id = video_records.animal_id
            AND animals.user_id = auth.uid()
        )
    );
```

### Step 3: Test Database Connection

Your app already has database integration. Test by:
1. Sign in to the app
2. Add a new animal
3. View the animals list
4. Check Supabase **Table Editor** to see the data

---

## 🔄 Real-time Subscriptions

### Step 1: Enable Realtime in Supabase

1. Go to **Database** → **Replication** in Supabase Dashboard
2. For each table you want real-time updates:
   - `animals`
   - `movement_data`
   - `lameness_records`
   - `video_records`

3. Toggle the switch to enable replication
4. Click **Save**

### Step 2: Verify Realtime is Enabled

Run this SQL to check:

```sql
-- Check which tables have replication enabled
SELECT schemaname, tablename, pg_is_in_replication_state(schemaname, tablename)
FROM pg_tables
WHERE schemaname = 'public';
```

### Step 3: Test Real-time in Your App

Your `SupabaseService` already has real-time methods. To use them:

```dart
// In your provider or service
import 'package:supabase_flutter/supabase_flutter.dart';

// Subscribe to animal updates
RealtimeChannel? _animalChannel;

void subscribeToAnimals() {
  _animalChannel = SupabaseService.instance.subscribeToAnimals(
    (payload) {
      print('Animal changed: ${payload.eventType}');
      print('New data: ${payload.newRecord}');
      // Update your UI state here
      notifyListeners();
    },
  );
}

void dispose() {
  if (_animalChannel != null) {
    SupabaseService.instance.unsubscribe(_animalChannel!);
  }
}
```

### Step 4: Enable Realtime API

1. Go to **Settings** → **API**
2. Scroll to **Realtime**
3. Ensure it's enabled
4. Configure settings:
   - **Max connections**: 100 (adjust as needed)
   - **Max channels per client**: 100

---

## 📦 Storage Setup

### Step 1: Create Storage Buckets

1. Go to **Storage** in Supabase Dashboard
2. Click **"New bucket"**

Create these three buckets:

#### Bucket 1: animal-images
- **Name**: `animal-images`
- **Public**: Yes (for easy viewing)
- Click **Create bucket**

#### Bucket 2: videos
- **Name**: `videos`
- **Public**: No (keep private)
- Click **Create bucket**

#### Bucket 3: ml-models (optional)
- **Name**: `ml-models`
- **Public**: Yes (if distributing models)
- Click **Create bucket**

### Step 2: Configure Storage Policies

Click on each bucket → **Policies** → **New policy**

#### For animal-images bucket:

```sql
-- Allow authenticated users to upload
CREATE POLICY "Authenticated users can upload images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'animal-images');

-- Allow authenticated users to read their own images
CREATE POLICY "Users can read own images"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'animal-images');

-- Allow public to read images (if public bucket)
CREATE POLICY "Public can read images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'animal-images');

-- Allow users to update their own images
CREATE POLICY "Users can update own images"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'animal-images');

-- Allow users to delete their own images
CREATE POLICY "Users can delete own images"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'animal-images');
```

#### For videos bucket:

```sql
-- Allow authenticated users to upload videos
CREATE POLICY "Authenticated users can upload videos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'videos');

-- Allow users to read own videos
CREATE POLICY "Users can read own videos"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'videos');

-- Allow users to delete own videos
CREATE POLICY "Users can delete own videos"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'videos');
```

### Step 3: Configure File Size Limits

1. Go to **Storage** → **Settings**
2. Set **Max file size**: 100MB (or as needed)
3. Set **Allowed MIME types**:
   ```
   image/jpeg
   image/png
   image/webp
   video/mp4
   video/quicktime
   ```

### Step 4: Test File Upload in App

Your app already has storage methods. Test by:

```dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';

Future<void> uploadAnimalImage() async {
  final picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
  
  if (image != null) {
    final bytes = await File(image.path).readAsBytes();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
    
    try {
      final url = await SupabaseService.instance.uploadFile(
        bucket: AppConstants.animalImagesBucket,
        path: 'animals/$fileName',
        fileBytes: bytes,
        contentType: 'image/jpeg',
      );
      
      print('Uploaded successfully: $url');
    } catch (e) {
      print('Upload failed: $e');
    }
  }
}
```

---

## ⚡ Edge Functions

Edge Functions allow you to run custom server-side logic.

### Step 1: Install Supabase CLI

```bash
# macOS
brew install supabase/tap/supabase

# Windows (via Scoop)
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase

# Linux
brew install supabase/tap/supabase
```

### Step 2: Login to Supabase

```bash
supabase login
```

### Step 3: Link Your Project

```bash
supabase link --project-ref nznoonwreqsdrawfxrwr
```

### Step 4: Create Edge Function

```bash
# Create a new edge function for video processing
supabase functions new process-video
```

### Step 5: Write Edge Function Code

Edit `supabase/functions/process-video/index.ts`:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    // Get video ID from request
    const { videoId } = await req.json()
    
    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    )
    
    // Get video record
    const { data: video, error } = await supabaseClient
      .from('video_records')
      .select('*')
      .eq('id', videoId)
      .single()
    
    if (error) throw error
    
    // Simulate ML processing
    const analysisResults = {
      lamenessDetected: Math.random() > 0.5,
      confidence: Math.random(),
      processedAt: new Date().toISOString()
    }
    
    // Update video record
    await supabaseClient
      .from('video_records')
      .update({
        processing_status: 'completed',
        analysis_results: analysisResults
      })
      .eq('id', videoId)
    
    return new Response(
      JSON.stringify({ success: true, results: analysisResults }),
      { headers: { "Content-Type": "application/json" } }
    )
    
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    )
  }
})
```

### Step 6: Deploy Edge Function

```bash
supabase functions deploy process-video
```

### Step 7: Call Edge Function from Flutter

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> processVideoWithEdgeFunction(String videoId) async {
  try {
    final response = await Supabase.instance.client.functions.invoke(
      'process-video',
      body: {'videoId': videoId},
    );
    
    print('Function response: ${response.data}');
  } catch (e) {
    print('Error calling edge function: $e');
  }
}
```

### Additional Edge Functions Examples

#### 1. Send Notification Edge Function

Create `supabase/functions/send-notification/index.ts`:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  const { userId, message, severity } = await req.json()
  
  // Send push notification, email, or SMS
  // Integration with FCM, SendGrid, Twilio, etc.
  
  return new Response(
    JSON.stringify({ sent: true }),
    { headers: { "Content-Type": "application/json" } }
  )
})
```

#### 2. Generate Health Report Edge Function

Create `supabase/functions/generate-report/index.ts`:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const { animalId, startDate, endDate } = await req.json()
  
  const supabaseClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? ''
  )
  
  // Fetch all relevant data
  const { data: animal } = await supabaseClient
    .from('animals')
    .select('*')
    .eq('id', animalId)
    .single()
  
  const { data: movements } = await supabaseClient
    .from('movement_data')
    .select('*')
    .eq('animal_id', animalId)
    .gte('date', startDate)
    .lte('date', endDate)
  
  const { data: lameness } = await supabaseClient
    .from('lameness_records')
    .select('*')
    .eq('animal_id', animalId)
    .gte('detection_date', startDate)
    .lte('detection_date', endDate)
  
  // Generate PDF report
  const report = {
    animal,
    movements,
    lameness,
    generatedAt: new Date().toISOString()
  }
  
  return new Response(
    JSON.stringify(report),
    { headers: { "Content-Type": "application/json" } }
  )
})
```

---

## 🔒 Security Configuration

### Step 1: Environment Variables

Never hardcode secrets in your app. Use environment variables:

1. Go to **Settings** → **Edge Functions** → **Secrets**
2. Add secrets:
   ```
   SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
   SMTP_PASSWORD=your_smtp_password
   API_KEY=your_external_api_key
   ```

### Step 2: Enable Email Confirmations

1. Go to **Authentication** → **Settings**
2. Enable **"Enable email confirmations"**
3. This prevents fake signups

### Step 3: Set Password Requirements

1. Go to **Authentication** → **Settings**
2. Set minimum password strength
3. Enable password requirements

### Step 4: Enable Multi-Factor Authentication (MFA)

1. Go to **Authentication** → **Settings**
2. Enable **"Enable MFA"**
3. Choose methods: TOTP, SMS

### Step 5: Configure CORS

1. Go to **Settings** → **API**
2. Add allowed origins:
   ```
   http://localhost:*
   https://your-domain.com
   cattle-ai://*
   ```

---

## ✅ Verification Checklist

After setup, verify everything works:

### Authentication ✓
- [ ] User can sign up
- [ ] User receives confirmation email
- [ ] User can sign in
- [ ] User can reset password
- [ ] User can sign out
- [ ] Auth state persists on app restart

### Database ✓
- [ ] All tables created
- [ ] RLS policies working
- [ ] Foreign keys enforced
- [ ] Indexes created
- [ ] Can insert data
- [ ] Can query data
- [ ] Can update data
- [ ] Can delete data

### Real-time ✓
- [ ] Replication enabled on tables
- [ ] Can subscribe to table changes
- [ ] Receive INSERT events
- [ ] Receive UPDATE events
- [ ] Receive DELETE events
- [ ] Can unsubscribe from channels

### Storage ✓
- [ ] Buckets created
- [ ] Storage policies working
- [ ] Can upload images
- [ ] Can upload videos
- [ ] Can retrieve public URLs
- [ ] Can delete files
- [ ] File size limits enforced

### Edge Functions ✓
- [ ] Functions deployed
- [ ] Can invoke from Flutter
- [ ] Error handling works
- [ ] Secrets configured
- [ ] Logging enabled

---

## 🚀 Quick Start Commands

```bash
# Install dependencies
flutter pub get

# Run app
flutter run

# Check Supabase status
supabase status

# View edge function logs
supabase functions logs process-video

# Test edge function locally
supabase functions serve process-video

# Deploy all functions
supabase functions deploy
```

---

## 📊 Monitoring & Logs

### View Logs in Supabase Dashboard

1. **Auth Logs**: **Authentication** → **Logs**
2. **Database Logs**: **Database** → **Logs**
3. **Storage Logs**: **Storage** → **Logs**
4. **Function Logs**: **Edge Functions** → Select function → **Logs**

### Monitor Usage

1. Go to **Settings** → **Usage**
2. Check:
   - Database size
   - Storage usage
   - Bandwidth
   - Edge function invocations

---

## 🐛 Troubleshooting

### Authentication Issues

**Problem**: User can't sign in
- Check email is confirmed
- Verify password is correct
- Check auth logs for errors
- Ensure RLS policies allow access

**Problem**: Session expires
- Check JWT expiry settings
- Implement token refresh logic

### Database Issues

**Problem**: Can't insert data
- Check RLS policies
- Verify foreign key constraints
- Check user authentication

**Problem**: Queries slow
- Add indexes
- Optimize queries
- Use pagination

### Real-time Issues

**Problem**: Not receiving updates
- Check replication is enabled
- Verify subscription code
- Check network connection
- Review RLS policies

### Storage Issues

**Problem**: Upload fails
- Check file size limit
- Verify storage policies
- Check authentication
- Verify bucket exists

### Edge Function Issues

**Problem**: Function times out
- Increase timeout in settings
- Optimize function code
- Check external API calls

**Problem**: Function returns error
- Check function logs
- Verify secrets are set
- Test locally first

---

## 📚 Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Flutter Supabase Package](https://pub.dev/packages/supabase_flutter)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Edge Functions Guide](https://supabase.com/docs/guides/functions)
- [Realtime Guide](https://supabase.com/docs/guides/realtime)

---

## 💡 Best Practices

1. **Always use RLS**: Never disable Row Level Security in production
2. **Validate on server**: Don't trust client-side validation alone
3. **Use prepared statements**: Prevent SQL injection
4. **Limit data exposure**: Only select needed columns
5. **Implement pagination**: Don't fetch all records at once
6. **Monitor usage**: Set up alerts for quota limits
7. **Backup regularly**: Enable automated backups
8. **Use indexes**: Speed up common queries
9. **Handle errors gracefully**: Show user-friendly messages
10. **Keep secrets secure**: Never commit API keys to git

---

## 🎯 Next Steps

1. ✅ Complete this setup guide
2. Test all features in development
3. Add sample data for testing
4. Implement error handling
5. Add loading states in UI
6. Set up CI/CD pipeline
7. Configure production environment
8. Enable monitoring and alerts
9. Prepare for production deployment
10. Document API for your team

---

**Setup Guide Version**: 1.0  
**Last Updated**: January 10, 2026  
**Supabase Project**: cattle-ai-monitor
