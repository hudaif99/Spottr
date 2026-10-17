import 'workout_day.dart';
import 'set_log.dart';

class ActiveWorkout {
  final String workoutLogId;
  final String planId;
  final WorkoutDay day;
  final DateTime startTime;
  final Map<String, List<SetLog>> exerciseLogs;
  final Map<String, List<SetLog>> previousExerciseLogs;
  final DateTime? restUntil;

  ActiveWorkout({
    required this.workoutLogId,
    required this.planId,
    required this.day,
    required this.startTime,
    required Map<String, List<SetLog>> exerciseLogs,
    Map<String, List<SetLog>> previousExerciseLogs = const {},
    this.restUntil,
  }) : exerciseLogs = immutableSetLogs(exerciseLogs),
       previousExerciseLogs = immutableSetLogs(previousExerciseLogs);
}
