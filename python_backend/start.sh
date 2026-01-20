#!/bin/bash

# Start the FastAPI backend server

echo "🚀 Starting Cattle AI Backend..."

# Activate virtual environment
if [ -d "venv" ]; then
    source venv/bin/activate
else
    echo "❌ Virtual environment not found. Run setup.sh first."
    exit 1
fi

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "❌ .env file not found. Please create it from .env.example"
    exit 1
fi

# Start the server
echo "🌐 Starting server on http://0.0.0.0:8000"
python3 main.py
