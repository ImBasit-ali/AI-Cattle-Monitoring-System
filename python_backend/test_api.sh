#!/bin/bash

# Quick Test Script for Cattle AI Backend
# This script tests all backend endpoints

echo "🧪 Testing Cattle AI Backend..."
echo ""

BACKEND_URL="http://localhost:8000"

# Test 1: Health Check
echo "1️⃣ Testing Health Check..."
curl -s $BACKEND_URL/health | python3 -m json.tool
echo ""

# Test 2: Root endpoint
echo "2️⃣ Testing Root Endpoint..."
curl -s $BACKEND_URL/ | python3 -m json.tool
echo ""

# Test 3: Tracking Stats
echo "3️⃣ Testing Tracking Stats..."
curl -s $BACKEND_URL/api/tracking/stats | python3 -m json.tool
echo ""

# Test 4: Daily Stats
echo "4️⃣ Testing Daily Stats..."
curl -s $BACKEND_URL/api/stats/daily | python3 -m json.tool
echo ""

# Test 5: Health Stats
echo "5️⃣ Testing Health Stats..."
curl -s $BACKEND_URL/api/stats/health | python3 -m json.tool
echo ""

echo "✅ Basic tests complete!"
echo ""
echo "📝 To test image detection, use:"
echo "   curl -X POST -F \"file=@your_image.jpg\" $BACKEND_URL/api/detect"
echo ""
echo "📚 Full API documentation available at: $BACKEND_URL/docs"
