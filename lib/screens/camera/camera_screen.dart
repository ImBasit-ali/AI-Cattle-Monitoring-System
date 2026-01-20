import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/camera_detection_service.dart';
import '../video/video_upload_screen.dart';
import '../dashboard/dashboard_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with AutomaticKeepAliveClientMixin {
  final _cameraService = CameraDetectionService.instance;
  bool _isDetecting = false;

  @override
  bool get wantKeepAlive => true; // Keep screen alive when navigating away

  @override
  void initState() {
    super.initState();
    _detectCameras();
  }

  Future<void> _detectCameras() async {
    setState(() {
      _isDetecting = true;
    });

    await _cameraService.detectCameras();

    if (mounted) {
      setState(() {
        _isDetecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: Colors.grey[50],
    appBar: AppBar(
  leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const DashboardScreen(),
        ),
      );
    },
  ),
  title: const Text('Screen Title Here'),
  actions: [
    IconButton(
      icon: const Icon(Icons.search),
      onPressed: () {},
    ),
  ],
),
      body: _isDetecting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Detecting cameras...'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _detectCameras,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCameraStatusCard(),
                    const SizedBox(height: 20),
                    if (_cameraService.hasAvailableCameras) ...[
                      _buildAvailableCamerasSection(),
                      const SizedBox(height: 20),
                    ],
                    _buildVideoUploadCard(),
                    const SizedBox(height: 20),
                    _buildSystemInfoCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCameraStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _cameraService.hasAvailableCameras
                      ? Icons.videocam
                      : Icons.videocam_off,
                  color: _cameraService.hasAvailableCameras
                      ? AppTheme.greenCard
                      : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Camera System Status',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _cameraService.hasAvailableCameras
                            ? '${_cameraService.availableCameras.length} camera(s) detected'
                            : 'No cameras detected',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cameraService.hasAvailableCameras
                    ? AppTheme.greenCard.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _cameraService.hasAvailableCameras
                      ? AppTheme.greenCard
                      : Colors.orange,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _cameraService.hasAvailableCameras
                        ? Icons.check_circle
                        : Icons.info,
                    color: _cameraService.hasAvailableCameras
                        ? AppTheme.greenCard
                        : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _cameraService.hasAvailableCameras
                          ? 'Real-time camera feed available'
                          : 'Use video upload for processing',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableCamerasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Cameras',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          _cameraService.availableCameras.length,
          (index) {
            final camera = _cameraService.availableCameras[index];
            return _buildCameraCard(camera);
          },
        ),
      ],
    );
  }

  Widget _buildCameraCard(CameraDevice camera) {
    IconData cameraIcon;
    Color cameraColor;

    switch (camera.type) {
      case CameraType.ipCamera:
        cameraIcon = Icons.camera_outdoor;
        cameraColor = AppTheme.blueCard;
        break;
      case CameraType.rgbdCamera:
        cameraIcon = Icons.camera_enhance;
        cameraColor = AppTheme.greenCard;
        break;
      case CameraType.depthCamera:
        cameraIcon = Icons.threed_rotation;
        cameraColor = const Color(0xFFFF6B9D);
        break;
      default:
        cameraIcon = Icons.videocam;
        cameraColor = AppTheme.primaryTeal;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cameraColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(cameraIcon, color: cameraColor, size: 28),
        ),
        title: Text(
          camera.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (camera.functionalZone != null)
              Text(
                'Zone: ${camera.functionalZone}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            if (camera.cameraNumber != null)
              Text(
                'Camera #${camera.cameraNumber}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: camera.isAvailable
                ? AppTheme.greenCard.withValues(alpha: 0.2)
                : Colors.red.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            camera.isAvailable ? 'Active' : 'Offline',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: camera.isAvailable ? AppTheme.greenCard : Colors.red,
            ),
          ),
        ),
        onTap: () {
          // In production, open camera stream view
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Camera stream: ${camera.name}'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoUploadCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VideoUploadScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.cloud_upload,
                  size: 32,
                  color: AppTheme.primaryTeal,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upload & Process Video',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Extract cattle health data from video files',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.blueCard),
                const SizedBox(width: 12),
                const Text(
                  'System Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Total Expected Cameras', '22'),
            _buildInfoRow('System Latency', '0.62s avg'),
            _buildInfoRow('Supported Zones', '4'),
            _buildInfoRow('AI Functions', '5'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No cameras? Upload videos to extract health data using AI.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }



}