import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:spottr/data/datasources/local_database_service.dart';
import 'package:spottr/data/mappers/workout_storage_mapper.dart';
import 'package:spottr/data/repositories/notification_repository.dart';
import 'package:spottr/data/repositories/workout_repository_impl.dart';
import 'package:spottr/domain/models/workout_models.dart';
import 'package:spottr/presentation/blocs/workout/workout_bloc.dart';
import 'package:spottr/presentation/blocs/workout/workout_event.dart';
import 'package:spottr/presentation/blocs/workout/workout_state.dart';

void main() {
  final now = DateTime.utc(2026, 10, 17, 18, 30);
  final exercise = Exercise(
    id: 'cable',
    name: 'Cable kickback',
    targetSets: 2,
    targetReps: 12,
    targetWeight: 12.5,
    restDurationSeconds: 75,
    useDefaultRest: false,
    imageUrl: 'local-cue.png',
    note: 'Pulley at knee level',
  );
  final day = WorkoutDay(
    id: 'day',
    name: 'Lower',
    notes: 'Training day note',
    exercises: [exercise],
  );
  final plan = Plan(
    id: 'plan',
    name: 'Routine',
    isActive: true,
    days: [day],
    createdAt: now,
  );
  final set = SetLog(
    id: 'set',
    reps: 12,
    weight: 12.5,
    isCompleted: true,
    isWarmup: true,
    isDropSet: true,
  );
  final sets = {
    'cable': [set],
  };

  test('app snapshots detach nested collections and reject mutation', () {
    final inputExercises = [exercise];
    final copiedDay = WorkoutDay(
      id: 'day',
      name: 'Lower',
      exercises: inputExercises,
    );
    final inputDays = [copiedDay];
    final copiedPlan = Plan(id: 'plan', name: 'Routine', days: inputDays);
    final inputSets = {
      'cable': [set],
    };
    final inputNames = {'cable': 'Snapshot name'};
    final log = WorkoutLog(
      id: 'log',
      planId: 'plan',
      dayId: 'day',
      dayName: 'Lower',
      startTime: now,
      exerciseLogs: inputSets,
      exerciseNames: inputNames,
    );
    final active = ActiveWorkout(
      workoutLogId: 'active',
      planId: 'plan',
      day: copiedDay,
      startTime: now,
      exerciseLogs: inputSets,
      previousExerciseLogs: inputSets,
    );
    final state = WorkoutInProgress(
      workoutLogId: 'state',
      planId: 'plan',
      day: copiedDay,
      startTime: now,
      exerciseLogs: inputSets,
      previousExerciseLogs: inputSets,
    );
    final inputWeekdays = [1, 3, 5];
    final schedule = WorkoutSchedule(
      workoutHour: 18,
      workoutMinute: 30,
      workoutDays: inputWeekdays,
    );
    inputExercises.clear();
    inputDays.clear();
    inputSets['cable']!.clear();
    inputSets.clear();
    inputNames.clear();
    inputWeekdays.clear();
    expect(copiedPlan.days.single.exercises.single.id, 'cable');
    expect(log.exerciseLogs['cable']!.single.weight, 12.5);
    expect(log.exerciseNames['cable'], 'Snapshot name');
    expect(active.previousExerciseLogs['cable']!.single.id, 'set');
    expect(state.exerciseLogs['cable']!.single.id, 'set');
    expect(schedule.workoutDays, [1, 3, 5]);
    for (final mutation in <void Function()>[
      () => copiedPlan.days.clear(),
      () => copiedDay.exercises.clear(),
      () => log.exerciseNames.clear(),
      () => log.exerciseLogs.clear(),
      () => log.exerciseLogs['cable']!.clear(),
      () => active.previousExerciseLogs['cable']!.clear(),
      () => state.exerciseLogs['cable']!.clear(),
      () => schedule.workoutDays.clear(),
    ]) {
      expect(mutation, throwsUnsupportedError);
    }
  });

  test('storage conversion does not share mutable collections', () {
    final stored = plan.toStorage();
    final model = stored.toDomain();
    stored.days.single.exercises.clear();
    expect(model.days.single.exercises.single.note, exercise.note);
    final exported = model.toStorage();
    exported.days.clear();
    expect(model.days, hasLength(1));
    final storedLog = WorkoutLog(
      id: 'log',
      planId: 'plan',
      dayId: 'day',
      dayName: 'Lower',
      startTime: now,
      exerciseLogs: sets,
      exerciseNames: {'cable': 'Saved name'},
    ).toStorage();
    final mapped = storedLog.toDomain();
    storedLog.exerciseLogs['cable']!.clear();
    storedLog.exerciseNames.clear();
    expect(mapped.exerciseLogs['cable']!.single.isCompleted, isTrue);
    expect(mapped.exerciseNames['cable'], 'Saved name');
  });

  group('Hive repository boundary', () {
    late Directory directory;
    late LocalDatabaseService database;
    late WorkoutRepositoryImpl repository;
    setUp(() async {
      directory = await Directory.systemTemp.createTemp('spottr_boundary_');
      database = LocalDatabaseService();
      await database.init(path: directory.path);
      repository = WorkoutRepositoryImpl(database);
    });
    tearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });
    Future<void> reopen() async {
      await Hive.close();
      await database.init(path: directory.path);
    }

    test(
      'all workout fields survive writes and reopen through repositories',
      () async {
        await repository.savePlan(plan);
        await repository.saveExercise(exercise);
        await repository.saveWorkoutLog(
          WorkoutLog(
            id: 'log',
            planId: plan.id,
            dayId: day.id,
            dayName: day.name,
            startTime: now,
            endTime: now.add(const Duration(minutes: 45)),
            exerciseLogs: sets,
            exerciseNames: {'cable': 'Saved cable name'},
            exerciseIdentities: {'cable': exercise.identityId},
          ),
        );
        await repository.saveActiveWorkout(
          ActiveWorkout(
            workoutLogId: 'active',
            planId: plan.id,
            day: day,
            startTime: now,
            exerciseLogs: sets,
            previousExerciseLogs: sets,
            restUntil: now.add(const Duration(seconds: 75)),
          ),
        );
        final notifications = NotificationRepositoryImpl(database);
        await notifications.saveSchedule(
          WorkoutSchedule(
            workoutHour: 18,
            workoutMinute: 30,
            workoutDays: [1, 3, 5],
            remindersEnabled: false,
            notificationPermissionStatus: 'denied',
          ),
        );
        await reopen();
        final restored = (await repository.getPlans()).single;
        expect(
          [restored.id, restored.name, restored.isActive, restored.createdAt],
          ['plan', 'Routine', true, now],
        );
        expect(
          [
            restored.days.single.id,
            restored.days.single.name,
            restored.days.single.notes,
          ],
          ['day', 'Lower', 'Training day note'],
        );
        final savedExercise = restored.days.single.exercises.single;
        expect(
          [
            savedExercise.id,
            savedExercise.name,
            savedExercise.targetSets,
            savedExercise.targetReps,
            savedExercise.targetWeight,
            savedExercise.restDurationSeconds,
            savedExercise.useDefaultRest,
            savedExercise.note,
            savedExercise.imageUrl,
          ],
          [
            'cable',
            'Cable kickback',
            2,
            12,
            12.5,
            75,
            false,
            'Pulley at knee level',
            'local-cue.png',
          ],
        );
        expect((await repository.getExercises()).single.note, exercise.note);
        final history = (await repository.getWorkoutLogs()).single;
        expect(
          [
            history.id,
            history.planId,
            history.dayId,
            history.dayName,
            history.startTime,
            history.endTime,
          ],
          [
            'log',
            'plan',
            'day',
            'Lower',
            now,
            now.add(const Duration(minutes: 45)),
          ],
        );
        expect(history.exerciseNames, {'cable': 'Saved cable name'});
        expect(history.exerciseIdentities, {'cable': exercise.identityId});
        expect(savedExercise.identityId, exercise.identityId);
        final logged = history.exerciseLogs['cable']!.single;
        expect(
          [
            logged.id,
            logged.reps,
            logged.weight,
            logged.isCompleted,
            logged.isWarmup,
            logged.isDropSet,
          ],
          ['set', 12, 12.5, true, true, true],
        );
        expect(history.totalVolume, 150);
        final active = repository.getActiveWorkout()!;
        expect(
          [
            active.workoutLogId,
            active.planId,
            active.startTime,
            active.restUntil,
          ],
          ['active', 'plan', now, now.add(const Duration(seconds: 75))],
        );
        expect(active.day.exercises.single.note, exercise.note);
        expect(active.previousExerciseLogs['cable']!.single.isDropSet, isTrue);
        expect(active.exerciseLogs['cable']!.single.weight, 12.5);
        final schedule = notifications.getSchedule()!;
        expect(
          [
            schedule.workoutHour,
            schedule.workoutMinute,
            schedule.remindersEnabled,
            schedule.notificationPermissionStatus,
          ],
          [18, 30, false, 'denied'],
        );
        expect(schedule.workoutDays, [1, 3, 5]);
        expect((await repository.getScheduleForToday())!.workoutDays, [
          1,
          3,
          5,
        ]);
        expect((await repository.getActivePlan())!.id, plan.id);
        expect(database.getAllPlans().single.isInBox, isTrue);
        await repository.savePlan(plan.copyWith(id: 'other', isActive: false));
        await repository.setActivePlan('other');
        expect((await repository.getActivePlan())!.id, 'other');
        await notifications.deleteSchedule();
        await repository.deleteExercise(exercise.id);
        await repository.deleteWorkoutLog(history.id);
        await repository.deletePlan('other');
        await repository.clearActiveWorkout();
        await reopen();
        expect(repository.getActiveWorkout(), isNull);
        expect(await repository.getWorkoutLogs(), isEmpty);
        expect(await repository.getExercises(), isEmpty);
        expect(await repository.getActivePlan(), isNull);
        expect(notifications.getSchedule(), isNull);
      },
    );

    test(
      'real disk session resumes and finishes without changing logged work',
      () async {
        var bloc = WorkoutBloc(repository, null, () => now);
        addTearDown(() => bloc.close());
        Future<void> apply(
          WorkoutEvent event,
          bool Function(WorkoutState) complete,
        ) async {
          final done = bloc.stream.firstWhere(complete);
          bloc.add(event);
          await done.timeout(const Duration(seconds: 3));
        }

        bool ready(WorkoutState state) =>
            state is WorkoutInProgress && !state.isSaving;
        await repository.savePlan(plan);
        await apply(StartWorkout(plan: plan, day: day), ready);
        final first =
            (bloc.state as WorkoutInProgress).exerciseLogs['cable']!.first;
        await apply(
          UpdateSet(
            exerciseId: 'cable',
            setLog: first.copyWith(weight: 15, reps: 8, isCompleted: true),
          ),
          ready,
        );
        final deadline = now.add(const Duration(seconds: 75));
        await apply(ChangeWorkoutRest(deadline), ready);
        final extra = Exercise(id: 'extra', name: 'Leg press');
        final replacement = Exercise(
          id: 'replacement',
          name: 'Dumbbell squat',
          note: 'Keep heels down',
        );
        await apply(AddSessionExercise(extra), ready);
        await apply(
          ReplaceSessionExercise(
            exerciseId: extra.id,
            replacement: replacement,
          ),
          ready,
        );
        await apply(
          MoveSessionExercise(exerciseId: replacement.id, offset: -1),
          ready,
        );
        await bloc.close();
        await reopen();
        bloc = WorkoutBloc(repository, null, () => now);
        await apply(ResumeWorkout(), ready);
        final resumed = bloc.state as WorkoutInProgress;
        expect(resumed.restUntil, deadline);
        expect(resumed.day.exercises.map((exercise) => exercise.id), [
          replacement.id,
          exercise.id,
        ]);
        expect(resumed.day.exercises.first.note, replacement.note);
        expect(resumed.day.exercises.last.note, exercise.note);
        expect(resumed.exerciseLogs.containsKey(extra.id), isFalse);
        expect(
          (await repository.getPlans()).single.days.single.exercises.single.id,
          exercise.id,
        );
        expect(resumed.exerciseLogs['cable']!.first.weight, 15);
        await apply(FinishWorkout(), (state) => state is WorkoutInitial);
        await reopen();
        expect(repository.getActiveWorkout(), isNull);
        final saved = (await repository.getWorkoutLogs()).single;
        expect(saved.totalVolume, 120);
        expect(saved.exerciseNames['cable'], exercise.name);
        expect(saved.exerciseLogs.keys, [replacement.id, exercise.id]);
        expect(
          saved.exerciseIdentities[replacement.id],
          replacement.identityId,
        );
        expect(
          saved.exerciseLogs['cable']!.where((set) => set.isCompleted),
          hasLength(1),
        );
        await apply(StartWorkout(plan: plan, day: day), ready);
        await apply(CancelWorkout(), (state) => state is WorkoutInitial);
        await reopen();
        expect(repository.getActiveWorkout(), isNull);
        expect(await repository.getWorkoutLogs(), hasLength(1));
      },
    );
  });
}
