import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/set_log.dart';
import '../../../data/models/workout_log.dart';
import '../../../data/models/active_workout.dart';
import '../../../domain/repositories/workout_repository.dart';
import '../../../notifications/workout_reminder_scheduler.dart';
import 'workout_event.dart';
import 'workout_state.dart';

class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  final WorkoutRepository _repository;
  final WorkoutReminderScheduler _scheduler;
  final _uuid = const Uuid();

  WorkoutBloc(this._repository, this._scheduler) : super(WorkoutInitial()) {
    on<StartWorkout>(_onStartWorkout);
    on<AddSet>(_onAddSet);
    on<UpdateSet>(_onUpdateSet);
    on<RemoveSet>(_onRemoveSet);
    on<FinishWorkout>(_onFinishWorkout);
    on<CancelWorkout>(_onCancelWorkout);
    on<ResumeWorkout>(_onResumeWorkout);
  }

  Future<void> _saveProgress(WorkoutInProgress state) async {
    final activeWorkout = ActiveWorkout(
      workoutLogId: state.workoutLogId,
      planId: state.planId,
      day: state.day,
      startTime: state.startTime,
      exerciseLogs: state.exerciseLogs,
      previousExerciseLogs: state.previousExerciseLogs,
    );
    await _repository.saveActiveWorkout(activeWorkout);
  }

  void _onResumeWorkout(ResumeWorkout event, Emitter<WorkoutState> emit) {
    final activeWorkout = _repository.getActiveWorkout();
    if (activeWorkout != null) {
      emit(
        WorkoutInProgress(
          workoutLogId: activeWorkout.workoutLogId,
          planId: activeWorkout.planId,
          day: activeWorkout.day,
          startTime: activeWorkout.startTime,
          exerciseLogs: Map<String, List<SetLog>>.from(
            activeWorkout.exerciseLogs,
          ),
          previousExerciseLogs: Map<String, List<SetLog>>.from(
            activeWorkout.previousExerciseLogs,
          ),
        ),
      );
    }
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

    final newState = WorkoutInProgress(
      workoutLogId: 'log_${_uuid.v4()}',
      planId: event.plan.id,
      day: event.day,
      startTime: DateTime.now(),
      exerciseLogs: initialLogs,
      previousExerciseLogs: previousExerciseLogs,
    );

    await _saveProgress(newState);
    emit(newState);

    // Cancel today's missed-workout reminder — the user has started training.
    // It will be rescheduled for next week automatically.
    try {
      final schedule = await _repository.getScheduleForToday();
      if (schedule != null) {
        await _scheduler.cancelAndRescheduleTodaysMissedWorkout(schedule);
      }
    } catch (_) { /* non-critical */ }
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

      final newState = currentState.copyWith(exerciseLogs: currentLogs);
      _saveProgress(newState);
      emit(newState);
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
        final newState = currentState.copyWith(exerciseLogs: currentLogs);
        _saveProgress(newState);
        emit(newState);
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

      final newState = currentState.copyWith(exerciseLogs: currentLogs);
      _saveProgress(newState);
      emit(newState);
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
        await _repository.clearActiveWorkout();

        // —— Post-workout notification hooks ——
        await _handlePostWorkoutNotifications(currentState, workoutLog);

        emit(WorkoutCompleted());
        // Reset state after completion so we can start another one later
        emit(WorkoutInitial());
      } catch (e) {
        emit(WorkoutError('Failed to save workout: $e'));
      }
    }
  }

  // ─────────────────────────── Post-workout notification logic

  Future<void> _handlePostWorkoutNotifications(
    WorkoutInProgress currentState,
    WorkoutLog savedLog,
  ) async {
    try {
      final schedule = await _repository.getScheduleForToday();

      // Cancel today’s missed-workout and streak reminders.
      if (schedule != null) {
        await _scheduler.cancelAndRescheduleTodaysMissedWorkout(schedule);
      }
      await _scheduler.cancelStreakReminder();

      // ── Milestone detection ─────────────────────────────────
      final allLogs = await _repository.getWorkoutLogs();
      const milestones = [1, 10, 25, 50, 100, 365];
      if (milestones.contains(allLogs.length)) {
        await _scheduler.showMilestoneNotification(allLogs.length);
        return; // Milestone takes priority over PR
      }

      // ── Personal Record detection ────────────────────────────
      // Build historical best per exercise (weight, reps).
      final historicalBests = <String, ({double weight, int reps})>{};
      for (final log in allLogs) {
        if (log.id == savedLog.id) continue; // exclude current session
        for (final entry in log.exerciseLogs.entries) {
          for (final set in entry.value) {
            if (!set.isCompleted) continue;
            final prev = historicalBests[entry.key];
            if (prev == null ||
                set.weight > prev.weight ||
                (set.weight == prev.weight && set.reps > prev.reps)) {
              historicalBests[entry.key] = (weight: set.weight, reps: set.reps);
            }
          }
        }
      }

      // Check current session for new records.
      bool hasNewPR = false;
      String prDetail = '';

      for (final entry in savedLog.exerciseLogs.entries) {
        for (final set in entry.value) {
          if (!set.isCompleted) continue;
          final prev = historicalBests[entry.key];
          if (prev == null || set.weight > prev.weight ||
              (set.weight == prev.weight && set.reps > prev.reps)) {
            hasNewPR = true;
            prDetail = '${set.weight}kg × ${set.reps} reps — new best!';
            break;
          }
        }
        if (hasNewPR) break;
      }

      // Check session duration record.
      if (!hasNewPR) {
        final currentDuration = savedLog.totalDurationInSeconds;
        final maxPrevDuration = allLogs
            .where((l) => l.id != savedLog.id)
            .fold<int>(0, (m, l) => l.totalDurationInSeconds > m ? l.totalDurationInSeconds : m);
        if (currentDuration > maxPrevDuration && maxPrevDuration > 0) {
          hasNewPR = true;
          final mins = currentDuration ~/ 60;
          prDetail = 'Longest workout yet: ${mins}m!';
        }
      }

      if (hasNewPR) {
        await _scheduler.showPersonalRecordNotification(prDetail);
      }
    } catch (_) { /* non-critical — never block workout save */ }
  }

  Future<void> _onCancelWorkout(
    CancelWorkout event,
    Emitter<WorkoutState> emit,
  ) async {
    await _repository.clearActiveWorkout();
    emit(WorkoutInitial());
  }
}
