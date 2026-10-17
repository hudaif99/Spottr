import 'package:timezone/timezone.dart' as tz;
import '../domain/models/workout_schedule.dart';
import '../domain/repositories/workout_repository.dart';
import 'notification_ids.dart';
import 'notification_service.dart';
import 'reminder_dates.dart';

class WorkoutReminderScheduler {
  final NotificationService _service;
  final WorkoutRepository? _workouts;
  final tz.TZDateTime Function() _now;
  final Future<void> Function()? _refreshTimeZone;
  Future<void> _operations = Future.value();

  WorkoutReminderScheduler(
    this._service, {
    WorkoutRepository? workouts,
    tz.TZDateTime Function()? now,
    Future<void> Function()? refreshTimeZone,
  }) : _workouts = workouts,
       _now = now ?? (() => tz.TZDateTime.now(tz.local)),
       _refreshTimeZone = refreshTimeZone;

  Future<void> _enqueue(Future<void> Function() action) {
    final next = _operations.then((_) => action());
    _operations = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  Future<void> rescheduleAll(WorkoutSchedule schedule) => _enqueue(() async {
    final current = _workouts == null
        ? schedule
        : await _workouts.getScheduleForToday();
    var reminders = const <WorkoutReminder>[];
    if (current != null &&
        current.remindersEnabled &&
        current.workoutDays.isNotEmpty) {
      await _refreshTimeZone?.call();
      final history = await _workouts?.getWorkoutLogs();
      final active = _workouts?.getActiveWorkout();
      reminders = upcomingWorkoutReminders(
        schedule: current,
        now: _now(),
        history: history ?? const [],
        activeWorkout: active,
      );
    }
    await _cancelWorkoutReminders();
    await _cancelStreakReminder();
    await _cancelWeeklySummary();
    for (final reminder in reminders) {
      await _service.schedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        date: reminder.date,
        channelId: reminder.channelId,
      );
    }
  });

  Future<void> cancelWorkoutReminders() => _enqueue(_cancelWorkoutReminders);
  Future<void> cancelStreakReminder() => _enqueue(_cancelStreakReminder);
  Future<void> cancelWeeklySummary() => _enqueue(_cancelWeeklySummary);

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
    await _service.cancelRange(
      NotificationIds.datedEarlyMin,
      NotificationIds.datedEarlyMax,
    );
    await _service.cancelRange(
      NotificationIds.datedImmediateMin,
      NotificationIds.datedImmediateMax,
    );
    await _service.cancelRange(
      NotificationIds.datedMissedMin,
      NotificationIds.datedMissedMax,
    );
  }

  Future<void> _cancelStreakReminder() async {
    await _service.cancel(NotificationIds.streakReminder);
    await _service.cancelRange(
      NotificationIds.datedStreakMin,
      NotificationIds.datedStreakMax,
    );
  }

  Future<void> _cancelWeeklySummary() async {
    await _service.cancel(NotificationIds.weeklySummary);
    await _service.cancelRange(
      NotificationIds.datedSummaryMin,
      NotificationIds.datedSummaryMax,
    );
  }

  Future<void> showPersonalRecordNotification(String detail) =>
      _service.showNow(
        id: NotificationIds.personalRecord,
        title: '🏆 New Personal Record!',
        body: detail,
        channelId: NotificationChannels.achievements,
      );

  Future<void> showMilestoneNotification(int totalWorkouts) => _service.showNow(
    id: NotificationIds.milestone,
    title: '🎯 Milestone Reached!',
    body: "You've completed $totalWorkouts workouts. Keep going!",
    channelId: NotificationChannels.achievements,
  );

  Future<void> scheduleTestNotification() => _enqueue(() async {
    await _refreshTimeZone?.call();
    await _service.schedule(
      id: NotificationIds.testNotification,
      title: '✅ Notifications are Working',
      body: 'Spottr notifications are set up correctly on your device.',
      date: _now().add(const Duration(seconds: 10)),
      channelId: NotificationChannels.workoutReminders,
    );
  });
}
