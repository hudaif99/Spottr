import 'set_log.dart';

class WorkoutLog {
  final String id;
  final String planId;
  final String dayId;
  final String dayName;
  final DateTime startTime;
  final DateTime? endTime;

  final Map<String, List<SetLog>> exerciseLogs;
  final Map<String, String> exerciseNames;
  final Map<String, String> exerciseIdentities;

  WorkoutLog({
    required this.id,
    required this.planId,
    required this.dayId,
    required this.dayName,
    required this.startTime,
    this.endTime,
    Map<String, List<SetLog>> exerciseLogs = const {},
    Map<String, String> exerciseNames = const {},
    Map<String, String> exerciseIdentities = const {},
  }) : exerciseLogs = immutableSetLogs(exerciseLogs),
       exerciseNames = Map.unmodifiable(exerciseNames),
       exerciseIdentities = Map.unmodifiable(exerciseIdentities);

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
    Map<String, String>? exerciseIdentities,
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
      exerciseIdentities: exerciseIdentities ?? this.exerciseIdentities,
    );
  }
}
