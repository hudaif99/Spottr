import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:spottr/domain/models/exercise.dart';
import 'package:spottr/domain/models/plan.dart';
import 'package:spottr/domain/models/set_log.dart';
import 'package:spottr/domain/models/workout_day.dart';
import 'package:spottr/domain/models/workout_log.dart';
import 'package:spottr/presentation/blocs/workout/workout_bloc.dart';
import 'package:spottr/presentation/blocs/workout/workout_event.dart';
import 'package:spottr/presentation/blocs/workout/workout_state.dart';
import 'support/fake_workout_repository.dart';
import 'package:spottr/notifications/workout_reminder_scheduler.dart';
import 'package:spottr/notifications/notification_service.dart';

class _Achievements extends WorkoutReminderScheduler {
  int records = 0;
  _Achievements() : super(NotificationService());
  @override
  Future<void> showPersonalRecordNotification(String detail) async {
    records++;
  }

  @override
  Future<void> showMilestoneNotification(int totalWorkouts) async {}
}

Future<void> settle(WorkoutBloc bloc, WorkoutEvent event) async {
  final done = bloc.stream.firstWhere(
    (state) =>
        state is WorkoutInitial ||
        event is! CancelWorkout &&
            state is WorkoutInProgress &&
            !state.isSaving,
  );
  bloc.add(event);
  await done.timeout(const Duration(seconds: 3));
}

