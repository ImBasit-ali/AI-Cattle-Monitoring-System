# Cattle AI Monitor - Complete Project Documentation

## 📋 Project Overview

**Cattle AI Monitor** is an IoT-based Cattle Monitoring System built with Flutter and Firebase. The application focuses on three core entities:
1. **Animal Identification** - Tracking cattle with unique IDs
2. **Movement Analysis** - Monitoring daily activity patterns
3. **Lameness Detection** - AI/ML-powered health monitoring

---

## 🏗️ System Architecture

### Technology Stack

#### Frontend
- **Flutter** 3.10+ (Dart null-safety)
- **State Management**: Provider
- **UI Components**: Material Design 3
- **Animations**: flutter_animate
- **Charts**: FL Chart, Syncfusion Charts

#### Backend
- **Firebase**
  - Authentication
  - firestore

#### Machine Learning
- **TensorFlow Lite** - On-device inference
- **Rule-Based System** - Phase 1 detection
- **ML-Based System** - Phase 2 neural network

#### Camera & Media
- **Flutter Camera Plugin**
- **Video Recording & Upload**
- **Image Processing**

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart       # App-wide constants
│   ├── theme/
│   │   └── app_theme.dart          # Theme configuration
│   └── utils/
│       └── helpers.dart            # Utility functions
├── models/
│   ├── animal.dart                 # Animal data model
│   ├── movement_data.dart          # Movement tracking model
│   ├── lameness_record.dart        # Lameness detection model
│   ├── video_record.dart           # Video upload model
│   └── user_model.dart             # User/Farmer model
├── services/
│   ├── supabase_service.dart       # Supabase integration
│   └── ml_service.dart             # ML/AI service
├── providers/
│   ├── auth_provider.dart          # Authentication state
│   └── animal_provider.dart        # Animal data state
├── iot_simulation/
│   └── iot_simulation_service.dart # IoT sensor simulation
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── dashboard/
│   │   └── dashboard_screen.dart
│   ├── animals/
│   │   ├── animals_list_screen.dart
│   │   ├── animal_detail_screen.dart
│   │   └── add_animal_screen.dart
│   ├── movement/
│   │   ├── movement_screen.dart
│   │   └── movement_graphs_screen.dart
│   ├── lameness/
│   │   ├── lameness_screen.dart
│   │   └── lameness_analysis_screen.dart
│   └── camera/
│       ├── camera_screen.dart
│       └── video_upload_screen.dart
├── widgets/
│   ├── custom_card.dart
│   ├── stat_card.dart
│   └── chart_widgets.dart
└── main.dart                       # App entry point
```

---

## 🗄️ Database Schema (Supabase/PostgreSQL)

### Tables

#### 1. `animals` Table
```sql
CREATE TABLE animals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    animal_id VARCHAR(20) UNIQUE NOT NULL,
    species VARCHAR(50) NOT NULL,
    age INTEGER NOT NULL,
    health_status VARCHAR(50) NOT NULL,
    image_url TEXT,
    breed VARCHAR(100),
    weight DECIMAL(10, 2),
    notes TEXT,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_animals_user_id ON animals(user_id);
