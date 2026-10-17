import 'package:hive/hive.dart';
import 'workout_day.dart';
import 'set_log.dart';

part 'active_workout.g.dart';

@HiveType(typeId: 5)
class ActiveWorkout extends HiveObject {
  @HiveField(0)
  final String workoutLogId;

  @HiveField(1)
  final String planId;

  @HiveField(2)
  final WorkoutDay day;

  @HiveField(3)
  final DateTime startTime;

  @HiveField(4)
  final Map<String, List<SetLog>> exerciseLogs;

  @HiveField(5)
  final Map<String, List<SetLog>> previousExerciseLogs;

  @HiveField(6)
  final DateTime? restUntil;

  ActiveWorkout({
    required this.workoutLogId,
    required this.planId,
    required this.day,
    required this.startTime,
    required this.exerciseLogs,
    this.previousExerciseLogs = const {},
    this.restUntil,
  });
}
