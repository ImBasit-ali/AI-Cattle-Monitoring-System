import 'package:shared_preferences/shared_preferences.dart';

/// Settings Service - Centralized settings management
/// Provides access to app settings from anywhere in the app
class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static SettingsService get instance => _instance;

  SharedPreferences? _prefs;

  /// Initialize the settings service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('SettingsService not initialized. Call initialize() first.');
    }
    return _prefs!;
  }

  // ==================== NOTIFICATION SETTINGS ====================

  bool get enableNotifications => prefs.getBool('enableNotifications') ?? true;
  bool get lamenessAlerts => prefs.getBool('lamenessAlerts') ?? true;
  bool get milkingAlerts => prefs.getBool('milkingAlerts') ?? true;
  bool get healthAlerts => prefs.getBool('healthAlerts') ?? true;

  Future<void> setEnableNotifications(bool value) async {
    await prefs.setBool('enableNotifications', value);
  }

  Future<void> setLamenessAlerts(bool value) async {
    await prefs.setBool('lamenessAlerts', value);
  }

  Future<void> setMilkingAlerts(bool value) async {
    await prefs.setBool('milkingAlerts', value);
  }

  Future<void> setHealthAlerts(bool value) async {
    await prefs.setBool('healthAlerts', value);
  }

  // ==================== AI DETECTION SETTINGS ====================

  double get detectionConfidence => prefs.getDouble('detectionConfidence') ?? 0.7;
  bool get autoProcessVideos => prefs.getBool('autoProcessVideos') ?? true;
  bool get saveProcessedVideos => prefs.getBool('saveProcessedVideos') ?? true;

  Future<void> setDetectionConfidence(double value) async {
    await prefs.setDouble('detectionConfidence', value);
  }

  Future<void> setAutoProcessVideos(bool value) async {
    await prefs.setBool('autoProcessVideos', value);
  }

  Future<void> setSaveProcessedVideos(bool value) async {
    await prefs.setBool('saveProcessedVideos', value);
  }

  // ==================== CAMERA SETTINGS ====================

  int get cameraFPS => prefs.getInt('cameraFPS') ?? 30;
  String get videoQuality => prefs.getString('videoQuality') ?? 'high';

  Future<void> setCameraFPS(int value) async {
    await prefs.setInt('cameraFPS', value);
  }

  Future<void> setVideoQuality(String value) async {
    await prefs.setString('videoQuality', value);
  }

  // ==================== DATA & SYNC SETTINGS ====================

  bool get autoSync => prefs.getBool('autoSync') ?? true;
  int get dataSyncInterval => prefs.getInt('dataSyncInterval') ?? 5;
  bool get wifiOnly => prefs.getBool('wifiOnly') ?? false;

  Future<void> setAutoSync(bool value) async {
    await prefs.setBool('autoSync', value);
  }

  Future<void> setDataSyncInterval(int value) async {
    await prefs.setInt('dataSyncInterval', value);
  }

  Future<void> setWifiOnly(bool value) async {
    await prefs.setBool('wifiOnly', value);
  }

  // ==================== DISPLAY SETTINGS ====================

  bool get darkMode => prefs.getBool('darkMode') ?? false;
  String get language => prefs.getString('language') ?? 'English';

  Future<void> setDarkMode(bool value) async {
    await prefs.setBool('darkMode', value);
  }

  Future<void> setLanguage(String value) async {
    await prefs.setString('language', value);
  }

  // ==================== UTILITY METHODS ====================

  /// Reset all settings to default
  Future<void> resetToDefault() async {
    await prefs.clear();
  }

  /// Get video quality as integer (for backend)
  int getVideoQualityAsInt() {
    switch (videoQuality) {
      case 'low':
        return 480;
      case 'medium':
        return 720;
      case 'high':
        return 1080;
      case 'ultra':
        return 2160;
      default:
        return 1080;
    }
  }

  /// Check if notifications should be shown for a specific type
  bool shouldShowNotification(String type) {
    if (!enableNotifications) return false;

    switch (type.toLowerCase()) {
      case 'lameness':
        return lamenessAlerts;
      case 'milking':
        return milkingAlerts;
      case 'health':
        return healthAlerts;
      default:
        return true;
    }
  }
}
