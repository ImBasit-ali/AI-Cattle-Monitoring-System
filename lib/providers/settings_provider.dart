import 'package:flutter/foundation.dart';
import '../services/settings_service.dart';

/// Settings Provider - Manages app settings with reactive updates
class SettingsProvider with ChangeNotifier {
  final SettingsService _settingsService = SettingsService.instance;

  // ==================== NOTIFICATION SETTINGS ====================

  bool get enableNotifications => _settingsService.enableNotifications;
  bool get lamenessAlerts => _settingsService.lamenessAlerts;
  bool get milkingAlerts => _settingsService.milkingAlerts;
  bool get healthAlerts => _settingsService.healthAlerts;

  Future<void> setEnableNotifications(bool value) async {
    await _settingsService.setEnableNotifications(value);
    notifyListeners();
  }

  Future<void> setLamenessAlerts(bool value) async {
    await _settingsService.setLamenessAlerts(value);
    notifyListeners();
  }

  Future<void> setMilkingAlerts(bool value) async {
    await _settingsService.setMilkingAlerts(value);
    notifyListeners();
  }

  Future<void> setHealthAlerts(bool value) async {
    await _settingsService.setHealthAlerts(value);
    notifyListeners();
  }

  // ==================== AI DETECTION SETTINGS ====================

  double get detectionConfidence => _settingsService.detectionConfidence;
  bool get autoProcessVideos => _settingsService.autoProcessVideos;
  bool get saveProcessedVideos => _settingsService.saveProcessedVideos;

  Future<void> setDetectionConfidence(double value) async {
    await _settingsService.setDetectionConfidence(value);
    notifyListeners();
  }

  Future<void> setAutoProcessVideos(bool value) async {
    await _settingsService.setAutoProcessVideos(value);
    notifyListeners();
  }

  Future<void> setSaveProcessedVideos(bool value) async {
    await _settingsService.setSaveProcessedVideos(value);
    notifyListeners();
  }

  // ==================== CAMERA SETTINGS ====================

  int get cameraFPS => _settingsService.cameraFPS;
  String get videoQuality => _settingsService.videoQuality;

  Future<void> setCameraFPS(int value) async {
    await _settingsService.setCameraFPS(value);
    notifyListeners();
  }

  Future<void> setVideoQuality(String value) async {
    await _settingsService.setVideoQuality(value);
    notifyListeners();
  }

  // ==================== DATA & SYNC SETTINGS ====================

  bool get autoSync => _settingsService.autoSync;
  int get dataSyncInterval => _settingsService.dataSyncInterval;
  bool get wifiOnly => _settingsService.wifiOnly;

  Future<void> setAutoSync(bool value) async {
    await _settingsService.setAutoSync(value);
    notifyListeners();
  }

  Future<void> setDataSyncInterval(int value) async {
    await _settingsService.setDataSyncInterval(value);
    notifyListeners();
  }

  Future<void> setWifiOnly(bool value) async {
    await _settingsService.setWifiOnly(value);
    notifyListeners();
  }

  // ==================== DISPLAY SETTINGS ====================

  bool get darkMode => _settingsService.darkMode;
  String get language => _settingsService.language;

  Future<void> setDarkMode(bool value) async {
    await _settingsService.setDarkMode(value);
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    await _settingsService.setLanguage(value);
    notifyListeners();
  }

  // ==================== UTILITY METHODS ====================

  /// Reset all settings to default
  Future<void> resetToDefault() async {
    await _settingsService.resetToDefault();
    notifyListeners();
  }

  /// Check if notifications should be shown for a specific type
  bool shouldShowNotification(String type) {
    return _settingsService.shouldShowNotification(type);
  }

  /// Get video quality as integer (for backend)
  int getVideoQualityAsInt() {
    return _settingsService.getVideoQualityAsInt();
  }
}
