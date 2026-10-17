import 'exercise_catalog.dart';
import 'models/exercise.dart';
import 'models/set_log.dart';
import 'models/workout_log.dart';

String identityForExerciseEdit(
  Exercise? original,
  String name,
  String customId,
) {
  String normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  if (original != null && normalize(original.name) == normalize(name)) {
    return original.identityId;
  }
  return catalogIdentityForName(name) ?? customId;
}

List<SetLog> previousSetsForExercise(
  Exercise exercise,
  List<WorkoutLog> history,
) {
  List<SetLog> previous = const [];
  DateTime? latest;
  for (final log in history) {
    if (latest != null && !log.startTime.isAfter(latest)) continue;
    final directIdentity = log.exerciseIdentities[exercise.id];
    final savedName = log.exerciseNames[exercise.id];
    final legacyNameMatches =
        savedName == null ||
        savedName.trim().toLowerCase() == exercise.name.trim().toLowerCase();
    if (directIdentity == exercise.identityId ||
        directIdentity == null && legacyNameMatches) {
      final direct = (log.exerciseLogs[exercise.id] ?? const <SetLog>[])
          .where((set) => set.isCompleted)
          .toList();
      if (direct.isNotEmpty) {
        previous = direct;
        latest = log.startTime;
        continue;
      }
    }
    final candidates = [
      for (final entry in log.exerciseIdentities.entries)
        if (entry.value == exercise.identityId)
          (log.exerciseLogs[entry.key] ?? const <SetLog>[])
              .where((set) => set.isCompleted)
              .toList(),
    ].where((sets) => sets.isNotEmpty).toList();
    // Duplicate entries in a session do not imply a single comparable set sequence.
    if (candidates.length == 1) {
      previous = candidates.single;
      latest = log.startTime;
    }
  }
  return previous;
}

List<SetLog> completedSetsForExercise(Exercise exercise, WorkoutLog log) => [
  for (final entry in log.exerciseLogs.entries)
    if (log.exerciseIdentities[entry.key] == exercise.identityId ||
        entry.key == exercise.id &&
            log.exerciseIdentities[entry.key] == null &&
            (log.exerciseNames[entry.key] == null ||
                log.exerciseNames[entry.key]!.trim().toLowerCase() ==
                    exercise.name.trim().toLowerCase()))
      ...entry.value.where((set) => set.isCompleted),
];
