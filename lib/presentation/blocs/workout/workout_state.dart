import 'package:equatable/equatable.dart';
import '../../../data/models/set_log.dart';
import '../../../data/models/workout_day.dart';

abstract class WorkoutState extends Equatable {
  const WorkoutState();

  @override
  List<Object?> get props => [];
}

class WorkoutInitial extends WorkoutState {}

class WorkoutInProgress extends WorkoutState {
  final String workoutLogId;
  final String planId;
  final WorkoutDay day;
  final DateTime startTime;
  final Map<String, List<SetLog>> exerciseLogs;

  const WorkoutInProgress({
    required this.workoutLogId,
    required this.planId,
    required this.day,
    required this.startTime,
    required this.exerciseLogs,
  });

  WorkoutInProgress copyWith({
    String? workoutLogId,
    String? planId,
    WorkoutDay? day,
    DateTime? startTime,
    Map<String, List<SetLog>>? exerciseLogs,
  }) {
    return WorkoutInProgress(
      workoutLogId: workoutLogId ?? this.workoutLogId,
      planId: planId ?? this.planId,
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      exerciseLogs: exerciseLogs ?? this.exerciseLogs,
    );
  }

  @override
  List<Object?> get props => [
    workoutLogId,
    planId,
    day,
    startTime,
    exerciseLogs,
  ];
}

class WorkoutCompleted extends WorkoutState {}

class WorkoutError extends WorkoutState {
  final String message;
  const WorkoutError(this.message);

  @override
  List<Object?> get props => [message];
}
