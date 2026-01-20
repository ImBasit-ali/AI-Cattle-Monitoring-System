#!/bin/bash

# Setup script for Cattle AI Backend

echo "🚀 Setting up Cattle AI Backend..."

# Check Python version
python_version=$(python3 --version 2>&1 | awk '{print $2}')
echo "✓ Python version: $python_version"

# Create virtual environment
echo "📦 Creating virtual environment..."
python3 -m venv venv

# Activate virtual environment
echo "🔌 Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
echo "⬆️  Upgrading pip..."
pip install --upgrade pip

# Install requirements
echo "📥 Installing requirements..."
pip install -r requirements.txt

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p models
mkdir -p logs
mkdir -p temp

# Copy environment file
echo "🔧 Setting up environment..."
if [ ! -f .env ]; then
    cp .env.example .env
    echo "⚠️  Please update .env file with your configuration"
else
    echo "✓ .env file already exists"
fi

# Download default YOLOv8 models (for testing)
echo "📥 Downloading YOLOv8 models..."
python3 -c "
from ultralytics import YOLO
import os

models_dir = './models'
os.makedirs(models_dir, exist_ok=True)

print('Downloading YOLOv8n...')
model = YOLO('yolov8n.pt')
model.save(f'{models_dir}/yolov8n.pt')

print('Downloading YOLOv8n-pose...')
pose_model = YOLO('yolov8n-pose.pt')
pose_model.save(f'{models_dir}/yolov8n-pose.pt')

print('✓ Models downloaded')
"

echo ""
echo "✅ Setup complete!"
echo ""
echo "📝 Next steps:"
echo "1. Update .env file with your Supabase credentials"
echo "2. Train custom models for cow/buffalo detection"
echo "3. Train udder detection model"
echo "4. Train lameness classifier"
echo "5. Run: python3 main.py"
echo ""
echo "💡 To activate environment: source venv/bin/activate"
echo "💡 To run backend: python3 main.py"
echo ""
