import 'package:timezone/timezone.dart' as tz;
import '../domain/models/active_workout.dart';
import '../domain/models/workout_log.dart';
import '../domain/models/workout_schedule.dart';
import 'notification_ids.dart';
import 'notification_service.dart';

class WorkoutReminder {
  final int id;
  final tz.TZDateTime date;
  final String title;
  final String body;
  final String channelId;
  const WorkoutReminder({
    required this.id,
    required this.date,
    required this.title,
    required this.body,
    required this.channelId,
  });
}

List<WorkoutReminder> upcomingWorkoutReminders({
  required WorkoutSchedule schedule,
  required tz.TZDateTime now,
  Iterable<WorkoutLog> history = const [],
  ActiveWorkout? activeWorkout,
}) {
  if (!schedule.remindersEnabled || schedule.workoutDays.isEmpty) {
    return const [];
  }
  final zone = now.location;
  int dayKey(DateTime value) {
    final local = tz.TZDateTime.from(value, zone);
    return DateTime.utc(
          local.year,
          local.month,
          local.day,
        ).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
  }

  final trainedDays = <int>{};
  final completedDays = <int>{};
  for (final log in history) {
    if (!log.exerciseLogs.values
        .expand((sets) => sets)
        .any((set) => set.isCompleted)) {
      continue;
    }
    trainedDays.add(dayKey(log.startTime));
    final finished =
        log.endTime != null && !log.endTime!.isBefore(log.startTime)
        ? log.endTime!
        : log.startTime;
    trainedDays.add(dayKey(finished));
    completedDays.add(dayKey(finished));
  }
  if (activeWorkout != null) trainedDays.add(dayKey(activeWorkout.startTime));
  final end = tz.TZDateTime(
    zone,
    now.year,
    now.month,
    now.day + NotificationIds.reminderWindowDays,
  );
  final reminders = <WorkoutReminder>[];
  void add(
    int base,
    tz.TZDateTime date,
    String title,
    String body,
    String channel,
  ) {
    if (!date.isAfter(now) || !date.isBefore(end)) return;
    reminders.add(
      WorkoutReminder(
        id: base + dayKey(date) % NotificationIds.reminderSlots,
        date: date,
        title: title,
        body: body,
        channelId: channel,
      ),
    );
  }

  // Include adjacent workout dates whose offsets can cross the window's edges.
  for (
    var offset = -1;
    offset <= NotificationIds.reminderWindowDays;
    offset++
  ) {
    final day = tz.TZDateTime(zone, now.year, now.month, now.day + offset, 12);
    if (schedule.workoutDays.contains(day.weekday) &&
        !trainedDays.contains(dayKey(day))) {
      final workout = tz.TZDateTime(
        zone,
        day.year,
        day.month,
        day.day,
        schedule.workoutHour,
        schedule.workoutMinute,
      );
      add(
        NotificationIds.datedEarlyMin,
        workout.subtract(const Duration(minutes: 30)),
        '💪 Get Ready to Hit the Gym',
        'Your workout starts in 30 minutes. Time to get prepared.',
        NotificationChannels.workoutReminders,
      );
      add(
        NotificationIds.datedImmediateMin,
        workout.subtract(const Duration(minutes: 5)),
        '🔥 Workout Starts Soon',
        "Only 5 minutes left. Let's get moving.",
        NotificationChannels.workoutReminders,
      );
      add(
        NotificationIds.datedMissedMin,
        workout.add(const Duration(minutes: 30)),
        '⏰ Still Planning to Train?',
        'A short workout is better than none. You can still complete your scheduled session.',
        NotificationChannels.workoutReminders,
      );
    }
    if (!completedDays.contains(dayKey(day))) {
      add(
        NotificationIds.datedStreakMin,
        tz.TZDateTime(zone, day.year, day.month, day.day, 20),
        '🔥 Protect Your Streak',
        "Complete today's workout to keep your streak alive.",
        NotificationChannels.streaksMotivation,
      );
    }
    if (day.weekday == DateTime.sunday) {
      add(
        NotificationIds.datedSummaryMin,
        tz.TZDateTime(zone, day.year, day.month, day.day, 19),
        '📊 Weekly Progress Summary',
        'Check out how you performed this week!',
        NotificationChannels.weeklySummaries,
      );
    }
  }
  reminders.sort((a, b) => a.date.compareTo(b.date));
  return List.unmodifiable(reminders);
}
