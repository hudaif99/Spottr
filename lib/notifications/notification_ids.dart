/// Centralised, deterministic notification IDs.
///
/// Using fixed numeric ranges prevents duplicate notifications across
/// app restarts and makes bulk-cancel by range straightforward.
class NotificationIds {
  // --- Workout Reminders (per weekday, weekday: 1=Mon…7=Sun) ---

  /// 30-minute early reminders → IDs 101–107
  static int earlyReminder(int weekday) => 100 + weekday;

  /// 5-minute final reminders → IDs 201–207
  static int immediateReminder(int weekday) => 200 + weekday;

  /// Missed-workout reminders (30 min AFTER workout time) → IDs 301–307
  static int missedWorkout(int weekday) => 300 + weekday;

  //  Always-on reminders

  /// Daily 20:00 streak protection reminder
  static const int streakReminder = 400;

  /// Weekly Sunday 19:00 progress summary
  static const int weeklySummary = 500;

  // Event-triggered (shown immediately)

  /// Personal record achieved
  static const int personalRecord = 600;

  /// Milestone workout count reached
  static const int milestone = 700;

  /// Test notification (fires after 10 s)
  static const int testNotification = 999;

  //  Bulk-cancel ranges
  static const int earlyReminderMin = 101;
  static const int earlyReminderMax = 107;
  static const int immediateReminderMin = 201;
  static const int immediateReminderMax = 207;
  static const int missedWorkoutMin = 301;
  static const int missedWorkoutMax = 307;
}
