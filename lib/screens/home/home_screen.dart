import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/animal_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../animals/animals_list_screen.dart';
import '../animals/cattle_information_screen.dart';
import '../camera/camera_screen.dart';
import '../monitoring/ai_monitoring_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
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
    // Clear all previous data and load fresh data for current user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        debugPrint('🔄 HomeScreen: Loading data for current user');
        context.read<AnimalProvider>().loadAnimals();
      }
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
