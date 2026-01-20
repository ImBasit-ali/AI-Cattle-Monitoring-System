import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../providers/ai_detection_provider.dart';
import '../../core/theme/app_theme.dart';

class AIDetectionExampleScreen extends StatefulWidget {
  const AIDetectionExampleScreen({super.key});

  @override
  State<AIDetectionExampleScreen> createState() => _AIDetectionExampleScreenState();
}

class _AIDetectionExampleScreenState extends State<AIDetectionExampleScreen> {
  final _imagePicker = ImagePicker();
  String? _selectedAnimalId;
  
  @override
  void initState() {
    super.initState();
    // Check backend health on startup
    Future.microtask(() {
      if (mounted) {
        Provider.of<AIDetectionProvider>(context, listen: false).checkBackendHealth();
      }
    });
  }
  
  Future<void> _detectAnimals() async {
    final aiProvider = Provider.of<AIDetectionProvider>(context, listen: false);
    
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      try {
        showLoadingDialog('Detecting animals...');
        
        final result = await aiProvider.detectAnimals(File(pickedFile.path));
        
        if (!mounted) return;
        Navigator.pop(context); // Close loading
        
        if (result['success']) {
          _showResultDialog(
            'Detection Complete',
            'Detected ${result['count']} animal(s)',
            Colors.green,
          );
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading
        _showErrorDialog('Detection failed: $e');
      }
    }
  }
  
  Future<void> _detectMilkingStatus() async {
    final aiProvider = Provider.of<AIDetectionProvider>(context, listen: false);
    
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      try {
        showLoadingDialog('Analyzing milking status...');
        
        final result = await aiProvider.detectMilkingStatus(
          File(pickedFile.path),
          animalId: _selectedAnimalId,
        );
        
        if (!mounted) return;
        Navigator.pop(context); // Close loading
        
        if (result['success']) {
          final status = result['status'];
          _showResultDialog(
            'Milking Status',
            'Status: ${status['status']}\nConfidence: ${(status['confidence'] * 100).toStringAsFixed(1)}%',
            Colors.blue,
          );
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading
        _showErrorDialog('Milking detection failed: $e');
      }
    }
  }
  
  Future<void> _detectLameness() async {
    final aiProvider = Provider.of<AIDetectionProvider>(context, listen: false);
    
    final pickedFile = await _imagePicker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 30),
    );
    
    if (pickedFile != null) {
      try {
        showLoadingDialog('Analyzing gait for lameness...\nThis may take a moment.');
        
        final result = await aiProvider.detectLameness(
          File(pickedFile.path),
          animalId: _selectedAnimalId,
        );
        
        if (!mounted) return;
        Navigator.pop(context); // Close loading
        
        if (result['success']) {
          final lameness = result['lameness'];
          final gait = lameness['gait_features'];
          
          _showResultDialog(
            'Lameness Analysis',
            'Level: ${lameness['level']}\n'
            'Confidence: ${(lameness['confidence'] * 100).toStringAsFixed(1)}%\n'
            'Step Symmetry: ${(gait['step_symmetry'] * 100).toStringAsFixed(1)}%\n'
            'Walking Speed: ${gait['walking_speed'].toStringAsFixed(2)}',
            _getLamenessColor(lameness['level']),
          );
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading
        _showErrorDialog('Lameness detection failed: $e');
      }
    }
  }
  
  void showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
  
  void _showResultDialog(String title, String message, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: color),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  Color _getLamenessColor(String level) {
    switch (level.toLowerCase()) {
      case 'normal':
        return Colors.green;
      case 'mild':
        return Colors.orange;
      case 'moderate':
        return Colors.deepOrange;
      case 'severe':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Detection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<AIDetectionProvider>(context, listen: false)
                  .checkBackendHealth();
            },
          ),
        ],
      ),
      body: Consumer<AIDetectionProvider>(
        builder: (context, aiProvider, _) {
          return Column(
            children: [
              // Backend Status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: aiProvider.isBackendOnline 
                    ? Colors.green.shade100 
                    : Colors.red.shade100,
                child: Row(
                  children: [
                    Icon(
                      aiProvider.isBackendOnline 
                          ? Icons.cloud_done 
                          : Icons.cloud_off,
                      color: aiProvider.isBackendOnline 
                          ? Colors.green 
                          : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      aiProvider.isBackendOnline 
                          ? 'AI Backend Online' 
                          : 'AI Backend Offline',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: aiProvider.isBackendOnline 
                            ? Colors.green.shade900 
                            : Colors.red.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: aiProvider.isBackendOnline ? _detectAnimals : null,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Detect Animals (Cow/Buffalo)'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: AppTheme.primaryTeal,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: aiProvider.isBackendOnline ? _detectMilkingStatus : null,
                      icon: const Icon(Icons.water_drop),
                      label: const Text('Check Milking Status'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: AppTheme.warningOrange,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: aiProvider.isBackendOnline ? _detectLameness : null,
                      icon: const Icon(Icons.healing),
                      label: const Text('Detect Lameness (Video)'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: AppTheme.errorRed,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Divider(),
              
              // Detections List
              Expanded(
                child: aiProvider.detections.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.pets,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No detections yet',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Use buttons above to detect animals',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: aiProvider.detections.length,
                        itemBuilder: (context, index) {
                          final detection = aiProvider.detections[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: detection['animal_type'] == 'cow'
                                    ? Colors.brown
                                    : Colors.black,
                                child: const Icon(
                                  Icons.pets,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                detection['animal_type']?.toString().toUpperCase() ?? 'Unknown',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Confidence: ${(detection['confidence'] * 100).toStringAsFixed(1)}%',
                              ),
                              trailing: Text(
                                detection['timestamp'] ?? '',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              
              // Statistics Footer
              if (aiProvider.trackingStats != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Active Tracks',
                        aiProvider.trackingStats!['active_tracks']?.toString() ?? '0',
                        Icons.track_changes,
                      ),
                      _buildStatItem(
                        'Total Tracked',
                        aiProvider.trackingStats!['total_tracked']?.toString() ?? '0',
                        Icons.pets,
                      ),
                      _buildStatItem(
                        'Frames',
                        aiProvider.trackingStats!['frame_count']?.toString() ?? '0',
                        Icons.camera,
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryTeal),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
