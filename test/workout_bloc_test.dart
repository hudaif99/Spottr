import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:spottr/data/models/exercise.dart';
import 'package:spottr/data/models/plan.dart';
import 'package:spottr/data/models/set_log.dart';
import 'package:spottr/data/models/workout_day.dart';
import 'package:spottr/data/models/workout_log.dart';
import 'package:spottr/presentation/blocs/workout/workout_bloc.dart';
import 'package:spottr/presentation/blocs/workout/workout_event.dart';
import 'package:spottr/presentation/blocs/workout/workout_state.dart';
import 'support/fake_workout_repository.dart';

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
}
