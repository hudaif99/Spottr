import '../../data/models/plan.dart';
import '../../data/models/workout_log.dart';
import '../../data/models/exercise.dart';

abstract class WorkoutRepository {
  // Plans
  Future<List<Plan>> getPlans();
  Future<Plan?> getActivePlan();
  Future<void> savePlan(Plan plan);
  Future<void> deletePlan(String id);
  Future<void> setActivePlan(String id);

  // Exercises
  Future<List<Exercise>> getExercises();
  Future<void> saveExercise(Exercise exercise);
  Future<void> deleteExercise(String id);

  // Logs
  Future<List<WorkoutLog>> getWorkoutLogs();
  Future<void> saveWorkoutLog(WorkoutLog log);
  Future<void> deleteWorkoutLog(String id);
}
