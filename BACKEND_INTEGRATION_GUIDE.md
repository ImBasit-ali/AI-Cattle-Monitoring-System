# Flutter + Python Backend Integration Guide

Complete guide to integrate the Python ML backend with your Flutter Cattle AI app.

## Architecture Overview

```
Flutter App (Frontend)
    ↓ HTTP/WebSocket
Python FastAPI (Backend)
    ↓ ML Processing
YOLOv8 Models + ML Services
    ↓ Database
Supabase (PostgreSQL)
```

## Setup Steps

### 1. Setup Python Backend

```bash
cd python_backend
chmod +x setup.sh
./setup.sh

# Edit environment file
nano .env
```

Add your Supabase credentials to `.env`:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your_anon_key
SUPABASE_SERVICE_KEY=your_service_key
```

### 2. Start the Backend

```bash
chmod +x start.sh
./start.sh
```

Backend will run on `http://localhost:8000`

### 3. Update Flutter App Configuration

Edit `lib/services/python_backend_service.dart`:

```dart
// For local development
static const String baseUrl = 'http://localhost:8000';
static const String wsUrl = 'ws://localhost:8000';

// For production (your server IP or domain)
// static const String baseUrl = 'http://your-server-ip:8000';
// static const String wsUrl = 'ws://your-server-ip:8000';
```

### 4. Install Flutter Dependencies

```bash
flutter pub get
```

### 5. Update Supabase Schema

Run this SQL in your Supabase SQL editor:

```sql
-- Add AI detection tables

-- Detections table
CREATE TABLE IF NOT EXISTS detections (
    id BIGSERIAL PRIMARY KEY,
    detection_id TEXT UNIQUE NOT NULL,
    animal_type TEXT NOT NULL,
    confidence FLOAT NOT NULL,
    bbox_x1 FLOAT,
    bbox_y1 FLOAT,
    bbox_x2 FLOAT,
    bbox_y2 FLOAT,
    detected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Animal tracks table
CREATE TABLE IF NOT EXISTS animal_tracks (
    id BIGSERIAL PRIMARY KEY,
    track_id INTEGER UNIQUE NOT NULL,
    animal_type TEXT NOT NULL,
    first_seen TIMESTAMP WITH TIME ZONE,
    last_seen TIMESTAMP WITH TIME ZONE,
    confidence_avg FLOAT,
    frame_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Milking status table
CREATE TABLE IF NOT EXISTS milking_status (
    id BIGSERIAL PRIMARY KEY,
    animal_id TEXT REFERENCES animals(animal_id),
    status TEXT NOT NULL,
    confidence FLOAT,
    udder_detected BOOLEAN DEFAULT FALSE,
    udder_size FLOAT,
    behavioral_score FLOAT,
    detected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Lameness detections table
CREATE TABLE IF NOT EXISTS lameness_detections (
    id BIGSERIAL PRIMARY KEY,
    animal_id TEXT REFERENCES animals(animal_id),
    lameness_level TEXT NOT NULL,
    confidence FLOAT,
    step_length FLOAT,
    step_symmetry FLOAT,
    walking_speed FLOAT,
    back_curvature FLOAT,
    affected_leg TEXT,
    detected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Cameras table
CREATE TABLE IF NOT EXISTS cameras (
    id BIGSERIAL PRIMARY KEY,
    camera_id TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    rtsp_url TEXT,
    location TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add ML columns to animals table if not exists
ALTER TABLE animals ADD COLUMN IF NOT EXISTS milking_status TEXT DEFAULT 'unknown';
ALTER TABLE animals ADD COLUMN IF NOT EXISTS lameness_level TEXT DEFAULT 'normal';
ALTER TABLE animals ADD COLUMN IF NOT EXISTS last_milking_check TIMESTAMP WITH TIME ZONE;
ALTER TABLE animals ADD COLUMN IF NOT EXISTS last_health_check TIMESTAMP WITH TIME ZONE;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_detections_detected_at ON detections(detected_at);
CREATE INDEX IF NOT EXISTS idx_milking_animal_id ON milking_status(animal_id);
CREATE INDEX IF NOT EXISTS idx_lameness_animal_id ON lameness_detections(animal_id);
CREATE INDEX IF NOT EXISTS idx_tracks_track_id ON animal_tracks(track_id);
```

## Using the Backend in Flutter

### 1. Basic Detection

```dart
import 'package:provider/provider.dart';
import '../providers/ai_detection_provider.dart';

// In your widget
final aiProvider = Provider.of<AIDetectionProvider>(context);

// Check if backend is online
await aiProvider.checkBackendHealth();

if (aiProvider.isBackendOnline) {
  // Detect animals in image
  final result = await aiProvider.detectAnimals(imageFile);
  
  if (result['success']) {
    print('Detected ${result['count']} animals');
    // result['detections'] contains list of detections
  }
}
```

### 2. Milking Status Detection

```dart
// Capture image of animal's udder
final imageFile = await ImagePicker().pickImage(source: ImageSource.camera);

if (imageFile != null) {
  final file = File(imageFile.path);
  
  // Detect milking status
  final result = await aiProvider.detectMilkingStatus(
    file,
    animalId: 'ANIMAL123',  // Optional
  );
  
  if (result['success']) {
    final status = result['status'];
    print('Milking Status: ${status['status']}');
    print('Confidence: ${status['confidence']}');
  }
}
```

### 3. Lameness Detection

