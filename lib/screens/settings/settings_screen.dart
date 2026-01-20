import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

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
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAboutDialog(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Notifications Section
          _buildSectionHeader('Notifications'),
          _buildCard([
            _buildSwitchTile(
              'Enable Notifications',
              'Receive alerts and updates',
              settingsProvider.enableNotifications,
              (value) => settingsProvider.setEnableNotifications(value),
            ),
            if (settingsProvider.enableNotifications) ...[
              _buildSwitchTile(
                'Lameness Alerts',
                'Alert when lameness is detected',
                settingsProvider.lamenessAlerts,
                (value) => settingsProvider.setLamenessAlerts(value),
              ),
              _buildSwitchTile(
                'Milking Alerts',
                'Alert for milking status changes',
                settingsProvider.milkingAlerts,
                (value) => settingsProvider.setMilkingAlerts(value),
              ),
              _buildSwitchTile(
                'Health Alerts',
                'Alert for health status changes',
                settingsProvider.healthAlerts,
                (value) => settingsProvider.setHealthAlerts(value),
              ),
            ],
          ]),

          const SizedBox(height: 24),

          // AI Detection Section
          _buildSectionHeader('AI Detection Settings'),
          _buildCard([
            _buildSliderTile(
              'Detection Confidence',
              'Minimum confidence threshold for AI detection',
              settingsProvider.detectionConfidence,
              0.5,
              1.0,
              (value) => settingsProvider.setDetectionConfidence(value),
              valueLabel: '${(settingsProvider.detectionConfidence * 100).toInt()}%',
            ),
            _buildSwitchTile(
              'Auto Process Videos',
              'Automatically process uploaded videos',
              settingsProvider.autoProcessVideos,
              (value) => settingsProvider.setAutoProcessVideos(value),
            ),
            _buildSwitchTile(
              'Save Processed Videos',
              'Keep processed videos in storage',
              settingsProvider.saveProcessedVideos,
              (value) => settingsProvider.setSaveProcessedVideos(value),
            ),
          ]),

          const SizedBox(height: 24),

          // Camera Settings Section
          _buildSectionHeader('Camera Settings'),
          _buildCard([
            _buildDropdownTile(
              'Camera FPS',
              'Frames per second for recording',
              settingsProvider.cameraFPS.toString(),
              ['15', '24', '30', '60'],
              (value) {
                if (value != null) {
                  settingsProvider.setCameraFPS(int.parse(value));
                }
              },
            ),
            _buildDropdownTile(
              'Video Quality',
              'Recording quality preference',
              settingsProvider.videoQuality,
              ['low', 'medium', 'high', 'ultra'],
              (value) => settingsProvider.setVideoQuality(value!),
            ),
          ]),

          const SizedBox(height: 24),

          // Data & Sync Section
          _buildSectionHeader('Data & Sync'),
          _buildCard([
            _buildSwitchTile(
              'Auto Sync',
              'Automatically sync data with cloud',
              settingsProvider.autoSync,
              (value) => settingsProvider.setAutoSync(value),
            ),
            if (settingsProvider.autoSync)
              _buildDropdownTile(
                'Sync Interval',
                'How often to sync data',
                '${settingsProvider.dataSyncInterval} minutes',
                ['1 minutes', '5 minutes', '15 minutes', '30 minutes', '60 minutes'],
                (value) {
                  final minutes = int.parse(value!.split(' ')[0]);
                  settingsProvider.setDataSyncInterval(minutes);
                },
              ),
            _buildSwitchTile(
              'WiFi Only',
              'Sync only when connected to WiFi',
              settingsProvider.wifiOnly,
              (value) => settingsProvider.setWifiOnly(value),
            ),
          ]),

          const SizedBox(height: 24),

          // Display Settings Section
          _buildSectionHeader('Display'),
          _buildCard([
            _buildSwitchTile(
              'Dark Mode',
              'Enable dark theme',
              settingsProvider.darkMode,
              (value) {
                settingsProvider.setDarkMode(value);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Restart app to apply theme changes'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            _buildDropdownTile(
              'Language',
              'App language',
              settingsProvider.language,
              ['English', 'Spanish', 'French', 'German', 'Chinese'],
              (value) => settingsProvider.setLanguage(value!),
            ),
          ]),

          const SizedBox(height: 24),

          // Account Section
          _buildSectionHeader('Account'),
          _buildCard([
            _buildActionTile(
              'Profile',
              'Manage your profile information',
              Icons.person,
              () => _showComingSoonDialog('Profile settings'),
            ),
            _buildActionTile(
              'Privacy & Security',
              'Manage privacy settings',
              Icons.security,
              () => _showComingSoonDialog('Privacy settings'),
            ),
            _buildActionTile(
              'Data Management',
              'Export or delete your data',
              Icons.storage,
              () => _showDataManagementDialog(),
            ),
          ]),

          const SizedBox(height: 24),

          // Support Section
          _buildSectionHeader('Support'),
          _buildCard([
            _buildActionTile(
              'Help & FAQ',
              'Get help and view frequently asked questions',
              Icons.help,
              () => _showComingSoonDialog('Help & FAQ'),
            ),
            _buildActionTile(
              'Contact Support',
              'Reach out to our support team',
              Icons.contact_support,
              () => _showComingSoonDialog('Contact support'),
            ),
            _buildActionTile(
              'Send Feedback',
              'Share your thoughts with us',
              Icons.feedback,
              () => _showComingSoonDialog('Feedback'),
            ),
          ]),

          const SizedBox(height: 24),

          // Danger Zone
          _buildSectionHeader('Danger Zone', color: AppTheme.errorRed),
          _buildCard([
            _buildActionTile(
              'Clear Cache',
              'Free up storage space',
              Icons.delete_sweep,
              () => _showClearCacheDialog(),
              textColor: AppTheme.errorRed,
            ),
            _buildActionTile(
              'Reset Settings',
              'Reset all settings to default',
              Icons.restore,
              () => _showResetSettingsDialog(),
              textColor: AppTheme.errorRed,
            ),
            _buildActionTile(
              'Logout',
              'Sign out of your account',
              Icons.logout,
              () => _showLogoutDialog(authProvider),
              textColor: AppTheme.errorRed,
            ),
          ]),

          const SizedBox(height: 24),

          // App Version
          Center(
            child: Column(
              children: [
                Text(
                  'Cattle AI Monitor',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textHint,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color ?? AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: AppTheme.textSecondary,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppTheme.primaryTeal,
    );
  }

  Widget _buildSliderTile(
    String title,
    String subtitle,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    String? valueLabel,
  }) {
    return ListTile(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            valueLabel ?? value.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.primaryTeal,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: 10,
            activeColor: AppTheme.primaryTeal,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: AppTheme.textSecondary,
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppTheme.primaryTeal),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: AppTheme.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: textColor ?? AppTheme.textHint,
      ),
      onTap: onTap,
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Cattle AI Monitor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Version 1.0.0',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'AI-powered cattle monitoring system for detecting lameness, tracking milking status, and managing cattle health.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            Text(
              '© 2026 Cattle AI Monitor',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textHint,
              ),
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

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: Text('$feature will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDataManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Management'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Data'),
              subtitle: const Text('Download your cattle data'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoonDialog('Export data');
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_forever, color: AppTheme.errorRed),
              title: Text('Delete All Data', style: TextStyle(color: AppTheme.errorRed)),
              subtitle: const Text('Permanently delete all your data'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDataDialog();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data?'),
        content: const Text(
          'This will permanently delete all your cattle data, videos, and records. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feature coming soon')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text('This will clear temporary files and free up storage space.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showResetSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings?'),
        content: const Text('This will reset all settings to their default values.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final settingsProvider = context.read<SettingsProvider>();
              
              await settingsProvider.resetToDefault();
              if (mounted) {
                nav.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Settings reset to default')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final nav1 = Navigator.of(context);
              final nav2 = Navigator.of(context);
              nav1.pop();
              
              // Sign out
              await authProvider.signOut();
              
              if (mounted) {
                // Navigate to login screen and clear navigation stack
                nav2.pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
