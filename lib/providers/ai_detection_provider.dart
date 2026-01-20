import 'package:flutter/foundation.dart';
import 'dart:io';
import '../services/python_backend_service.dart';

class AIDetectionProvider with ChangeNotifier {
  final _backendService = PythonBackendService.instance;
  
  bool _isBackendOnline = false;
  bool _isDetecting = false;
  List<Map<String, dynamic>> _detections = [];
  Map<String, dynamic>? _trackingStats;
  List<Map<String, dynamic>> _trackedAnimals = [];
  Map<String, dynamic>? _healthStats;
  
  // Getters
  bool get isBackendOnline => _isBackendOnline;
  bool get isDetecting => _isDetecting;
  List<Map<String, dynamic>> get detections => _detections;
  Map<String, dynamic>? get trackingStats => _trackingStats;
  List<Map<String, dynamic>> get trackedAnimals => _trackedAnimals;
  Map<String, dynamic>? get healthStats => _healthStats;

  /// Clear all detection data (call on logout)
  void clearData() {
    _detections = [];
    _trackingStats = null;
    _trackedAnimals = [];
    _healthStats = null;
    _isDetecting = false;
    notifyListeners();
    debugPrint('🧹 AIDetectionProvider: Data cleared');
  }
  
  /// Check backend health
  Future<void> checkBackendHealth() async {
    try {
      _isBackendOnline = await _backendService.checkHealth();
      notifyListeners();
    } catch (e) {
      _isBackendOnline = false;
      notifyListeners();
      debugPrint('Backend health check error: $e');
    }
  }
  
  /// Detect animals in image
  Future<Map<String, dynamic>> detectAnimals(File imageFile) async {
    _isDetecting = true;
    notifyListeners();
    
    try {
      final result = await _backendService.detectAnimals(imageFile);
      
      if (result['success'] == true) {
        _detections = List<Map<String, dynamic>>.from(result['detections'] ?? []);
      }
      
      return result;
    } catch (e) {
      debugPrint('Detection error: $e');
      rethrow;
    } finally {
      _isDetecting = false;
      notifyListeners();
    }
  }
  
  /// Process video for detection and tracking
  Future<Map<String, dynamic>> processVideo(File videoFile) async {
    _isDetecting = true;
    notifyListeners();
    
    try {
      final result = await _backendService.processVideo(videoFile);
      return result;
    } catch (e) {
      debugPrint('Video processing error: $e');
      rethrow;
    } finally {
      _isDetecting = false;
      notifyListeners();
    }
  }
  
  /// Get tracking statistics
  Future<void> fetchTrackingStats() async {
    try {
      final result = await _backendService.getTrackingStats();
      
      if (result['success'] == true) {
        _trackingStats = result['stats'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Tracking stats error: $e');
    }
  }
  
  /// Get tracked animals
  Future<void> fetchTrackedAnimals() async {
    try {
      final result = await _backendService.getTrackedAnimals();
      
      if (result['success'] == true) {
        _trackedAnimals = List<Map<String, dynamic>>.from(result['animals'] ?? []);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Fetch tracked animals error: $e');
    }
  }
  
  /// Detect milking status
  Future<Map<String, dynamic>> detectMilkingStatus(
    File imageFile, {
    String? animalId,
  }) async {
    _isDetecting = true;
    notifyListeners();
    
    try {
      final result = await _backendService.detectMilkingStatus(
        imageFile,
        animalId: animalId,
      );
      
      return result;
    } catch (e) {
      debugPrint('Milking detection error: $e');
      rethrow;
    } finally {
      _isDetecting = false;
      notifyListeners();
    }
  }
  
  /// Detect lameness
  Future<Map<String, dynamic>> detectLameness(
    File videoFile, {
    String? animalId,
  }) async {
    _isDetecting = true;
    notifyListeners();
    
    try {
      final result = await _backendService.detectLameness(
        videoFile,
        animalId: animalId,
      );
      
      return result;
    } catch (e) {
      debugPrint('Lameness detection error: $e');
      rethrow;
    } finally {
      _isDetecting = false;
      notifyListeners();
    }
  }
  
  /// Get health statistics
  Future<void> fetchHealthStats() async {
    try {
      final result = await _backendService.getHealthStats();
      
      if (result['success'] == true) {
        _healthStats = result['health'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Health stats error: $e');
    }
  }
  
  /// Clear detections
  void clearDetections() {
    _detections = [];
    notifyListeners();
  }
  
  /// Refresh all data
  Future<void> refreshAllData() async {
    await Future.wait([
      checkBackendHealth(),
      fetchTrackingStats(),
      fetchTrackedAnimals(),
      fetchHealthStats(),
    ]);
  }
}
