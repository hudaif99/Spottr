import '../../domain/models/workout_models.dart';
import '../../domain/repositories/workout_repository.dart';
import '../datasources/local_database_service.dart';
import '../mappers/workout_storage_mapper.dart';

class WorkoutRepositoryImpl implements WorkoutRepository {
  final LocalDatabaseService _localDb;

  WorkoutRepositoryImpl(this._localDb);

  @override
  Future<List<Plan>> getPlans() async =>
      _localDb.getAllPlans().map((plan) => plan.toDomain()).toList();

  @override
  Future<Plan?> getActivePlan() async => _localDb
      .getAllPlans()
      .where((plan) => plan.isActive)
      .firstOrNull
      ?.toDomain();

  @override
  Future<void> savePlan(Plan plan) => _localDb.savePlan(plan.toStorage());

  @override
  Future<void> deletePlan(String id) => _localDb.deletePlan(id);

  @override
  Future<void> setActivePlan(String id) async {
    for (final plan in _localDb.getAllPlans()) {
      final active = plan.id == id;
      if (plan.isActive != active) {
        await _localDb.savePlan(plan.copyWith(isActive: active));
      }
    }
  }

  @override
  Future<List<Exercise>> getExercises() async => _localDb
      .getAllExercises()
      .map((exercise) => exercise.toDomain())
      .toList();

  @override
  Future<void> saveExercise(Exercise exercise) =>
      _localDb.saveExercise(exercise.toStorage());

  @override
  Future<void> deleteExercise(String id) => _localDb.deleteExercise(id);

  @override
  Future<List<WorkoutLog>> getWorkoutLogs() async =>
      _localDb.getAllWorkoutLogs().map((log) => log.toDomain()).toList();

  @override
  Future<void> saveWorkoutLog(WorkoutLog log) =>
      _localDb.saveWorkoutLog(log.toStorage());

  @override
  Future<void> deleteWorkoutLog(String id) => _localDb.deleteWorkoutLog(id);

  @override
  ActiveWorkout? getActiveWorkout() => _localDb.getActiveWorkout()?.toDomain();

  @override
  Future<void> saveActiveWorkout(ActiveWorkout workout) =>
      _localDb.saveActiveWorkout(workout.toStorage());

  @override
  Future<void> clearActiveWorkout() => _localDb.clearActiveWorkout();

  @override
  int getDefaultRestTime() => _localDb.getRestTime();

  @override
  Future<WorkoutSchedule?> getScheduleForToday() async =>
      _localDb.getWorkoutSchedule()?.toDomain();
}
