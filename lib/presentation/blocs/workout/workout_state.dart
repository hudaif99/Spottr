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
  final Map<String, List<SetLog>> previousExerciseLogs;
  final bool isSaving;
  final String? errorMessage;
  final DateTime? restUntil;
  final bool completionPending;

  const WorkoutInProgress({
    required this.workoutLogId,
    required this.planId,
    required this.day,
    required this.startTime,
    required this.exerciseLogs,
    this.previousExerciseLogs = const {},
    this.isSaving = false,
    this.errorMessage,
    this.restUntil,
    this.completionPending = false,
  });

  WorkoutInProgress copyWith({
    String? workoutLogId,
    String? planId,
    WorkoutDay? day,
    DateTime? startTime,
    Map<String, List<SetLog>>? exerciseLogs,
    Map<String, List<SetLog>>? previousExerciseLogs,
    bool? isSaving,
    String? errorMessage,
    DateTime? restUntil,
    bool clearRest = false,
    bool? completionPending,
  }) {
    return WorkoutInProgress(
      workoutLogId: workoutLogId ?? this.workoutLogId,
      planId: planId ?? this.planId,
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      exerciseLogs: exerciseLogs ?? this.exerciseLogs,
      previousExerciseLogs: previousExerciseLogs ?? this.previousExerciseLogs,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      restUntil: clearRest ? null : restUntil ?? this.restUntil,
      completionPending: completionPending ?? this.completionPending,
    );
  }

  bool get hasProgress {
    for (var logs in exerciseLogs.values) {
      if (logs.any(
        (set) => set.isCompleted || set.weight > 0 || set.reps > 0,
      )) {
        return true;
      }
    }
    return false;
  }

  @override
  List<Object?> get props => [
    workoutLogId,
    planId,
    day,
    startTime,
    exerciseLogs,
    previousExerciseLogs,
    isSaving,
    errorMessage,
    restUntil,
    completionPending,
  ];
}

class WorkoutCompleted extends WorkoutState {}

class WorkoutError extends WorkoutState {
  final String message;
  const WorkoutError(this.message);

  @override
  List<Object?> get props => [message];
}