void main() {
  final exercise = Exercise(
    id: 'exercise',
    name: 'Cable kickback',
    targetWeight: 12.5,
    note: 'Pulley at knee level',
  );
  final day = WorkoutDay(id: 'day', name: 'Lower body', exercises: [exercise]);
  final plan = Plan(id: 'plan', name: 'Routine', days: [day]);
  final now = DateTime(2026, 10, 11, 10);
  late FakeWorkoutRepository repository;
  late WorkoutBloc bloc;
  setUp(() {
    repository = FakeWorkoutRepository();
    bloc = WorkoutBloc(repository, null, () => now);
  });
  tearDown(() => bloc.close());

  Future<void> start() => settle(bloc, StartWorkout(plan: plan, day: day));
  Future<void> complete() async {
    final state = bloc.state as WorkoutInProgress;
    await settle(
      bloc,
      UpdateSet(
        exerciseId: exercise.id,
        setLog: state.exerciseLogs[exercise.id]!.first.copyWith(
          isCompleted: true,
        ),
      ),
    );
  }

  test(
    'prefills only from completed sets and persists the setup note',
    () async {
      repository.logs.add(
        WorkoutLog(
          id: 'old',
          planId: plan.id,
          dayId: day.id,
          dayName: day.name,
          startTime: now.subtract(const Duration(days: 2)),
          exerciseLogs: {
            exercise.id: [
              SetLog(id: 'good', reps: 8, weight: 20, isCompleted: true),
              SetLog(id: 'draft', reps: 99, weight: 200),
            ],
          },
        ),
      );
      await start();
      expect(
        repository.active!.exerciseLogs[exercise.id]!.map((set) => set.weight),
        [20, 20, 20],
      );
      expect(repository.active!.day.exercises.first.note, exercise.note);
      expect(repository.logs.single.totalVolume, 160);
    },
  );

  test(
    'rapid edit then finish waits for persistence and keeps the latest set',
    () async {
      await start();
      final set =
          (bloc.state as WorkoutInProgress).exerciseLogs[exercise.id]!.first;
      repository.saveGate = Completer<void>();
      bloc.add(
        UpdateSet(
          exerciseId: exercise.id,
          setLog: set.copyWith(weight: 25, isCompleted: true),
        ),
      );
      final finished = bloc.stream.firstWhere(
        (state) => state is WorkoutInitial,
      );
      bloc.add(FinishWorkout());
      await Future<void>.delayed(Duration.zero);
      expect(repository.logs, isEmpty);
      repository.saveGate!.complete();
      await finished.timeout(const Duration(seconds: 3));
      expect(repository.maxConcurrentWrites, 1);
      expect(repository.logs.single.totalVolume, 250);
      expect(repository.logs.single.exerciseNames[exercise.id], exercise.name);
      expect(repository.active, isNull);
    },
  );

  test(
    'empty finish clears cached suggestions without creating history',
    () async {
      await start();
      await settle(bloc, FinishWorkout());
      expect(repository.active, isNull);
      expect(repository.logs, isEmpty);
    },
  );

  test('failed edit keeps values in memory and retry saves them', () async {
    await start();
    repository.failSave = true;
    await complete();
    final state = bloc.state as WorkoutInProgress;
    expect(state.exerciseLogs[exercise.id]!.first.isCompleted, isTrue);
    expect(state.errorMessage, isNotNull);
    repository.failSave = false;
    await settle(bloc, RetryWorkoutSave());
    expect(
      repository.active!.exerciseLogs[exercise.id]!.first.isCompleted,
      isTrue,
    );
    expect((bloc.state as WorkoutInProgress).errorMessage, isNull);
  });

  test('failed finish retains a recoverable workout', () async {
    await start();
    await complete();
    repository.failHistory = true;
    await settle(bloc, FinishWorkout());
    expect(bloc.state, isA<WorkoutInProgress>());
    expect(repository.active, isNotNull);
    repository.failHistory = false;
    await settle(bloc, FinishWorkout());
    expect(repository.logs.length, 1);
    expect(repository.active, isNull);
  });

  test(
    'retrying cleanup does not rewrite an already completed workout',
    () async {
      await start();
      await complete();
      repository.failClear = true;
      await settle(bloc, FinishWorkout());
      expect((bloc.state as WorkoutInProgress).completionPending, isTrue);
      repository.failClear = false;
      await settle(bloc, RetryWorkoutSave());
      expect(repository.logWrites, 1);
      expect(repository.active, isNull);
    },
  );

  test('resume does not replace unsaved edits with an older cache', () async {
    await start();
    repository.failSave = true;
    await complete();
    expect(
      repository.active!.exerciseLogs[exercise.id]!.first.isCompleted,
      isFalse,
    );
    bloc.add(ResumeWorkout());
    repository.failSave = false;
    await settle(bloc, RetryWorkoutSave());
    expect(
      repository.active!.exerciseLogs[exercise.id]!.first.isCompleted,
      isTrue,
    );
  });

  test('start recovers an existing cache instead of replacing it', () async {
    await start();
    await complete();
    final savedId = repository.active!.workoutLogId;
    await bloc.close();
    bloc = WorkoutBloc(repository);
    await settle(
      bloc,
      StartWorkout(
        plan: plan.copyWith(id: 'new-plan'),
        day: day.copyWith(id: 'new-day'),
      ),
    );
    expect(repository.active!.workoutLogId, savedId);
    final resumed = bloc.state as WorkoutInProgress;
    expect(resumed.planId, plan.id);
    expect(resumed.day.id, day.id);
    expect(resumed.exerciseLogs[exercise.id]!.first.isCompleted, isTrue);
  });

  test(
    'history failure locks recovery until a committed session can be checked',
    () async {
      await start();
      await complete();
      repository.failClear = true;
      await settle(bloc, FinishWorkout());
      final saved = repository.logs.single;
      await bloc.close();
      repository.failClear = false;
      repository.failReadHistory = true;
      bloc = WorkoutBloc(repository);
      await settle(bloc, ResumeWorkout());
      expect((bloc.state as WorkoutInProgress).historyCheckPending, isTrue);
      bloc.add(AddSet(exercise.id));
      bloc.add(FinishWorkout());
      bloc.add(CancelWorkout());
      await settle(bloc, RetryWorkoutSave());
      expect(repository.logWrites, 1);
      expect(repository.active, isNotNull);
      expect((bloc.state as WorkoutInProgress).isReadOnly, isTrue);
      repository.failReadHistory = false;
      await settle(bloc, RetryWorkoutSave());
      expect(bloc.state, isA<WorkoutInitial>());
      expect(repository.active, isNull);
      expect(repository.logWrites, 1);
      expect(repository.logs.single, same(saved));
    },
  );

  test(
    'history retry restores an unfinished session without losing progress',
    () async {
      await start();
      await complete();
      final savedId = repository.active!.workoutLogId;
      await bloc.close();
      repository.failReadHistory = true;
      bloc = WorkoutBloc(repository);
      await settle(bloc, ResumeWorkout());
      repository.failReadHistory = false;
      await settle(bloc, RetryWorkoutSave());
      final resumed = bloc.state as WorkoutInProgress;
      expect(resumed.historyCheckPending, isFalse);
      expect(resumed.workoutLogId, savedId);
      expect(resumed.exerciseLogs[exercise.id]!.first.isCompleted, isTrue);
      await settle(bloc, FinishWorkout());
      expect(repository.logs.single.totalVolume, 125);
      expect(repository.logWrites, 1);
    },
  );

  test(
    'cache read failures are recoverable and never start over the cache',
    () async {
      await start();
      final savedId = repository.active!.workoutLogId;
      await bloc.close();
      bloc = WorkoutBloc(repository);
      repository.failReadActive = true;
      var failed = bloc.stream.firstWhere((state) => state is WorkoutError);
      bloc.add(ResumeWorkout());
      await failed;
      failed = bloc.stream.firstWhere((state) => state is WorkoutError);
      bloc.add(
        StartWorkout(
          plan: plan.copyWith(id: 'new-plan'),
          day: day,
        ),
      );
      await failed;
      expect(repository.active!.workoutLogId, savedId);
      repository.failReadActive = false;
      await settle(bloc, ResumeWorkout());
      expect((bloc.state as WorkoutInProgress).workoutLogId, savedId);
    },
  );

  test(
    'partial finish preserves completed work and excludes untouched suggestions from totals',
    () async {
      final skipped = Exercise(
        id: 'skipped',
        name: 'Leg press',
        targetWeight: 500,
      );
      final partialDay = day.copyWith(exercises: [exercise, skipped]);
      await settle(bloc, StartWorkout(plan: plan, day: partialDay));
      await complete();
      await settle(bloc, FinishWorkout());
      final saved = repository.logs.single;
      expect(saved.totalVolume, 125);
      expect(
        saved.exerciseLogs.values
            .expand((sets) => sets)
            .where((set) => set.isCompleted),
        hasLength(1),
      );
      expect(
        saved.exerciseLogs[skipped.id]!.every((set) => !set.isCompleted),
        isTrue,
      );
      expect(saved.endTime, now);
      expect(repository.active, isNull);
    },
  );

  test('resume preserves sets and the wall clock rest deadline', () async {
    await start();
    await complete();
    final cached = repository.active!;
    await bloc.close();
    bloc = WorkoutBloc(repository);
    await settle(bloc, ResumeWorkout());
    final resumed = bloc.state as WorkoutInProgress;
    expect(resumed.exerciseLogs[exercise.id]!.first.isCompleted, isTrue);
    expect(resumed.restUntil, now.add(const Duration(seconds: 90)));
    expect(resumed.workoutLogId, cached.workoutLogId);
  });

  test('resume removes a cache left after history was committed', () async {
    await start();
    await complete();
    repository.failClear = true;
    await settle(bloc, FinishWorkout());
    await bloc.close();
    repository.failClear = false;
    bloc = WorkoutBloc(repository);
    await settle(bloc, ResumeWorkout());
    expect(repository.active, isNull);
    expect(repository.logs.length, 1);
  });

  test(
    'classic entries honor default rest while explicit targets override it',
    () async {
      repository.defaultRestTime = 120;
      await start();
      await complete();
      expect(
        (bloc.state as WorkoutInProgress).restUntil,
        now.add(const Duration(seconds: 120)),
      );
      await settle(bloc, CancelWorkout());
      final customDay = day.copyWith(
        exercises: [
          exercise.copyWith(restDurationSeconds: 60, useDefaultRest: false),
        ],
      );
      await settle(bloc, StartWorkout(plan: plan, day: customDay));
      await complete();
      expect(
        (bloc.state as WorkoutInProgress).restUntil,
        now.add(const Duration(seconds: 60)),
      );
    },
  );

  test(
    'removed completed sets can be restored without losing their values',
    () async {
      await start();
      await complete();
      final set =
          (bloc.state as WorkoutInProgress).exerciseLogs[exercise.id]!.first;
      await settle(bloc, RemoveSet(exerciseId: exercise.id, setId: set.id));
      await settle(
        bloc,
        RestoreSet(exerciseId: exercise.id, setLog: set, index: 0),
      );
      final restored = repository.active!.exerciseLogs[exercise.id]!.first;
      expect(restored.id, set.id);
      expect(restored.isCompleted, isTrue);
      expect(restored.weight, set.weight);
    },
  );

  test('queued increments and completion use the latest set values', () async {
    await start();
    final set = repository.active!.exerciseLogs[exercise.id]!.first;
    bloc.add(
      AdjustSet(exerciseId: exercise.id, setId: set.id, weightDelta: 2.5),
    );
    bloc.add(
      AdjustSet(exerciseId: exercise.id, setId: set.id, weightDelta: 2.5),
    );
    bloc.add(
      SetCompletion(exerciseId: exercise.id, setId: set.id, completed: true),
    );
    final finished = bloc.stream.firstWhere((state) => state is WorkoutInitial);
    bloc.add(FinishWorkout());
    await finished;
    expect(
      repository.logs.single.exerciseLogs[exercise.id]!.first.weight,
      17.5,
    );
    expect(repository.logs.single.totalVolume, 175);
  });

  test('cancel waits for pending edits then clears the session', () async {
    await start();
    bloc.add(AddSet(exercise.id));
    await settle(bloc, CancelWorkout());
    expect(repository.active, isNull);
    expect(repository.logs, isEmpty);
  });

  test(
    'replacement uses new movement context and ignores stale set actions',
    () async {
      repository.plans.add(plan);
      final replacement = Exercise(
        id: 'new-entry',
        name: 'Leg press',
        targetSets: 2,
        note: 'Seat at 3',
      );
      repository.logs.add(
        WorkoutLog(
          id: 'previous-legpress',
          planId: 'other',
          dayId: 'other-day',
          dayName: 'Legs',
          startTime: now.subtract(const Duration(days: 1)),
          exerciseIdentities: {'old-legpress': replacement.identityId},
          exerciseLogs: {
            'old-legpress': [
              SetLog(
                id: 'previous-set',
                weight: 90,
                reps: 8,
                isCompleted: true,
              ),
            ],
          },
        ),
      );
      await start();
      final oldSet = repository.active!.exerciseLogs[exercise.id]!.first;
      await settle(
        bloc,
        ReplaceSessionExercise(
          exerciseId: exercise.id,
          replacement: replacement,
        ),
      );
      final active = repository.active!;
      expect(active.day.exercises.single.id, replacement.id);
      expect(active.day.exercises.single.note, 'Seat at 3');
      expect(active.exerciseLogs.keys, [replacement.id]);
      expect(active.previousExerciseLogs.keys, [replacement.id]);
      expect(active.exerciseLogs[replacement.id]!.map((set) => set.weight), [
        90,
        90,
      ]);
      expect(
        active.exerciseLogs[replacement.id]!.every((set) => !set.isCompleted),
        isTrue,
      );
      expect(
        repository.plans.single.days.single.exercises.single,
        same(exercise),
      );
      bloc.add(RestoreSet(exerciseId: exercise.id, setLog: oldSet, index: 0));
      bloc.add(AddSet(exercise.id));
      await settle(bloc, RetryWorkoutSave());
      expect(repository.active!.exerciseLogs.keys, [replacement.id]);
      await settle(
        bloc,
        SetCompletion(
          exerciseId: replacement.id,
          setId: active.exerciseLogs[replacement.id]!.first.id,
          completed: true,
        ),
      );
      await settle(bloc, FinishWorkout());
      final saved = repository.logs.last;
      expect(saved.exerciseNames, {replacement.id: replacement.name});
      expect(saved.exerciseIdentities, {
        replacement.id: replacement.identityId,
      });
      expect(saved.totalVolume, 720);
    },
  );

  test(
    'replacement cannot overwrite logged work or reuse an occupied entry',
    () async {
      await start();
      final another = Exercise(id: 'other', name: 'Leg press');
      await settle(bloc, AddSessionExercise(another));
      bloc.add(
        ReplaceSessionExercise(exerciseId: exercise.id, replacement: another),
      );
      bloc.add(
        ReplaceSessionExercise(exerciseId: exercise.id, replacement: exercise),
      );
      await settle(bloc, RetryWorkoutSave());
      expect(repository.active!.day.exercises.map((exercise) => exercise.id), [
        exercise.id,
        another.id,
      ]);
      final set = repository.active!.exerciseLogs[exercise.id]!.first;
      bloc.add(
        SetCompletion(exerciseId: exercise.id, setId: set.id, completed: true),
      );
      bloc.add(
        ReplaceSessionExercise(
          exerciseId: exercise.id,
          replacement: Exercise(id: 'fresh', name: 'Squat'),
        ),
      );
      await settle(bloc, RetryWorkoutSave());
      expect(repository.active!.day.exercises.first.id, exercise.id);
      expect(
        repository.active!.exerciseLogs[exercise.id]!.first.isCompleted,
        isTrue,
      );
    },
  );

  test(
    'queued moves preserve sets, entry context and the saved plan',
    () async {
      final extra = Exercise(id: 'extra', name: 'Leg press', note: 'Seat at 2');
      final third = Exercise(id: 'third', name: 'Calf raise');
      final orderedDay = day.copyWith(exercises: [exercise, extra, third]);
      final orderedPlan = plan.copyWith(days: [orderedDay]);
      repository.plans.add(orderedPlan);
      await settle(bloc, StartWorkout(plan: orderedPlan, day: orderedDay));
      await complete();
      final logged = repository.active!.exerciseLogs[exercise.id]!.first;
      repository.saveGate = Completer<void>();
      bloc.add(MoveSessionExercise(exerciseId: third.id, offset: -1));
      bloc.add(MoveSessionExercise(exerciseId: third.id, offset: -1));
      final done = bloc.stream.firstWhere((state) => state is WorkoutInitial);
      bloc.add(FinishWorkout());
      await Future<void>.delayed(Duration.zero);
      repository.saveGate!.complete();
      await done;
      final history = repository.logs.single;
      expect(history.exerciseLogs.keys, [third.id, exercise.id, extra.id]);
      expect(history.exerciseLogs[exercise.id]!.first, same(logged));
      expect(history.totalVolume, 125);
      expect(repository.plans.single.days.single.exercises, [
        exercise,
        extra,
        third,
      ]);
      expect(repository.maxConcurrentWrites, 1);
    },
  );

  test(
    'failed replacement and move retain the latest session for retry and resume',
    () async {
      await start();
      final extra = Exercise(id: 'extra', name: 'Leg press');
      await settle(bloc, AddSessionExercise(extra));
      repository.failSave = true;
      final replacement = Exercise(
        id: 'replacement',
        name: 'Squat',
        note: 'Rack at 5',
      );
      await settle(
        bloc,
        ReplaceSessionExercise(exerciseId: extra.id, replacement: replacement),
      );
      await settle(
        bloc,
        MoveSessionExercise(exerciseId: replacement.id, offset: -1),
      );
      expect((bloc.state as WorkoutInProgress).errorMessage, isNotNull);
      expect(repository.active!.day.exercises.last.id, extra.id);
      repository.failSave = false;
      await settle(bloc, RetryWorkoutSave());
      bloc.add(MoveSessionExercise(exerciseId: replacement.id, offset: -1));
      bloc.add(MoveSessionExercise(exerciseId: 'missing', offset: 1));
      bloc.add(MoveSessionExercise(exerciseId: exercise.id, offset: 20));
      await settle(bloc, RetryWorkoutSave());
      await bloc.close();
      bloc = WorkoutBloc(repository);
      await settle(bloc, ResumeWorkout());
      final resumed = bloc.state as WorkoutInProgress;
      expect(resumed.day.exercises.map((exercise) => exercise.id), [
        replacement.id,
        exercise.id,
      ]);
      expect(resumed.day.exercises.first.note, 'Rack at 5');
      expect(resumed.exerciseLogs.containsKey(extra.id), isFalse);
    },
  );

  test(
    'new plan uses shared exercise history while keeping entry targets and notes separate',
    () async {
      await start();
      final original = repository.active!.exerciseLogs[exercise.id]!.first;
      await settle(
        bloc,
        UpdateSet(
          exerciseId: exercise.id,
          setLog: original.copyWith(weight: 25, reps: 8, isCompleted: true),
        ),
      );
      await settle(bloc, FinishWorkout());
      expect(
        repository.logs.single.exerciseIdentities[exercise.id],
        exercise.identityId,
      );
      final other = exercise.copyWith(
        id: 'other-entry',
        targetSets: 2,
        note: 'Different plan cue',
      );
      final otherDay = day.copyWith(id: 'other-day', exercises: [other]);
      await settle(
        bloc,
        StartWorkout(
          plan: plan.copyWith(id: 'other-plan', days: [otherDay]),
          day: otherDay,
        ),
      );
      final active = repository.active!;
      expect(active.exerciseLogs['other-entry'], hasLength(2));
      expect(active.exerciseLogs['other-entry']!.first.weight, 25);
      expect(active.exerciseLogs['other-entry']!.first.reps, 8);
      expect(active.day.exercises.single.note, 'Different plan cue');
      expect(active.previousExerciseLogs['other-entry']!.single.weight, 25);
      expect(repository.logs.single.exerciseNames[exercise.id], exercise.name);
      expect(repository.logs.single.totalVolume, 200);
    },
  );

  test(
    'changing an unlogged exercise resets suggestions and logged identities cannot change',
    () async {
      await start();
      final replacement = Exercise(
        id: exercise.id,
        name: 'Barbell bench press',
        targetWeight: 60,
        targetReps: 6,
        targetSets: 2,
      );
      await settle(bloc, EditSessionExercise(replacement));
      expect(
        repository.active!.day.exercises.single.identityId,
        replacement.identityId,
      );
      expect(repository.active!.exerciseLogs[exercise.id]!.first.weight, 60);
      expect(repository.active!.previousExerciseLogs[exercise.id], isEmpty);
      await complete();
      final before = bloc.state;
      bloc.add(EditSessionExercise(exercise));
      await Future<void>.delayed(Duration.zero);
      expect(identical(bloc.state, before), isTrue);
      expect(
        repository.active!.day.exercises.single.identityId,
        replacement.identityId,
      );
    },
  );

  test(
    'session additions use shared completed history without changing the plan',
    () async {
      repository.logs.add(
        WorkoutLog(
          id: 'previous',
          planId: 'other-plan',
          dayId: 'other-day',
          dayName: 'Other',
          startTime: now.subtract(const Duration(days: 1)),
          exerciseLogs: {
            'old-entry': [
              SetLog(id: 'old', weight: 40, reps: 8, isCompleted: true),
            ],
          },
          exerciseIdentities: {'old-entry': 'catalog:barbell-bench-press'},
        ),
      );
      await start();
      final added = Exercise(
        id: 'new-entry',
        name: 'Barbell bench press',
        targetSets: 2,
      );
      await settle(bloc, AddSessionExercise(added));
      expect(repository.active!.exerciseLogs['new-entry']!.first.weight, 40);
      expect(
        repository.active!.previousExerciseLogs['new-entry']!.single.reps,
        8,
      );
      expect(day.exercises, hasLength(1));
    },
  );
  test(
    'record comparison uses identity instead of a reused entry ID',
    () async {
      final scheduler = _Achievements();
      await bloc.close();
      bloc = WorkoutBloc(repository, scheduler, () => now);
      repository.logs.addAll([
        WorkoutLog(
          id: 'wrong-movement',
          planId: 'plan',
          dayId: 'day',
          dayName: 'Upper',
          startTime: now.subtract(const Duration(days: 2)),
          exerciseLogs: {
            exercise.id: [
              SetLog(id: 'bench', weight: 20, reps: 8, isCompleted: true),
            ],
          },
          exerciseIdentities: {exercise.id: 'catalog:barbell-bench-press'},
        ),
        WorkoutLog(
          id: 'correct-movement',
          planId: 'other-plan',
          dayId: 'other-day',
          dayName: 'Lower',
          startTime: now.subtract(const Duration(days: 1)),
          exerciseLogs: {
            'other-entry': [
              SetLog(id: 'kickback', weight: 50, reps: 8, isCompleted: true),
            ],
          },
          exerciseIdentities: {'other-entry': exercise.identityId},
        ),
      ]);
      await start();
      final current = repository.active!.exerciseLogs[exercise.id]!.first;
      await settle(
        bloc,
        UpdateSet(
          exerciseId: exercise.id,
          setLog: current.copyWith(weight: 30, reps: 8, isCompleted: true),
        ),
      );
      await settle(bloc, FinishWorkout());
      await Future<void>.delayed(Duration.zero);
      expect(scheduler.records, 0);
    },
  );
}
