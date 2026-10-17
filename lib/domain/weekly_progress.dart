import 'history_summary.dart';
import 'models/workout_log.dart';

class WeeklyProgress {
  final List<DateTime> days;
  final List<WorkoutLog> workouts;
  final HistorySummary summary;
  final Duration recordedDuration;
  final int missingDurations;

  WeeklyProgress._(
    this.days,
    this.workouts,
    this.summary,
    this.recordedDuration,
    this.missingDurations,
  );

  factory WeeklyProgress.fromLogs(
    Iterable<WorkoutLog> logs, {
    required DateTime now,
  }) {
    final localNow = now.toLocal();
    // Calendar dates avoid shifting the week when a daylight-saving offset changes.
    final monday = DateTime(
      localNow.year,
      localNow.month,
      localNow.day - localNow.weekday + 1,
    );
    final days = List<DateTime>.unmodifiable(
      List.generate(
        7,
        (index) => DateTime(monday.year, monday.month, monday.day + index),
      ),
    );
    final workouts = List<WorkoutLog>.unmodifiable(
      logs.where(
        (log) => !log.startTime.isBefore(monday) && !log.startTime.isAfter(now),
      ),
    );
    var duration = Duration.zero;
    var missing = 0;
    for (final workout in workouts) {
      final recorded = recordedWorkoutDuration(workout);
      if (recorded == null) {
        missing++;
      } else {
        duration += recorded;
      }
    }
    return WeeklyProgress._(
      days,
      workouts,
      HistorySummary.fromLogs(workouts),
      duration,
      missing,
    );
  }

  bool trainedOn(DateTime date) => workouts.any((log) {
    final start = log.startTime.toLocal();
    return start.year == date.year &&
        start.month == date.month &&
        start.day == date.day &&
        log.exerciseLogs.values
            .expand((sets) => sets)
            .any((set) => set.isCompleted);
  });
}
