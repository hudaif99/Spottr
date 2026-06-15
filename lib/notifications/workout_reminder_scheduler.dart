import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../data/models/workout_schedule.dart';
import 'notification_ids.dart';
import 'notification_service.dart';

class WorkoutReminderScheduler {
  final NotificationService _service;

  WorkoutReminderScheduler(this._service);

  Future<void> rescheduleAll(WorkoutSchedule schedule) async {
    await _cancelWorkoutReminders();
    await _cancelStreakReminder();
    await _cancelWeeklySummary();

    if (!schedule.remindersEnabled) return;

    await _scheduleWorkoutReminders(schedule);
    await _scheduleStreakReminder(schedule);
    await _scheduleWeeklySummary();
  }

  /// Cancel all workout-reminder notifications (early, immediate, missed).
  Future<void> cancelWorkoutReminders() => _cancelWorkoutReminders();

  /// Cancel just the streak reminder.
  Future<void> cancelStreakReminder() =>
      _service.cancel(NotificationIds.streakReminder);

  /// Cancel just the weekly summary.
  Future<void> cancelWeeklySummary() => _cancelWeeklySummary();

  /// Cancel the missed-workout reminder for today and reschedule it for
  /// next week so the weekly series continues uninterrupted.
  Future<void> cancelAndRescheduleTodaysMissedWorkout(
    WorkoutSchedule schedule,
  ) async {
    final weekday = DateTime.now().weekday; // 1–7
    final id = NotificationIds.missedWorkout(weekday);
    await _service.cancel(id);

    if (!schedule.remindersEnabled) return;

    // Reschedule for next occurrence of this weekday (7 days from now).
    // Because we're already past today's instance, the next fire is next week.
    await _scheduleMissedWorkoutForWeekday(
      weekday,
      schedule,
      forceNextWeek: true,
    );
  }

  /// Fire an immediate personal-record notification.
  Future<void> showPersonalRecordNotification(String detail) async {
    await _service.showNow(
      id: NotificationIds.personalRecord,
      title: '🏆 New Personal Record!',
      body: detail,
      channelId: NotificationChannels.achievements,
    );
  }

  /// Fire an immediate milestone notification.
  Future<void> showMilestoneNotification(int totalWorkouts) async {
    await _service.showNow(
      id: NotificationIds.milestone,
      title: '🎯 Milestone Reached!',
      body: "You've completed $totalWorkouts workouts. Keep going!",
      channelId: NotificationChannels.achievements,
    );
  }

  /// Send a test notification that fires 10 seconds from now.
  Future<void> scheduleTestNotification() async {
    final scheduledDate = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(seconds: 10));

