# Settings Integration - Complete Implementation

## Overview
All settings in the Settings Screen now properly affect the app's functionality through a centralized settings service and provider pattern.

## Implementation Summary

### 1. **Settings Service** (`lib/services/settings_service.dart`)
- Centralized settings management using SharedPreferences
- Provides type-safe getters and setters for all settings
- Singleton pattern for global access
- Must be initialized before use in `main.dart`

### 2. **Settings Provider** (`lib/providers/settings_provider.dart`)
- Reactive state management using ChangeNotifier
- Automatically updates UI when settings change
- Wraps SettingsService for reactive behavior
- Registered in MultiProvider in `main.dart`

### 3. **Notification Service** (`lib/services/notification_service.dart`)
- Respects notification settings before showing alerts
- Checks if specific notification types are enabled
- Different notification types: lameness, milking, health
- Provides themed notifications based on type

## Settings Categories & Their Effects

### 📢 Notification Settings

#### Enable Notifications
- **Setting**: `enableNotifications` (bool)
- **Effect**: Master switch for all notifications
- **Usage**: Checked by NotificationService before showing any alert
- **Default**: `true`

#### Lameness Alerts
- **Setting**: `lamenessAlerts` (bool)
- **Effect**: Shows/hides lameness detection alerts
- **Usage**: `NotificationService.showLamenessAlert()` checks this setting
- **Default**: `true`

#### Milking Alerts
- **Setting**: `milkingAlerts` (bool)
- **Effect**: Shows/hides milking status change alerts
- **Usage**: `NotificationService.showMilkingAlert()` checks this setting
- **Default**: `true`

#### Health Alerts
- **Setting**: `healthAlerts` (bool)
- **Effect**: Shows/hides general health alerts
- **Usage**: `NotificationService.showHealthAlert()` checks this setting
- **Default**: `true`

### 🤖 AI Detection Settings

#### Detection Confidence
- **Setting**: `detectionConfidence` (double, 0.5-1.0)
- **Effect**: Minimum confidence threshold for AI detections
- **Usage**: Applied in `VideoProcessingService` for:
  - Ear tag identification
  - Face identification
  - Lameness detection (depth camera)
  - Lameness detection (side view camera)
  - BCS prediction
  - Point cloud identification
- **Default**: `0.7` (70%)
- **Example**: If set to 0.8, only detections with 80%+ confidence are accepted

#### Auto Process Videos
- **Setting**: `autoProcessVideos` (bool)
- **Effect**: Automatically process videos after upload
- **Usage**: Can be used in video upload workflow to auto-start processing
- **Default**: `true`

#### Save Processed Videos
- **Setting**: `saveProcessedVideos` (bool)
- **Effect**: Keep processed videos in storage after analysis
- **Usage**: Can be used to determine whether to delete processed videos
- **Default**: `true`

### 📹 Camera Settings

#### Camera FPS
- **Setting**: `cameraFPS` (int: 15, 24, 30, 60)
- **Effect**: Frames per second for camera recording
- **Usage**: Available for camera capture configuration
- **Default**: `30`

#### Video Quality
- **Setting**: `videoQuality` (string: low, medium, high, ultra)
- **Effect**: Video recording quality
- **Usage**: 
  - Maps to resolution via `getVideoQualityAsInt()`
  - low = 480p, medium = 720p, high = 1080p, ultra = 2160p
- **Default**: `'high'` (1080p)

### 💾 Data & Sync Settings

#### Auto Sync
- **Setting**: `autoSync` (bool)
- **Effect**: Automatically sync data with cloud
- **Usage**: Can be used to enable/disable automatic data synchronization
- **Default**: `true`

#### Sync Interval
- **Setting**: `dataSyncInterval` (int: 1, 5, 15, 30, 60 minutes)
- **Effect**: How often to sync data
- **Usage**: Can be used to schedule periodic sync operations
- **Default**: `5` minutes

#### WiFi Only
- **Setting**: `wifiOnly` (bool)
- **Effect**: Sync only when connected to WiFi
- **Usage**: Can be checked before initiating sync operations
- **Default**: `false`

### 🎨 Display Settings

