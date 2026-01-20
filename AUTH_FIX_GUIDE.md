# Authentication Fix Guide

## What Was Fixed

### 1. **Enhanced Error Handling**
- Added detailed logging at each authentication step
- Better error messages for users
- Proper session validation before proceeding

### 2. **Improved User Profile Creation**
- Extended wait time for database trigger (500ms → 1000ms)
- Force profile creation using `upsert` with `onConflict`
- Added additional delay (300ms) to ensure database write completion
- Better fallback handling if profile creation fails

### 3. **Better Session Management**
- Validate session exists before setting user as authenticated
- Check both user AND session in response
- Clear error messages when session creation fails

### 4. **Comprehensive Debug Logging**
- Step-by-step logging throughout signup/login process
- User ID, email, and session status tracking
- Profile data verification logs

## Common Issues & Solutions

### Issue 1: "Invalid Supabase credentials"

**Symptom:** App crashes or shows connection errors

**Solution:**
1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project
3. Go to Settings → API
4. Copy the correct values:
   - Project URL
   - `anon` public key (NOT service_role key)
5. Update `lib/core/constants/app_constants.dart`:

```dart
static const String supabaseUrl = 'YOUR_PROJECT_URL';
static const String supabaseAnonKey = 'YOUR_ANON_KEY';
```

### Issue 2: "Email confirmation required"

**Symptom:** User sees "Please check your email to confirm..."

**Solution:** Disable email confirmation in Supabase:
1. Supabase Dashboard → Authentication → Settings
2. Find "Enable email confirmations"
3. Turn it **OFF**
4. Save changes

### Issue 3: "User profile not created"

**Symptom:** Login works but name doesn't show, or errors occur

**Solution:** Ensure database trigger is set up:

Run this in Supabase SQL Editor:

```sql
-- Create function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, name, created_at)
    VALUES (
        NEW.id, 
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', ''),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE 
    SET 
        email = EXCLUDED.email,
        name = COALESCE(EXCLUDED.name, user_profiles.name),
        updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();
```

### Issue 4: Row Level Security (RLS) blocking access

**Solution:** Enable RLS policies for user_profiles table:

```sql
-- Enable RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Policy for users to read their own profile
CREATE POLICY "Users can read own profile"
ON user_profiles FOR SELECT
USING (auth.uid() = id);

-- Policy for users to update their own profile
CREATE POLICY "Users can update own profile"
ON user_profiles FOR UPDATE
USING (auth.uid() = id);

-- Policy for users to insert their own profile
CREATE POLICY "Users can insert own profile"
ON user_profiles FOR INSERT
WITH CHECK (auth.uid() = id);
```

## Testing Steps

### 1. Test New User Signup

1. Run the app
2. Click "Create Account"
3. Fill in:
   - Name: Test User
   - Email: test@example.com
   - Password: Test1234!
4. Click "Sign Up"

**Expected Console Output:**
```
🔄 Checking if email exists: test@example.com
🔄 Attempting signup for: test@example.com
🔄 SupabaseService: Attempting signup for test@example.com
✅ SupabaseService: Signup response received - User ID: [uuid]
📊 Signup response - User: [uuid], Session: true
✅ User created with session, creating profile...
🔄 Creating/updating user profile with name: Test User
📊 Profile loaded: Test User
✅ Signup successful! User: test@example.com, Name: Test User, Authenticated: true
```

**Expected UI:**
- Success message: "Account created successfully! Welcome Test User!"
- Navigate to Dashboard immediately

### 2. Test Existing User Login

1. Use previously created account
2. Click "Sign In"
3. Enter email and password
4. Click "Sign In"

**Expected Console Output:**
```
🔄 Starting login process...
🔄 Attempting login for: test@example.com
🔄 SupabaseService: Attempting signin for test@example.com
✅ SupabaseService: Signin response received - User ID: [uuid]
📊 Login response - User: [uuid], Session: true
🔄 Loading user profile for: [uuid]
📊 Profile data: Test User
✅ Login successful! User: test@example.com, Name: Test User, Authenticated: true
```

**Expected UI:**
- Success message: "Login successful! Welcome back Test User!"
- Navigate to Dashboard immediately

## Troubleshooting

### Check Console Logs

Look for these patterns:

**Good:**
```
✅ Signup/Login successful
📊 Profile loaded: [name]
🔍 AuthWrapper: isAuthenticated=true
```

**Bad:**
```
❌ Login error: [error message]
⚠️ Error loading profile
📊 Profile data: null
```

### Verify Database

1. Open Supabase Dashboard
2. Go to Table Editor
3. Check `user_profiles` table:
   - Should have row with your user ID
   - `name` column should have value
   - `email` column should match

### Check Network Tab (Chrome DevTools)

1. Open DevTools (F12)
2. Go to Network tab
3. Filter by "supabase"
4. Look for:
   - POST to `/auth/v1/signup` → Should return 200
   - POST to `/auth/v1/token?grant_type=password` → Should return 200
   - GET to `/rest/v1/user_profiles` → Should return 200

## Next Steps

If authentication still fails after these fixes:

1. **Check Supabase credentials** in `app_constants.dart`
2. **Verify email confirmation is disabled** in Supabase dashboard
3. **Run the complete SQL schema** in Supabase SQL Editor
4. **Check RLS policies** are properly configured
5. **Review console logs** for specific error messages
6. **Test with a new email** (previous failed attempts may cause issues)

## Updated Files

The following files were modified to fix authentication:

1. `/lib/providers/auth_provider.dart` - Improved error handling and session management
2. `/lib/services/supabase_service.dart` - Added detailed logging
3. This guide created at: `/AUTH_FIX_GUIDE.md`
