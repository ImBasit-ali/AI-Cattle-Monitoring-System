import 'package:flutter/material.dart';
import 'settings_service.dart';

/// Notification Service - Handles app notifications based on settings
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static NotificationService get instance => _instance;

  final SettingsService _settingsService = SettingsService.instance;

  /// Show a notification if enabled in settings
  void showNotification(
    BuildContext context,
    String type,
    String title,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 4),
  }) {
    // Check if notifications are enabled and if this specific type is enabled
    if (!_settingsService.shouldShowNotification(type)) {
      debugPrint('Notification blocked by settings: $type - $title');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(message),
          ],
        ),
        backgroundColor: backgroundColor ?? _getColorForType(type),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );

    debugPrint('✅ Notification shown: $type - $title');
  }

  /// Show a lameness alert
  void showLamenessAlert(
    BuildContext context,
    String animalId,
    int lamenessScore,
    String severity,
  ) {
    showNotification(
      context,
      'lameness',
      'Lameness Detected',
      'Animal $animalId has $severity (Score: $lamenessScore/5)',
      backgroundColor: Colors.orange,
    );
  }

  /// Show a milking status alert
  void showMilkingAlert(
    BuildContext context,
    String animalId,
    bool isMilking,
  ) {
    showNotification(
      context,
      'milking',
      'Milking Status Update',
      'Animal $animalId is ${isMilking ? "being milked" : "not being milked"}',
      backgroundColor: Colors.blue,
    );
  }

  /// Show a health alert
  void showHealthAlert(
    BuildContext context,
    String animalId,
    String healthIssue,
  ) {
    showNotification(
      context,
      'health',
      'Health Alert',
      'Animal $animalId: $healthIssue',
      backgroundColor: Colors.red,
    );
  }

  /// Get color for notification type
  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'lameness':
        return Colors.orange;
      case 'milking':
        return Colors.blue;
      case 'health':
        return Colors.red;
      default:
        return Colors.teal;
    }
  }
}
