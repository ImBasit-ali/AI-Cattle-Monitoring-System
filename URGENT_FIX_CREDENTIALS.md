🚨 CRITICAL: INVALID SUPABASE CREDENTIALS DETECTED! 🚨
============================================================

Your Supabase credentials in app_constants.dart are INVALID!

Current values:
❌ supabaseUrl: https://nznoonwreqsdrawfxrwr.supabase.co
❌ supabaseAnonKey: sb_publishable_hac1WXtWlst8ZES8Jor5MQ_fj3dl0JS  (INVALID - TOO SHORT!)

The anon key should be 200+ characters long, starting with "eyJ"

## URGENT: Fix This Now!

### Step 1: Get Your Real Credentials

1. Go to https://app.supabase.com
2. Log in to your account
3. Select your project (or create a new one if needed)
4. Click on "Settings" icon (⚙️) in the left sidebar
5. Click on "API" in the Settings menu

### Step 2: Copy the Correct Values

You'll see two sections:

**Project URL:**
```
https://[your-project-ref].supabase.co
```

**API Keys:**
- `anon` `public` - This is the one you need! (200+ characters, starts with "eyJ")
- `service_role` `secret` - DO NOT use this in your app!

### Step 3: Update app_constants.dart

Replace the values in `/lib/core/constants/app_constants.dart`:

```dart
// Supabase Configuration
static const String supabaseUrl = 'https://YOUR_PROJECT_REF.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'; // Full key here
```

**IMPORTANT:** 
- Use the `anon` / `public` key (NOT the service_role key!)
- The key should be very long (~200+ characters)
- It should start with "eyJ"

### Step 4: Restart Your App

After updating the credentials:
```bash
flutter clean
flutter pub get
flutter run
```

## Why Authentication Fails

Your current anon key "sb_publishable_hac1WXtWlst8ZES8Jor5MQ_fj3dl0JS" is:
1. Too short (actual keys are 200+ characters)
2. Wrong format (should start with "eyJ")
3. Invalid - Supabase rejects all requests

This is why:
- ❌ Signup fails
- ❌ Login fails  
- ❌ Database queries fail
- ❌ Storage operations fail

## Example of a VALID anon key:

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im56bm9vbndyZXFzZHJhd2Z4cndyIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NzAwMDAwMDAsImV4cCI6MTk4NTU3NjAwMH0.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

Notice:
- Starts with "eyJ"
- Has multiple parts separated by "."
- Is very long (~200+ characters)

## Still Having Issues?

If you don't have a Supabase project:

1. Go to https://app.supabase.com
2. Click "New Project"
3. Fill in:
   - Name: Cattle AI Monitor
   - Database Password: (Choose a strong password - SAVE IT!)
   - Region: Choose closest to you
4. Wait 2-3 minutes for project to be created
5. Once ready, follow Steps 1-4 above

## Need Help?

Check these resources:
- Supabase Docs: https://supabase.com/docs/guides/getting-started
- Your Project Dashboard: https://app.supabase.com/project/_/settings/api

============================================================
AUTHENTICATION WILL NOT WORK UNTIL YOU FIX THIS!
============================================================
