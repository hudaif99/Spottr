import '../data/models/workout_log.dart';

class HistorySummary {
  final int workouts;
  final int completedSets;
  final double volume;

  const HistorySummary({
    required this.workouts,
    required this.completedSets,
    required this.volume,
  });

  factory HistorySummary.fromLogs(Iterable<WorkoutLog> logs) {
    var workouts = 0;
    var sets = 0;
    var volume = 0.0;
    for (final log in logs) {
      workouts++;
      for (final set in log.exerciseLogs.values.expand((sets) => sets)) {
        if (!set.isCompleted) continue;
        sets++;
        volume += set.weight * set.reps;
      }
    }
    return HistorySummary(
      workouts: workouts,
      completedSets: sets,
      volume: volume,
    );
  }
}

Duration? recordedWorkoutDuration(WorkoutLog log) {
  final end = log.endTime;
  if (end == null || end.isBefore(log.startTime)) return null;
  return end.difference(log.startTime);
}
