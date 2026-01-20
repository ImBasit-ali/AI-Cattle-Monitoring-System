import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/dashboard_data_service.dart';
import '../dashboard/dashboard_screen.dart';

/// AI Monitoring Dashboard Screen
/// Based on research: Multi-camera monitoring with real-time AI analytics
/// Features: Identification accuracy stats, BCS monitoring, Feeding analysis, Localization tracking
class AIMonitoringScreen extends StatefulWidget {
  const AIMonitoringScreen({super.key});

  @override
  State<AIMonitoringScreen> createState() => _AIMonitoringScreenState();
}

class _AIMonitoringScreenState extends State<AIMonitoringScreen> with AutomaticKeepAliveClientMixin {
  String _selectedPeriod = '24 Hours';
  final List<String> _periods = ['24 Hours', '7 Days', '30 Days', '3 Months'];
  
  final DashboardDataService _dataService = DashboardDataService.instance;
  DashboardStats _stats = DashboardStats();
  List<Map<String, dynamic>> _cattleData = [];
  bool _isLoading = true;
  StreamSubscription? _realtimeSubscription;
  
  int _totalDetections = 0;

  @override
  bool get wantKeepAlive => true; // Keep screen alive when navigating away

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupRealtimeUpdates();
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _dataService.getDashboardStats();
      final cattle = await _dataService.getCattleInformation();
      
      // Calculate total detections from daily counts
      int totalDetections = 0;
      stats.dailyCounts.forEach((date, count) {
        totalDetections += count;
      });
      
