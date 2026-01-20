#!/bin/bash

# ============================================
# CATTLE AI MONITOR - QUICK DEPLOYMENT SCRIPT
# ============================================

echo "🐄 Cattle AI Monitor - Supabase Deployment"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Project details
PROJECT_URL="https://nznoonwreqsdrawfxrwr.supabase.co"
PROJECT_REF="nznoonwreqsdrawfxrwr"

echo -e "${YELLOW}📋 Deployment Checklist${NC}"
echo ""
echo "This script will guide you through deploying to Supabase."
echo "You'll need to manually execute SQL scripts in Supabase Dashboard."
echo ""

# Check if migration files exist
if [ ! -f "supabase/migrations/01_create_tables.sql" ]; then
    echo -e "${RED}❌ Error: Migration files not found!${NC}"
    echo "Please ensure you're in the project root directory."
    exit 1
fi

echo -e "${GREEN}✅ Migration files found${NC}"
echo ""

# Step 1: Authentication
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1: Enable Authentication"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Open: https://supabase.com/dashboard/project/${PROJECT_REF}/auth/providers"
echo "2. Ensure 'Email' provider is enabled"
echo "3. For testing: Disable email confirmations in Settings"
echo ""
read -p "Press ENTER when authentication is configured..."
echo -e "${GREEN}✅ Authentication configured${NC}"
echo ""

# Step 2: Database Tables
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2: Create Database Tables"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Open: https://supabase.com/dashboard/project/${PROJECT_REF}/sql"
echo "2. Click 'New query'"
echo "3. Copy content from: supabase/migrations/01_create_tables.sql"
echo "4. Click RUN"
echo ""
echo -e "${YELLOW}💡 Tip: Use Ctrl+A to select all, then Ctrl+C to copy${NC}"
echo ""
read -p "Press ENTER when tables are created..."
echo -e "${GREEN}✅ Database tables created${NC}"
echo ""

# Step 3: Row Level Security
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3: Enable Row Level Security"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. In SQL Editor, click 'New query'"
echo "2. Copy content from: supabase/migrations/02_enable_rls.sql"
echo "3. Click RUN"
echo ""
read -p "Press ENTER when RLS is enabled..."
echo -e "${GREEN}✅ Row Level Security enabled${NC}"
echo ""

# Step 4: Storage Buckets
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 4: Create Storage Buckets"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Open: https://supabase.com/dashboard/project/${PROJECT_REF}/storage/buckets"
echo "2. Create these buckets:"
echo "   - animal-images (Public: YES)"
echo "   - videos (Public: NO)"
echo "   - ml-models (Public: YES)"
echo ""
read -p "Press ENTER when buckets are created..."
echo ""
echo "3. In SQL Editor, click 'New query'"
echo "4. Copy content from: supabase/migrations/03_storage_policies.sql"
echo "5. Click RUN"
echo ""
read -p "Press ENTER when storage policies are applied..."
echo -e "${GREEN}✅ Storage configured${NC}"
echo ""

# Step 5: Realtime
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 5: Enable Realtime"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Open: https://supabase.com/dashboard/project/${PROJECT_REF}/database/replication"
echo "2. Enable replication for these tables:"
echo "   - animals"
echo "   - movement_data"
echo "   - lameness_records"
echo "   - video_records"
echo ""
read -p "Press ENTER when realtime is enabled..."
echo -e "${GREEN}✅ Realtime enabled${NC}"
echo ""

# Step 6: Test
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 6: Test Your Deployment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Running Flutter app..."
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${YELLOW}⚠️  Flutter not found. Please run manually:${NC}"
    echo "   flutter pub get"
    echo "   flutter run"
else
    flutter pub get
    echo ""
    echo -e "${GREEN}✅ Dependencies installed${NC}"
    echo ""
    echo "Starting app..."
    flutter run
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Your Cattle AI Monitor app is now connected to Supabase!"
echo ""
echo "Next steps:"
echo "1. Sign up in the app with a test email"
echo "2. Add a test animal"
echo "3. Check Supabase Dashboard to see the data"
echo ""
echo "For detailed documentation, see:"
echo "  - DEPLOYMENT_GUIDE.md"
echo "  - SUPABASE_SETUP_GUIDE.md"
echo ""
