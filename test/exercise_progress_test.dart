import 'package:flutter_test/flutter_test.dart';
import 'package:spottr/domain/exercise_progress.dart';
import 'package:spottr/domain/models/set_log.dart';
import 'package:spottr/domain/models/workout_log.dart';
import 'package:spottr/domain/workout_records.dart';
import 'package:spottr/presentation/blocs/history/history_state.dart';

SetLog set(
  String id,
  double weight,
  int reps, {
  bool completed = true,
  bool warmup = false,
  bool drop = false,
}) => SetLog(
  id: id,
  weight: weight,
  reps: reps,
  isCompleted: completed,
  isWarmup: warmup,
  isDropSet: drop,
);

WorkoutLog log(
  String id,
  int day, {
  String entry = 'entry',
  String? identity = 'squat',
  String name = 'Squat',
  List<SetLog>? sets,
}) => WorkoutLog(
  id: id,
  planId: id,
  dayId: 'day',
  dayName: 'Leg day',
  startTime: DateTime(2026, 10, day),
  exerciseNames: {entry: name},
  exerciseIdentities: {entry: ?identity},
  exerciseLogs: {
    entry: sets ?? [set(id, 20, 8)],
  },
);

void main() {
  test(
    'best uses load then reps, excludes suggestions, includes set types',
    () {
      final warmup = set('warmup', 30, 2, warmup: true);
      final drop = set('drop', 30, 3, drop: true);
      final tie = set('tie', 30, 3);
      expect(bestCompletedSet([set('lighter', 20, 100), warmup]), same(warmup));
      expect(
        bestCompletedSet([
          warmup,
          drop,
          tie,
          set('suggestion', 999, 99, completed: false),
        ]),
        same(drop),
      );
      expect(isBetterSet(tie, drop), isFalse);
      expect(
        bestCompletedSet([set('zero', 0, 10), set('zero-more', 0, 11)])!.reps,
        11,
      );
      expect(
        bestCompletedSet([set('unfinished', 40, 10, completed: false)]),
        isNull,
      );
    },
  );

  test(
    'shared movements join across plans with original positions and dates',
    () {
      final older = log('old', 1, sets: [set('best', 30, 10)]);
      final recent = log(
        'new',
        17,
        entry: 'new-entry',
        name: 'Renamed squat',
        sets: [
          set('first', 20, 8),
          set('skip', 999, 10, completed: false),
          set('third', 25, 5),
        ],
      );
      final input = [older, recent];
      final result = buildExerciseProgress(input).single;
      expect(result.name, 'Renamed squat');
      expect(result.sessions.map((session) => session.workout.id), [
        'new',
        'old',
      ]);
      expect(result.completedSets, 3);
      expect(result.sessions.first.sets.map((entry) => entry.number), [1, 3]);
      expect(result.best.id, 'best');
      expect(result.bestDate, older.startTime);
      expect(input.first, same(older));
      expect(() => result.sessions.clear(), throwsUnsupportedError);
      expect(() => result.sessions.first.sets.clear(), throwsUnsupportedError);
    },
  );

  test(
    'duplicate movement entries count as one workout without losing sets',
    () {
      final original = log('one', 17);
      final duplicate = original.copyWith(
        exerciseIdentities: {'entry': 'squat', 'second': 'squat'},
        exerciseNames: {'entry': 'Squat', 'second': 'Squat again'},
        exerciseLogs: {
          ...original.exerciseLogs,
          'second': [set('extra', 25, 8)],
        },
      );
      final progress = buildExerciseProgress([duplicate]).single;
      expect(progress.sessions, hasLength(1));
      expect(progress.completedSets, 2);
      expect(progress.sessions.single.sets.map((entry) => entry.entryId), [
        'entry',
        'second',
      ]);
    },
  );

  test(
    'custom identity and legacy snapshots never merge by matching names',
    () {
      final progress = buildExerciseProgress([
        log('catalog', 17),
        log('custom', 16, identity: 'custom:squat'),
        log('legacy', 15, identity: null),
        log('legacy-same', 14, identity: null, name: '  SQUAT  '),
        log('legacy-renamed', 13, identity: null, name: 'Bench press'),
        log('other-entry', 12, identity: null, entry: 'other'),
      ]);
      expect(progress, hasLength(5));
      expect(progress.where((exercise) => exercise.isLegacy), hasLength(3));
      expect(
        progress
            .firstWhere((exercise) => exercise.sessions.length == 2)
            .isLegacy,
        isTrue,
      );
    },
  );

  test('unfinished entries are absent and state owns its history snapshot', () {
    final logs = [
      log('one', 17),
      log(
        'unfinished',
        16,
        sets: [set('suggested', 999, 99, completed: false)],
      ),
    ];
    final state = HistoryLoaded(logs);
    logs.clear();
    expect(state.logs, hasLength(2));
    expect(state.exercises.single.completedSets, 1);
    expect(() => state.logs.clear(), throwsUnsupportedError);
    expect(() => state.exercises.clear(), throwsUnsupportedError);
    expect(buildExerciseProgress([]), isEmpty);
  });
}
