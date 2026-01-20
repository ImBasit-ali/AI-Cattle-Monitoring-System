# Authentication Debugging Guide

## Current Issue
Signup and login show success messages but don't navigate to dashboard.

## Debug Steps Added

### 1. Check Console Output
After running the app, watch for these debug messages:

**During Signup:**
```
🔄 Starting signup process...
✅ Signup successful! User: [email], Authenticated: true
📊 Signup result: success=true, isAuthenticated=true
🔍 AuthWrapper: isLoading=false, isAuthenticated=true, user=[email]
```

**During Login:**
```
🔄 Starting login process...
✅ Login successful! User: [email], Name: [name], Authenticated: true
📊 Login result: success=true, isAuthenticated=true
🔍 AuthWrapper: isLoading=false, isAuthenticated=true, user=[email]
```

### 2. Common Issues & Solutions

#### Issue 1: Email Confirmation Required
**Symptom:** Console shows:
```
Please check your email to confirm your account before signing in.
```

**Solution:** Disable email confirmation in Supabase:
1. Go to Supabase Dashboard
2. Authentication → Settings
3. Find "Enable email confirmations"
4. Turn it OFF
5. Save changes

#### Issue 2: Profile Not Created
**Symptom:** Login works but name doesn't show

**Solution:** Run migration in Supabase SQL Editor:
```sql
-- Check if trigger exists
SELECT * FROM pg_trigger WHERE tgname = 'on_auth_user_created';

-- If not, run the migration file:
-- /supabase/migrations/09_user_profiles.sql
```

#### Issue 3: Session Not Persisting
**Symptom:** Success message shows but immediately returns to login

**Solution:** Check Supabase initialization:
- Ensure `AppConstants.supabaseUrl` is correct
- Ensure `AppConstants.supabaseAnonKey` is correct
- Check network connectivity

### 3. Manual Testing Steps

1. **Clear App Data:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Test Signup:**
   - Fill form with: name, email, password
   - Click "Sign Up"
   - Watch console for debug messages
   - Should navigate to dashboard immediately

3. **Test Login:**
   - Enter same email/password
   - Click "Sign In"
   - Watch console for debug messages
   - Should navigate to dashboard with name displayed

### 4. Expected Behavior

**After Successful Signup:**
```
1. Form submitted
2. Email validation check (no duplicates)
3. Supabase creates auth.users record
4. Database trigger creates user_profiles record
5. AuthProvider sets _currentUser
6. isAuthenticated = true
7. notifyListeners() called
8. AuthWrapper detects isAuthenticated
9. Navigates to HomeScreen (Dashboard)
10. Success message shown in dashboard
```

**After Successful Login:**
```
1. Form submitted
2. Credentials validated
3. Session created
4. Profile data loaded
5. last_login_at updated
6. AuthProvider sets _currentUser with name
7. isAuthenticated = true
8. notifyListeners() called
9. AuthWrapper detects isAuthenticated
10. Navigates to HomeScreen (Dashboard)
11. Success message shown
12. Name displayed: "Welcome, [Name]"
```

### 5. Verification Checklist

- [ ] Supabase email confirmation is DISABLED
- [ ] Migration 09_user_profiles.sql is applied
- [ ] Trigger `on_auth_user_created` exists
- [ ] Table `user_profiles` exists
- [ ] Console shows "✅ Signup successful!"
- [ ] Console shows "isAuthenticated=true"
- [ ] AuthWrapper navigates to HomeScreen
- [ ] Dashboard shows user name

### 6. If Still Not Working

Check these files have the latest code:

1. **lib/providers/auth_provider.dart**
   - Line ~229: Should have debug print after signup success
   - Line ~293: Should have debug print after login success

2. **lib/main.dart**
   - Line ~55: Should have debug print in AuthWrapper

3. **lib/screens/auth/signup_screen.dart**
   - Should have debug prints in _handleSignup

4. **lib/screens/auth/login_screen.dart**
   - Should have debug prints in _handleLogin

### 7. Quick Fix Command

If all else fails, try this:
```bash
cd /home/basitali/StudioProjects/cattle_ai
flutter clean
flutter pub get
flutter run --verbose
```

Then watch the console output carefully during signup/login.
