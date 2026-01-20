# 🚀 5-MINUTE SUPABASE DEPLOYMENT

Deploy your Cattle AI Monitor to Supabase in 5 minutes!

**Your Project:** https://nznoonwreqsdrawfxrwr.supabase.co

---

## ⚡ Quick Start (Choose One Method)

### Method 1: Guided Script (Recommended)

```bash
./deploy.sh
```

The script will guide you through each step!

### Method 2: Manual Steps

Follow the [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for detailed instructions.

---

## 📋 What Gets Deployed

✅ **Authentication** - Email/password login  
✅ **Database** - 4 tables with indexes  
✅ **Row Level Security** - User data isolation  
✅ **Storage** - 3 buckets for images/videos  
✅ **Real-time** - Live data synchronization  

---

## 🎯 After Deployment

1. **Test the app:**
   ```bash
   flutter run
   ```

2. **Sign up** with test email

3. **Add an animal** to test database

4. **Check Supabase Dashboard** to see your data

---

## 📁 Files You Need

All SQL scripts are in `supabase/migrations/`:
- `01_create_tables.sql` - Database schema
- `02_enable_rls.sql` - Security policies  
- `03_storage_policies.sql` - Storage permissions

---

## 🐛 Issues?

See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) → Troubleshooting section

---

## 📚 Full Documentation

- **Quick Deploy:** This file  
- **Step-by-Step:** [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)  
- **Complete Setup:** [SUPABASE_SETUP_GUIDE.md](SUPABASE_SETUP_GUIDE.md)  
- **Project Docs:** [PROJECT_DOCUMENTATION.md](PROJECT_DOCUMENTATION.md)

---

**Ready?** Run `./deploy.sh` and let's go! 🚀
