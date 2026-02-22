import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/set_log.dart';
import '../../../data/models/workout_log.dart';
import '../../../domain/repositories/workout_repository.dart';
import 'workout_event.dart';
import 'workout_state.dart';

class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  final WorkoutRepository _repository;
  final _uuid = const Uuid();

  WorkoutBloc(this._repository) : super(WorkoutInitial()) {
    on<StartWorkout>(_onStartWorkout);
    on<AddSet>(_onAddSet);
    on<UpdateSet>(_onUpdateSet);
    on<RemoveSet>(_onRemoveSet);
    on<FinishWorkout>(_onFinishWorkout);
    on<CancelWorkout>(_onCancelWorkout);
  }

  Future<void> _onStartWorkout(
    StartWorkout event,
    Emitter<WorkoutState> emit,
  ) async {
    final Map<String, List<SetLog>> initialLogs = {};
    for (var exercise in event.day.exercises) {
      initialLogs[exercise.id] = [];
    }

    final Map<String, List<SetLog>> previousExerciseLogs = {};
    try {
      final allLogs = await _repository.getWorkoutLogs();
      // Sort by date descending
      allLogs.sort((a, b) => b.startTime.compareTo(a.startTime));

      for (var exercise in event.day.exercises) {
        for (var log in allLogs) {
          if (log.exerciseLogs.containsKey(exercise.id) &&
              log.exerciseLogs[exercise.id]!.isNotEmpty) {
            previousExerciseLogs[exercise.id] = log.exerciseLogs[exercise.id]!;
            break; // Found the most recent logs for this exercise
          }
        }
      }
    } catch (_) {
      // Ignore errors fetching previous logs
    }

    emit(
      WorkoutInProgress(
        workoutLogId: 'log_${_uuid.v4()}',
        planId: event.plan.id,
        day: event.day,
        startTime: DateTime.now(),
        exerciseLogs: initialLogs,
        previousExerciseLogs: previousExerciseLogs,
      ),
    );
  }

  void _onAddSet(AddSet event, Emitter<WorkoutState> emit) {
    if (state is WorkoutInProgress) {
      final currentState = state as WorkoutInProgress;
      final currentLogs = Map<String, List<SetLog>>.from(
        currentState.exerciseLogs,
      );

      final exerciseSets = List<SetLog>.from(
        currentLogs[event.exerciseId] ?? [],
      );

      // Auto-fill values based on the previous set if it exists
      double weight = 0.0;
      int reps = 0;
      if (exerciseSets.isNotEmpty) {
        weight = exerciseSets.last.weight;
        reps = exerciseSets.last.reps;
      }

      exerciseSets.add(
        SetLog(id: 'set_${_uuid.v4()}', weight: weight, reps: reps),
      );

      currentLogs[event.exerciseId] = exerciseSets;

      emit(currentState.copyWith(exerciseLogs: currentLogs));
    }
  }

  void _onUpdateSet(UpdateSet event, Emitter<WorkoutState> emit) {
    if (state is WorkoutInProgress) {
      final currentState = state as WorkoutInProgress;
      final currentLogs = Map<String, List<SetLog>>.from(
        currentState.exerciseLogs,
      );

      final exerciseSets = List<SetLog>.from(
        currentLogs[event.exerciseId] ?? [],
      );

      final setIndex = exerciseSets.indexWhere((s) => s.id == event.setLog.id);
      if (setIndex != -1) {
        exerciseSets[setIndex] = event.setLog;
        currentLogs[event.exerciseId] = exerciseSets;
        emit(currentState.copyWith(exerciseLogs: currentLogs));
      }
    }
  }

  void _onRemoveSet(RemoveSet event, Emitter<WorkoutState> emit) {
    if (state is WorkoutInProgress) {
      final currentState = state as WorkoutInProgress;
      final currentLogs = Map<String, List<SetLog>>.from(
        currentState.exerciseLogs,
      );

      final exerciseSets = List<SetLog>.from(
        currentLogs[event.exerciseId] ?? [],
      );

      exerciseSets.removeWhere((s) => s.id == event.setId);
      currentLogs[event.exerciseId] = exerciseSets;

      emit(currentState.copyWith(exerciseLogs: currentLogs));
    }
  }

  Future<void> _onFinishWorkout(
    FinishWorkout event,
    Emitter<WorkoutState> emit,
  ) async {
    if (state is WorkoutInProgress) {
      final currentState = state as WorkoutInProgress;

      bool hasCompletedSets = false;
      for (var logs in currentState.exerciseLogs.values) {
        if (logs.any((set) => set.isCompleted)) {
          hasCompletedSets = true;
          break;
        }
      }

      if (!hasCompletedSets) {
        // Discard the workout if nothing was completed
        emit(WorkoutInitial());
        return;
      }

      final workoutLog = WorkoutLog(
        id: currentState.workoutLogId,
        planId: currentState.planId,
        dayId: currentState.day.id,
        dayName: currentState.day.name,
        startTime: currentState.startTime,
        endTime: DateTime.now(),
        exerciseLogs: currentState.exerciseLogs,
      );

      try {
        await _repository.saveWorkoutLog(workoutLog);
        emit(WorkoutCompleted());
        // Reset state after completion so we can start another one later
        emit(WorkoutInitial());
      } catch (e) {
        emit(WorkoutError('Failed to save workout: $e'));
      }
    }
  }

  void _onCancelWorkout(CancelWorkout event, Emitter<WorkoutState> emit) {
    emit(WorkoutInitial());
  }
}
