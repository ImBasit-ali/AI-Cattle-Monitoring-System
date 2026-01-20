import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/dashboard_data_service.dart';
import '../dashboard/dashboard_screen.dart';

class CattleInformationScreen extends StatefulWidget {
  const CattleInformationScreen({super.key});

  @override
  State<CattleInformationScreen> createState() => _CattleInformationScreenState();
}

class _CattleInformationScreenState extends State<CattleInformationScreen> with AutomaticKeepAliveClientMixin {
  final DashboardDataService _dataService = DashboardDataService.instance;
  List<Map<String, dynamic>> _cattleData = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true; // Keep screen alive when navigating away

  @override
  void initState() {
    super.initState();
    _loadCattleData();
  }

  Future<void> _loadCattleData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _dataService.getCattleInformation();
      setState(() {
        _cattleData = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading cattle data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
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
  title: const Text('Cattle Information'),
  actions: [
    IconButton(
      icon: const Icon(Icons.refresh),
      onPressed: _loadCattleData,
    ),
  ],
),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cattleData.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  itemCount: _cattleData.length,
                  itemBuilder: (context, index) {
                    final cattle = _cattleData[index];
                    return _buildCattleCard(cattle, index + 1);
                  },
                ),
    );
  }

  Widget _buildCattleCard(Map<String, dynamic> cattle, int number) {
    final cowId = cattle['cow_id']?.toString() ?? 'Unknown';
    final earTag = cattle['ear_tag']?.toString() ?? 'N/A';
    final isMilking = cattle['is_milking'] == true;
    final isLame = cattle['is_lame'] == true;
    final lamenessScore = cattle['lameness_score'];
    final lamenessSeverity = cattle['lameness_severity']?.toString() ?? 'N/A';
    final milkingConfidence = cattle['milking_confidence'];

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: isLame ? AppTheme.errorRed.withValues(alpha: 0.3) : AppTheme.lightBackground,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Cow ID
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: isLame 
                  ? AppTheme.errorRed.withValues(alpha: 0.1)
                  : AppTheme.primaryTeal.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusMd),
                topRight: Radius.circular(AppTheme.radiusMd),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '#$number',
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.pets,
                      color: AppTheme.primaryTeal,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cowId,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (isLame)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: AppTheme.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'ALERT',
                          style: TextStyle(
                            color: AppTheme.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Cattle Information
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              children: [
                // Ear Tag Information
                _buildInfoRow(
                  'Ear Tag Number',
                  earTag,
                  Icons.sell_outlined,
                  AppTheme.primaryTeal,
                ),
                const SizedBox(height: AppTheme.spacingSm),

                // Milking Status
                _buildStatusRow(
                  'Milking Status',
                  isMilking ? 'Being Milked' : 'Not Milking',
                  isMilking ? Icons.water_drop : Icons.water_drop_outlined,
                  isMilking ? AppTheme.successGreen : AppTheme.textSecondary,
                  isMilking,
                  milkingConfidence != null 
                      ? 'Confidence: ${(milkingConfidence * 100).toStringAsFixed(1)}%'
                      : null,
                ),
                const SizedBox(height: AppTheme.spacingSm),

                // Lameness Status
                _buildStatusRow(
                  'Lameness Status',
                  isLame ? lamenessSeverity : 'Normal',
                  isLame ? Icons.warning : Icons.check_circle,
                  isLame ? AppTheme.errorRed : AppTheme.successGreen,
                  isLame,
                  lamenessScore != null ? 'Score: $lamenessScore/5' : null,
                ),

                // Additional lameness details if lame
                if (isLame && lamenessScore != null) ...[
                  const SizedBox(height: AppTheme.spacingSm),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.errorRed.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.errorRed, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Requires immediate attention - $lamenessSeverity detected',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.errorRed,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(
    String label,
    String status,
    IconData icon,
    Color statusColor,
    bool isActive,
    String? additionalInfo,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 15,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (additionalInfo != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    additionalInfo,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isActive ? 'YES' : 'NO',
              style: const TextStyle(
                color: AppTheme.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets_outlined,
            size: 100,
            color: AppTheme.textHint.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Data',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

