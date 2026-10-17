import '../models/plan.dart';
import '../models/workout_log.dart';
import '../models/exercise.dart';
import '../models/active_workout.dart';
import '../models/workout_schedule.dart';

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

  // Active Workout Cache
  ActiveWorkout? getActiveWorkout();
  Future<void> saveActiveWorkout(ActiveWorkout workout);
  Future<void> clearActiveWorkout();
  int getDefaultRestTime();

  // Schedule (read-only access for notification hooks)
  Future<WorkoutSchedule?> getScheduleForToday();
}