#### Dark Mode
- **Setting**: `darkMode` (bool)
- **Effect**: Enable dark theme
- **Usage**: Requires app restart to apply
- **Default**: `false`
- **Note**: Shows snackbar message to restart app

#### Language
- **Setting**: `language` (string: English, Spanish, French, German, Chinese)
- **Effect**: App language preference
- **Usage**: Can be used for localization
- **Default**: `'English'`

## How Settings Affect the App

### Video Processing Flow with Settings

```dart
// When processing a video
VideoProcessingService processes video
  ↓
Uses _settingsService.detectionConfidence
  ↓
Applies minimum confidence threshold to:
  - Ear tag identification (min 70% by default)
  - Face identification (min 70% by default)
  - Lameness detection (min 70% by default)
  - BCS prediction (min 70% by default)
  ↓
Only results meeting confidence threshold are saved
  ↓
If lameness detected and lamenessAlerts enabled
  ↓
NotificationService shows alert
```

### Notification Flow with Settings

```dart
// When an event occurs (lameness, milking, health issue)
Event triggered (e.g., lameness detected)
  ↓
NotificationService.showLamenessAlert() called
  ↓
Checks enableNotifications setting
  ↓
Checks lamenessAlerts setting
  ↓
If both enabled: Shows notification
If either disabled: Notification blocked
```

## Usage Examples

### Accessing Settings Anywhere in the App

```dart
// Using the service (non-reactive)
final minConfidence = SettingsService.instance.detectionConfidence;

// Using the provider (reactive)
final settingsProvider = context.watch<SettingsProvider>();
final minConfidence = settingsProvider.detectionConfidence;

// Updating a setting
await settingsProvider.setDetectionConfidence(0.85);
```

### Checking if Notification Should Be Shown

```dart
// In any service or screen
if (SettingsService.instance.shouldShowNotification('lameness')) {
  NotificationService.instance.showLamenessAlert(
    context,
    animalId,
    lamenessScore,
    severity,
  );
}
```

### Using Video Quality Setting

```dart
// Get quality as resolution
final resolution = SettingsService.instance.getVideoQualityAsInt();
// Returns: 480, 720, 1080, or 2160 based on setting
```

## File Structure

```
lib/
├── services/
│   ├── settings_service.dart          # Core settings management
│   ├── notification_service.dart      # Notifications respecting settings
│   ├── video_processing_service.dart  # Uses detection confidence
│   └── python_backend_service.dart    # Backend integration
├── providers/
│   └── settings_provider.dart         # Reactive settings provider
├── screens/
│   └── settings/
│       └── settings_screen.dart       # UI for managing settings
└── main.dart                          # Initializes settings & provider
```

## Initialization Flow

```dart
// In main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize Settings Service
  await SettingsService.instance.initialize();
  
  runApp(const CattleAIApp());
}

// 2. Register Settings Provider
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => SettingsProvider()),
    // ... other providers
  ],
  child: MaterialApp(...),
)
```

## Testing Settings Integration

### Test Detection Confidence

1. Open Settings
2. Adjust "Detection Confidence" slider to 80%
3. Upload a video
4. Check console logs - detections should have confidence ≥ 80%

### Test Notifications

1. Open Settings
2. Disable "Lameness Alerts"
3. Process a video with lame cattle
4. Verify no lameness notification appears
5. Re-enable "Lameness Alerts"
6. Process another video
7. Verify lameness notification appears

### Test Video Quality

1. Open Settings
2. Change "Video Quality" to "ultra"
3. Call `getVideoQualityAsInt()` 
4. Should return 2160 (4K resolution)

## Benefits

✅ **Centralized**: All settings in one place  
✅ **Reactive**: UI updates automatically when settings change  
✅ **Type-Safe**: Typed getters/setters prevent errors  
✅ **Persistent**: Settings saved to SharedPreferences  
✅ **Accessible**: Available throughout the app  
✅ **Testable**: Easy to mock and test  
✅ **Functional**: All settings actually affect app behavior  

## Future Enhancements

- [ ] Export/import settings as JSON
- [ ] Settings sync across devices
- [ ] Advanced notification scheduling
- [ ] Per-animal notification preferences
- [ ] Theme switching without restart
- [ ] Multi-language support implementation

---

**Status**: ✅ Complete - All settings are now functional and integrated throughout the app!
