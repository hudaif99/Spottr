import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as zones;
import 'package:timezone/timezone.dart' as tz;
import 'package:spottr/domain/models/active_workout.dart';
import 'package:spottr/domain/models/set_log.dart';
import 'package:spottr/domain/models/workout_day.dart';
import 'package:spottr/domain/models/workout_log.dart';
import 'package:spottr/domain/models/workout_schedule.dart';
import 'package:spottr/notifications/notification_ids.dart';
import 'package:spottr/notifications/reminder_dates.dart';

WorkoutSchedule schedule({
  int hour = 18,
  int minute = 0,
  List<int> days = const [1],
}) => WorkoutSchedule(
  workoutHour: hour,
  workoutMinute: minute,
  workoutDays: days,
);

bool inRange(WorkoutReminder reminder, int min) =>
    reminder.id >= min && reminder.id < min + NotificationIds.reminderSlots;

WorkoutLog completed(DateTime start, {DateTime? end, bool logged = true}) =>
    WorkoutLog(
      id: 'session',
      planId: 'plan',
      dayId: 'day',
      dayName: 'Day',
      startTime: start,
      endTime: end,
      exerciseLogs: {
        'entry': [SetLog(id: 'set', reps: 10, weight: 20, isCompleted: logged)],
      },
    );

