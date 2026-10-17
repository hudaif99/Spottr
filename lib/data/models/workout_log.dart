import 'package:hive/hive.dart';
import 'set_log.dart';

part 'workout_log.g.dart';

@HiveType(typeId: 4)
class WorkoutLog extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String planId;

  @HiveField(2)
  final String dayId;

  @HiveField(3)
  final String dayName;

  @HiveField(4)
  final DateTime startTime;

  @HiveField(5)
  final DateTime? endTime;

  // Map of exerciseId to list of SetLogs
  @HiveField(6)
  final Map<String, List<SetLog>> exerciseLogs;

  @HiveField(7, defaultValue: {})
  final Map<String, String> exerciseNames;

  WorkoutLog({
    required this.id,
    required this.planId,
    required this.dayId,
    required this.dayName,
    required this.startTime,
    this.endTime,
    this.exerciseLogs = const {},
    this.exerciseNames = const {},
  });

  int get totalDurationInSeconds {
    if (endTime == null) return DateTime.now().difference(startTime).inSeconds;
    return endTime!.difference(startTime).inSeconds;
  }

  double get totalVolume {
    double volume = 0;
    for (var sets in exerciseLogs.values) {
      for (var set in sets) {
        if (set.isCompleted) {
          volume += (set.weight * set.reps);
        }
      }
    }
    return volume;
  }

  WorkoutLog copyWith({
    String? id,
    String? planId,
    String? dayId,
    String? dayName,
    DateTime? startTime,
    DateTime? endTime,
    Map<String, List<SetLog>>? exerciseLogs,
    Map<String, String>? exerciseNames,
  }) {
    return WorkoutLog(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      dayId: dayId ?? this.dayId,
      dayName: dayName ?? this.dayName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      exerciseLogs: exerciseLogs ?? this.exerciseLogs,
      exerciseNames: exerciseNames ?? this.exerciseNames,
    );
  }
}
