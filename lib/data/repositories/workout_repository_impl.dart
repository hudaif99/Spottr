import '../../domain/repositories/workout_repository.dart';
import '../datasources/local_database_service.dart';
import '../models/exercise.dart';
import '../models/plan.dart';
import '../models/workout_log.dart';
import '../models/active_workout.dart';
import '../models/workout_schedule.dart';

class WorkoutRepositoryImpl implements WorkoutRepository {
  final LocalDatabaseService _localDb;

  WorkoutRepositoryImpl(this._localDb);

  @override
  Future<List<Plan>> getPlans() async {
    return _localDb.getAllPlans();
  }

  @override
  Future<Plan?> getActivePlan() async {
    final plans = _localDb.getAllPlans();
    try {
      return plans.firstWhere((p) => p.isActive);
    } catch (e) {
      return null; // No active plan found
    }
  }

  @override
  Future<void> savePlan(Plan plan) async {
    await _localDb.savePlan(plan);
  }

  @override
  Future<void> deletePlan(String id) async {
    await _localDb.deletePlan(id);
  }

  @override
  Future<void> setActivePlan(String id) async {
    final plans = _localDb.getAllPlans();
    for (var plan in plans) {
      if (plan.id == id) {
        if (!plan.isActive) {
          await _localDb.savePlan(plan.copyWith(isActive: true));
        }
      } else {
        if (plan.isActive) {
          await _localDb.savePlan(plan.copyWith(isActive: false));
        }
      }
    }
  }

  @override
  Future<List<Exercise>> getExercises() async {
    return _localDb.getAllExercises();
  }

  @override
  Future<void> saveExercise(Exercise exercise) async {
    await _localDb.saveExercise(exercise);
  }

  @override
  Future<void> deleteExercise(String id) async {
    await _localDb.deleteExercise(id);
  }

  @override
  Future<List<WorkoutLog>> getWorkoutLogs() async {
    return _localDb.getAllWorkoutLogs();
  }

  @override
  Future<void> saveWorkoutLog(WorkoutLog log) async {
    await _localDb.saveWorkoutLog(log);
  }

  @override
  Future<void> deleteWorkoutLog(String id) async {
    await _localDb.deleteWorkoutLog(id);
  }

  // Active Workout Caching Methods
  @override
  ActiveWorkout? getActiveWorkout() {
    return _localDb.getActiveWorkout();
  }

  @override
  Future<void> saveActiveWorkout(ActiveWorkout workout) async {
    await _localDb.saveActiveWorkout(workout);
  }

  @override
  Future<void> clearActiveWorkout() async {
    await _localDb.clearActiveWorkout();
  }

  @override
  int getDefaultRestTime() => _localDb.getRestTime();

  @override
  Future<WorkoutSchedule?> getScheduleForToday() async {
    return _localDb.getWorkoutSchedule();
  }
}
