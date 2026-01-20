#!/bin/bash
# Start the FastAPI backend server

cd "$(dirname "$0")"
echo "Starting Cattle AI Backend Server..."
echo "Server will run on http://0.0.0.0:8000"
echo "Press Ctrl+C to stop"
echo ""

python main.py
