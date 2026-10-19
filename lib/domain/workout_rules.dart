import 'models/plan.dart';
import 'models/workout_day.dart';
import 'models/workout_log.dart';
import 'models/set_log.dart';

/// A recorded final set can end logging without inventing earlier performance.
bool hasLoggedFinalSetWithGaps(List<SetLog> sets) =>
    sets.length > 1 &&
    sets.last.isCompleted &&
    sets.take(sets.length - 1).any((set) => !set.isCompleted);

WorkoutDay? nextWorkoutDay(Plan plan, List<WorkoutLog> history) {
  if (plan.days.isEmpty) return null;
  final sessions = history.where((log) => log.planId == plan.id).toList()
    ..sort((a, b) => b.startTime.compareTo(a.startTime));
  if (sessions.isEmpty) return plan.days.first;
  final previous = plan.days.indexWhere(
    (day) => day.id == sessions.first.dayId,
  );
  return plan.days[(previous + 1) % plan.days.length];
}