void main() {
  setUpAll(zones.initializeTimeZones);

  test('early reminders for Monday after midnight fire on Sunday', () {
    final now = tz.TZDateTime(tz.UTC, 2026, 10, 18, 20);
    final reminders = upcomingWorkoutReminders(
      schedule: schedule(hour: 0, minute: 15),
      now: now,
    );
    final early = reminders.firstWhere(
      (reminder) => inRange(reminder, NotificationIds.datedEarlyMin),
    );
    expect(early.date, tz.TZDateTime(tz.UTC, 2026, 10, 18, 23, 45));
    final finalReminder = reminders.firstWhere(
      (reminder) => inRange(reminder, NotificationIds.datedImmediateMin),
    );
    expect(finalReminder.date, tz.TZDateTime(tz.UTC, 2026, 10, 19, 0, 10));
  });

  test('late Sunday missed reminder remains due on Monday after midnight', () {
    final now = tz.TZDateTime(tz.UTC, 2026, 10, 19, 0, 5);
    final reminders = upcomingWorkoutReminders(
      schedule: schedule(hour: 23, minute: 45, days: [7]),
      now: now,
    );
    final missed = reminders.firstWhere(
      (reminder) => inRange(reminder, NotificationIds.datedMissedMin),
    );
    expect(missed.date, tz.TZDateTime(tz.UTC, 2026, 10, 19, 0, 15));
  });

  test(
    'seven training days fit inside the native pending limit with stable unique IDs',
    () {
      final now = tz.TZDateTime(tz.UTC, 2026, 10, 19);
      final allDays = schedule(days: [1, 2, 3, 4, 5, 6, 7]);
      final reminders = upcomingWorkoutReminders(schedule: allDays, now: now);
      expect(reminders, hasLength(58));
      expect(reminders.map((reminder) => reminder.id).toSet(), hasLength(58));
      expect(
        reminders.every(
          (reminder) =>
              reminder.date.isAfter(now) &&
              reminder.date.isBefore(tz.TZDateTime(tz.UTC, 2026, 11, 2)),
        ),
        isTrue,
      );
      final later = upcomingWorkoutReminders(
        schedule: allDays,
        now: now.add(const Duration(hours: 1)),
      );
      expect(
        later.map((reminder) => reminder.id),
        reminders.map((reminder) => reminder.id),
      );
    },
  );

  for (final date in [(2026, 3, 7), (2026, 10, 31)]) {
    test('local workout and daily times survive DST around $date', () {
      final zone = tz.getLocation('America/New_York');
      final now = tz.TZDateTime(zone, date.$1, date.$2, date.$3, 12);
      final reminders = upcomingWorkoutReminders(
        schedule: schedule(days: [1, 2, 3, 4, 5, 6, 7]),
        now: now,
      );
      expect(
        reminders
            .where(
              (reminder) =>
                  inRange(reminder, NotificationIds.datedImmediateMin),
            )
            .every(
              (reminder) =>
                  reminder.date.hour == 17 && reminder.date.minute == 55,
            ),
        isTrue,
      );
      expect(
        reminders
            .where(
              (reminder) => inRange(reminder, NotificationIds.datedStreakMin),
            )
            .every((reminder) => reminder.date.hour == 20),
        isTrue,
      );
      expect(
        reminders.map((reminder) => reminder.date.timeZoneOffset).toSet(),
        hasLength(2),
      );
    });
  }

  test('a nonexistent spring time moves forward through the DST gap', () {
    final zone = tz.getLocation('America/New_York');
    final reminders = upcomingWorkoutReminders(
      schedule: schedule(hour: 2, minute: 30, days: [7]),
      now: tz.TZDateTime(zone, 2026, 3, 7, 12),
    );
    final finalReminder = reminders.firstWhere(
      (reminder) => inRange(reminder, NotificationIds.datedImmediateMin),
    );
    expect(finalReminder.date.toUtc(), DateTime.utc(2026, 3, 8, 7, 25));
    expect([finalReminder.date.hour, finalReminder.date.minute], [3, 25]);
  });

  test('an ambiguous fall time schedules only the first occurrence', () {
    final zone = tz.getLocation('America/New_York');
    final reminders = upcomingWorkoutReminders(
      schedule: schedule(hour: 1, minute: 30, days: [7]),
      now: tz.TZDateTime(zone, 2026, 10, 31, 12),
    );
    final finalReminders = reminders
        .where(
          (reminder) =>
              inRange(reminder, NotificationIds.datedImmediateMin) &&
              reminder.date.month == 11 &&
              reminder.date.day == 1,
        )
        .toList();
    expect(finalReminders, hasLength(1));
    expect(
      finalReminders.single.date.toUtc(),
      DateTime.utc(2026, 11, 1, 5, 25),
    );
  });

  test(
    'completion suppresses only that day and keeps future recurring dates',
    () {
      final now = tz.TZDateTime(tz.UTC, 2026, 10, 19, 10);
      final reminders = upcomingWorkoutReminders(
        schedule: schedule(),
        now: now,
        history: [completed(tz.TZDateTime(tz.UTC, 2026, 10, 19, 8), end: now)],
      );
      expect(reminders.any((reminder) => reminder.date.day == 19), isFalse);
      expect(
        reminders.any(
          (reminder) =>
              inRange(reminder, NotificationIds.datedEarlyMin) &&
              reminder.date.day == 26,
        ),
        isTrue,
      );
      expect(
        reminders.any(
          (reminder) =>
              inRange(reminder, NotificationIds.datedStreakMin) &&
              reminder.date.day == 20,
        ),
        isTrue,
      );
    },
  );

  test(
    'active sessions suppress training prompts but not completion nudges; cancel restores prompts',
    () {
      final now = tz.TZDateTime(tz.UTC, 2026, 10, 19, 10);
      final active = ActiveWorkout(
        workoutLogId: 'session',
        planId: 'plan',
        day: WorkoutDay(id: 'day', name: 'Day'),
        startTime: now,
        exerciseLogs: const {},
      );
      final reminders = upcomingWorkoutReminders(
        schedule: schedule(),
        now: now,
        activeWorkout: active,
      );
      expect(
        reminders.any(
          (reminder) =>
              reminder.date.day == 19 &&
              reminder.channelId == 'workout_reminders',
        ),
        isFalse,
      );
      expect(
        reminders.any(
          (reminder) =>
              reminder.date.day == 19 &&
              inRange(reminder, NotificationIds.datedStreakMin),
        ),
        isTrue,
      );
      final cancelled = upcomingWorkoutReminders(
        schedule: schedule(),
        now: now,
      );
      expect(
        cancelled.any(
          (reminder) =>
              reminder.date.day == 19 &&
              reminder.channelId == 'workout_reminders',
        ),
        isTrue,
      );
    },
  );

  test(
    'overnight completion suppresses both training dates and uses local completion day for streaks',
    () {
      final zone = tz.getLocation('Asia/Kolkata');
      final now = tz.TZDateTime(zone, 2026, 10, 20, 0, 30);
      final reminders = upcomingWorkoutReminders(
        schedule: schedule(hour: 23, minute: 45, days: [1, 2]),
        now: now,
        history: [
          completed(
            DateTime.utc(2026, 10, 19, 18),
            end: DateTime.utc(2026, 10, 19, 19),
          ),
        ],
      );
      expect(reminders.any((reminder) => reminder.date.day == 20), isFalse);
      expect(
        reminders.any(
          (reminder) =>
              reminder.date.day == 21 &&
              inRange(reminder, NotificationIds.datedStreakMin),
        ),
        isTrue,
      );
    },
  );

  test(
    'unfinished suggestions do not suppress reminders and disabled/empty schedules produce none',
    () {
      final now = tz.TZDateTime(tz.UTC, 2026, 10, 19, 10);
      final plan = schedule();
      final reminders = upcomingWorkoutReminders(
        schedule: plan,
        now: now,
        history: [completed(now, logged: false)],
      );
      expect(
        reminders.any(
          (reminder) =>
              reminder.date.day == 19 &&
              reminder.channelId == 'workout_reminders',
        ),
        isTrue,
      );
      expect(
        upcomingWorkoutReminders(
          schedule: plan.copyWith(remindersEnabled: false),
          now: now,
        ),
        isEmpty,
      );
      expect(
        upcomingWorkoutReminders(
          schedule: plan.copyWith(workoutDays: []),
          now: now,
        ),
        isEmpty,
      );
    },
  );

  test(
    'a reminder at or before now is excluded, including year-end offsets',
    () {
      final now = tz.TZDateTime(tz.UTC, 2026, 12, 31, 23, 45);
      final reminders = upcomingWorkoutReminders(
        schedule: schedule(hour: 0, minute: 15, days: [5]),
        now: now,
      );
      expect(reminders.every((reminder) => reminder.date.isAfter(now)), isTrue);
      expect(
        reminders
            .firstWhere(
              (reminder) =>
                  inRange(reminder, NotificationIds.datedImmediateMin),
            )
            .date,
        tz.TZDateTime(tz.UTC, 2027, 1, 1, 0, 10),
      );
    },
  );
}
