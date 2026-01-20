# Complete Setup Guide - Cattle AI Monitor

## 📋 Prerequisites Checklist

- [ ] Flutter SDK 3.10.1 or higher installed
- [ ] Dart SDK 3.10.1 or higher installed
- [ ] Git installed
- [ ] IDE (VS Code / Android Studio) installed
- [ ] Supabase account created
- [ ] Android SDK (for Android development)
- [ ] Xcode (for iOS development on macOS)

---

## 🔧 Step-by-Step Installation

### Step 1: Clone and Setup Project

```bash
# Clone the repository
git clone <your-repo-url>
cd cattle_ai

# Install Flutter dependencies
flutter pub get

# Verify Flutter installation
flutter doctor -v
```

### Step 2: Configure Supabase Backend

#### 2.1 Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Click "New Project"
3. Enter project details:
   - Name: `cattle-ai-monitor`
   - Database Password: (save this securely)
   - Region: (choose closest to you)
4. Wait for project creation (~2 minutes)

#### 2.2 Get Supabase Credentials

1. Go to Project Settings > API
2. Copy these values:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon/public key**: `eyJhbGc...`

#### 2.3 Update App Constants

Edit `lib/core/constants/app_constants.dart`:

```dart
class AppConstants {
  // Replace with your actual credentials
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key-here';
  
  // ... rest of the file
}
```

### Step 3: Setup Database

#### 3.1 Run SQL Schema

1. Open Supabase Dashboard
2. Go to SQL Editor
3. Click "New Query"
4. Copy entire contents of `supabase_schema.sql`
5. Paste and click "Run"
6. Verify tables created: Go to Table Editor

Expected tables:
- ✅ animals
- ✅ movement_data
- ✅ lameness_records
- ✅ video_records
- ✅ user_profiles

#### 3.2 Verify Row Level Security (RLS)

1. Go to Authentication > Policies
2. Verify policies are enabled for all tables
3. Test with: `SELECT * FROM animals;` (should return empty)

### Step 4: Setup Storage Buckets

#### 4.1 Create Buckets

1. Go to Storage in Supabase Dashboard
2. Click "New bucket"
3. Create these buckets:

**Bucket 1: animal-images**
- Name: `animal-images`
- Public: ✅ Yes
- File size limit: 5 MB

**Bucket 2: videos**
- Name: `videos`
- Public: ❌ No
- File size limit: 100 MB

**Bucket 3: ml-models**
- Name: `ml-models`
- Public: ❌ No
- File size limit: 10 MB

#### 4.2 Configure Storage Policies

For **animal-images** bucket:

```sql
-- Allow authenticated users to upload
INSERT INTO storage.objects
  SELECT 'animal-images', 
         auth.uid() || '/' || (RANDOM() * 1000000)::text || '.jpg',
         authenticated users;

-- Allow public read
SELECT FROM storage.objects
  WHERE bucket_id = 'animal-images';
```

Apply policies in Storage > Policies.

### Step 5: Enable Realtime

1. Go to Database > Replication
2. Enable realtime for tables:
   - ✅ animals
   - ✅ movement_data
   - ✅ lameness_records
   - ✅ video_records

### Step 6: Configure Authentication

1. Go to Authentication > Settings
2. Enable Email provider
3. Disable "Confirm email" (for testing)
4. Set Site URL: `http://localhost` (or your domain)

### Step 7: Install ML Model (Optional)

If you have a trained TensorFlow Lite model:

```bash
# Create ML assets directory
mkdir -p assets/ml

# Place your model
cp /path/to/your/lameness_model.tflite assets/ml/

# Update pubspec.yaml to include assets
```

In `pubspec.yaml`, ensure:

```yaml
flutter:
  assets:
    - assets/ml/lameness_model.tflite
```

If you don't have a model yet, the app will use simulated ML predictions.

---

## ▶️ Running the Application

### Run on Android

```bash
# List available devices
flutter devices

# Run on connected Android device
flutter run -d <device-id>

# Or simply
flutter run
```

### Run on iOS (macOS only)

```bash
# Open iOS simulator
open -a Simulator

# Run on simulator
flutter run -d ios
```

### Run on Web

```bash
flutter run -d chrome
```

### Run on Desktop

```bash
# Windows
flutter run -d windows

# Linux
flutter run -d linux

# macOS
flutter run -d macos
```

---

## 🧪 Testing the Application

### 1. Create Test Account

1. Launch the app
2. Click "Sign Up"
3. Enter:
   - Name: Test User
   - Email: test@example.com
   - Password: Test@123
4. Click "Create Account"

### 2. Add Test Animal

