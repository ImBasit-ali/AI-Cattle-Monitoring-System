# Cattle AI Python Backend

Complete ML backend for cattle monitoring using YOLOv8, FastAPI, and Supabase.

## Features

- ✅ **Animal Detection**: YOLOv8-based detection for cows and buffaloes only
- ✅ **Tracking & Counting**: ByteTrack for unique animal identification
- ✅ **Milking Detection**: Udder detection and behavior analysis
- ✅ **Lameness Detection**: Pose estimation and gait analysis
- ✅ **Real-time Streaming**: WebSocket support for live camera feeds
- ✅ **Supabase Integration**: Automatic database synchronization

## Installation

### Prerequisites

- Python 3.8 or higher
- pip
- Virtual environment support

### Setup

1. **Run setup script:**
```bash
cd python_backend
chmod +x setup.sh
./setup.sh
```

2. **Configure environment:**
```bash
cp .env.example .env
# Edit .env with your configuration
nano .env
```

3. **Update Supabase credentials in `.env`:**
```env
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_anon_key
SUPABASE_SERVICE_KEY=your_supabase_service_key
```

## Running the Backend

### Development Mode

```bash
chmod +x start.sh
./start.sh
```

Or manually:
```bash
source venv/bin/activate
python3 main.py
```

The API will be available at `http://localhost:8000`

### Production Mode

```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
```

## API Endpoints

### Health Check
- `GET /` - Basic health check
- `GET /health` - Detailed health status

### Detection
- `POST /api/detect` - Detect animals in image
- `POST /api/detect-video` - Process video for detection

### Tracking
- `GET /api/tracking/stats` - Get tracking statistics
- `GET /api/tracking/animals` - Get all tracked animals

### Milking Status
- `POST /api/milking/detect` - Detect milking status

### Lameness Detection
- `POST /api/lameness/detect` - Detect lameness from video

### Statistics
- `GET /api/stats/daily` - Daily statistics
- `GET /api/stats/health` - Health monitoring statistics

### Real-time Streaming
- `WS /ws/camera/{camera_id}` - WebSocket camera stream

## Model Training

### 1. Cow/Buffalo Detection

Train YOLOv8 with custom dataset:

```python
from ultralytics import YOLO

# Prepare dataset with only cow and buffalo images
# Structure:
# dataset/
#   train/
#     images/
#     labels/
#   val/
#     images/
#     labels/

# Train
model = YOLO('yolov8n.pt')
results = model.train(
    data='cow_buffalo.yaml',
    epochs=100,
    imgsz=640,
    batch=16
)

# Save
model.save('models/cow_buffalo_detector.pt')
```

### 2. Udder Detection

Similar to cow detection, but train on udder images:

```python
model = YOLO('yolov8n.pt')
results = model.train(
    data='udder.yaml',
    epochs=100,
    imgsz=640
)
model.save('models/udder_detector.pt')
```

### 3. Lameness Classifier

Train Random Forest classifier:

```python
from sklearn.ensemble import RandomForestClassifier
import pickle

# Prepare features from gait analysis
# X = [step_length, step_symmetry, walking_speed, back_curvature, rest_time]
# y = [0=normal, 1=mild, 2=moderate, 3=severe]

clf = RandomForestClassifier(n_estimators=100)
clf.fit(X_train, y_train)

with open('models/lameness_classifier.pkl', 'wb') as f:
    pickle.dump(clf, f)
```

## Directory Structure

```
python_backend/
├── main.py                 # FastAPI application
├── config.py              # Configuration management
├── requirements.txt       # Python dependencies
├── .env.example          # Environment template
├── setup.sh              # Setup script
├── start.sh              # Start script
├── models/               # ML models
│   ├── cow_buffalo_detector.pt
│   ├── udder_detector.pt
│   ├── yolov8n-pose.pt
│   └── lameness_classifier.pkl
├── services/             # Service modules
│   ├── detection_service.py
│   ├── tracking_service.py
│   ├── milking_service.py
│   ├── lameness_service.py
│   └── database_service.py
└── models/               # Data models
    └── schemas.py
```

## Integration with Flutter

Update Flutter app's backend URL in `lib/services/python_backend_service.dart`:

```dart
static const String baseUrl = 'http://your-server-ip:8000';
static const String wsUrl = 'ws://your-server-ip:8000';
```

## Deployment

### Using Docker (Recommended)

```dockerfile
FROM python:3.9-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Using systemd

Create `/etc/systemd/system/cattle-ai-backend.service`:

```ini
[Unit]
Description=Cattle AI Backend
After=network.target

[Service]
Type=simple
User=your-user
WorkingDirectory=/path/to/python_backend
Environment="PATH=/path/to/python_backend/venv/bin"
ExecStart=/path/to/python_backend/venv/bin/python main.py
Restart=always

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable cattle-ai-backend
sudo systemctl start cattle-ai-backend
```

## Testing

Test endpoints using curl:

```bash
# Health check
curl http://localhost:8000/health

# Detect animals
curl -X POST -F "file=@test_image.jpg" http://localhost:8000/api/detect

# Get tracking stats
curl http://localhost:8000/api/tracking/stats
```

## Performance Optimization

1. **GPU Acceleration**: Install PyTorch with CUDA support
2. **Model Optimization**: Use TensorRT for inference
3. **Caching**: Implement Redis for frequent queries
4. **Load Balancing**: Use Nginx for multiple workers

## Troubleshooting

### Common Issues

1. **Models not found**: Run `setup.sh` to download default models
2. **Database connection failed**: Check Supabase credentials in `.env`
3. **Low FPS**: Enable GPU acceleration or reduce image resolution
4. **Memory issues**: Reduce batch size or use smaller models

## License

Proprietary - Cattle AI Monitoring System
