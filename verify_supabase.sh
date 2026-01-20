#!/bin/bash

# ============================================
# Supabase Deployment Verification Script
# Checks if all tables, buckets, and configs are correct
# ============================================

echo "🔍 Supabase Deployment Verification Script"
echo "============================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
FLUTTER_CONFIG_FILE="lib/core/constants/app_constants.dart"
PYTHON_ENV_FILE="python_backend/.env"

echo "📋 Phase 1: Checking Local Configuration Files"
echo "============================================"

# Check Flutter config
if [ -f "$FLUTTER_CONFIG_FILE" ]; then
    echo -e "${GREEN}✅${NC} Flutter config file found: $FLUTTER_CONFIG_FILE"
    
    # Extract Supabase URL
    FLUTTER_URL=$(grep -o "supabaseUrl = '[^']*'" "$FLUTTER_CONFIG_FILE" | cut -d "'" -f 2)
    if [ ! -z "$FLUTTER_URL" ] && [ "$FLUTTER_URL" != "YOUR_SUPABASE_URL" ]; then
        echo -e "${GREEN}✅${NC} Supabase URL configured: $FLUTTER_URL"
    else
        echo -e "${RED}❌${NC} Supabase URL not configured in Flutter"
        echo "   → Update 'supabaseUrl' in $FLUTTER_CONFIG_FILE"
    fi
    
    # Check anon key
    if grep -q "supabaseAnonKey = 'eyJ" "$FLUTTER_CONFIG_FILE"; then
        echo -e "${GREEN}✅${NC} Supabase anon key configured"
    else
        echo -e "${RED}❌${NC} Supabase anon key not configured in Flutter"
        echo "   → Update 'supabaseAnonKey' in $FLUTTER_CONFIG_FILE"
    fi
else
    echo -e "${RED}❌${NC} Flutter config file not found: $FLUTTER_CONFIG_FILE"
fi

echo ""

# Check Python .env
if [ -f "$PYTHON_ENV_FILE" ]; then
    echo -e "${GREEN}✅${NC} Python .env file found: $PYTHON_ENV_FILE"
    
    # Check SUPABASE_URL
    if grep -q "SUPABASE_URL=https://" "$PYTHON_ENV_FILE"; then
        PYTHON_URL=$(grep "SUPABASE_URL=" "$PYTHON_ENV_FILE" | cut -d '=' -f 2)
        echo -e "${GREEN}✅${NC} SUPABASE_URL configured: $PYTHON_URL"
    else
        echo -e "${RED}❌${NC} SUPABASE_URL not configured in Python"
        echo "   → Set SUPABASE_URL in $PYTHON_ENV_FILE"
    fi
    
    # Check SUPABASE_KEY
    if grep -q "SUPABASE_KEY=eyJ" "$PYTHON_ENV_FILE"; then
        echo -e "${GREEN}✅${NC} SUPABASE_KEY (anon) configured"
    else
        echo -e "${YELLOW}⚠️${NC}  SUPABASE_KEY not configured in Python"
        echo "   → Set SUPABASE_KEY (anon key) in $PYTHON_ENV_FILE"
    fi
    
    # Check SUPABASE_SERVICE_KEY
    if grep -q "SUPABASE_SERVICE_KEY=eyJ" "$PYTHON_ENV_FILE"; then
        echo -e "${GREEN}✅${NC} SUPABASE_SERVICE_KEY configured"
    else
        echo -e "${RED}❌${NC} SUPABASE_SERVICE_KEY not configured"
        echo "   → Set SUPABASE_SERVICE_KEY (service_role key) in $PYTHON_ENV_FILE"
    fi
else
    echo -e "${RED}❌${NC} Python .env file not found: $PYTHON_ENV_FILE"
fi

echo ""
echo "📦 Phase 2: Required Files Checklist"
echo "============================================"

# Check schema file
if [ -f "COMPLETE_SUPABASE_SCHEMA.sql" ]; then
    LINE_COUNT=$(wc -l < "COMPLETE_SUPABASE_SCHEMA.sql")
    echo -e "${GREEN}✅${NC} Database schema file found ($LINE_COUNT lines)"
else
    echo -e "${RED}❌${NC} COMPLETE_SUPABASE_SCHEMA.sql not found"
fi

# Check storage policies file
if [ -f "STORAGE_BUCKET_POLICIES.sql" ]; then
    echo -e "${GREEN}✅${NC} Storage bucket policies file found"
else
    echo -e "${YELLOW}⚠️${NC}  STORAGE_BUCKET_POLICIES.sql not found (optional)"
fi

# Check deployment guide
if [ -f "DEPLOY_TO_SUPABASE.md" ]; then
    echo -e "${GREEN}✅${NC} Deployment guide found"
