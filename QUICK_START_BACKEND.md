# 🚀 QUICK START GUIDE - Python ML Backend Integration

## ✅ What's Been Created

### Python Backend (`python_backend/`)
- ✅ **FastAPI Server** - Complete REST API with WebSocket support
- ✅ **YOLOv8 Detection** - Cow/Buffalo detection (rejects other animals)
- ✅ **ByteTrack Tracking** - Unique ID assignment and counting
- ✅ **Milking Detection** - Udder analysis for lactation status
- ✅ **Lameness Detection** - Pose estimation and gait analysis
- ✅ **Supabase Integration** - Automatic database sync

### Flutter Services
- ✅ **PythonBackendService** - HTTP/WebSocket client
- ✅ **AIDetectionProvider** - State management for ML operations
- ✅ **Example Screen** - Ready-to-use UI implementation

## 🎯 Setup in 5 Minutes

### 1. Backend Setup
```bash
cd python_backend
chmod +x setup.sh
./setup.sh
```

### 2. Configure Supabase
Edit `python_backend/.env`:
```env
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_anon_key
SUPABASE_SERVICE_KEY=your_service_key
```

### 3. Run Database Migration
Open Supabase SQL Editor and run:
```sql
-- See BACKEND_INTEGRATION_GUIDE.md section "Update Supabase Schema"
```

### 4. Start Backend
```bash
cd python_backend
./start.sh
```
Backend runs at: `http://localhost:8000`

### 5. Update Flutter Config
Edit `lib/services/python_backend_service.dart`:
```dart
static const String baseUrl = 'http://localhost:8000';  // Or your server IP
```

### 6. Install Flutter Dependencies
```bash
flutter pub get
```

### 7. Run Flutter App
```bash
flutter run
```

## 📱 Using the Features

### In Your App
Navigate to the AI Detection screen to:
- ✅ Detect cows/buffaloes in photos
- ✅ Check milking status (lactating/dry)
- ✅ Analyze lameness from walking videos
- ✅ View real-time tracking statistics

### Example Code
See `lib/screens/ai/ai_detection_example_screen.dart` for complete implementation.

## 🔧 Key Files Created

### Backend
```
python_backend/
├── main.py                          # FastAPI app
├── config.py                        # Configuration
├── requirements.txt                 # Dependencies
├── setup.sh                         # Setup script
├── start.sh                         # Start script
├── services/
│   ├── detection_service.py        # YOLOv8 detection
│   ├── tracking_service.py         # ByteTrack
│   ├── milking_service.py          # Milking detection
│   ├── lameness_service.py         # Lameness detection
│   └── database_service.py         # Supabase integration
└── models/
    └── schemas.py                   # Data models
```

### Flutter
```
lib/
├── services/
│   └── python_backend_service.dart  # Backend client
├── providers/
│   └── ai_detection_provider.dart   # State management
└── screens/
    └── ai/
        └── ai_detection_example_screen.dart  # Example UI
```

## 🎓 Learn More

- **Complete Guide**: See `BACKEND_INTEGRATION_GUIDE.md`
- **Backend Docs**: See `python_backend/README.md`
- **API Docs**: Visit `http://localhost:8000/docs` when backend is running

## 🔄 Workflow

```
1. User takes photo/video in Flutter app
   ↓
2. Flutter sends to Python backend via HTTP
   ↓
3. Backend runs ML models (YOLOv8, etc.)
   ↓
4. Results saved to Supabase
   ↓
5. Flutter receives and displays results
```

## ⚡ Testing

### Test Backend
```bash
curl http://localhost:8000/health
```

### Test Detection
```bash
curl -X POST -F "file=@test_image.jpg" http://localhost:8000/api/detect
```

### Test from Flutter
1. Run backend
2. Run Flutter app
3. Use camera to test features

## 📊 What Each Feature Does

### 1. Animal Detection
- **Input**: Photo
- **Output**: List of detected cows/buffaloes with bounding boxes
- **Rejects**: Dogs, cats, goats, chickens, etc.

### 2. Tracking & Counting
- **Input**: Video stream
- **Output**: Unique ID for each animal, count totals
- **Uses**: ByteTrack algorithm

### 3. Milking Status
- **Input**: Photo of animal (side/rear view)
- **Output**: Milking/Dry status with confidence
- **Method**: Udder detection + size analysis

### 4. Lameness Detection
- **Input**: Video of animal walking
- **Output**: Normal/Mild/Moderate/Severe with gait metrics
- **Method**: Pose estimation + ML classifier

## 🚀 Next Steps

1. **Train Custom Models**
   - Collect cow/buffalo images
   - Train YOLOv8 with your data
   - Replace default models

2. **Deploy to Production**
   - Use VPS or cloud server
   - Set up nginx reverse proxy
   - Enable HTTPS

3. **Optimize Performance**
   - Enable GPU acceleration
   - Use model quantization
   - Implement caching

## ❓ Troubleshooting

**Backend won't start?**
- Check Python version (3.8+)
- Run `./setup.sh` again
- Check `.env` file exists

**Detection not working?**
- Verify backend is running
- Check Flutter app URL matches backend
- Test with `curl` first

**Low accuracy?**
- Train custom models with your cattle
- Adjust confidence threshold
- Improve image quality

## 📞 Support

- See detailed docs in `BACKEND_INTEGRATION_GUIDE.md`
- Check API docs at `http://localhost:8000/docs`
- Review example code in `ai_detection_example_screen.dart`

---

**Created by**: Cattle AI Development Team
**Date**: January 2026
**Version**: 1.0.0
