import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/exercise_catalog.dart';
import '../../../domain/exercise_name_suggestions.dart';
import '../../../domain/models/exercise.dart';
import '../../../domain/repositories/workout_repository.dart';

class ExerciseLibraryEntry {
  final Exercise exercise;
  final String source;
  final bool isSaved;
  const ExerciseLibraryEntry(this.exercise, this.source, {this.isSaved = true});
}

sealed class ExerciseLibraryEvent {}

class LoadExerciseLibrary extends ExerciseLibraryEvent {}

class SearchExerciseLibrary extends ExerciseLibraryEvent {
  final String query;
  SearchExerciseLibrary(this.query);
}

class ExerciseLibraryState {
  final List<ExerciseLibraryEntry> entries;
  final String query;
  final bool isLoading;
  final bool hasError;
  ExerciseLibraryState({
    required Iterable<ExerciseLibraryEntry> entries,
    this.query = '',
    this.isLoading = false,
    this.hasError = false,
  }) : entries = List.unmodifiable(entries);

  List<ExerciseLibraryEntry> get matches {
    final words = query.trim().toLowerCase().split(RegExp(r'\s+'));
    final suggestions = suggestExerciseNames(query).toSet();
    return entries.where((entry) {
      final searchable = '${entry.exercise.name} ${entry.exercise.note}'
          .toLowerCase();
      return words.every(searchable.contains) ||
          entry.exercise.identityId.startsWith('catalog:') &&
              suggestions.contains(entry.exercise.name);
    }).toList();
  }
}

class ExerciseLibraryBloc
    extends Bloc<ExerciseLibraryEvent, ExerciseLibraryState> {
  final WorkoutRepository _repository;
  final List<Exercise> _localExercises;

  ExerciseLibraryBloc(
    this._repository, {
    Iterable<Exercise> localExercises = const [],
  }) : _localExercises = List.unmodifiable(localExercises),
       super(ExerciseLibraryState(entries: const [])) {
    on<LoadExerciseLibrary>(
      _load,
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
    on<SearchExerciseLibrary>((event, emit) {
      emit(
        ExerciseLibraryState(
          entries: state.entries,
          query: event.query,
          isLoading: state.isLoading,
          hasError: state.hasError,
        ),
      );
    });
  }

  Future<void> _load(
    LoadExerciseLibrary event,
    Emitter<ExerciseLibraryState> emit,
  ) async {
    final entries = <String, ExerciseLibraryEntry>{
      for (final exercise in _localExercises)
        exercise.identityId: ExerciseLibraryEntry(
          exercise,
          'Current exercises',
        ),
    };
    void add(ExerciseLibraryEntry entry) =>
        entries.putIfAbsent(entry.exercise.identityId, () => entry);
    void addCatalog() {
      for (final entry in commonExerciseCatalog.entries) {
        add(
          ExerciseLibraryEntry(
            Exercise(id: entry.key, identityId: entry.key, name: entry.value),
            'Common exercise',
            isSaved: false,
          ),
        );
      }
    }

    addCatalog();
    emit(
      ExerciseLibraryState(
        entries: entries.values,
        query: state.query,
        isLoading: true,
      ),
    );
    // Saved setup takes precedence over catalog defaults.
    entries.removeWhere((_, entry) => !entry.isSaved);
    var failed = false;
    try {
      for (final exercise in await _repository.getExercises()) {
        add(ExerciseLibraryEntry(exercise, 'Saved exercise'));
      }
    } catch (_) {
      failed = true;
    }
    try {
      for (final plan in await _repository.getPlans()) {
        for (final day in plan.days) {
          for (final exercise in day.exercises) {
            add(ExerciseLibraryEntry(exercise, plan.name));
          }
        }
      }
    } catch (_) {
      failed = true;
    }
    addCatalog();
    final sorted = entries.values.toList()
      ..sort((a, b) {
        if (a.isSaved != b.isSaved) return a.isSaved ? -1 : 1;
        return a.exercise.name.toLowerCase().compareTo(
          b.exercise.name.toLowerCase(),
        );
      });
    if (emit.isDone) return;
    emit(
      ExerciseLibraryState(
        entries: sorted,
        query: state.query,
        hasError: failed,
      ),
    );
  }
}
