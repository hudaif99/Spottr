import 'package:equatable/equatable.dart';
import '../../../data/models/plan.dart';
import '../../../data/models/workout_day.dart';
import '../../../data/models/set_log.dart';

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
