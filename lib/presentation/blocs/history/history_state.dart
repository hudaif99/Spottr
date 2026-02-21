import 'package:equatable/equatable.dart';
import '../../../data/models/workout_log.dart';

abstract class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<WorkoutLog> logs;

  const HistoryLoaded(this.logs);

  @override
  List<Object?> get props => [logs];
}

class HistoryError extends HistoryState {
  final String message;
  const HistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