      setState(() {
        _stats = stats;
        _cattleData = cattle;
        _totalDetections = totalDetections;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading AI monitoring data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _setupRealtimeUpdates() {
    _realtimeSubscription = _dataService.subscribeToUpdates((stats) {
      _loadData();
    });
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
  title: const Text('Ai Monitoring '),
  centerTitle: true,

),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildSystemOverview(),
              const SizedBox(height: 20),
              _buildIdentificationAccuracy(),
              const SizedBox(height: 20),
              _buildAIModuleStats(),
              const SizedBox(height: 20),
              _buildCameraSystemStatus(),
              const SizedBox(height: 20),
              _buildZoneDistribution(),
              const SizedBox(height: 20),
              _buildRecentAlerts(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryTeal, AppTheme.primaryTeal.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Monitoring System',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isLoading ? 'Loading...' : 'Real-time Multi-camera Intelligent Monitoring',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildHeaderStat(
                    _cattleData.length.toString(), 
                    'Active Cattle', 
                    Icons.pets
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHeaderStat(
                    _totalDetections.toString(), 
                    'Detections', 
                    Icons.camera_alt
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHeaderStat(
                    _stats.milkingCattle.toString(), 
                    'Milking', 
                    Icons.water_drop
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemOverview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'System Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              DropdownButton<String>(
                value: _selectedPeriod,
                items: _periods.map((period) {
                  return DropdownMenuItem(
                    value: period,
                    child: Text(period, style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPeriod = value!;
                  });
                },
                underline: Container(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  'Total Detections',
                  _totalDetections.toString(),
                  Icons.analytics,
                  AppTheme.blueCard,
                  'All Time',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOverviewCard(
                  'Active Animals',
                  _stats.totalCattle.toString(),
                  Icons.pets,
                  AppTheme.greenCard,
                  '100%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  'Lameness Alerts',
                  _stats.lamenessCattle.toString(),
                  Icons.notification_important,
                  Colors.orange,
                  _stats.lamenessCattle > 0 ? 'Attention' : 'All Clear',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOverviewCard(
                  'Milking Status',
                  '${_stats.milkingCattle}/${_stats.totalCattle}',
                  Icons.water_drop,
                  AppTheme.limeCard,
                  'Active',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentificationAccuracy() {
    final identificationMethods = [
      {'method': 'Body-Color Point Cloud', 'accuracy': 99.55, 'color': const Color(0xFF00D9A3)},
      {'method': 'Ear Tag Recognition', 'accuracy': 94.00, 'color': const Color(0xFF4169E1)},
      {'method': 'Face-based ID', 'accuracy': 93.66, 'color': const Color(0xFFFF6B9D)},
      {'method': 'Body-based ID', 'accuracy': 92.80, 'color': const Color(0xFFCEFF00)},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Identification Accuracy',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'AI model performance from research validation',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: identificationMethods.map((method) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildAccuracyBar(
                    method['method'] as String,
                    method['accuracy'] as double,
                    method['color'] as Color,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyBar(String method, double accuracy, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                method,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${accuracy.toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: accuracy / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildAIModuleStats() {
    // Calculate accuracy percentages based on real data
    final lamenessAccuracy = _cattleData.isNotEmpty 
        ? ((_cattleData.length - _stats.lamenessCattle) / _cattleData.length * 100).toStringAsFixed(2)
        : '0.00';
    
    final milkingAccuracy = _cattleData.isNotEmpty
        ? ((_stats.milkingCattle / _cattleData.length * 100)).toStringAsFixed(2)
        : '0.00';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Module Performance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildModuleCard(
                  'Lameness Detection',
                  '$lamenessAccuracy%',
                  Icons.directions_walk,
                  const Color(0xFFFF6B9D),
                  '${_stats.lamenessCattle} detected',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModuleCard(
                  'Milking Detection',
                  '$milkingAccuracy%',
                  Icons.water_drop,
                  const Color(0xFF4169E1),
                  '${_stats.milkingCattle} active',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(String title, String accuracy, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            accuracy,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraSystemStatus() {
    final cameraZones = [
      {'zone': 'Milking Parlor', 'cameras': 6, 'active': 6, 'fps': 29.8},
      {'zone': 'Return Lane', 'cameras': 4, 'active': 4, 'fps': 30.1},
      {'zone': 'Feeding Area', 'cameras': 8, 'active': 7, 'fps': 29.5},
      {'zone': 'Resting Space', 'cameras': 4, 'active': 4, 'fps': 30.0},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
            'Multi-camera setup: RGB, RGB-D, ToF Depth',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: cameraZones.map((zone) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: zone['active'] == zone['cameras'] ? AppTheme.greenCard : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Text(
                          zone['zone'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${zone['active']}/${zone['cameras']}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      Text(
                        '${zone['fps']} FPS',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneDistribution() {
    // Calculate zone distribution from cattle data
    final totalCattle = _stats.totalCattle;
    final milkingCattle = _stats.milkingCattle;
    final lameCattle = _stats.lamenessCattle;
    final healthyCattle = totalCattle - lameCattle;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Real-time Status Distribution',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildZoneCard(
                  'Milking', 
                  milkingCattle, 
                  Icons.water_drop, 
                  const Color(0xFF4169E1)
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildZoneCard(
                  'Healthy', 
                  healthyCattle, 
                  Icons.check_circle, 
                  const Color(0xFF00D9A3)
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildZoneCard(
                  'Lameness', 
                  lameCattle, 
                  Icons.warning, 
                  const Color(0xFFFF6B9D)
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildZoneCard(
                  'Total', 
                  totalCattle, 
                  Icons.pets, 
                  const Color(0xFFCEFF00)
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildZoneCard(String zone, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            zone,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAlerts() {
    // Generate alerts from real lameness data
    final lameCattle = _cattleData.where((c) => c['is_lame'] == true).toList();
    
    if (lameCattle.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Alerts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.successGreen, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'No Active Alerts',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'All cattle are healthy',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Alerts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${lameCattle.length} Alert${lameCattle.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...lameCattle.take(5).map((cattle) {
            final severity = cattle['lameness_severity']?.toString() ?? 'Unknown';
            final cowId = cattle['cow_id']?.toString() ?? 'Unknown';
            final lamenessScore = cattle['lameness_score'];
            
            Color severityColor = severity.toLowerCase().contains('severe') || (lamenessScore != null && lamenessScore > 3)
                ? Colors.red
                : severity.toLowerCase().contains('moderate') || (lamenessScore != null && lamenessScore > 2)
                    ? Colors.orange
                    : Colors.amber;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: severityColor.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.warning,
                      color: severityColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lameness detected in Cow $cowId',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Severity: $severity${lamenessScore != null ? ' (Score: $lamenessScore)' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      severity.toLowerCase().contains('severe') ? 'Critical' : 
                      severity.toLowerCase().contains('moderate') ? 'High' : 'Medium',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: severityColor,
                      ),
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
}

