import 'package:flutter_test/flutter_test.dart';
import 'package:spottr/domain/models/set_log.dart';
import 'package:spottr/domain/models/workout_log.dart';
import 'package:spottr/domain/weekly_progress.dart';
import 'package:spottr/presentation/formatters/workout_duration.dart';

WorkoutLog _log(
  String id,
  DateTime start, {
  DateTime? end,
  bool completed = true,
}) => WorkoutLog(
  id: id,
  planId: 'plan',
  dayId: 'day',
  dayName: 'Workout',
  startTime: start,
  endTime: end,
  exerciseLogs: {
    'exercise': [
      SetLog(id: 'logged', weight: 20, reps: 8, isCompleted: completed),
      SetLog(id: 'suggestion', weight: 999, reps: 99),
    ],
  },
);

void main() {
  test(
    'week includes Monday midnight through now, excluding future timestamps',
    () {
      final now = DateTime(2026, 10, 17, 18);
      final monday = DateTime(2026, 10, 12);
      final logs = [
        _log('before', monday.subtract(const Duration(seconds: 1))),
        _log('monday', monday, end: monday.add(const Duration(minutes: 45))),
        _log('today', now.subtract(const Duration(minutes: 30)), end: now),
        _log('later-today', now.add(const Duration(seconds: 1))),
        _log('next-week', DateTime(2026, 10, 19)),
      ];
      final week = WeeklyProgress.fromLogs(logs, now: now);
      expect(week.workouts.map((log) => log.id), ['monday', 'today']);
      expect(week.summary.workouts, 2);
      expect(week.summary.completedSets, 2);
      expect(week.summary.volume, 320);
      expect(week.recordedDuration, const Duration(minutes: 75));
      expect(week.missingDurations, 0);
      expect(week.trainedOn(monday), isTrue);
      expect(week.trainedOn(DateTime(2026, 10, 18)), isFalse);
      expect(logs, hasLength(5));
      expect(() => week.workouts.clear(), throwsUnsupportedError);
    },
  );

  test(
    'unknown and invalid durations never grow or reduce recorded minutes',
    () {
      final now = DateTime(2026, 10, 17, 18);
      final unknown = _log('unknown', DateTime(2026, 10, 15));
      final invalid = _log(
        'invalid',
        now,
        end: now.subtract(const Duration(minutes: 1)),
      );
      final valid = _log(
        'valid',
        now.subtract(const Duration(minutes: 20)),
        end: now,
      );
      final week = WeeklyProgress.fromLogs([unknown, invalid, valid], now: now);
      expect(week.recordedDuration.inMinutes, 20);
      expect(week.missingDurations, 2);
      expect(formatWorkoutDuration(unknown), 'Duration unavailable');
      expect(formatWorkoutDuration(invalid), 'Duration unavailable');
      expect(formatWorkoutDuration(valid), '20 min');
      expect(
        formatWorkoutDuration(
          _log('short', now, end: now.add(const Duration(seconds: 30))),
        ),
        'Under 1 min',
      );
    },
  );

  test(
    'calendar week crosses year and month boundaries without elapsed-day offsets',
    () {
      final week = WeeklyProgress.fromLogs([], now: DateTime(2027, 1, 3, 23));
      expect(week.days, [
        for (var day = 28; day <= 34; day++) DateTime(2026, 12, day),
      ]);
      expect(week.days.first.weekday, DateTime.monday);
      expect(week.days.last.weekday, DateTime.sunday);
      expect(week.summary.workouts, 0);
      expect(week.recordedDuration, Duration.zero);
      expect(week.missingDurations, 0);
      expect(() => week.days.clear(), throwsUnsupportedError);
      final nextWeek = WeeklyProgress.fromLogs([], now: DateTime(2027, 1, 4));
      expect(nextWeek.days.first, DateTime(2027, 1, 4));
    },
  );

  test('calendar marks completed local dates, including UTC timestamps', () {
    final local = DateTime(2026, 10, 14, 0, 5);
    final week = WeeklyProgress.fromLogs([
      _log('utc', local.toUtc()),
      _log('unlogged', DateTime(2026, 10, 15, 12), completed: false),
    ], now: DateTime(2026, 10, 17));
    expect(week.trainedOn(DateTime(2026, 10, 14)), isTrue);
    expect(week.trainedOn(DateTime(2026, 10, 15)), isFalse);
  });
}
