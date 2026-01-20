import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/dashboard_data_service.dart';
import '../dashboard/dashboard_screen.dart';

class AnimalsListScreen extends StatefulWidget {
  const AnimalsListScreen({super.key});

  @override
  State<AnimalsListScreen> createState() => _AnimalsListScreenState();
}

class _AnimalsListScreenState extends State<AnimalsListScreen> with AutomaticKeepAliveClientMixin {
  final DashboardDataService _dataService = DashboardDataService.instance;
  List<Map<String, dynamic>> _cattleData = [];
  List<Map<String, dynamic>> _filteredCattle = [];
  bool _isLoading = true;
  StreamSubscription? _realtimeSubscription;
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'all'; // all, milking, lame, healthy

  @override
  bool get wantKeepAlive => true; // Keep screen alive when navigating away

  @override
  void initState() {
    super.initState();
    _loadCattleData();
    _setupRealtimeUpdates();
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCattleData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _dataService.getCattleInformation();
      setState(() {
        _cattleData = data;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading cattle data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _setupRealtimeUpdates() {
    _realtimeSubscription = _dataService.subscribeToUpdates((stats) {
      _loadCattleData();
    });
  }

  void _applyFilters() {
    var filtered = _cattleData.where((cattle) {
      // Search filter
      final searchQuery = _searchController.text.toLowerCase();
      final matchesSearch = searchQuery.isEmpty ||
          cattle['cow_id'].toString().toLowerCase().contains(searchQuery) ||
          (cattle['ear_tag']?.toString().toLowerCase().contains(searchQuery) ?? false);

      if (!matchesSearch) return false;

      // Status filter
      if (_filterStatus == 'milking') {
        return cattle['is_milking'] == true;
      } else if (_filterStatus == 'lame') {
        return cattle['is_lame'] == true;
      } else if (_filterStatus == 'healthy') {
        return cattle['is_lame'] != true;
      }

      return true;
    }).toList();

    setState(() => _filteredCattle = filtered);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
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
        title: const Text('Animals List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCattleData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.white,
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by Cow ID or Ear Tag',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilters();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppTheme.lightBackground,
                  ),
                  onChanged: (value) => _applyFilters(),
                ),
                const SizedBox(height: 12),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Milking', 'milking'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Lame', 'lame'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Healthy', 'healthy'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Results count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_filteredCattle.length} cattle found',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          // Cattle list
          Expanded(
            child: _isLoading && _filteredCattle.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _filteredCattle.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredCattle.length,
                        itemBuilder: (context, index) {
                          return _buildCattleCard(_filteredCattle[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
          _applyFilters();
        });
      },
      backgroundColor: AppTheme.lightBackground,
      selectedColor: AppTheme.primaryTeal,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.white : AppTheme.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }

  Widget _buildCattleCard(Map<String, dynamic> cattle) {
    final isMilking = cattle['is_milking'] == true;
    final isLame = cattle['is_lame'] == true;
    final cowId = cattle['cow_id']?.toString() ?? 'Unknown';
    final earTag = cattle['ear_tag']?.toString();
    final lamenessScore = cattle['lameness_score'];
    final lamenessSeverity = cattle['lameness_severity']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showCattleDetails(cattle),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Cow icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.pets,
                      color: AppTheme.primaryTeal,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Cow info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cow ID: $cowId',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (earTag != null)
                          Text(
                            'Ear Tag: $earTag',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isLame
                          ? AppTheme.errorRed.withValues(alpha: 0.1)
                          : AppTheme.successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isLame ? 'Lame' : 'Healthy',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isLame ? AppTheme.errorRed : AppTheme.successGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Status row
              Row(
                children: [
                  _buildStatusChip(
                    icon: Icons.water_drop,
                    label: isMilking ? 'Milking' : 'Not Milking',
                    color: isMilking ? AppTheme.infoBlue : AppTheme.textHint,
                  ),
                  const SizedBox(width: 8),
                  if (isLame && lamenessSeverity != null)
                    _buildStatusChip(
                      icon: Icons.warning,
                      label: lamenessSeverity,
                      color: AppTheme.warningOrange,
                    ),
                ],
              ),
              if (lamenessScore != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Lameness Score: $lamenessScore',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
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
            size: 80,
            color: AppTheme.textHint.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty || _filterStatus != 'all'
                ? 'No cattle found'
                : 'No cattle data available',
            style: const TextStyle(
              fontSize: 18,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty || _filterStatus != 'all'
                ? 'Try adjusting your filters'
                : 'Upload a video to detect cattle',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textHint,
            ),
          ),
        ],
      ),
    );
  }

  void _showCattleDetails(Map<String, dynamic> cattle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cow ${cattle['cow_id']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Cow ID', cattle['cow_id']?.toString() ?? 'Unknown'),
            if (cattle['ear_tag'] != null)
              _buildDetailRow('Ear Tag', cattle['ear_tag'].toString()),
            _buildDetailRow(
              'Milking Status',
              cattle['is_milking'] == true ? 'Milking' : 'Not Milking',
            ),
            if (cattle['milking_confidence'] != null)
              _buildDetailRow(
                'Milking Confidence',
                '${cattle['milking_confidence']}%',
              ),
            _buildDetailRow(
              'Lameness Status',
              cattle['is_lame'] == true ? 'Lame' : 'Healthy',
            ),
            if (cattle['lameness_score'] != null)
              _buildDetailRow(
                'Lameness Score',
                cattle['lameness_score'].toString(),
              ),
            if (cattle['lameness_severity'] != null)
              _buildDetailRow(
                'Lameness Severity',
                cattle['lameness_severity'].toString(),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
