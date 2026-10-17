import 'package:equatable/equatable.dart';
import '../../../domain/models/workout_log.dart';
import '../../../domain/exercise_progress.dart';

abstract class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<WorkoutLog> logs;
  final List<ExerciseProgress> exercises;

  HistoryLoaded(List<WorkoutLog> logs)
    : logs = List.unmodifiable(logs),
      exercises = buildExerciseProgress(logs);

  @override
  List<Object?> get props => [logs];
}

class HistoryError extends HistoryState {
  final String message;
  const HistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
