import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notification channel IDs – must match those declared in AndroidManifest.xml.
class NotificationChannels {
  static const String workoutReminders = 'workout_reminders';
  static const String streaksMotivation = 'streaks_motivation';
  static const String achievements = 'achievements';
  static const String weeklySummaries = 'weekly_summaries';
}

/// Low-level notification service.
///
/// Responsibilities:
///   • Plugin initialisation
///   • Android channel creation
///   • show / zonedSchedule / cancel helpers
///
/// Everything above scheduling logic (i.e. *when* to schedule) lives in
/// [WorkoutReminderScheduler]. This class only handles *how* to display.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  FlutterLocalNotificationsPlugin get plugin => _plugin;

  // init

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

    // Create Android notification channels
    await _createAndroidChannels();
  }

  Future<void> _createAndroidChannels() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationChannels.workoutReminders,
        'Workout Reminders',
        description: 'Reminders before and after your scheduled workouts.',
        importance: Importance.high,
      ),
    );

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationChannels.streaksMotivation,
        'Streaks & Motivation',
        description: 'Streak protection and motivational nudges.',
        importance: Importance.defaultImportance,
      ),
    );

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationChannels.achievements,
        'Achievements',
        description: 'Personal records and milestone celebrations.',
        importance: Importance.high,
      ),
    );

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationChannels.weeklySummaries,
        'Weekly Summaries',
        description: 'Your weekly workout progress summary.',
        importance: Importance.defaultImportance,
      ),
    );
  }

  //  notification details

  NotificationDetails _buildDetails(String channelId) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        _channelName(channelId),
        importance:
            channelId == NotificationChannels.workoutReminders ||
                channelId == NotificationChannels.achievements
            ? Importance.high
            : Importance.defaultImportance,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  String _channelName(String channelId) {
    switch (channelId) {
      case NotificationChannels.workoutReminders:
        return 'Workout Reminders';
      case NotificationChannels.streaksMotivation:
        return 'Streaks & Motivation';
      case NotificationChannels.achievements:
        return 'Achievements';
      case NotificationChannels.weeklySummaries:
        return 'Weekly Summaries';
      default:
        return 'Spottr';
    }
  }

  // public API

  /// Show an immediate notification.
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    required String channelId,
  }) async {
    await _plugin.show(id, title, body, _buildDetails(channelId));
  }

  /// Cancel a single notification by ID.
  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  /// Cancel all notifications within an inclusive ID range.
  Future<void> cancelRange(int min, int max) async {
    for (int id = min; id <= max; id++) {
      await _plugin.cancel(id);
    }
  }

  /// Cancel every pending notification.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Expose the plugin for [WorkoutReminderScheduler] to call zonedSchedule.
  NotificationDetails detailsForChannel(String channelId) =>
      _buildDetails(channelId);
}
