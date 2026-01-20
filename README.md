# Cattle AI Monitor 🐄📱

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase)](https://supabase.com)

> **IoT-Based Cattle Monitoring System** with AI-powered lameness detection, real-time movement analysis, and comprehensive health tracking.

---

## ✨ Key Features

- 🐄 **Animal Identification** - Unique tracking with QR/RFID ready
- 📊 **Movement Analysis** - Real-time activity monitoring with IoT simulation
- 🤖 **AI Lameness Detection** - Rule-based + ML neural network
- 📸 **Video Processing** - Upload and analyze cattle movement
- 📈 **Interactive Charts** - Daily/weekly trends visualization
- 🌐 **Multi-Platform** - Android, iOS, Web, Windows, Linux, macOS
- 🎨 **Professional UI** - Glassy design with smooth animations

---

## 🚀 Quick Start

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Configure Supabase
Edit `lib/core/constants/app_constants.dart`:
```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### 3. Setup Database
Run `supabase_schema.sql` in Supabase SQL Editor

### 4. Run Application
```bash
flutter run
```

---

## 📚 Documentation

- [Complete Documentation](PROJECT_DOCUMENTATION.md)
- [ML Pipeline Guide](ML_DOCUMENTATION.md)
- [Database Schema](supabase_schema.sql)

---

## 🏗️ Architecture

```
lib/
├── core/          # Constants, theme, utilities
├── models/        # Data models
├── services/      # Supabase, ML services
├── providers/     # State management
├── screens/       # UI screens
└── main.dart      # Entry point
```

---

## 🔧 Tech Stack

- **Frontend**: Flutter, Provider
- **Backend**: Supabase (Auth, DB, Storage)
- **ML**: TensorFlow Lite
- **Charts**: FL Chart, Syncfusion
- **Camera**: Flutter Camera Plugin

---

**Made with ❤️ for cattle welfare and farming innovation**
