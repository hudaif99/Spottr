import 'package:equatable/equatable.dart';
import '../../../domain/models/plan.dart';
import '../../../domain/models/workout_day.dart';
import '../../../domain/models/set_log.dart';
import '../../../domain/models/exercise.dart';

abstract class WorkoutEvent extends Equatable {
  const WorkoutEvent();

  @override
  List<Object?> get props => [];
}

class StartWorkout extends WorkoutEvent {
  final Plan plan;
  final WorkoutDay day;

  const StartWorkout({required this.plan, required this.day});

  @override
  List<Object?> get props => [plan, day];
}

class FinishWorkout extends WorkoutEvent {}

class CancelWorkout extends WorkoutEvent {}

class ResumeWorkout extends WorkoutEvent {}

class RetryWorkoutSave extends WorkoutEvent {}

class AdjustSet extends WorkoutEvent {
  final String exerciseId;
  final String setId;
  final double weightDelta;
  final int repsDelta;
  const AdjustSet({
    required this.exerciseId,
    required this.setId,
    this.weightDelta = 0,
    this.repsDelta = 0,
  });
  @override
  List<Object?> get props => [exerciseId, setId, weightDelta, repsDelta];
}

class SetCompletion extends WorkoutEvent {
  final String exerciseId;
  final String setId;
  final bool completed;
  const SetCompletion({
    required this.exerciseId,
    required this.setId,
    required this.completed,
  });
  @override
  List<Object?> get props => [exerciseId, setId, completed];
}

class ChangeWorkoutRest extends WorkoutEvent {
  final DateTime? restUntil;
  const ChangeWorkoutRest(this.restUntil);
  @override
  List<Object?> get props => [restUntil];
}

class EditSessionExercise extends WorkoutEvent {
  final Exercise exercise;
  const EditSessionExercise(this.exercise);
  @override
  List<Object?> get props => [exercise];
}

class AddSessionExercise extends WorkoutEvent {
  final Exercise exercise;
  const AddSessionExercise(this.exercise);
  @override
  List<Object?> get props => [exercise];
}

class ReplaceSessionExercise extends WorkoutEvent {
  final String exerciseId;
  final Exercise replacement;
  const ReplaceSessionExercise({
    required this.exerciseId,
    required this.replacement,
  });
  @override
  List<Object?> get props => [exerciseId, replacement];
}

class MoveSessionExercise extends WorkoutEvent {
  final String exerciseId;
  final int offset;
  const MoveSessionExercise({required this.exerciseId, required this.offset});
  @override
  List<Object?> get props => [exerciseId, offset];
}

class AddSet extends WorkoutEvent {
  final String exerciseId;
  const AddSet(this.exerciseId);

  @override
  List<Object?> get props => [exerciseId];
}

class UpdateSet extends WorkoutEvent {
  final String exerciseId;
  final SetLog setLog;

  const UpdateSet({required this.exerciseId, required this.setLog});

  @override
  List<Object?> get props => [exerciseId, setLog];
}

class RemoveSet extends WorkoutEvent {
  final String exerciseId;
  final String setId;

  const RemoveSet({required this.exerciseId, required this.setId});

  @override
  List<Object?> get props => [exerciseId, setId];
}

class RestoreSet extends WorkoutEvent {
  final String exerciseId;
  final SetLog setLog;
  final int index;
  const RestoreSet({
    required this.exerciseId,
    required this.setLog,
    required this.index,
  });
  @override
  List<Object?> get props => [exerciseId, setLog, index];
}