CREATE INDEX idx_animals_animal_id ON animals(animal_id);
```

#### 2. `movement_data` Table
```sql
CREATE TABLE movement_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    animal_id UUID NOT NULL REFERENCES animals(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    step_count INTEGER NOT NULL,
    activity_duration_hours DECIMAL(5, 2) NOT NULL,
    rest_duration_hours DECIMAL(5, 2) NOT NULL,
    movement_score DECIMAL(5, 2) NOT NULL,
    movement_level VARCHAR(20) NOT NULL,
    average_speed DECIMAL(10, 2),
    distance_covered INTEGER,
    raw_sensor_data JSONB,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_movement_animal_id ON movement_data(animal_id);
CREATE INDEX idx_movement_date ON movement_data(date);
```

#### 3. `lameness_records` Table
```sql
CREATE TABLE lameness_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    animal_id UUID NOT NULL REFERENCES animals(id) ON DELETE CASCADE,
    detection_date DATE NOT NULL,
    severity VARCHAR(50) NOT NULL,
    confidence_score DECIMAL(5, 4) NOT NULL,
    detection_method VARCHAR(20) NOT NULL,
    step_count INTEGER,
    activity_hours DECIMAL(5, 2),
    rest_hours DECIMAL(5, 2),
    ml_input_features JSONB,
    ml_output_probabilities JSONB,
    video_url TEXT,
    notes TEXT,
    requires_attention BOOLEAN DEFAULT FALSE,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_lameness_animal_id ON lameness_records(animal_id);
CREATE INDEX idx_lameness_date ON lameness_records(detection_date);
CREATE INDEX idx_lameness_severity ON lameness_records(severity);
```

#### 4. `video_records` Table
```sql
CREATE TABLE video_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    animal_id UUID NOT NULL REFERENCES animals(id) ON DELETE CASCADE,
    video_url TEXT NOT NULL,
    thumbnail_url TEXT,
    upload_date DATE NOT NULL,
    duration_seconds INTEGER NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    purpose VARCHAR(50) NOT NULL,
    processing_status VARCHAR(20) NOT NULL,
    analysis_results JSONB,
    error_message TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_video_animal_id ON video_records(animal_id);
CREATE INDEX idx_video_status ON video_records(processing_status);
```

### Storage Buckets

1. **animal-images** - Animal profile pictures
2. **videos** - Uploaded video files
3. **ml-models** - TensorFlow Lite models

---

## 🤖 Machine Learning Pipeline

### Phase 1: Rule-Based Detection

```
Input: 
  - Step Count
  - Activity Duration (hours)
  - Rest Duration (hours)

Rules:
  1. Severe Lameness: steps < 1000 AND rest > 18h
  2. Severe Lameness: steps < 800 AND activity < 3h
  3. Mild Lameness: steps < 1500 AND activity < 4h
  4. Mild Lameness: steps < 2000
  5. Normal: Otherwise

Output:
  - Severity: Normal | Mild Lameness | Severe Lameness
  - Confidence Score: 0.0 - 1.0
```

### Phase 2: ML-Based Detection

```
Model Architecture:
  Input Layer: 10 features (normalized)
    - Step count (normalized)
    - Activity hours (normalized)
    - Rest hours (normalized)
    - Average speed (normalized)
    - Symmetry score
    - Movement score
    - Activity ratio
    - Asymmetry score
    - Step-activity interaction
    - Rest-activity ratio
  
  Hidden Layers: [Dense(32, ReLU), Dense(16, ReLU)]
  Output Layer: Dense(3, Softmax)
    - Probability[0]: Normal
    - Probability[1]: Mild Lameness
    - Probability[2]: Severe Lameness

Training:
  - Dataset: Labeled cattle movement data
  - Loss: Categorical Crossentropy
  - Optimizer: Adam
  - Metrics: Accuracy, Precision, Recall

TFLite Conversion:
  1. Train model in Python (TensorFlow/Keras)
  2. Convert to TFLite format
  3. Optimize for mobile (quantization)
  4. Deploy to assets/ml/lameness_model.tflite
```

### ML Training Script (Python)

```python
import tensorflow as tf
import numpy as np

# Model definition
def create_lameness_model():
    model = tf.keras.Sequential([
        tf.keras.layers.Dense(32, activation='relu', input_shape=(10,)),
        tf.keras.layers.Dropout(0.3),
        tf.keras.layers.Dense(16, activation='relu'),
        tf.keras.layers.Dropout(0.2),
        tf.keras.layers.Dense(3, activation='softmax')
    ])
    
    model.compile(
        optimizer='adam',
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )
    
    return model

# Convert to TFLite
def convert_to_tflite(model, save_path):
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()
    
    with open(save_path, 'wb') as f:
        f.write(tflite_model)
```

---

## 📊 Data Visualization

### Charts Implemented

1. **Movement Line Chart**
   - X-axis: Date (last 7 days)
   - Y-axis: Step Count
   - Library: FL Chart

2. **Activity Bar Chart**
   - X-axis: Day of Week
   - Y-axis: Activity Hours
   - Library: Syncfusion Charts

3. **Lameness Risk Indicator**
   - Gauge/Radial Chart
   - Color-coded: Green (Normal), Orange (Mild), Red (Severe)

---

## 🌐 IoT Integration (Future)

### Planned Hardware Integration

1. **RFID Readers**
   - Automatic animal identification
   - No manual ID entry needed

2. **Accelerometer Collars**
   - Real-time 3-axis movement data
   - Bluetooth Low Energy (BLE) communication

3. **Fixed Wall Cameras**
   - Automated video capture
   - Gait analysis using computer vision

4. **Edge AI Devices**
   - On-premise ML inference
   - Reduced cloud dependency

### Current Simulation

The `IoTSimulationService` generates realistic sensor data:
- Step count simulation
- Activity/rest pattern generation
- Accelerometer data (3-axis)
- Heart rate and temperature
- Circadian rhythm modeling

---

## 🎨 UI/UX Design Guidelines

### Color Palette
- **White**: #FFFFFF (Background)
- **Light Gray**: #F5F5F5 (Surface)
- **Charcoal**: #424242 (Text Primary)
- **Muted Blue**: #607D8B (Primary)
- **Accent Blue**: #4A90E2 (Accents)

### Design Principles
- Minimal, clean interfaces
- Glassy, frosted effects
- Smooth animations (200-600ms)
- Clear data hierarchy
- Research-grade professionalism

---

## 🚀 Getting Started

### Prerequisites
```bash
Flutter SDK: >=3.10.1
Dart SDK: >=3.10.1
Supabase Account
```

### Installation

1. **Clone Repository**
```bash
git clone <repository-url>
cd cattle_ai
```

2. **Install Dependencies**
```bash
flutter pub get
```

3. **Configure Supabase**

Edit `lib/core/constants/app_constants.dart`:
```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

4. **Run Database Migrations**

Execute the SQL schema in your Supabase SQL editor.

5. **Run Application**
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web
flutter run -d chrome

# Windows
flutter run -d windows

# Linux
flutter run -d linux
```

---

## 📱 Platform Support

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ Linux
- ✅ macOS

---

## 🔒 Security Features

1. Row-Level Security (RLS) in Supabase
2. JWT-based authentication
3. Secure file uploads
4. API key rotation support

---

## 📄 API Documentation

### Authentication
- `POST /auth/signup` - Create new account
- `POST /auth/signin` - Login
- `POST /auth/signout` - Logout
- `POST /auth/reset-password` - Reset password

### Animals
- `GET /animals` - List all animals
- `POST /animals` - Create animal
- `GET /animals/:id` - Get animal details
- `PUT /animals/:id` - Update animal
- `DELETE /animals/:id` - Delete animal

### Movement Data
- `GET /movement-data?animal_id=<id>` - Get movement records
- `POST /movement-data` - Create movement record

### Lameness Records
- `GET /lameness-records?animal_id=<id>` - Get lameness records
- `POST /lameness-records` - Create lameness record

---

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Generate coverage report
flutter test --coverage
```

---

## 📦 Build for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# Windows
flutter build windows --release
```

---

## 📖 User Manual

### Adding an Animal
1. Navigate to Animals tab
2. Tap the '+' floating action button
3. Enter animal details (ID, species, age, etc.)
4. Upload photo (optional)
5. Save

### Monitoring Movement
1. Select an animal from the list
2. View the Movement tab
3. Check daily step count and activity graphs
4. Review movement score and trends

### Lameness Detection
1. Movement data is analyzed automatically
2. View lameness status in animal details
3. Check detection history
4. Review ML confidence scores

### Video Upload
1. Go to Camera tab
2. Record or upload video
3. Select purpose (identification, movement, lameness)
4. Wait for processing
5. View analysis results

---

## 🔮 Future Enhancements

1. **Advanced ML Models**
   - Gait analysis from video
   - Disease prediction
   - Behavior pattern recognition

2. **IoT Hardware Integration**
   - Real sensor data ingestion
   - MQTT protocol support
   - LoRaWAN connectivity

3. **Multi-Farm Management**
   - Farm organization hierarchy
   - Staff access controls
   - Aggregate analytics

4. **Mobile Notifications**
   - Push alerts for critical events
   - Daily health summaries
   - Vaccination reminders

5. **Export & Reporting**
   - PDF health reports
   - Excel data export
   - Custom report builder

---

## 📞 Support & Contact

For questions or issues, please contact:
- Email: support@cattleai.com
- GitHub Issues: <repository-url>/issues

---

## 📄 License

[Specify your license here]

---

## 👥 Contributors

- Lead Developer: [Your Name]
- ML Engineer: [Name]
- UI/UX Designer: [Name]

---

**Last Updated**: January 9, 2026
**Version**: 1.0.0