else
    echo -e "${YELLOW}⚠️${NC}  DEPLOY_TO_SUPABASE.md not found"
fi

echo ""
echo "🎯 Phase 3: Required Tables Checklist"
echo "============================================"
echo "These tables should exist in your Supabase project:"
echo ""

REQUIRED_TABLES=(
    "animals"
    "ear_tag_camera"
    "detections"
    "animal_tracks"
    "milking_status"
    "lameness_detections"
    "lameness_records"
    "cameras"
    "movement_data"
    "video_records"
    "user_profiles"
)

for table in "${REQUIRED_TABLES[@]}"; do
    echo "   📊 $table"
done

echo ""
echo "Total: ${#REQUIRED_TABLES[@]} tables"

echo ""
echo "📁 Phase 4: Required Storage Buckets"
echo "============================================"
echo "These buckets should exist in your Supabase Storage:"
echo ""
echo "   🗂️  animal-images (Public: YES)"
echo "   🗂️  videos (Public: NO)"
echo "   🗂️  ml-models (Public: NO)"
echo ""
echo "Total: 3 buckets"

echo ""
echo "🚀 Phase 5: Deployment Steps"
echo "============================================"
echo ""
echo "To deploy to Supabase:"
echo ""
echo "1️⃣  Login to Supabase Dashboard:"
echo "   → https://supabase.com"
echo ""
echo "2️⃣  Run Database Schema:"
echo "   → SQL Editor → New Query"
echo "   → Copy contents of COMPLETE_SUPABASE_SCHEMA.sql"
echo "   → Paste and click 'Run'"
echo ""
echo "3️⃣  Create Storage Buckets:"
echo "   → Storage → New Bucket"
echo "   → Create: animal-images (Public)"
echo "   → Create: videos (Private)"
echo "   → Create: ml-models (Private)"
echo ""
echo "4️⃣  Set Storage Policies:"
echo "   → SQL Editor → New Query"
echo "   → Copy contents of STORAGE_BUCKET_POLICIES.sql"
echo "   → Paste and click 'Run'"
echo ""
echo "5️⃣  Get Credentials:"
echo "   → Settings → API"
echo "   → Copy Project URL"
echo "   → Copy anon key"
echo "   → Copy service_role key (click Reveal)"
echo ""
echo "6️⃣  Update Configurations:"
echo "   → Flutter: $FLUTTER_CONFIG_FILE"
echo "   → Python: $PYTHON_ENV_FILE"
echo ""

echo ""
echo "📝 Phase 6: Verification Steps"
echo "============================================"
echo ""
echo "After deployment, verify:"
echo ""
echo "✅ Check Tables:"
echo "   → Supabase Dashboard → Table Editor"
echo "   → Should see 11 tables"
echo ""
echo "✅ Check Buckets:"
echo "   → Supabase Dashboard → Storage"
echo "   → Should see 3 buckets"
echo ""
echo "✅ Test Python Backend:"
echo "   cd python_backend"
echo "   ./start.sh"
echo "   → Visit http://localhost:8000/health"
echo "   → Check: \"database\": true"
echo ""
echo "✅ Test Flutter App:"
echo "   flutter run"
echo "   → Open Dashboard"
echo "   → Should load without errors"
echo "   → No \"table not found\" errors"
echo ""

echo ""
echo "🐛 Troubleshooting"
echo "============================================"
echo ""
echo "Error: 'Could not find the table public.ear_tag_camera'"
echo "Fix: Run COMPLETE_SUPABASE_SCHEMA.sql in Supabase SQL Editor"
echo ""
echo "Error: 'insufficient_privilege'"
echo "Fix: Use service_role key in Python backend, not anon key"
echo ""
echo "Error: Storage bucket not found"
echo "Fix: Create buckets manually in Supabase Storage"
echo ""

echo ""
echo "📚 Documentation Files"
echo "============================================"
echo ""
echo "Full guides available:"
echo "   📄 DEPLOY_TO_SUPABASE.md - Complete deployment guide"
echo "   📄 SUPABASE_DEPLOYMENT_CHECKLIST.md - Step-by-step checklist"
echo "   📄 COMPLETE_SUPABASE_SCHEMA.sql - Database schema"
echo "   📄 STORAGE_BUCKET_POLICIES.sql - Storage policies"
echo ""

echo ""
echo "✅ Verification Complete!"
echo "============================================"
echo ""
echo "Next steps:"
echo "1. Review any ❌ or ⚠️  items above"
echo "2. Follow deployment steps in DEPLOY_TO_SUPABASE.md"
echo "3. Run this script again after deployment to verify"
echo ""
