import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

/// Python Backend API Service - Connects Flutter app to FastAPI backend for ML operations
class PythonBackendService {
  static PythonBackendService? _instance;
  
  // Backend URL - Update this with your deployed backend URL
  static const String baseUrl = 'http://localhost:8000';
  static const String wsUrl = 'ws://localhost:8000';
  
  PythonBackendService._internal();
  
  static PythonBackendService get instance {
    _instance ??= PythonBackendService._internal();
    return _instance!;
  }
  
  // ==================== HEALTH CHECK ====================
  
  /// Check if backend is online
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Backend health check failed: $e');
      return false;
    }
  }
  
  /// Get detailed health status
  Future<Map<String, dynamic>> getHealthStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'status': 'offline'};
    } catch (e) {
      debugPrint('Get health status error: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }
  
  // ==================== DETECTION ====================
  
  /// Detect animals in an image
  Future<Map<String, dynamic>> detectAnimals(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/detect'),
      );
      
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Detection failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Detection error: $e');
      rethrow;
    }
  }
  
  /// Detect animals in an image from bytes
  Future<Map<String, dynamic>> detectAnimalsFromBytes(
    Uint8List imageBytes,
    String filename,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/detect'),
      );
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: filename,
        ),
      );
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Detection failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Detection error: $e');
      rethrow;
    }
  }
  
  /// Process video for detection and tracking
  Future<Map<String, dynamic>> processVideo(File videoFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/detect-video'),
      );
      
      request.files.add(
        await http.MultipartFile.fromPath('file', videoFile.path),
      );
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Video processing failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Video processing error: $e');
      rethrow;
    }
  }
  
  // ==================== TRACKING ====================
  
  /// Get tracking statistics
  Future<Map<String, dynamic>> getTrackingStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/tracking/stats'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get tracking stats');
      }
    } catch (e) {
      debugPrint('Tracking stats error: $e');
      rethrow;
    }
  }
  
  /// Get all tracked animals
  Future<Map<String, dynamic>> getTrackedAnimals() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/tracking/animals'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get tracked animals');
      }
    } catch (e) {
      debugPrint('Get tracked animals error: $e');
      rethrow;
    }
  }
  
  // ==================== MILKING DETECTION ====================
  
  /// Detect milking status from image
  Future<Map<String, dynamic>> detectMilkingStatus(
    File imageFile, {
    String? animalId,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/api/milking/detect');
      if (animalId != null) {
        uri = uri.replace(queryParameters: {'animal_id': animalId});
      }
      
      var request = http.MultipartRequest('POST', uri);
      
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Milking detection failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Milking detection error: $e');
      rethrow;
    }
  }
  
  // ==================== LAMENESS DETECTION ====================
  
  /// Detect lameness from video
  Future<Map<String, dynamic>> detectLameness(
    File videoFile, {
    String? animalId,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/api/lameness/detect');
      if (animalId != null) {
        uri = uri.replace(queryParameters: {'animal_id': animalId});
      }
      
      var request = http.MultipartRequest('POST', uri);
      
      request.files.add(
        await http.MultipartFile.fromPath('file', videoFile.path),
      );
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Lameness detection failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Lameness detection error: $e');
      rethrow;
    }
  }
  
  // ==================== STATISTICS ====================
  
  /// Get daily statistics
  Future<Map<String, dynamic>> getDailyStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/stats/daily'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get daily stats');
      }
    } catch (e) {
      debugPrint('Daily stats error: $e');
      rethrow;
    }
  }
  
  /// Get health statistics
  Future<Map<String, dynamic>> getHealthStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/stats/health'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get health stats');
      }
    } catch (e) {
      debugPrint('Health stats error: $e');
      rethrow;
    }
  }
  
  // ==================== REAL-TIME CAMERA STREAM ====================
  
  /// Connect to camera stream via WebSocket
  WebSocketChannel connectToCameraStream(String cameraId) {
    final wsUri = Uri.parse('$wsUrl/ws/camera/$cameraId');
    return WebSocketChannel.connect(wsUri);
  }
  
  /// Stream camera feed with real-time detection
  Stream<Map<String, dynamic>> streamCamera(String cameraId) async* {
    try {
      final channel = connectToCameraStream(cameraId);
      
      await for (final message in channel.stream) {
        if (message is String) {
          yield json.decode(message);
        }
      }
    } catch (e) {
      debugPrint('Camera stream error: $e');
      rethrow;
    }
  }
}
