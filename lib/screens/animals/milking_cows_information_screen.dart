import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../monitoring/ai_monitoring_screen.dart';
import '../settings/settings_screen.dart';
import '../auth/login_screen.dart';
import 'cattle_information_screen.dart';
import 'animals_list_screen.dart';

import '../camera/camera_screen.dart';

class MilkingCowsInformationScreen extends StatefulWidget {
  const MilkingCowsInformationScreen({super.key});

  @override
  State<MilkingCowsInformationScreen> createState() => _MilkingCowsInformationScreenState();
}

class _MilkingCowsInformationScreenState extends State<MilkingCowsInformationScreen> {
  final _firebaseService = FirebaseService.instance;
  DateTime _selectedDate = DateTime.now();
  String _selectedTime = 'Evening';
  List<Map<String, dynamic>> _milkingCows = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMilkingCows();
  }

  Future<void> _loadMilkingCows() async {
    setState(() => _isLoading = true);
    
    try {
      final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      // Query ear_tag_camera for milking cows
      final snapshot = await _firebaseService.database
          .ref('ear_tag_camera')
          .get();
      
      List<Map<String, dynamic>> data = [];
      if (snapshot.exists) {
        final dataMap = Map<String, dynamic>.from(snapshot.value as Map);
        data = dataMap.entries.map((entry) {
          final record = Map<String, dynamic>.from(entry.value as Map);
          record['id'] = entry.key;
          return record;
        }).where((record) {
          final timestamp = DateTime.parse(record['timestamp'] ?? DateTime.now().toIso8601String());
          return timestamp.isAfter(startOfDay) && timestamp.isBefore(endOfDay);
        }).toList();
        
        // Sort by timestamp descending
        data.sort((a, b) {
          final aTime = DateTime.parse(a['timestamp'] ?? DateTime.now().toIso8601String());
          final bTime = DateTime.parse(b['timestamp'] ?? DateTime.now().toIso8601String());
          return bTime.compareTo(aTime);
        });
      }
      
      // Get unique cows and fetch their BCS and lameness data
      final Map<String, Map<String, dynamic>> uniqueCows = {};
      for (final record in data) {
        final cowId = record['cow_id'] as String;
        if (!uniqueCows.containsKey(cowId)) {
          uniqueCows[cowId] = {
            'cow_id': cowId,
            'ear_tag': record['ear_tag_number'] ?? cowId,
            'bcs': 3.5,
            'lameness_score': 1,
          };
        }
      }
      
      if (mounted) {
        setState(() {
          _milkingCows = uniqueCows.values.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadMilkingCows();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      drawer: _buildDrawer(context, authProvider),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const Text('Milking Cows Information'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: const Text(
                    '1',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMilkingCows,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date and Time Selector
                    Row(
                      children: [
                        // Date Picker
                        InkWell(
                          onTap: _selectDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.lightBackground,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.textHint.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  DateFormat('yyyy/MM/dd').format(_selectedDate),
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.calendar_today, size: 16),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Time Selector
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.lightBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.textHint.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.wb_twilight, size: 16),
                              const SizedBox(width: 8),
                              DropdownButton<String>(
                                value: _selectedTime,
                                underline: const SizedBox(),
                                items: ['Morning', 'Evening'].map((time) {
                                  return DropdownMenuItem(
                                    value: time,
                                    child: Text(time, style: const TextStyle(fontSize: 14)),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedTime = value;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    
                    // Milking Cows Table
                    if (_milkingCows.isEmpty)
                      _buildEmptyState()
                    else
                      _buildMilkingCowsTable(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'No Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No milking cows data for selected date',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMilkingCowsTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.lightBackground),
          columnSpacing: 40,
          columns: const [
            DataColumn(
              label: Text(
                'No.',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                'Cow ID',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                'BCS',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                'Lame Score',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ],
          rows: _milkingCows.asMap().entries.map((entry) {
            final index = entry.key;
            final cow = entry.value;
            
            return DataRow(
              cells: [
                DataCell(Text(
                  '${index + 1}',
                  style: const TextStyle(fontSize: 12),
                )),
                DataCell(Text(
                  cow['cow_id']?.toString() ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                )),
                DataCell(Text(
                  cow['bcs']?.toString() ?? '3.5',
                  style: const TextStyle(fontSize: 12),
                )),
                DataCell(Text(
                  cow['lameness_score']?.toString() ?? '1',
                  style: const TextStyle(fontSize: 12),
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider authProvider) {
    return Drawer(
      backgroundColor: AppTheme.primaryTeal,
      width: 80,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
                       // Dashboard/Home icon
            _DrawerIconButton(
              icon: Icons.home,
              isActive: false, // Currently active
              tooltip: 'Dashboard',
              onTap: () {
                Navigator.pop(context);
                 Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DashboardScreen(),
                  ),
                );
              },
            ),
  const SizedBox(height: 8),
            // Milking Cows icon
            _DrawerIconButton(
              icon: Icons.local_drink,
              isActive: true,
              tooltip: 'Milking Cows',
              onTap: () {
                Navigator.pop(context);
               
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
                    builder: (context) => const AIMonitoringScreen(),
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
                    builder: (context) => const AnimalsListScreen(),
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
                    builder: (context) => const CameraScreen(),
                  ),
                );
              },
            ),
         
            const SizedBox(height: 8),
            // Settings icon
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

class _DrawerIconButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final String tooltip;
  final VoidCallback onTap;

  const _DrawerIconButton({
    required this.icon,
    required this.isActive,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: Material(
        color: isActive ? const Color(0xFFE8C4D8) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.black,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
