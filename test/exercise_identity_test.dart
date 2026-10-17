import 'package:flutter_test/flutter_test.dart';
import 'package:spottr/domain/exercise_catalog.dart';
import 'package:spottr/domain/exercise_identity.dart';
import 'package:spottr/domain/exercise_name_suggestions.dart';
import 'package:spottr/domain/models/workout_models.dart';

void main() {
  final date = DateTime(2026, 10, 17);
  final squat = Exercise(id: 'new-entry', name: 'Squat');
  WorkoutLog log(
    String id,
    Map<String, List<SetLog>> sets, {
    Map<String, String> identities = const {},
    Map<String, String> names = const {},
    int daysAgo = 0,
  }) => WorkoutLog(
    id: id,
    planId: 'other-plan',
    dayId: 'day',
    dayName: 'Lower',
    startTime: date.subtract(Duration(days: daysAgo)),
    exerciseLogs: sets,
    exerciseIdentities: identities,
    exerciseNames: names,
  );
  SetLog set(String id, double weight, {bool completed = true}) =>
      SetLog(id: id, weight: weight, reps: 8, isCompleted: completed);

  test(
    'catalog identities are stable and distinct from plan entries and variants',
    () {
      expect(squat.identityId, 'catalog:squat');
      expect(
        Exercise(id: 'another-entry', name: '  SQUAT  ').identityId,
        squat.identityId,
      );
      expect(
        catalogIdentityForName('Dumbbell   bench press'),
        'catalog:dumbbell-bench-press',
      );
      expect(catalogIdentityForName('RDL'), isNull);
      expect(catalogIdentityForName('back squat'), isNull);
      expect(
        Exercise(id: 'barbell', name: 'Barbell bench press').identityId,
        isNot(
          Exercise(id: 'dumbbell', name: 'Dumbbell bench press').identityId,
        ),
      );
      expect(
        commonExerciseCatalog.values.toSet().length,
        commonExerciseCatalog.length,
      );
      expect(commonExerciseNames.length, commonExerciseCatalog.length);
      for (final entry in commonExerciseCatalog.entries) {
        expect(catalogIdentityForName(entry.value), entry.key);
      }
    },
  );

  test(
    'custom entries stay separate unless an identity is deliberately reused',
    () {
      final custom = Exercise(id: 'one', name: 'My cable setup');
      expect(
        Exercise(id: 'two', name: custom.name).identityId,
        isNot(custom.identityId),
      );
      expect(
        custom.copyWith(id: 'another-plan-entry').identityId,
        custom.identityId,
      );
      expect(
        identityForExerciseEdit(custom, 'My cable setup', 'custom:new'),
        custom.identityId,
      );
      expect(
        identityForExerciseEdit(custom, 'New movement', 'custom:new'),
        'custom:new',
      );
      expect(
        identityForExerciseEdit(custom, 'Squat', 'custom:new'),
        squat.identityId,
      );
    },
  );

  test(
    'uses latest completed shared identity across plans and preserves set values',
    () {
      final history = [
        log(
          'older',
          {
            'old-entry': [set('older', 30)],
          },
          identities: {'old-entry': squat.identityId},
          daysAgo: 3,
        ),
        log(
          'latest',
          {
            'other-entry': [
              set('logged', 50),
              set('draft', 999, completed: false),
            ],
          },
          identities: {'other-entry': squat.identityId},
          names: {'other-entry': 'Historical label'},
          daysAgo: 1,
        ),
      ];
      final previous = previousSetsForExercise(squat, history);
      expect(previous.map((set) => set.id), ['logged']);
      expect(previous.single.weight, 50);
      expect(history.first.id, 'older');
      expect(history.last.exerciseNames['other-entry'], 'Historical label');
    },
  );

  test(
    'legacy entry fallback does not infer cross-plan identity from names',
    () {
      final named = log(
        'named',
        {
          'other-entry': [set('unrelated', 90)],
        },
        names: {'other-entry': 'Squat'},
      );
      expect(previousSetsForExercise(squat, [named]), isEmpty);
      final sameEntry = log('classic', {
        squat.id: [set('classic', 40)],
      });
      expect(previousSetsForExercise(squat, [sameEntry]).single.weight, 40);
      final renamed = sameEntry.copyWith(
        exerciseNames: {squat.id: 'Barbell bench press'},
      );
      expect(previousSetsForExercise(squat, [renamed]), isEmpty);
      final different = sameEntry.copyWith(
        exerciseIdentities: {squat.id: 'catalog:barbell-bench-press'},
      );
      expect(previousSetsForExercise(squat, [different]), isEmpty);
    },
  );

  test(
    'does not combine duplicate exercise entries into a false previous session',
    () {
      final duplicate = log(
        'duplicate',
        {
          'first': [set('one', 30)],
          'second': [set('two', 60)],
        },
        identities: {'first': squat.identityId, 'second': squat.identityId},
      );
      expect(previousSetsForExercise(squat, [duplicate]), isEmpty);
      expect(
        completedSetsForExercise(squat, duplicate).map((set) => set.weight),
        [30, 60],
      );
      final exactEntry = squat.copyWith(id: 'second');
      expect(
        previousSetsForExercise(exactEntry, [duplicate]).single.weight,
        60,
      );
    },
  );

  test('identity snapshots copy input maps and cannot be changed', () {
    final identities = {'entry': squat.identityId};
    final saved = log('immutable', {}, identities: identities);
    identities.clear();
    expect(saved.exerciseIdentities['entry'], squat.identityId);
    expect(() => saved.exerciseIdentities.clear(), throwsUnsupportedError);
  });
}
