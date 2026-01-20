#!/bin/bash
# Quick Setup Script for Video Processing Database Integration

echo "================================================"
echo "Video Processing Database Integration Setup"
echo "================================================"
echo ""

# Step 1: Run Database Migration
echo "📊 Step 1: Setting up database tables..."
echo "Please run the following in Supabase SQL Editor:"
echo ""
echo "File: supabase/migrations/08_milking_status_table.sql"
echo ""
echo "Or copy this SQL:"
cat supabase/migrations/08_milking_status_table.sql
echo ""
echo "Press Enter when done..."
read -r

# Step 2: Start Backend Server
echo ""
echo "🚀 Step 2: Starting Python backend server..."
cd python_backend || exit
./start_server.sh &
BACKEND_PID=$!
echo "Backend started with PID: $BACKEND_PID"
cd ..

# Wait for backend to initialize
echo "Waiting for backend to initialize..."
sleep 5

# Step 3: Test Backend
echo ""
echo "🧪 Step 3: Testing backend health..."
HEALTH_CHECK=$(curl -s http://localhost:8000/health)
if [ -n "$HEALTH_CHECK" ]; then
    echo "✅ Backend is healthy!"
    echo "$HEALTH_CHECK"
else
    echo "❌ Backend health check failed"
    kill $BACKEND_PID
    exit 1
fi

# Step 4: Instructions
echo ""
echo "================================================"
echo "✅ Setup Complete!"
echo "================================================"
echo ""
echo "Next steps:"
echo "1. Run your Flutter app: flutter run"
echo "2. Upload a video with cattle"
echo "3. Watch the dashboard update automatically!"
echo ""
echo "Dashboard Statistics:"
echo "  - Total Number of Cows (real-time)"
echo "  - Milking Cows Count (real-time)"
echo "  - Lameness Count (real-time)"
echo ""
echo "Backend running on: http://localhost:8000"
echo "To stop backend: kill $BACKEND_PID"
echo ""
echo "For more details, see:"
echo "  - VIDEO_PROCESSING_DATABASE_INTEGRATION.md"
echo "  - BACKEND_SETUP_COMPLETE.md"
echo ""
