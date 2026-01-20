# YOLOv8 Video Processing Backend Setup

This Python backend uses **YOLOv8** for accurate animal detection, milking status assessment, and lameness detection.

## Features

✅ **Animal Detection & Classification** (YOLOv8)
- Detects and counts cattle, buffalo
- Filters out humans, dogs, cats, other animals
- Individual animal tracking with unique IDs

✅ **Milking Status Assessment**
- Analyzes udder region
- Detects milking equipment presence
- Returns milking/non-milking status with confidence

✅ **Lameness Detection**
- Analyzes gait patterns
- Detects movement irregularities
- Scores 0-5 with severity classification

## Installation

### 1. Install Python Dependencies

```bash
cd python_backend
pip install -r requirements.txt
```

### 2. Download YOLOv8 Model

The service will automatically download `yolov8n.pt` (nano model) on first run.

For better accuracy, use a larger model or custom trained model:
```bash
# Download medium model
wget https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8m.pt

# Or train your own model on cattle dataset
```

### 3. Start the Backend

```bash
# Development mode
python main.py

# Or using uvicorn
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

## API Endpoints

### Complete Video Processing
```
POST /api/video/process
Content-Type: multipart/form-data
Body: file (video file), cattle_id (optional)

Response:
{
  "success": true,
  "message": "Detected 3 cattle, 0 buffalo",
  "cattle_count": 3,
  "buffalo_count": 0,
  "total_count": 3,
  "other_animals": [],
  "is_milking": true,
  "milking_confidence": 0.87,
  "lameness_score": 1,
  "lameness_severity": "Mild Lameness",
  "is_lame": true,
  "lameness_confidence": 0.82
}
```

### Animal Detection Only
```
POST /api/video/detect-animals
```

### Milking Assessment Only
```
POST /api/video/assess-milking
```

### Lameness Detection Only
```
POST /api/video/detect-lameness
```

## Integration with Flutter App

The Flutter app's `VideoProcessingService` can call the Python backend:

```dart
// Update the service to call Python backend
final response = await http.post(
  Uri.parse('http://localhost:8000/api/video/process'),
  headers: {'Content-Type': 'multipart/form-data'},
  body: formData,
);
```

## Model Configuration

### Using Custom Trained Model

1. Train YOLOv8 on your cattle dataset:
```python
from ultralytics import YOLO

model = YOLO('yolov8n.pt')
results = model.train(
    data='cattle_dataset.yaml',
    epochs=100,
    imgsz=640
)
```

2. Update `video_processing_service.py`:
```python
model_path = 'path/to/your/custom_model.pt'
self.yolo_model = YOLO(model_path)
```

### Optimizing Performance

- **CPU**: Use `yolov8n.pt` (nano) for fastest processing
- **GPU**: Use `yolov8m.pt` or `yolov8l.pt` for better accuracy
- Adjust `sample_rate` in code to balance speed vs accuracy

## Error Handling

The system handles:
- ✅ No animals detected → Clear error message
- ✅ Wrong animals detected → Lists what was found
- ✅ Model not loaded → Falls back to simulation mode
- ✅ Video format issues → Returns appropriate error

## Production Deployment

### Docker Deployment
```dockerfile
FROM python:3.10-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Environment Variables
```bash
export YOLO_MODEL_PATH=/path/to/model.pt
export API_PORT=8000
export LOG_LEVEL=INFO
```

## Testing

```bash
# Test with sample video
curl -X POST http://localhost:8000/api/video/process \
  -F "file=@sample_cattle_video.mp4" \
  -F "cattle_id=COW001"
```

## Performance

- **Processing Speed**: ~5-15 FPS depending on model and hardware
- **Accuracy**: >90% cattle detection (YOLOv8m on COCO dataset)
- **Video Formats**: MP4, AVI, MOV supported

## Troubleshooting

### YOLOv8 Not Loading
```bash
# Reinstall ultralytics
pip uninstall ultralytics
pip install ultralytics==8.1.0
```

### Out of Memory
- Use smaller model (`yolov8n.pt`)
- Increase `sample_rate` to process fewer frames
- Reduce video resolution before processing

### Slow Processing
- Enable GPU support
- Use TensorRT optimization
- Process smaller video segments
