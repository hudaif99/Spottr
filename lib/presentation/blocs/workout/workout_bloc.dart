import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/models/active_workout.dart';
import '../../../domain/models/exercise.dart';
import '../../../domain/models/set_log.dart';
import '../../../domain/models/workout_log.dart';
import '../../../domain/exercise_identity.dart';
import '../../../domain/repositories/workout_repository.dart';
import '../../../notifications/workout_reminder_scheduler.dart';
import 'workout_event.dart';
import 'workout_state.dart';

class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  final WorkoutRepository _repository;
  final WorkoutReminderScheduler? _scheduler;
  final DateTime Function() _now;
  final _uuid = const Uuid();

  WorkoutBloc(this._repository, [this._scheduler, DateTime Function()? now])
    : _now = now ?? DateTime.now,
      super(WorkoutInitial()) {
    // One queue keeps edits, finish, and cancel in their original order.
    on<WorkoutEvent>(
      _handle,
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
  }

  Future<void> _save(
    WorkoutInProgress session,
    Emitter<WorkoutState> emit,
  ) async {
    emit(session.copyWith(isSaving: true));
    try {
      await _repository.saveActiveWorkout(
        ActiveWorkout(
          workoutLogId: session.workoutLogId,
          planId: session.planId,
          day: session.day,
          startTime: session.startTime,
          exerciseLogs: session.exerciseLogs,
          previousExerciseLogs: session.previousExerciseLogs,
          restUntil: session.restUntil,
        ),
      );
      emit(session.copyWith(isSaving: false));
    } catch (_) {
      emit(
        session.copyWith(
          isSaving: false,
          errorMessage: 'Changes are still here. Retry saving before leaving.',
        ),
      );
    }
  }

  List<SetLog> _suggestedSets(Exercise exercise, List<SetLog> previous) =>
      List.generate(exercise.targetSets, (index) {
        final suggestion = previous.isEmpty
            ? null
            : previous[index < previous.length ? index : previous.length - 1];
        return SetLog(
          id: _uuid.v4(),
          reps: suggestion?.reps ?? exercise.targetReps,
          weight: suggestion?.weight ?? exercise.targetWeight ?? 0,
        );
      });

  Future<void> _handle(
    WorkoutEvent incoming,
    Emitter<WorkoutState> emit,
  ) async {
    final event = _resolveSetChange(incoming);
    if (event is ResumeWorkout) {
      emit(WorkoutRestoring());
      final cached = _repository.getActiveWorkout();
      if (cached == null) {
        emit(WorkoutInitial());
        return;
      }
      bool completionPending = false;
      try {
        final logs = await _repository.getWorkoutLogs();
        if (logs.any((log) => log.id == cached.workoutLogId)) {
          completionPending = true;
          await _repository.clearActiveWorkout();
          emit(WorkoutInitial());
          return;
        }
        emit(
          WorkoutInProgress(
            workoutLogId: cached.workoutLogId,
            planId: cached.planId,
            day: cached.day.copyWith(
              exercises: cached.day.exercises.map(_resolveRest).toList(),
            ),
            startTime: cached.startTime,
            exerciseLogs: cached.exerciseLogs,
            previousExerciseLogs: cached.previousExerciseLogs,
            restUntil: cached.restUntil,
          ),
        );
      } catch (_) {
        emit(
          WorkoutInProgress(
            workoutLogId: cached.workoutLogId,
            planId: cached.planId,
            day: cached.day.copyWith(
              exercises: cached.day.exercises.map(_resolveRest).toList(),
            ),
            startTime: cached.startTime,
            exerciseLogs: cached.exerciseLogs,
            previousExerciseLogs: cached.previousExerciseLogs,
            restUntil: cached.restUntil,
            errorMessage: completionPending
                ? 'Workout saved. Retry finishing to close this session.'
                : 'Could not check saved history. Retry before finishing.',
            completionPending: completionPending,
          ),
        );
      }
      return;
    }
    if (event is StartWorkout) {
      if (state is WorkoutInProgress) return;
      try {
        final history = await _repository.getWorkoutLogs();
        final previous = <String, List<SetLog>>{};
        for (final exercise in event.day.exercises) {
          previous[exercise.id] = previousSetsForExercise(exercise, history);
        }
        await _save(
          WorkoutInProgress(
            workoutLogId: _uuid.v4(),
            planId: event.plan.id,
            day: event.day.copyWith(
              exercises: event.day.exercises.map(_resolveRest).toList(),
            ),
            startTime: _now(),
            previousExerciseLogs: previous,
            exerciseLogs: {
              for (final exercise in event.day.exercises)
                exercise.id: _suggestedSets(
                  exercise,
                  previous[exercise.id] ?? [],
                ),
            },
          ),
          emit,
        );
        await _updateReminders();
      } catch (_) {
        emit(
          const WorkoutError('Could not start the workout. Please try again.'),
        );
      }
      return;
    }
    final current = state;
    if (current is! WorkoutInProgress) return;
    if (event is FinishWorkout ||
        event is CancelWorkout ||
        event is RetryWorkoutSave && current.completionPending) {
      emit(current.copyWith(isSaving: true));
      bool saved = current.completionPending;
      try {
        final hasCompleted = current.exerciseLogs.values.any(
          (sets) => sets.any((set) => set.isCompleted),
        );
        if (event is FinishWorkout && hasCompleted && !saved) {
          await _repository.saveWorkoutLog(
            WorkoutLog(
              id: current.workoutLogId,
              planId: current.planId,
              dayId: current.day.id,
              dayName: current.day.name,
              startTime: current.startTime,
              endTime: _now(),
              exerciseLogs: current.exerciseLogs,
              exerciseNames: {
                for (final exercise in current.day.exercises)
                  exercise.id: exercise.name,
              },
              exerciseIdentities: {
                for (final exercise in current.day.exercises)
                  exercise.id: exercise.identityId,
              },
            ),
          );
          saved = true;
        }
        await _repository.clearActiveWorkout();
        emit(event is FinishWorkout ? WorkoutCompleted() : WorkoutInitial());
        emit(WorkoutInitial());
        if (saved) {
          await _updateReminders();
          await _notifyAchievements(current.workoutLogId);
        }
      } catch (_) {
        emit(
          current.copyWith(
            isSaving: false,
            errorMessage: saved
                ? 'Workout saved. Retry finishing to close this session.'
                : 'Could not save this workout. Your session is still here; try again.',
            completionPending: saved,
          ),
        );
      }
      return;
    }
    if (current.completionPending) return;
    if (event is RetryWorkoutSave) {
      await _save(current, emit);
      return;
    }
    if (event is ChangeWorkoutRest) {
      await _save(
        current.copyWith(
          restUntil: event.restUntil,
          clearRest: event.restUntil == null,
        ),
        emit,
      );
      return;
    }
    if (event is MoveSessionExercise) {
      if (event.offset != -1 && event.offset != 1) return;
      final exercises = [...current.day.exercises];
      final index = exercises.indexWhere(
        (exercise) => exercise.id == event.exerciseId,
      );
      final destination = index + event.offset;
      if (index < 0 || destination < 0 || destination >= exercises.length) {
        return;
      }
      exercises.insert(destination, exercises.removeAt(index));
      await _save(
        current.copyWith(
          day: current.day.copyWith(exercises: exercises),
          exerciseLogs: {
            for (final exercise in exercises)
              if (current.exerciseLogs.containsKey(exercise.id))
                exercise.id: current.exerciseLogs[exercise.id]!,
            ...current.exerciseLogs,
          },
        ),
        emit,
      );
      return;
    }
    if (event is EditSessionExercise || event is ReplaceSessionExercise) {
      final replacing = event is ReplaceSessionExercise;
      final updated = switch (event) {
        EditSessionExercise(:final exercise) => exercise,
        ReplaceSessionExercise(:final replacement) => replacement,
        _ => throw StateError('Unsupported exercise change'),
      };
      final originalId = event is ReplaceSessionExercise
          ? event.exerciseId
          : updated.id;
      final original = current.day.exercises
          .where((exercise) => exercise.id == originalId)
          .firstOrNull;
      if (original == null) return;
      if (replacing &&
          (updated.id == original.id ||
              current.day.exercises.any(
                (exercise) => exercise.id == updated.id,
              ))) {
        return;
      }
      final completed =
          current.exerciseLogs[original.id]?.any((set) => set.isCompleted) ??
          false;
      if (completed &&
          (replacing ||
              original.identityId != updated.identityId ||
              original.name != updated.name)) {
        return;
      }
      final resetSuggestions =
          replacing || original.identityId != updated.identityId;
      var previous =
          current.previousExerciseLogs[original.id] ?? const <SetLog>[];
      if (resetSuggestions) {
        try {
          previous = previousSetsForExercise(
            updated,
            await _repository.getWorkoutLogs(),
          );
        } catch (_) {
          emit(
            current.copyWith(
              errorMessage:
                  'Could not load exercise history. Your workout is unchanged; try again.',
            ),
          );
          return;
        }
      }
      final exercises = current.day.exercises
          .map(
            (exercise) =>
                exercise.id == original.id ? _resolveRest(updated) : exercise,
          )
          .toList();
      final previousLogs = {...current.previousExerciseLogs};
      final logs = {...current.exerciseLogs};
      if (resetSuggestions) {
        previousLogs.remove(original.id);
        previousLogs[updated.id] = previous;
        logs.remove(original.id);
        logs[updated.id] = _suggestedSets(updated, previous);
      }
      await _save(
        current.copyWith(
          day: current.day.copyWith(exercises: exercises),
          previousExerciseLogs: resetSuggestions ? previousLogs : null,
          exerciseLogs: resetSuggestions
              ? {
                  for (final exercise in exercises)
                    if (logs.containsKey(exercise.id))
                      exercise.id: logs[exercise.id]!,
                  ...logs,
                }
              : null,
        ),
        emit,
      );
      return;
    }
    if (event is AddSessionExercise) {
      if (current.day.exercises.any(
        (exercise) => exercise.id == event.exercise.id,
      )) {
        return;
      }
      List<SetLog> previous;
      try {
        previous = previousSetsForExercise(
          event.exercise,
          await _repository.getWorkoutLogs(),
        );
      } catch (_) {
        emit(
          current.copyWith(
            errorMessage:
                'Could not load exercise history. Your workout is unchanged; try again.',
          ),
        );
        return;
      }
      await _save(
        current.copyWith(
          day: current.day.copyWith(
            exercises: [...current.day.exercises, _resolveRest(event.exercise)],
          ),
          exerciseLogs: {
            ...current.exerciseLogs,
            event.exercise.id: _suggestedSets(event.exercise, previous),
          },
          previousExerciseLogs: {
            ...current.previousExerciseLogs,
            event.exercise.id: previous,
          },
        ),
        emit,
      );
      return;
    }
    final logs = {...current.exerciseLogs};
    String? exerciseId;
    if (event is AddSet) exerciseId = event.exerciseId;
    if (event is UpdateSet) exerciseId = event.exerciseId;
    if (event is RemoveSet) exerciseId = event.exerciseId;
    if (event is RestoreSet) exerciseId = event.exerciseId;
    if (exerciseId == null) return;
    if (!current.day.exercises.any((exercise) => exercise.id == exerciseId)) {
      return;
    }
    final sets = [...logs[exerciseId] ?? <SetLog>[]];
    DateTime? restUntil;
    if (event is AddSet) {
      final exercise = current.day.exercises.firstWhere(
        (exercise) => exercise.id == exerciseId,
      );
      sets.add(
        SetLog(
          id: _uuid.v4(),
          weight: sets.lastOrNull?.weight ?? exercise.targetWeight ?? 0,
          reps: sets.lastOrNull?.reps ?? exercise.targetReps,
        ),
      );
    } else if (event is UpdateSet) {
      final index = sets.indexWhere((set) => set.id == event.setLog.id);
      if (index < 0) return;
      if (event.setLog.reps < 0 ||
          event.setLog.weight < 0 ||
          !event.setLog.weight.isFinite) {
        return;
      }
      if (event.setLog.isCompleted && event.setLog.reps == 0) return;
      if (event.setLog.isCompleted && !sets[index].isCompleted) {
        final exercise = current.day.exercises.firstWhere(
          (exercise) => exercise.id == exerciseId,
        );
        restUntil = _now().add(Duration(seconds: exercise.restDurationSeconds));
      }
      sets[index] = event.setLog;
    } else if (event is RemoveSet) {
      sets.removeWhere((set) => set.id == event.setId);
    } else if (event is RestoreSet) {
      if (sets.any((set) => set.id == event.setLog.id)) return;
      sets.insert(event.index.clamp(0, sets.length), event.setLog);
    }
    logs[exerciseId] = sets;
    await _save(
      current.copyWith(exerciseLogs: logs, restUntil: restUntil),
      emit,
    );
  }

  WorkoutEvent _resolveSetChange(WorkoutEvent event) {
    final current = state;
    if (current is! WorkoutInProgress) return event;
    if (event is AdjustSet) {
      final set = (current.exerciseLogs[event.exerciseId] ?? [])
          .where((set) => set.id == event.setId)
          .firstOrNull;
      if (set == null || !event.weightDelta.isFinite) return event;
      return UpdateSet(
        exerciseId: event.exerciseId,
        setLog: set.copyWith(
          weight: (set.weight + event.weightDelta).clamp(0, 2000).toDouble(),
          reps: (set.reps + event.repsDelta).clamp(0, 2000),
        ),
      );
    }
    if (event is SetCompletion) {
      final set = (current.exerciseLogs[event.exerciseId] ?? [])
          .where((set) => set.id == event.setId)
          .firstOrNull;
      if (set == null) return event;
      return UpdateSet(
        exerciseId: event.exerciseId,
        setLog: set.copyWith(isCompleted: event.completed),
      );
    }
    return event;
  }

  Future<void> _updateReminders() async {
    final scheduler = _scheduler;
    if (scheduler == null) return;
    try {
      final schedule = await _repository.getScheduleForToday();
      if (schedule != null) {
        await scheduler.cancelAndRescheduleTodaysMissedWorkout(schedule);
      }
    } catch (_) {
      /* Reminders must not block logging. */
    }
  }

  Exercise _resolveRest(Exercise exercise) => exercise.useDefaultRest
      ? exercise.copyWith(
          restDurationSeconds: _repository.getDefaultRestTime(),
          useDefaultRest: false,
        )
      : exercise;

  Future<void> _notifyAchievements(String sessionId) async {
    final scheduler = _scheduler;
    if (scheduler == null) return;
    try {
      final history = await _repository.getWorkoutLogs();
      if ([1, 10, 25, 50, 100, 365].contains(history.length)) {
        await scheduler.showMilestoneNotification(history.length);
        return;
      }
      final session = history.where((log) => log.id == sessionId).firstOrNull;
      if (session == null) return;
      for (final entry in session.exerciseLogs.entries) {
        final exercise = Exercise(
          id: entry.key,
          name: session.exerciseNames[entry.key] ?? '',
          identityId: session.exerciseIdentities[entry.key],
        );
        final previous = history
            .where((log) => log.id != sessionId)
            .expand((log) => completedSetsForExercise(exercise, log))
            .toList();
        if (previous.isEmpty) continue;
        for (final set in entry.value.where((set) => set.isCompleted)) {
          if (previous.every(
            (old) =>
                set.weight > old.weight ||
                set.weight == old.weight && set.reps > old.reps,
          )) {
            await scheduler.showPersonalRecordNotification(
              '${set.weight} kg × ${set.reps} reps — new best!',
            );
            return;
          }
        }
      }
    } catch (_) {
      /* Achievements must not block saving. */
    }
  }
}
