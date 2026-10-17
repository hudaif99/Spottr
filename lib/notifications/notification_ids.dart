/// Centralised, deterministic notification IDs.
///
/// Using fixed numeric ranges prevents duplicate notifications across
/// app restarts and makes bulk-cancel by range straightforward.
class NotificationIds {
  static const reminderWindowDays = 14;
  static const reminderSlots = 32;
  static const datedEarlyMin = 10000;
  static const datedEarlyMax = datedEarlyMin + reminderSlots - 1;
  static const datedImmediateMin = 10100;
  static const datedImmediateMax = datedImmediateMin + reminderSlots - 1;
  static const datedMissedMin = 10200;
  static const datedMissedMax = datedMissedMin + reminderSlots - 1;
  static const datedStreakMin = 10300;
  static const datedStreakMax = datedStreakMin + reminderSlots - 1;
  static const datedSummaryMin = 10400;
  static const datedSummaryMax = datedSummaryMin + reminderSlots - 1;

  // Legacy recurring IDs are retained only for cancellation after an upgrade.
  static const int streakReminder = 400;
  static const int weeklySummary = 500;
  static const int personalRecord = 600;
  static const int milestone = 700;
  static const int testNotification = 999;
  static const int earlyReminderMin = 101;
  static const int earlyReminderMax = 107;
  static const int immediateReminderMin = 201;
  static const int immediateReminderMax = 207;
  static const int missedWorkoutMin = 301;
  static const int missedWorkoutMax = 307;
}