    await _service.plugin.zonedSchedule(
      NotificationIds.testNotification,
      '✅ Notifications are Working',
      'Spottr notifications are set up correctly on your device.',
      scheduledDate,
      _service.detailsForChannel(NotificationChannels.workoutReminders),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _cancelWorkoutReminders() async {
    await _service.cancelRange(
      NotificationIds.earlyReminderMin,
      NotificationIds.earlyReminderMax,
    );
    await _service.cancelRange(
      NotificationIds.immediateReminderMin,
      NotificationIds.immediateReminderMax,
    );
    await _service.cancelRange(
      NotificationIds.missedWorkoutMin,
      NotificationIds.missedWorkoutMax,
    );
  }

  Future<void> _cancelStreakReminder() =>
      _service.cancel(NotificationIds.streakReminder);

  Future<void> _cancelWeeklySummary() =>
      _service.cancel(NotificationIds.weeklySummary);

  // Workout reminders (30-min, 5-min, missed)

  Future<void> _scheduleWorkoutReminders(WorkoutSchedule schedule) async {
    for (final weekday in schedule.workoutDays) {
      // ① 30-minute early reminder
      await _scheduleWeeklyNotification(
        id: NotificationIds.earlyReminder(weekday),
        weekday: weekday,
        hour: schedule.workoutHour,
        minute: schedule.workoutMinute,
        offsetMinutes: -30,
        title: '💪 Get Ready to Hit the Gym',
        body: 'Your workout starts in 30 minutes. Time to get prepared.',
        channelId: NotificationChannels.workoutReminders,
      );

      // ② 5-minute final reminder
      await _scheduleWeeklyNotification(
        id: NotificationIds.immediateReminder(weekday),
        weekday: weekday,
        hour: schedule.workoutHour,
        minute: schedule.workoutMinute,
        offsetMinutes: -5,
        title: '🔥 Workout Starts Soon',
        body: "Only 5 minutes left. Let's get moving.",
        channelId: NotificationChannels.workoutReminders,
      );

      // ③ Missed-workout reminder (30 min after)
      await _scheduleMissedWorkoutForWeekday(weekday, schedule);
    }
  }

  Future<void> _scheduleMissedWorkoutForWeekday(
    int weekday,
    WorkoutSchedule schedule, {
    bool forceNextWeek = false,
  }) async {
    await _scheduleWeeklyNotification(
      id: NotificationIds.missedWorkout(weekday),
      weekday: weekday,
      hour: schedule.workoutHour,
      minute: schedule.workoutMinute,
      offsetMinutes: 30, // 30 min AFTER workout time
      title: '⏰ Still Planning to Train Today?',
      body:
          "A short workout is better than none. You can still complete today's session.",
      channelId: NotificationChannels.workoutReminders,
      forceNextWeek: forceNextWeek,
    );
  }

  // Streak reminder (daily 20:00)

  Future<void> _scheduleStreakReminder(WorkoutSchedule schedule) async {
    // Fires every day at 20:00. WorkoutBloc cancels it on workout completion.
    // Only scheduled when the user has notifications enabled.
    final scheduledDate = _nextDailyOccurrence(hour: 20, minute: 0);

    await _service.plugin.zonedSchedule(
      NotificationIds.streakReminder,
      '🔥 Protect Your Streak',
      'Complete today\'s workout to keep your streak alive.',
      scheduledDate,
      _service.detailsForChannel(NotificationChannels.streaksMotivation),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeats daily
    );
  }

  //  Weekly summary (Sunday 19:00)

  Future<void> _scheduleWeeklySummary() async {
    // Sunday = weekday 7
    final scheduledDate = _nextWeeklyOccurrence(
      weekday: DateTime.sunday,
      hour: 19,
      minute: 0,
    );

    await _service.plugin.zonedSchedule(
      NotificationIds.weeklySummary,
      '📊 Weekly Progress Summary',
      'Check out how you performed this week!',
      scheduledDate,
      _service.detailsForChannel(NotificationChannels.weeklySummaries),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  // Generic weekly-repeating scheduler

  /// Schedule a notification that repeats weekly on [weekday] at
  /// ([hour]:[minute] + [offsetMinutes]).
  Future<void> _scheduleWeeklyNotification({
    required int id,
    required int weekday,
    required int hour,
    required int minute,
    required int offsetMinutes,
    required String title,
    required String body,
    required String channelId,
    bool forceNextWeek = false,
  }) async {
    // Apply offset in minutes
    int totalMinutes = hour * 60 + minute + offsetMinutes;

    // Clamp to valid 24-hour range
    if (totalMinutes < 0) totalMinutes += 24 * 60;
    if (totalMinutes >= 24 * 60) totalMinutes -= 24 * 60;

    final targetHour = totalMinutes ~/ 60;
    final targetMinute = totalMinutes % 60;

    final scheduledDate = _nextWeeklyOccurrence(
      weekday: weekday,
      hour: targetHour,
      minute: targetMinute,
      forceNextWeek: forceNextWeek,
    );

    await _service.plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      _service.detailsForChannel(channelId),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // dayOfWeekAndTime makes this repeat weekly automatically
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  // Date-time helpers

  /// Returns the next [tz.TZDateTime] for a given [weekday] and time.
  /// If [forceNextWeek] is true, always returns at least 7 days ahead.
  tz.TZDateTime _nextWeeklyOccurrence({
    required int weekday,
    required int hour,
    required int minute,
    bool forceNextWeek = false,
  }) {
    final now = tz.TZDateTime.now(tz.local);

    // Start from today at target time
    tz.TZDateTime candidate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Advance to the correct weekday
    int daysUntil = (weekday - candidate.weekday + 7) % 7;

    // If today is the right weekday but time has passed (or we must skip),
    // advance by 7 days to next week.
    if (daysUntil == 0 && (candidate.isBefore(now) || forceNextWeek)) {
      daysUntil = 7;
    }

    return candidate.add(Duration(days: daysUntil));
  }

  /// Returns the next [tz.TZDateTime] for a daily [hour]:[minute] occurrence.
  tz.TZDateTime _nextDailyOccurrence({required int hour, required int minute}) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime candidate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (candidate.isBefore(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }
}
