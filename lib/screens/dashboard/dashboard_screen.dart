import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/animal_provider.dart';
import '../../providers/ai_detection_provider.dart';
import '../../services/dashboard_data_service.dart';
import '../monitoring/ai_monitoring_screen.dart';
import '../animals/cattle_information_screen.dart';
import '../animals/milking_cows_information_screen.dart';
import '../animals/animals_list_screen.dart';
import '../settings/settings_screen.dart';
import '../auth/login_screen.dart';

import '../camera/camera_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with AutomaticKeepAliveClientMixin {
  final _dashboardService = DashboardDataService.instance;
  DashboardStats _stats = DashboardStats();
  List<Map<String, dynamic>> _todaysCattle = [];
  List<Map<String, dynamic>> _filteredCattle = [];
  bool _isLoading = true;
  StreamSubscription? _realtimeSubscription;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  bool get wantKeepAlive => true; // Keep dashboard alive when navigating away


  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _setupRealtimeUpdates();
    // Removed _showSignupSuccessMessage() - already shown by login/signup screens
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    // Only show loading spinner on first load, not on refreshes
    if (_stats.totalCattle == 0) {
      setState(() => _isLoading = true);
    }
    
    try {
      final stats = await _dashboardService.getDashboardStats();
      final cattle = await _dashboardService.getTodaysCattle();
      
      if (mounted) {
        setState(() {
          _stats = stats;
          _todaysCattle = cattle;
          _filteredCattle = cattle;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setupRealtimeUpdates() {
    _realtimeSubscription = _dashboardService.subscribeToUpdates((stats) {
      if (mounted) {
        setState(() => _stats = stats);
        // Silently refresh data in background without showing loading
        _loadDashboardData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                // style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search by Cow ID or Ear Tag',
                  // hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  border: InputBorder.none,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, ),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchCattle('');
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  _searchCattle(value);
                },
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Dashboard'),

                ],
              ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchCattle('');
                }
              });
            },
            tooltip: _isSearching ? 'Close Search' : 'Search Cattle',
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      drawer: _buildDrawer(context, authProvider),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    _buildWelcomeSection(authProvider),
                    
                    const SizedBox(height: AppTheme.spacingLg),
                    
                    // Statistics Cards
                    _buildStatisticsCards(
                      _stats.totalCattle,
                      _stats.milkingCattle,
                      _stats.lamenessCattle,
                    ),
                    
                    const SizedBox(height: AppTheme.spacingLg),
                    
                    // Monthly Cattle Health Report Chart and Today's Cattle Table
                    // Responsive layout: Column on mobile, Row on desktop
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth > 900;
                        
                        if (isDesktop) {
                          // Desktop: Side by side
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 1,
                                child: _buildHealthReportChart(_stats),
                              ),
                              const SizedBox(width: AppTheme.spacingLg),
                              Expanded(
                                flex: 1,
                                child: _buildTodaysCattleTable(),
                              ),
                            ],
                          );
                        } else {
                          // Mobile: Stacked vertically
                          return Column(
                            children: [
                              _buildHealthReportChart(_stats),
                              const SizedBox(height: AppTheme.spacingLg),
                              _buildTodaysCattleTable(),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildWelcomeSection(AuthProvider authProvider) {
    // Get user name from current user or fallback to email username
    String userName = 'User';
    
    if (authProvider.currentUser?.name != null && 
        authProvider.currentUser!.name!.isNotEmpty) {
      userName = authProvider.currentUser!.name!;
      debugPrint('👤 Dashboard showing name: $userName');
    } else if (authProvider.currentUser?.email != null) {
      // Fallback: use email username (part before @)
      userName = authProvider.currentUser!.email.split('@')[0];
      debugPrint('👤 Dashboard using email username: $userName (name not available)');
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text(
              'Welcome, ',
              style: TextStyle(
                fontSize: 24,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              userName,
              style: const TextStyle(
                fontSize: 24,
                color: AppTheme.primaryTeal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        // Row(
        //   children: [
      
        //     const SizedBox(width: 2),
        //     ElevatedButton(
        //       onPressed: () {
        //         // Navigate to create new animal
        //       },
        //       style: ElevatedButton.styleFrom(
        //         backgroundColor: AppTheme.textPrimary,
        //         padding: const EdgeInsets.symmetric(
        //           horizontal: 16,
        //           vertical: 10,
        //         ),
        //         shape: RoundedRectangleBorder(
        //           borderRadius: BorderRadius.circular(8),
        //         ),
        //       ),
        //       child: const Row(
        //         mainAxisSize: MainAxisSize.min,
        //         children: [
        //           Text('Create New', style: TextStyle(fontSize: 12)),
        //           SizedBox(width: 4),
        //           Icon(Icons.add, size: 16),
        //         ],
        //       ),
        //     ),
        //   ],
        // ),
      ],
    );
  }

  Widget _buildStatisticsCards(int totalCows, int milkingCows, int lamenessCows) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total Number of Cows',
            value: totalCows.toString(),
            color: AppTheme.greenCard,
            icon: Icons.show_chart,
          ),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: _StatCard(
            title: 'Total Number of Milking Cows',
            value: milkingCows.toString(),
            color: AppTheme.limeCard,
            icon: Icons.show_chart,
          ),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: _StatCard(
            title: 'Total Number of Lameness Cattle',
            value: lamenessCows.toString(),
            color: AppTheme.blueCard,
            icon: Icons.show_chart,
          ),
        ),
      ],
    );
  }

  Widget _buildHealthReportChart(DashboardStats stats) {
    if (stats.dailyCounts.isEmpty) {
      return Container(
        // height: 300,
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            const Text(
              'Daily Cattle Health Report',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            Icon(Icons.bar_chart, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No data available',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload videos to start tracking cattle health',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
    }

    // Get last 7 days of data
    final sortedDates = stats.dailyCounts.keys.toList()..sort();
    final last7Days = sortedDates.length > 7 
        ? sortedDates.sublist(sortedDates.length - 7) 
        : sortedDates;

    return Container(
      // height: 300,
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Cattle Health Report',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLegendItem(AppTheme.chartPink, 'Total Detections'),
              const SizedBox(width: 16),
              _buildLegendItem(AppTheme.blueCard, 'Lameness Cases'),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.textHint.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < last7Days.length) {
                          final date = DateTime.parse(last7Days[value.toInt()]);
                          return Text(
                            '${date.day}/${date.month}',
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Total detections line
                  LineChartBarData(
                    spots: List.generate(last7Days.length, (index) {
                      return FlSpot(
                        index.toDouble(),
                        (stats.dailyCounts[last7Days[index]] ?? 0).toDouble(),
                      );
                    }),
                    isCurved: true,
                    color: AppTheme.chartPink,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                  // Lameness cases line
                  LineChartBarData(
                    spots: List.generate(last7Days.length, (index) {
                      return FlSpot(
                        index.toDouble(),
                        (stats.lamenessCount[last7Days[index]] ?? 0).toDouble(),
                      );
                    }),
                    isCurved: true,
                    color: AppTheme.blueCard,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildTodaysCattleTable() {
    return Container(
      // height: 300,
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today\'s Cattle',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${_filteredCattle.length} detected',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          if (_filteredCattle.isEmpty && _searchQuery.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(Icons.pets_outlined, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text(
                      'No cattle detected today',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upload videos to start tracking',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            )
          else if (_filteredCattle.isEmpty && _searchQuery.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text(
                      'No cattle found',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try a different search term',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            )
          else if (_todaysCattle.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(Icons.pets_outlined, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text(
                      'No cattle detected today',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upload videos to start tracking',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppTheme.lightBackground),
                columns: const [
                  DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                  DataColumn(label: Text('Cow ID', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                  DataColumn(label: Text('Ear Tag', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                  DataColumn(label: Text('Lameness', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                  DataColumn(label: Text('BCS', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                ],
                rows: _filteredCattle.asMap().entries.map((entry) {
                  final index = entry.key;
                  final cattle = entry.value;
                  final lamenessScore = cattle['lameness_score'] as double?;
                  final bcsScore = cattle['bcs_score'] as double?;
                  final isLame = lamenessScore != null && lamenessScore > 1.0;
                  
                  return DataRow(
                    cells: [
                      DataCell(Text('${index + 1}', style: const TextStyle(fontSize: 12))),
                      DataCell(Text(
                        cattle['cow_id']?.toString() ?? 'N/A',
                        style: const TextStyle(fontSize: 12),
                      )),
                      DataCell(Text(
                        cattle['ear_tag']?.toString() ?? 'N/A',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      )),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isLame ? Colors.red.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            lamenessScore != null ? lamenessScore.toStringAsFixed(1) : 'N/A',
                            style: TextStyle(
                              fontSize: 11,
                              color: isLame ? Colors.red[700] : Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(
                        bcsScore != null ? bcsScore.toStringAsFixed(1) : 'N/A',
                        style: const TextStyle(fontSize: 12),
                      )),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isLame ? Colors.orange.withValues(alpha: 0.2) : AppTheme.greenCard.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isLame ? 'Lame' : 'Healthy',
                            style: TextStyle(
                              fontSize: 10,
                              color: isLame ? Colors.orange[700] : AppTheme.greenCard,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  void _searchCattle(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredCattle = _todaysCattle;
      } else {
        _filteredCattle = _todaysCattle.where((cattle) {
          final cowId = cattle['cow_id']?.toString().toLowerCase() ?? '';
          final earTag = cattle['ear_tag']?.toString().toLowerCase() ?? '';
          return cowId.contains(_searchQuery) || earTag.contains(_searchQuery);
        }).toList();
      }
    });
  }



  Widget _buildDrawer(BuildContext context, AuthProvider authProvider) {
    return Drawer(
      backgroundColor: AppTheme.primaryTeal,
      width: 80,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // User profile section
            if (authProvider.currentUser?.name != null)
              Column(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: Text(
                      authProvider.currentUser!.name!.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryTeal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    authProvider.currentUser!.name!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white54, height: 1),
                  const SizedBox(height: 16),
                ],
              ),
                       // Dashboard/Home icon
            _DrawerIconButton(
              icon: Icons.home,
              isActive: true, // Currently active
              tooltip: 'Dashboard',
              onTap: () {
                Navigator.pop(context);
              },
            ),
  const SizedBox(height: 8),
            // Milking Cows icon
            _DrawerIconButton(
              icon: Icons.local_drink,
              isActive: false,
              tooltip: 'Milking Cows',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MilkingCowsInformationScreen(),
                  ),
                );
              },
            ),
                 const SizedBox(height: 8),
            // Cattle Information icon
            _DrawerIconButton(
              icon: Icons.info,
              isActive: false,
              tooltip: 'Cattle Information',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CattleInformationScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            // AI Monitoring icon
            _DrawerIconButton(
              icon: Icons.memory,
              isActive: false,
              tooltip: 'AI Monitoring',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const _HomeScreenWithTab(initialTab: 1),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            // Cattle/Animals icon
            _DrawerIconButton(
              icon: Icons.pets,
              isActive: false,
              tooltip: 'Animals',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const _HomeScreenWithTab(initialTab: 3),
                  ),
                );
              },
            ),
       
          
            const SizedBox(height: 8),
            // Camera icon
            _DrawerIconButton(
              icon: Icons.camera_alt,
              isActive: false,
              tooltip: 'Camera & Video',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const _HomeScreenWithTab(initialTab: 4),
                  ),
                );
              },
            ),
         
            const SizedBox(height: 8),
            // // Settings icon
            _DrawerIconButton(
              icon: Icons.settings,
              isActive: false,
              tooltip: 'Settings',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            // const Spacer(),
            // Logout icon at bottom
            _DrawerIconButton(
              icon: Icons.logout,
              isActive: false,
              tooltip: 'Logout',
              onTap: () async {
                Navigator.pop(context);
                
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.errorRed,
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
                
                if (shouldLogout == true && context.mounted) {
                  // Clear all user data before signing out
                  debugPrint('🔄 Clearing all user data before logout');
                  context.read<AnimalProvider>().clearData();
                  context.read<AIDetectionProvider>().clearData();
                  
                  // Sign out
                  await authProvider.signOut();
                  
                  if (context.mounted) {
                    // Navigate to login screen instantly and clear navigation stack
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color == AppTheme.limeCard ? AppTheme.textPrimary : AppTheme.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color == AppTheme.limeCard ? AppTheme.textPrimary : AppTheme.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                icon,
                color: color == AppTheme.limeCard ? AppTheme.textPrimary : AppTheme.white,
                size: 24,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DrawerIconButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final String tooltip;

  const _DrawerIconButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      verticalOffset: 8,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFE8C4D8) : Colors.transparent, // Pink/light background for active
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isActive ? AppTheme.primaryTeal : Colors.black,
            size: 24,
          ),
        ),
      ),
    );
  }
}

// Helper widget to navigate to home screen with specific tab
class _HomeScreenWithTab extends StatefulWidget {
  final int initialTab;
  
  const _HomeScreenWithTab({required this.initialTab});

  @override
  State<_HomeScreenWithTab> createState() => _HomeScreenWithTabState();
}

class _HomeScreenWithTabState extends State<_HomeScreenWithTab> {
  late int _currentIndex;
  
  final List<Widget> _screens = const [
    DashboardScreen(),
    AIMonitoringScreen(),
    CattleInformationScreen(),
    AnimalsListScreen(),
    CameraScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    // Load animals when home screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnimalProvider>().loadAnimals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      // Removed bottom navigation bar - using drawer navigation only
    );
  }
}
