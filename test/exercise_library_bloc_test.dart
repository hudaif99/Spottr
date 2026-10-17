import 'package:flutter_test/flutter_test.dart';
import 'package:spottr/domain/models/exercise.dart';
import 'package:spottr/domain/models/plan.dart';
import 'package:spottr/domain/models/workout_day.dart';
import 'package:spottr/presentation/blocs/exercise_library/exercise_library_bloc.dart';
import 'support/fake_workout_repository.dart';

class _Repository extends FakeWorkoutRepository {
  bool failExercises = false;
  @override
  Future<List<Exercise>> getExercises() async {
    if (failExercises) throw StateError('Unavailable');
    return super.getExercises();
  }
}

Future<void> load(ExerciseLibraryBloc bloc) async {
  final done = bloc.stream.firstWhere((state) => !state.isLoading);
  bloc.add(LoadExerciseLibrary());
  await done;
}

Future<void> search(ExerciseLibraryBloc bloc, String query) async {
  final done = bloc.stream.first;
  bloc.add(SearchExerciseLibrary(query));
  await done;
}

void main() {
  test(
    'library keeps entry setup and deduplicates identity without merging custom names',
    () async {
      final repository = _Repository();
      final local = Exercise(
        id: 'local',
        name: 'Cable kickback',
        note: 'Pulley at knee level',
        targetWeight: 12.5,
      );
      final first = Exercise(id: 'custom-one', name: 'My row');
      final second = Exercise(id: 'custom-two', name: 'My row');
      repository.exercises.addAll([
        local.copyWith(id: 'saved', note: 'Old note'),
        first,
      ]);
      repository.plans.add(
        Plan(
          id: 'plan',
          name: 'Strength',
          days: [
            WorkoutDay(id: 'day', name: 'Pull', exercises: [second, local]),
          ],
        ),
      );
      final bloc = ExerciseLibraryBloc(repository, localExercises: [local]);
      addTearDown(bloc.close);
      await load(bloc);
      final saved = bloc.state.entries.where((entry) => entry.isSaved).toList();
      expect(saved, hasLength(3));
      expect(saved.first.exercise, same(local));
      expect(saved.first.exercise.note, 'Pulley at knee level');
      expect(saved.first.exercise.targetWeight, 12.5);
      expect(
        saved
            .where((entry) => entry.exercise.name == 'My row')
            .map((entry) => entry.exercise.identityId)
            .toSet(),
        hasLength(2),
      );
      expect(
        bloc.state.entries.where(
          (entry) => entry.exercise.identityId == local.identityId,
        ),
        hasLength(1),
      );
      expect(() => bloc.state.entries.clear(), throwsUnsupportedError);
      expect(repository.active, isNull);
      expect(repository.logWrites, 0);
      expect(repository.plans.single.days.single.exercises.last, same(local));
    },
  );

  test('search finds custom names, setup cues and catalog aliases', () async {
    final repository = _Repository();
    final custom = Exercise(
      id: 'local',
      name: 'Trainer row',
      note: 'Seat at knee level',
    );
    final bloc = ExerciseLibraryBloc(repository, localExercises: [custom]);
    addTearDown(bloc.close);
    await load(bloc);
    await search(bloc, '  KNEE seat ');
    expect(bloc.state.matches.single.exercise, same(custom));
    await search(bloc, 'hex bar');
    expect(bloc.state.matches.single.exercise.name, 'Trap bar deadlift');
    await search(bloc, 'does not exist');
    expect(bloc.state.matches, isEmpty);
  });

  test(
    'partial load failure keeps other sources and catalog available, retry preserves search',
    () async {
      final repository = _Repository()..failExercises = true;
      final custom = Exercise(id: 'custom', name: 'Trainer row');
      repository.plans.add(
        Plan(
          id: 'plan',
          name: 'Pull',
          days: [
            WorkoutDay(id: 'day', name: 'Day', exercises: [custom]),
          ],
        ),
      );
      final bloc = ExerciseLibraryBloc(repository);
      addTearDown(bloc.close);
      await load(bloc);
      expect(bloc.state.hasError, isTrue);
      expect(
        bloc.state.entries.any((entry) => entry.exercise.id == custom.id),
        isTrue,
      );
      expect(bloc.state.entries.any((entry) => !entry.isSaved), isTrue);
      await search(bloc, 'Trainer');
      repository.failExercises = false;
      await load(bloc);
      expect(bloc.state.hasError, isFalse);
      expect(bloc.state.query, 'Trainer');
      expect(bloc.state.matches.single.exercise.identityId, custom.identityId);
    },
  );
}