```dart
// Capture video of animal walking
final videoFile = await ImagePicker().pickVideo(source: ImageSource.camera);

if (videoFile != null) {
  final file = File(videoFile.path);
  
  // Show loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 20),
          Text('Analyzing gait...'),
        ],
      ),
    ),
  );
  
  // Detect lameness
  final result = await aiProvider.detectLameness(
    file,
    animalId: 'ANIMAL123',
  );
  
  Navigator.pop(context);  // Close loading
  
  if (result['success']) {
    final lameness = result['lameness'];
    print('Lameness Level: ${lameness['level']}');
    print('Confidence: ${lameness['confidence']}');
    print('Step Symmetry: ${lameness['gait_features']['step_symmetry']}');
  }
}
```

### 4. Real-time Camera Streaming

```dart
import 'package:web_socket_channel/web_socket_channel.dart';

// Connect to camera stream
final backendService = PythonBackendService.instance;

StreamBuilder<Map<String, dynamic>>(
  stream: backendService.streamCamera('camera_1'),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final data = snapshot.data!;
      final detections = data['detections'] as List;
      
      return ListView.builder(
        itemCount: detections.length,
        itemBuilder: (context, index) {
          final detection = detections[index];
          return ListTile(
            title: Text(detection['animal_type']),
            subtitle: Text('Confidence: ${detection['confidence']}'),
          );
        },
      );
    }
    
    return CircularProgressIndicator();
  },
)
```

### 5. Display Statistics

```dart
// Fetch statistics
await aiProvider.fetchHealthStats();

// Display
if (aiProvider.healthStats != null) {
  final stats = aiProvider.healthStats!;
  
  // Lameness distribution
  final lameness = stats['lameness'];
  print('Normal: ${lameness['normal']}');
  print('Mild: ${lameness['mild']}');
  print('Moderate: ${lameness['moderate']}');
  print('Severe: ${lameness['severe']}');
  
  // Milking distribution
  final milking = stats['milking'];
  print('Milking: ${milking['milking']}');
  print('Dry: ${milking['dry']}');
}
```

## Complete Example Widget

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/ai_detection_provider.dart';

class AIDetectionScreen extends StatefulWidget {
  @override
  _AIDetectionScreenState createState() => _AIDetectionScreenState();
}

class _AIDetectionScreenState extends State<AIDetectionScreen> {
  final _imagePicker = ImagePicker();
  
  Future<void> _detectAnimals() async {
    final aiProvider = Provider.of<AIDetectionProvider>(context, listen: false);
    
    // Pick image
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
    );
    
    if (pickedFile != null) {
      try {
        final result = await aiProvider.detectAnimals(File(pickedFile.path));
        
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Detected ${result['count']} animals'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Detection failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI Detection')),
      body: Consumer<AIDetectionProvider>(
        builder: (context, aiProvider, _) {
          return Column(
            children: [
              // Backend status
              Container(
                padding: EdgeInsets.all(16),
                color: aiProvider.isBackendOnline ? Colors.green : Colors.red,
                child: Row(
                  children: [
                    Icon(
                      aiProvider.isBackendOnline ? Icons.check_circle : Icons.error,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      aiProvider.isBackendOnline ? 'Backend Online' : 'Backend Offline',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              // Detections list
              Expanded(
                child: ListView.builder(
                  itemCount: aiProvider.detections.length,
                  itemBuilder: (context, index) {
                    final detection = aiProvider.detections[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.pets),
                        title: Text(detection['animal_type'] ?? 'Unknown'),
                        subtitle: Text(
                          'Confidence: ${(detection['confidence'] * 100).toStringAsFixed(1)}%',
                        ),
                        trailing: Text(detection['detection_id'] ?? ''),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _detectAnimals,
        child: Icon(Icons.camera_alt),
      ),
    );
  }
}
```

## Testing

### Test Backend Endpoints

```bash
# Health check
curl http://localhost:8000/health

# Test detection (with image file)
curl -X POST -F "file=@test_cow.jpg" http://localhost:8000/api/detect

# Get statistics
curl http://localhost:8000/api/stats/daily
```

### Test from Flutter

1. Run backend: `cd python_backend && ./start.sh`
2. Run Flutter app: `flutter run`
3. Use camera to capture image
4. Check console for detection results

## Deployment

### Backend Deployment Options

#### Option 1: VPS (DigitalOcean, AWS, etc.)

```bash
# On server
git clone your-repo
cd python_backend
./setup.sh

# Configure nginx reverse proxy
sudo nano /etc/nginx/sites-available/cattle-ai

# Add:
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    location /ws/ {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

#### Option 2: Docker

See `python_backend/README.md` for Docker deployment

### Flutter App Deployment

Update `python_backend_service.dart` with production URL:

```dart
static const String baseUrl = 'https://your-domain.com';
static const String wsUrl = 'wss://your-domain.com';
```

## Performance Tips

1. **Image Optimization**: Compress images before sending
2. **Batch Processing**: Process multiple frames together
3. **Caching**: Cache detection results locally
4. **Background Processing**: Use isolates for heavy operations
5. **Connection Pooling**: Reuse HTTP connections

## Troubleshooting

### Backend Not Connecting

1. Check if backend is running: `curl http://localhost:8000/health`
2. Check firewall rules
3. Verify URL in Flutter app matches backend URL
4. Check network connectivity

### Low Accuracy

1. Train custom models with your specific cattle breeds
2. Collect more training data
3. Adjust confidence thresholds
4. Improve image quality

### Slow Performance

1. Enable GPU acceleration on backend
2. Use smaller YOLOv8 models (n instead of x)
3. Reduce image resolution
4. Process frames at lower FPS

## Next Steps

1. ✅ Train custom YOLOv8 model for your cattle
2. ✅ Collect udder images and train udder detector
3. ✅ Gather gait videos and train lameness classifier
4. ✅ Set up camera infrastructure
5. ✅ Deploy to production server
6. ✅ Monitor and optimize performance

## Support

For issues and questions, refer to:
- Python Backend: `python_backend/README.md`
- API Documentation: http://localhost:8000/docs (when backend is running)