1. Go to Animals tab
2. Click "+" button
3. Enter:
   - Animal ID: COW001
   - Species: Cow
   - Age: 24 months
   - Health Status: Healthy
4. Save

### 3. Test Movement Simulation

1. Select the animal
2. Enable IoT simulation
3. Wait for data to generate
4. View movement graphs

### 4. Test Lameness Detection

1. Generate movement data (via simulation)
2. Go to Lameness tab
3. Click "Analyze"
4. View detection results

---

## 🔍 Troubleshooting

### Issue: "Supabase initialization failed"

**Solution**:
- Verify `supabaseUrl` and `supabaseAnonKey` are correct
- Check internet connection
- Ensure Supabase project is active

### Issue: "No data showing"

**Solution**:
- Check if user is logged in
- Verify RLS policies are correct
- Check Supabase logs: Dashboard > Logs

### Issue: "Video upload fails"

**Solution**:
- Verify `videos` bucket exists
- Check storage policies
- Ensure file size is under limit

### Issue: "ML model not loading"

**Solution**:
- Check if `assets/ml/lameness_model.tflite` exists
- Verify `pubspec.yaml` includes assets
- Run `flutter clean` then `flutter pub get`

### Issue: "Platform-specific build errors"

**Android**:
```bash
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter run
```

**iOS**:
```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter run
```

**Web**:
```bash
flutter clean
flutter pub get
flutter run -d chrome --release
```

---

## 🚀 Deployment

### Android (Play Store)

```bash
# Build release APK
flutter build apk --release

# Or build App Bundle (recommended)
flutter build appbundle --release

# Output location
# build/app/outputs/bundle/release/app-release.aab
```

### iOS (App Store)

```bash
# Build for iOS
flutter build ios --release

# Then use Xcode to archive and upload
```

### Web Hosting

```bash
# Build for web
flutter build web --release

# Deploy to hosting (e.g., Firebase, Netlify, Vercel)
# Output: build/web/
```

---

## 📊 Database Maintenance

### Backup Database

1. Go to Supabase Dashboard
2. Settings > Database
3. Click "Backup Now"

### View Logs

```sql
-- View recent animals
SELECT * FROM animals ORDER BY created_at DESC LIMIT 10;

-- View movement data stats
SELECT animal_id, COUNT(*), AVG(movement_score)
FROM movement_data
GROUP BY animal_id;

-- View lameness detections
SELECT severity, COUNT(*)
FROM lameness_records
GROUP BY severity;
```

---

## 🔐 Security Best Practices

1. **Never commit credentials**:
   - Add `lib/core/constants/app_constants.dart` to `.gitignore`
   - Use environment variables for production

2. **Use Row Level Security**:
   - All policies enabled
   - Users can only access their own data

3. **Regular backups**:
   - Daily automated backups in Supabase
   - Export critical data weekly

4. **Monitor usage**:
   - Check Supabase usage dashboard
   - Set up alerts for unusual activity

---

## 📈 Performance Optimization

### 1. Lazy Loading

Implement pagination for large datasets:

```dart
// Load animals with limit
final animals = await supabaseService.getAnimals(limit: 20);
```

### 2. Caching

Use shared_preferences for offline data:

```dart
// Cache recent data
await prefs.setString('cached_animals', jsonEncode(animals));
```

### 3. Image Optimization

Compress images before upload:

```dart
// Resize and compress
final compressedImage = await FlutterImageCompress.compressWithFile(
  imagePath,
  quality: 70,
  minWidth: 800,
  minHeight: 800,
);
```

---

## 🆘 Support Resources

- **Documentation**: See PROJECT_DOCUMENTATION.md
- **ML Guide**: See ML_DOCUMENTATION.md
- **Supabase Docs**: https://supabase.com/docs
- **Flutter Docs**: https://docs.flutter.dev

---

## ✅ Post-Installation Checklist

- [ ] App launches successfully
- [ ] Can create account and login
- [ ] Can add new animal
- [ ] Dashboard shows statistics
- [ ] Movement simulation works
- [ ] Lameness detection runs
- [ ] Charts display data
- [ ] Camera access works
- [ ] Images upload to storage
- [ ] Real-time updates work

---

## 🎓 Next Steps

1. **Customize branding**: Update app name, icon, colors
2. **Add sample data**: Create demo animals and data
3. **Train ML model**: Follow ML_DOCUMENTATION.md
4. **Setup IoT hardware**: Plan sensor integration
5. **Deploy to production**: Follow deployment steps

---

**Setup complete! 🎉**

If you encounter any issues, please check the troubleshooting section or create an issue on GitHub.

**Last Updated**: January 9, 2026
