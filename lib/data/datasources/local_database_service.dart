import 'package:hive_flutter/hive_flutter.dart';
import '../models/exercise.dart';
import '../models/plan.dart';
import '../models/set_log.dart';
import '../models/workout_day.dart';
import '../models/workout_log.dart';
import '../models/active_workout.dart';

class LocalDatabaseService {
  static const String _plansBoxName = 'plans_box';
  static const String _exercisesBoxName = 'exercises_box';
  static const String _workoutLogsBoxName = 'workout_logs_box';
  static const String _activeWorkoutBoxName = 'active_workout_box';

  late Box<Plan> _plansBox;
  late Box<Exercise> _exercisesBox;
  late Box<WorkoutLog> _workoutLogsBox;
  late Box<ActiveWorkout> _activeWorkoutBox;

  Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SetLogAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ExerciseAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(WorkoutDayAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(PlanAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(WorkoutLogAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(ActiveWorkoutAdapter());
    }

    // Open Boxes
    _plansBox = await Hive.openBox<Plan>(_plansBoxName);
    _exercisesBox = await Hive.openBox<Exercise>(_exercisesBoxName);
    _workoutLogsBox = await Hive.openBox<WorkoutLog>(_workoutLogsBoxName);
    _activeWorkoutBox = await Hive.openBox<ActiveWorkout>(
      _activeWorkoutBoxName,
    );
  }

  // --- Plans ---
  List<Plan> getAllPlans() => _plansBox.values.toList();
  Plan? getPlan(String id) => _plansBox.get(id);
  Future<void> savePlan(Plan plan) => _plansBox.put(plan.id, plan);
  Future<void> deletePlan(String id) => _plansBox.delete(id);

  // --- Exercises ---
  List<Exercise> getAllExercises() => _exercisesBox.values.toList();
  Exercise? getExercise(String id) => _exercisesBox.get(id);
  Future<void> saveExercise(Exercise exercise) =>
      _exercisesBox.put(exercise.id, exercise);
  Future<void> deleteExercise(String id) => _exercisesBox.delete(id);

  // --- Workout Logs ---
  List<WorkoutLog> getAllWorkoutLogs() => _workoutLogsBox.values.toList();
  WorkoutLog? getWorkoutLog(String id) => _workoutLogsBox.get(id);
  Future<void> saveWorkoutLog(WorkoutLog log) =>
      _workoutLogsBox.put(log.id, log);
  Future<void> deleteWorkoutLog(String id) => _workoutLogsBox.delete(id);

  // --- Active Workout Cache ---
  ActiveWorkout? getActiveWorkout() {
    if (_activeWorkoutBox.isEmpty) return null;
    return _activeWorkoutBox.getAt(0);
  }

  Future<void> saveActiveWorkout(ActiveWorkout workout) async {
    await _activeWorkoutBox.clear();
    await _activeWorkoutBox.add(workout);
  }

  Future<void> clearActiveWorkout() async {
    await _activeWorkoutBox.clear();
  }

  // --- Database Lifecycle (For Backup/Restore) ---
  Future<void> closeAll() async {
    await Hive.close();
  }

  Future<void> reopenAll() async {
    _plansBox = await Hive.openBox<Plan>(_plansBoxName);
    _exercisesBox = await Hive.openBox<Exercise>(_exercisesBoxName);
    _workoutLogsBox = await Hive.openBox<WorkoutLog>(_workoutLogsBoxName);
    _activeWorkoutBox = await Hive.openBox<ActiveWorkout>(
      _activeWorkoutBoxName,
    );
  }
}
