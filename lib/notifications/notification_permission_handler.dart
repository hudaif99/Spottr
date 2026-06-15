import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_service.dart';

/// Handles runtime notification permission requests and status checks.
///
/// Keeps all platform-specific permission logic in one place so the rest
/// of the app can remain platform-agnostic.
class NotificationPermissionHandler {
  final NotificationService _service;

  NotificationPermissionHandler(this._service);

  /// Request notification permission from the OS.
  ///
  /// Returns `true` if the user granted permission, `false` otherwise.
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final android = _service.plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final result = await android?.requestNotificationsPermission();
      return result ?? false;
    } else if (Platform.isIOS) {
      final ios = _service.plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final result = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    }
    return false;
  }

  /// Returns the current permission status as one of:
  ///   'granted', 'denied', or 'undetermined'
  Future<String> checkPermissionStatus() async {
    if (Platform.isAndroid) {
      final android = _service.plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final enabled = await android?.areNotificationsEnabled();
      if (enabled == null) return 'undetermined';
      return enabled ? 'granted' : 'denied';
    } else if (Platform.isIOS) {
      // On iOS, use the pending-notifications count as a proxy:
      // If the plugin is initialized and the user hasn't been asked, return 'undetermined'.
      // A full implementation would use the app_settings package.
      // For now we return 'undetermined' on first launch.
      return 'undetermined';
    }
    return 'undetermined';
  }

  /// Opens the OS notification settings for the app.
  Future<void> openAppSettings() async {
    if (Platform.isAndroid) {
      // flutter_local_notifications v18 does not expose openNotificationSettings.
      // On Android, users need to navigate to Settings > Apps > Spottr > Notifications.
      // A future upgrade to flutter_local_notifications v19+ or the app_settings
      // package can provide a direct deep-link.
    }
  }
}
