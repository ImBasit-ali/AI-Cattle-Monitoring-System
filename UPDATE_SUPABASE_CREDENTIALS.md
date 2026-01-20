# Update Supabase Credentials

## Problem
Your app is trying to connect to an invalid Supabase URL: `https://nznoonwreqsdrawfxrwr.supabase.co`

This is causing the error: "Failed host lookup: No address associated with hostname"

## Solution

### Step 1: Get Your Real Supabase Credentials

1. Go to [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. **Sign in** or **create a new account** if you don't have one
3. **Create a new project** or select your existing project
4. Go to **Settings** → **API** (in the left sidebar)
5. Copy these two values:
   - **Project URL** (e.g., `https://abcdefghijk.supabase.co`)
   - **anon public** key (a long JWT token)

### Step 2: Update Flutter App Credentials

Edit the file: `lib/core/constants/app_constants.dart`

Replace lines 8-9 with your actual credentials:

```dart
static const String supabaseUrl = 'YOUR_PROJECT_URL_HERE';
static const String supabaseAnonKey = 'YOUR_ANON_KEY_HERE';
```

### Step 3: Update Python Backend Credentials (if using)

Edit the file: `python_backend/.env`

Update lines 2-4:

```env
SUPABASE_URL='YOUR_PROJECT_URL_HERE'
SUPABASE_KEY='YOUR_ANON_KEY_HERE'
SUPABASE_SERVICE_KEY='YOUR_SERVICE_ROLE_KEY_HERE'
```

Note: The service role key is found in the same Settings → API page as the "service_role" key.

### Step 4: Rebuild Your App

After updating the credentials:

```bash
flutter clean
flutter pub get
flutter build apk --split-per-abi
```

### Step 5: Set Up Your Database

Once connected, you'll need to set up your database tables. Run the SQL files in this order:

1. `COMPLETE_SUPABASE_SCHEMA.sql` - Creates all tables
2. `STORAGE_BUCKET_POLICIES.sql` - Sets up storage buckets

You can run these in the Supabase Dashboard → SQL Editor

## Quick Test

After updating, you can test the connection by running:

```bash
flutter run
```

Then try to sign up a new user. The error should be gone!

## Need Help?

If you don't have a Supabase account yet:
1. It's free to start
2. Go to https://supabase.com
3. Click "Start your project"
4. Follow the setup wizard
5. Come back here and follow the steps above
