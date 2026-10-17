import 'models/set_log.dart';

bool isBetterSet(SetLog candidate, SetLog reference) =>
    candidate.weight > reference.weight ||
    (candidate.weight == reference.weight && candidate.reps > reference.reps);

SetLog? bestCompletedSet(Iterable<SetLog> sets) {
  SetLog? best;
  for (final set in sets) {
    if (set.isCompleted && (best == null || isBetterSet(set, best))) {
      best = set;
    }
  }
  return best;
}
