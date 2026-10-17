import 'models/set_log.dart';
import 'models/workout_log.dart';
import 'workout_records.dart';

typedef ExerciseProgressKey = ({String? identity, String? entry, String? name});

class LoggedExerciseSet {
  final String entryId;
  final int number;
  final SetLog set;

  const LoggedExerciseSet(this.entryId, this.number, this.set);
}

class ExerciseSession {
  final WorkoutLog workout;
  final List<LoggedExerciseSet> sets;

  ExerciseSession(this.workout, Iterable<LoggedExerciseSet> sets)
    : sets = List.unmodifiable(sets);

  late final SetLog best = bestCompletedSet(sets.map((entry) => entry.set))!;
}

class ExerciseProgress {
  final ExerciseProgressKey key;
  final String name;
  final List<ExerciseSession> sessions;

  ExerciseProgress(this.key, this.name, Iterable<ExerciseSession> sessions)
    : sessions = List.unmodifiable(sessions);

  bool get isLegacy => key.identity == null;
  int get completedSets =>
      sessions.fold(0, (sum, session) => sum + session.sets.length);
  late final SetLog best = bestCompletedSet(
    sessions.expand((session) => session.sets.map((entry) => entry.set)),
  )!;
  late final DateTime bestDate = sessions
      .firstWhere(
        (session) => session.sets.any((entry) => identical(entry.set, best)),
      )
      .workout
      .startTime;
}

List<ExerciseProgress> buildExerciseProgress(Iterable<WorkoutLog> logs) {
  final sorted = logs.toList()
    ..sort((a, b) {
      final date = b.startTime.compareTo(a.startTime);
      return date == 0 ? a.id.compareTo(b.id) : date;
    });
  final groups = <ExerciseProgressKey, List<ExerciseSession>>{};
  final names = <ExerciseProgressKey, String>{};
  for (final log in sorted) {
    final sessionSets = <ExerciseProgressKey, List<LoggedExerciseSet>>{};
    for (final entry in log.exerciseLogs.entries) {
      final name = log.exerciseNames[entry.key]?.trim();
      final identity = log.exerciseIdentities[entry.key];
      // Legacy snapshots cannot safely be joined to a movement by name alone.
      final ExerciseProgressKey key = identity != null && identity.isNotEmpty
          ? (identity: identity, entry: null, name: null)
          : (
              identity: null,
              entry: entry.key,
              name: name?.toLowerCase().replaceAll(RegExp(r'\s+'), ' '),
            );
      for (final (index, set) in entry.value.indexed) {
        if (!set.isCompleted) continue;
        sessionSets
            .putIfAbsent(key, () => [])
            .add(LoggedExerciseSet(entry.key, index + 1, set));
        names.putIfAbsent(
          key,
          () => name == null || name.isEmpty
              ? 'Exercise from an earlier plan'
              : name,
        );
      }
    }
    for (final entry in sessionSets.entries) {
      groups
          .putIfAbsent(entry.key, () => [])
          .add(ExerciseSession(log, entry.value));
    }
  }
  return List.unmodifiable(
    groups.entries.map(
      (entry) => ExerciseProgress(entry.key, names[entry.key]!, entry.value),
    ),
  );
}
