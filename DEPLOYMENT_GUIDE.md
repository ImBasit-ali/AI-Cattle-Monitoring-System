# 🚀 Automated Deployment Guide - Cattle AI Monitor

This guide will help you deploy all Supabase features to your project in **5 minutes**.

**Your Supabase Project:**
- URL: `https://nznoonwreqsdrawfxrwr.supabase.co`
- Project Ref: `nznoonwreqsdrawfxrwr`

---

## ✅ Step 1: Enable Authentication (30 seconds)

1. Go to [Supabase Dashboard](https://supabase.com/dashboard/project/nznoonwreqsdrawfxrwr)
2. Click **Authentication** → **Providers**
3. Ensure **Email** is toggled ON
4. Click **Save**

**Optional - Disable Email Confirmation for Testing:**
- Go to **Authentication** → **Settings**
- Scroll to **Email Auth**
- Toggle OFF **"Enable email confirmations"** (for development only)
- Click **Save**

---

## ✅ Step 2: Deploy Database Schema (2 minutes)

### 2.1 Create Tables

1. Go to **SQL Editor** in Supabase Dashboard
2. Click **"+ New query"**
3. Copy and paste content from `supabase/migrations/01_create_tables.sql`
4. Click **RUN** (▶️)
5. Wait for "Success. No rows returned" message

### 2.2 Enable Row Level Security

1. Click **"+ New query"** again
2. Copy and paste content from `supabase/migrations/02_enable_rls.sql`
3. Click **RUN** (▶️)
4. Verify all policies created successfully

### 2.3 Verify Tables

1. Go to **Table Editor**
2. You should see these tables:
   - ✅ animals
   - ✅ movement_data
   - ✅ lameness_records
   - ✅ video_records

---

## ✅ Step 3: Create Storage Buckets (1 minute)

### 3.1 Create Buckets

1. Go to **Storage** in Supabase Dashboard
2. Click **"New bucket"**

**Create Bucket #1:**
- Name: `animal-images`
- Public: ✅ Yes
- Click **Create bucket**

**Create Bucket #2:**
- Name: `videos`
- Public: ❌ No
- Click **Create bucket**

**Create Bucket #3 (Optional):**
- Name: `ml-models`
- Public: ✅ Yes
- Click **Create bucket**

### 3.2 Apply Storage Policies

1. Go to **SQL Editor**
2. Click **"+ New query"**
3. Copy and paste content from `supabase/migrations/03_storage_policies.sql`
4. Click **RUN** (▶️)

---

## ✅ Step 4: Enable Realtime (30 seconds)

1. Go to **Database** → **Replication**
2. Enable replication for each table:

| Table | Enable Replication |
|-------|-------------------|
| animals | ✅ |
| movement_data | ✅ |
| lameness_records | ✅ |
| video_records | ✅ |

3. Click **Save** after enabling each one

---

## ✅ Step 5: Test Your App (1 minute)

### 5.1 Run the App

```bash
cd /home/basitali/StudioProjects/cattle_ai
flutter pub get
flutter run
```

### 5.2 Test Authentication

1. Click **"Sign Up"**
2. Enter email: `test@example.com`
3. Enter password: `password123`
4. Click **Sign Up**
5. If email confirmation is disabled, you'll be logged in immediately

### 5.3 Test Database

1. After login, navigate to Animals screen
2. Click **"+"** to add a new animal
3. Fill in details:
   - Animal ID: `COW001`
   - Species: Cow
   - Age: 3
   - Health Status: Healthy
4. Click **Save**
5. Go to Supabase Dashboard → **Table Editor** → **animals**
6. You should see your new animal entry! ✅

### 5.4 Test Storage (Optional)

1. When adding animal, click **"Upload Image"**
2. Select an image from your device
3. Image should upload to Supabase Storage
4. Check **Storage** → **animal-images** in dashboard

---

## 🎯 Verification Checklist

Run through this checklist to ensure everything works:

### Authentication ✓
- [ ] Can create new account
- [ ] Can sign in
- [ ] Can sign out
- [ ] Session persists on app reload

### Database ✓
- [ ] Can add new animal
- [ ] Animal appears in Supabase Table Editor
- [ ] Can view animals list in app
- [ ] Can update animal
- [ ] Can delete animal

### Storage ✓
- [ ] Buckets created: `animal-images`, `videos`, `ml-models`
- [ ] Can upload images
- [ ] Images appear in Storage dashboard

### Real-time ✓
- [ ] Replication enabled on all tables
- [ ] Open app on two devices/browsers
- [ ] Add animal on device 1
- [ ] Animal appears on device 2 automatically

---

## 🐛 Troubleshooting

### Issue: "Auth session missing!" error

**Solution:**
```bash
# Clear app data and restart
flutter clean
flutter pub get
flutter run
```

### Issue: Can't insert animal - "new row violates row-level security policy"

**Solution:** Make sure you're signed in. Check:
```dart
// In your code, verify user is authenticated
final user = Supabase.instance.client.auth.currentUser;
print('Current user: ${user?.email}');
```

### Issue: Storage upload fails - "The resource already exists"

**Solution:** Change filename to be unique:
```dart
final fileName = '${DateTime.now().millisecondsSinceEpoch}_${uuid.v4()}.jpg';
```

### Issue: SQL scripts fail to run

**Solution:** Run scripts **one at a time** in this order:
1. First: `01_create_tables.sql`
2. Second: `02_enable_rls.sql`
3. Third: `03_storage_policies.sql`

### Issue: Real-time not working

**Solution:**
1. Verify replication is enabled (Database → Replication)
2. Check your auth state listener is working
3. Restart the app

---

## 📊 Monitor Your Deployment

### Check Database

```bash
# Open Supabase SQL Editor and run:
SELECT COUNT(*) FROM animals;
SELECT COUNT(*) FROM movement_data;
SELECT COUNT(*) FROM lameness_records;
SELECT COUNT(*) FROM video_records;
```

### Check Storage Usage

Go to **Settings** → **Usage** to see:
- Database size
- Storage used
- API requests
- Bandwidth

---

## 🎉 Success! What's Next?

Your Supabase backend is fully deployed and configured! 

### Next Steps:

1. **Add Sample Data:**
   - Create a few test animals
   - Add movement data
   - Upload test videos

2. **Test All Features:**
   - Movement tracking
   - Lameness detection
   - Video recording/upload
   - Real-time updates

3. **Customize:**
   - Update email templates (Authentication → Email Templates)
   - Configure your domain
   - Add custom auth redirects

4. **Production Prep:**
   - Enable email confirmations
   - Set up custom SMTP (Authentication → Settings)
   - Configure backup schedule (Database → Backups)
   - Review RLS policies

---

## 📚 Quick Reference

### Important URLs

- **Dashboard:** https://supabase.com/dashboard/project/nznoonwreqsdrawfxrwr
- **SQL Editor:** https://supabase.com/dashboard/project/nznoonwreqsdrawfxrwr/sql
- **Table Editor:** https://supabase.com/dashboard/project/nznoonwreqsdrawfxrwr/editor
- **Storage:** https://supabase.com/dashboard/project/nznoonwreqsdrawfxrwr/storage/buckets
- **Auth:** https://supabase.com/dashboard/project/nznoonwreqsdrawfxrwr/auth/users

### Flutter Commands

```bash
# Get dependencies
flutter pub get

# Run app
flutter run

# Clean build
flutter clean

# Build for Android
flutter build apk --release

# Check for errors
flutter analyze
```

### Supabase Test Commands (SQL Editor)

```sql
-- View all users
SELECT * FROM auth.users;

-- View all animals
SELECT * FROM animals;

-- View policies
SELECT * FROM pg_policies WHERE tablename = 'animals';

-- Check storage buckets
SELECT * FROM storage.buckets;

-- View recent auth activity
SELECT * FROM auth.audit_log_entries ORDER BY created_at DESC LIMIT 10;
```

---

## 💡 Pro Tips

1. **Use Supabase Dashboard for debugging** - Real-time logs are very helpful
2. **Test RLS policies** - Try accessing data from different user accounts
3. **Monitor API usage** - Set up alerts to avoid surprise bills
4. **Backup before production** - Enable automated backups
5. **Use staging environment** - Create a separate Supabase project for testing

---

## 🔗 Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Flutter Supabase Package](https://pub.dev/packages/supabase_flutter)
- [Full Setup Guide](SUPABASE_SETUP_GUIDE.md)
- [Project Documentation](PROJECT_DOCUMENTATION.md)

---

**Deployment completed successfully!** 🎊

Your Cattle AI Monitor app is now connected to Supabase with:
- ✅ Authentication enabled
- ✅ Database tables created
- ✅ Row Level Security configured
- ✅ Storage buckets ready
- ✅ Real-time enabled

**Estimated Setup Time:** 5 minutes
**Status:** Ready for development & testing
