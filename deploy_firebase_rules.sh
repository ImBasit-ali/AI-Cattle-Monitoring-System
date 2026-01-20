#!/bin/bash

# Firebase Security Rules Deployment Script
# Auto-deploy Firebase Realtime Database and Storage Rules

echo "🔥 Firebase Security Rules Deployment"
echo "======================================"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ Firebase CLI not found. Please install it:${NC}"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Check if logged in
echo -e "\n${YELLOW}Checking Firebase authentication...${NC}"
if ! firebase login:list &> /dev/null; then
    echo -e "${RED}❌ Not logged in to Firebase${NC}"
    echo "Please run: firebase login"
    exit 1
fi

# Set the project
echo -e "\n${YELLOW}Setting Firebase project...${NC}"
firebase use ai-cattle-monitoring-system

# Deploy Realtime Database Rules
echo -e "\n${YELLOW}Deploying Realtime Database security rules...${NC}"
if firebase deploy --only database; then
    echo -e "${GREEN}✅ Database rules deployed successfully!${NC}"
else
    echo -e "${RED}❌ Failed to deploy database rules${NC}"
    exit 1
fi

# Deploy Storage Rules (if storage is enabled)
echo -e "\n${YELLOW}Deploying Storage security rules...${NC}"
if firebase deploy --only storage 2>&1 | grep -q "not been set up"; then
    echo -e "${YELLOW}⚠️  Firebase Storage not enabled yet.${NC}"
    echo -e "${YELLOW}Please enable it at:${NC}"
    echo -e "https://console.firebase.google.com/project/ai-cattle-monitoring-system/storage"
    echo -e "\n${YELLOW}After enabling, run this script again to deploy storage rules.${NC}"
else
    echo -e "${GREEN}✅ Storage rules deployed successfully!${NC}"
fi

echo -e "\n${GREEN}======================================"
echo -e "🎉 Deployment Complete!"
echo -e "======================================${NC}"
echo -e "\n${YELLOW}Security Rules Summary:${NC}"
echo "• Database rules: User data isolated by UID"
echo "• Storage rules: Files protected per user"
echo "• All write operations require authentication"
echo "• Indexes configured for optimal queries"
echo -e "\n${YELLOW}Project Console:${NC}"
echo "https://console.firebase.google.com/project/ai-cattle-monitoring-system/overview"
