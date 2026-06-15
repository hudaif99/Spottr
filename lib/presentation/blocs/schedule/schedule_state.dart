import 'package:equatable/equatable.dart';
import '../../../data/models/workout_schedule.dart';

abstract class ScheduleState extends Equatable {
  const ScheduleState();
  @override
  List<Object?> get props => [];
}

/// Initial state before loading.
class ScheduleInitial extends ScheduleState {}

/// Schedule successfully loaded (or absent — schedule is null when not set up).
class ScheduleLoaded extends ScheduleState {
  final WorkoutSchedule? schedule;
  const ScheduleLoaded(this.schedule);

  @override
  List<Object?> get props => [schedule];
}

/// An error occurred during load or save.
class ScheduleError extends ScheduleState {
  final String message;
  const ScheduleError(this.message);

  @override
  List<Object?> get props => [message];
}
