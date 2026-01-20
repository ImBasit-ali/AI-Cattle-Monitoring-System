import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../services/camera_detection_service.dart';
import '../../services/video_processing_service.dart';

/// Video Upload Screen
/// Allows users to upload videos when cameras are not available
class VideoUploadScreen extends StatefulWidget {
  const VideoUploadScreen({super.key});

  @override
  State<VideoUploadScreen> createState() => _VideoUploadScreenState();
}

class _VideoUploadScreenState extends State<VideoUploadScreen> {
  final _cameraService = CameraDetectionService.instance;
  final _videoService = VideoProcessingService.instance;

  File? _selectedVideo;
  String _selectedZone = 'Milking Parlor';
  String _cattleId = '';
  int? _cameraNumber;
  bool _isProcessing = false;

  final List<String> _zones = [
    'Milking Parlor',
    'Return Lane',
    'Feeding Area',
    'Resting Space',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload & Process Video'),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCameraStatusCard(),
            const SizedBox(height: 20),
            _buildVideoUploadCard(),
            const SizedBox(height: 20),
            if (_selectedVideo != null) ...[
              _buildVideoDetailsCard(),
              const SizedBox(height: 20),
              _buildProcessingOptionsCard(),
              const SizedBox(height: 20),
            ],
            if (_isProcessing) _buildProcessingProgress(),
            if (!_isProcessing && _selectedVideo != null) _buildProcessButton(),
          ],
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
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Camera Status',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _cameraService.hasAvailableCameras
                    ? AppTheme.greenCard.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _cameraService.hasAvailableCameras
                        ? Icons.check_circle
                        : Icons.warning,
                    color: _cameraService.hasAvailableCameras
                        ? AppTheme.greenCard
                        : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _cameraService.hasAvailableCameras
                          ? '${_cameraService.availableCameras.length} camera(s) detected'
                          : 'No cameras detected. Upload video instead.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!_cameraService.isInitialized) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _detectCameras,
                icon: const Icon(Icons.search),
                label: const Text('Detect Cameras'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVideoUploadCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Video',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedVideo == null)
              InkWell(
                onTap: _pickVideo,
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.primaryTeal, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    color: AppTheme.primaryTeal.withValues(alpha: 0.05),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_upload,
                        size: 64,
                        color: AppTheme.primaryTeal,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tap to select video',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Supported formats: MP4, MOV, AVI',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_selectedVideo != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.greenCard.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.greenCard),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedVideo!.path.split('/').last,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Size: ${(_selectedVideo!.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedVideo = null;
                        });
                      },
                      icon: const Icon(Icons.close),
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoDetailsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Video Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Cattle ID',
                hintText: 'Enter cattle ID (e.g., A-001)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.pets),
              ),
              onChanged: (value) {
                setState(() {
                  _cattleId = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingOptionsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Processing Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedZone,
              decoration: InputDecoration(
                labelText: 'Functional Zone',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.location_on),
              ),
              items: _zones.map((zone) {
                return DropdownMenuItem(
                  value: zone,
                  child: Text(zone),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedZone = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Camera Number (Optional)',
                hintText: 'e.g., 1 for Camera 1',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.videocam),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _cameraNumber = int.tryParse(value);
                });
              },
            ),
            const SizedBox(height: 16),
            _buildAIFunctionsInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildAIFunctionsInfo() {
    List<Map<String, dynamic>> functions = [];
    
    switch (_selectedZone) {
      case 'Milking Parlor':
        functions = [
          {'name': 'Ear-Tag Recognition', 'accuracy': '94.00%', 'model': 'CRAFT + ResNet18'},
          {'name': 'Face Identification', 'accuracy': '93.66%', 'model': 'ArcFace'},
        ];
        break;
      case 'Return Lane':
        functions = [
          {'name': 'Lameness Detection', 'accuracy': '88.88%', 'model': 'Detectron2 + SVM'},
          {'name': 'BCS Prediction', 'accuracy': '86.21%', 'model': 'Random Forest'},
          {'name': 'Point Cloud ID', 'accuracy': '99.55%', 'model': 'PointNet++'},
        ];
        break;
      case 'Feeding Area':
        functions = [
          {'name': 'Face Identification', 'accuracy': '93.66%', 'model': 'ArcFace'},
          {'name': 'Feeding Time', 'accuracy': 'High', 'model': 'Frame Tracking'},
        ];
        break;
      case 'Resting Space':
        functions = [
          {'name': 'Body Identification', 'accuracy': '92.80%', 'model': 'ResNet-101'},
          {'name': 'Localization', 'accuracy': 'High', 'model': 'ByteTrack'},
        ];
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.blueCard.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science, color: AppTheme.blueCard),
              const SizedBox(width: 8),
              const Text(
                'AI Functions for this Zone:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...functions.map((func) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.greenCard, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          func['name'],
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${func['model']} • ${func['accuracy']}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProcessingProgress() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _videoService.currentTask,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(_videoService.progress * 100).toInt()}% complete',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _videoService.progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryTeal),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessButton() {
    return ElevatedButton(
      onPressed: _cattleId.isEmpty ? null : _processVideo,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        disabledBackgroundColor: Colors.grey,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_arrow),
          SizedBox(width: 8),
          Text(
            'Process Video',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _detectCameras() async {
    await _cameraService.detectCameras();
    setState(() {});
  }

  Future<void> _pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedVideo = File(result.files.first.path!);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking video: $e')),
        );
      }
    }
  }

  Future<void> _processVideo() async {
    if (_selectedVideo == null || _cattleId.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    final result = await _videoService.processVideo(
      videoFile: _selectedVideo!,
      cattleId: _cattleId,
      functionalZone: _selectedZone,
      cameraNumber: _cameraNumber,
    );

    setState(() {
      _isProcessing = false;
    });

    if (mounted) {
      if (result.success) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.greenCard),
                const SizedBox(width: 12),
                const Text('Processing Complete'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.message,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryTeal.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.sync, color: AppTheme.primaryTeal, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Real-Time Update Triggered ✓',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryTeal,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Dashboard & all screens updating automatically',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildResultsSummary(result),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Return to previous screen
                },
                child: const Text('Close'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildResultsSummary(VideoProcessingResult result) {
    List<Widget> results = [];

    // Animal Detection Summary
    results.add(_buildInfoCard(
      'Animal Detection',
      'Total: ${result.totalAnimalsDetected} | Cattle: ${result.cattleCount} | Buffalo: ${result.buffaloCount}',
      Icons.pets,
      AppTheme.primaryTeal,
    ));
    
    // Milking Status
    results.add(_buildInfoCard(
      'Milking Status',
      result.isMilking ? 'Currently Milking' : 'Not Milking',
      Icons.water_drop,
      result.isMilking ? AppTheme.greenCard : Colors.grey,
    ));
    
    // Lameness Assessment
    results.add(_buildInfoCard(
      'Lameness',
      '${result.lamenessSeverity} (Score: ${result.lamenessScore})',
      Icons.directions_walk,
      result.isLame ? AppTheme.errorRed : AppTheme.greenCard,
    ));

    if (result.earTagRecord != null) {
      results.add(_buildResultItem(
        'Ear-Tag',
        result.earTagRecord!.earTagNumber ?? 'N/A',
        result.earTagRecord!.confidence,
      ));
    }
    if (result.faceIdentificationRecord != null) {
      results.add(_buildResultItem(
        'Face ID',
        'Identified',
        result.faceIdentificationRecord!.confidence,
      ));
    }
    if (result.bcsRecord != null) {
      results.add(_buildResultItem(
        'BCS Score',
        result.bcsRecord!.bcsScore.toStringAsFixed(1),
        result.bcsRecord!.bcsConfidence,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: results,
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(String label, String value, double confidence) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(confidence * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.greenCard,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
