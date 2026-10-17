import '../../domain/history_summary.dart';
import '../../domain/models/workout_log.dart';

String formatWorkoutDuration(WorkoutLog log) {
  final duration = recordedWorkoutDuration(log);
  if (duration == null) return 'Duration unavailable';
  if (duration.inMinutes == 0) return 'Under 1 min';
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  return hours == 0 ? '$minutes min' : '${hours}h ${minutes}m';
}
