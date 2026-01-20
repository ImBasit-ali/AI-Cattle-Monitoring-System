import 'dart:io';
import 'package:flutter/foundation.dart';

/// Camera Detection Service
/// Detects available cameras and provides camera status information
class CameraDetectionService {
  static final CameraDetectionService _instance = CameraDetectionService._internal();
  factory CameraDetectionService() => _instance;
  CameraDetectionService._internal();

  static CameraDetectionService get instance => _instance;

  List<CameraDevice> _availableCameras = [];
  bool _isInitialized = false;

  List<CameraDevice> get availableCameras => _availableCameras;
  bool get hasAvailableCameras => _availableCameras.isNotEmpty;
  bool get isInitialized => _isInitialized;

  /// Initialize and detect available cameras (IoT-based only)
  /// Excludes mobile device cameras, only detects IP cameras, USB cameras, and depth cameras
  Future<List<CameraDevice>> detectCameras() async {
    try {
      _availableCameras.clear();

      // Only detect IoT-based cameras on desktop platforms
      // Mobile cameras are excluded - use video upload instead
      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        // Desktop platforms - check for IoT video devices (USB cameras, IP cameras)
        _availableCameras = await _detectDesktopCameras();
      } else if (kIsWeb) {
        // Web platform - check for IoT camera access only
        _availableCameras = await _detectWebCameras();
      }
      // Note: Mobile platforms (Android/iOS) intentionally excluded
      // Users should use video upload feature instead

      _isInitialized = true;
      return _availableCameras;
    } catch (e) {
      debugPrint('Error detecting cameras: $e');
      _isInitialized = true;
      return [];
    }
  }

  /// Detect IP cameras on network
  Future<List<CameraDevice>> detectIPCameras(List<String> ipAddresses) async {
    List<CameraDevice> ipCameras = [];

    for (int i = 0; i < ipAddresses.length; i++) {
      try {
        final camera = CameraDevice(
          id: 'ip_camera_$i',
          name: 'IP Camera ${i + 1}',
          type: CameraType.ipCamera,
          streamUrl: ipAddresses[i],
          isAvailable: await _checkIPCameraAvailability(ipAddresses[i]),
          cameraNumber: i + 1,
          functionalZone: _assignZone(i + 1),
        );
        ipCameras.add(camera);
      } catch (e) {
        debugPrint('Error checking IP camera ${ipAddresses[i]}: $e');
      }
    }

    return ipCameras;
  }

  /// Check specific camera availability
  Future<bool> isCameraAvailable(String cameraId) async {
    final camera = _availableCameras.firstWhere(
      (cam) => cam.id == cameraId,
      orElse: () => CameraDevice(
        id: '',
        name: '',
        type: CameraType.unknown,
        isAvailable: false,
      ),
    );
    return camera.isAvailable;
  }

  /// Get camera by functional zone
  List<CameraDevice> getCamerasByZone(String zone) {
    return _availableCameras.where((cam) => cam.functionalZone == zone).toList();
  }

  /// Get camera by camera number (1-22 from research)
  CameraDevice? getCameraByNumber(int cameraNumber) {
    try {
      return _availableCameras.firstWhere(
        (cam) => cam.cameraNumber == cameraNumber,
      );
    } catch (e) {
      return null;
    }
  }

  // Private methods for platform-specific detection

  Future<List<CameraDevice>> _detectWebCameras() async {
    // Simulated web camera detection
    // In production, use JavaScript interop to detect WebRTC devices
    return [];
  }

  Future<List<CameraDevice>> _detectDesktopCameras() async {
    // Simulated desktop camera detection
    List<CameraDevice> cameras = [];

    if (Platform.isLinux) {
      // Check /dev/video* devices
      cameras = await _detectLinuxCameras();
    } else if (Platform.isWindows) {
      // Check Windows DirectShow devices
      cameras = await _detectWindowsCameras();
    } else if (Platform.isMacOS) {
      // Check macOS AVFoundation devices
      cameras = await _detectMacOSCameras();
    }

    return cameras;
  }

  Future<List<CameraDevice>> _detectLinuxCameras() async {
    List<CameraDevice> cameras = [];
    
    try {
      // Check for /dev/video* devices
      final devDir = Directory('/dev');
      if (await devDir.exists()) {
        final videoDevices = devDir
            .listSync()
            .where((entity) => entity.path.contains('video'))
            .toList();

        for (int i = 0; i < videoDevices.length; i++) {
          cameras.add(CameraDevice(
            id: 'linux_video_$i',
            name: 'Video Device $i',
            type: CameraType.usbWebcam,
            devicePath: videoDevices[i].path,
            isAvailable: true,
            cameraNumber: i + 1,
            functionalZone: _assignZone(i + 1),
          ));
        }
      }
    } catch (e) {
      debugPrint('Error detecting Linux cameras: $e');
    }

    return cameras;
  }

  Future<List<CameraDevice>> _detectWindowsCameras() async {
    // In production, use FFI to call Windows DirectShow API
    return [];
  }

  Future<List<CameraDevice>> _detectMacOSCameras() async {
    // In production, use FFI to call macOS AVFoundation API
    return [];
  }

  Future<bool> _checkIPCameraAvailability(String url) async {
    try {
      // In production, send HTTP request to camera endpoint
      // For now, return true if URL is not empty
      return url.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  String _assignZone(int cameraNumber) {
    // Assign functional zones based on camera number (from research)
    if (cameraNumber >= 1 && cameraNumber <= 2) {
      return 'Milking Parlor';
    } else if (cameraNumber >= 3 && cameraNumber <= 6) {
      return 'Return Lane';
    } else if (cameraNumber >= 7 && cameraNumber <= 10) {
      return 'Feeding Area';
    } else if (cameraNumber >= 11 && cameraNumber <= 23) {
      return 'Resting Space';
    } else {
      return 'Unknown';
    }
  }
}

/// Camera Device Model
class CameraDevice {
  final String id;
  final String name;
  final CameraType type;
  final bool isAvailable;
  final String? streamUrl;
  final String? devicePath;
  final int? cameraNumber;
  final String? functionalZone;
  final String? cameraModel;

  CameraDevice({
    required this.id,
    required this.name,
    required this.type,
    this.isAvailable = false,
    this.streamUrl,
    this.devicePath,
    this.cameraNumber,
    this.functionalZone,
    this.cameraModel,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString(),
      'is_available': isAvailable,
      'stream_url': streamUrl,
      'device_path': devicePath,
      'camera_number': cameraNumber,
      'functional_zone': functionalZone,
      'camera_model': cameraModel,
    };
  }
}

enum CameraType {
  usbWebcam,
  ipCamera,
  rgbCamera,
  depthCamera,
  rgbdCamera,
  tofCamera,
  mobileFront,
  mobileBack,
  unknown,
}
