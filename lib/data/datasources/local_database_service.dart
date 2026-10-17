import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'backup_file_transaction.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/exercise.dart';
import '../models/plan.dart';
import '../models/set_log.dart';
import '../models/workout_day.dart';
import '../models/workout_log.dart';
import '../models/active_workout.dart';
import '../models/workout_schedule.dart';

class LocalDatabaseService {
  Future<void> _writes = Future.value();
  bool _maintenance = false;
  bool _available = true;
  late Directory directory;

  Future<void> _write(Future<void> Function() action) {
    if (_maintenance || !_available) {
      return Future.error(StateError('Database maintenance is in progress.'));
    }
    final next = _writes.then((_) => action());
    _writes = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  Future<T> maintenance<T>(Future<T> Function() action) async {
    if (_maintenance || !_available) {
      throw StateError('Database is unavailable.');
    }
    _maintenance = true;
    try {
      await _writes;
      return await action();
    } finally {
      _maintenance = false;
    }
  }

  void markUnavailable() => _available = false;

  static const String _plansBoxName = 'plans_box';
  static const String _exercisesBoxName = 'exercises_box';
  static const String _workoutLogsBoxName = 'workout_logs_box';
  static const String _activeWorkoutBoxName = 'active_workout_box';
  static const String _workoutScheduleBoxName = 'workout_schedule_box';

  static const String _settingsBoxName = 'settings_box';

  late Box<Plan> _plansBox;
  late Box<Exercise> _exercisesBox;
  late Box<WorkoutLog> _workoutLogsBox;
  late Box<ActiveWorkout> _activeWorkoutBox;
  late Box<WorkoutSchedule> _workoutScheduleBox;
  late Box<dynamic> _settingsBox;

  Future<void> init({String? path}) async {
    directory = Directory(
      path ?? (await getApplicationDocumentsDirectory()).path,
    );
    await directory.create(recursive: true);
    await BackupFileTransaction(directory).recover();
    Hive.init(directory.path);
    _available = true;

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
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(WorkoutScheduleAdapter());
    }

    // Open Boxes
    _plansBox = await Hive.openBox<Plan>(_plansBoxName);
    _exercisesBox = await Hive.openBox<Exercise>(_exercisesBoxName);
    _workoutLogsBox = await Hive.openBox<WorkoutLog>(_workoutLogsBoxName);
    _activeWorkoutBox = await Hive.openBox<ActiveWorkout>(
      _activeWorkoutBoxName,
    );
    _workoutScheduleBox = await Hive.openBox<WorkoutSchedule>(
      _workoutScheduleBoxName,
    );
    _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);
  }

  // --- Plans ---
  List<Plan> getAllPlans() => _plansBox.values.toList();
  Plan? getPlan(String id) => _plansBox.get(id);
  Future<void> savePlan(Plan plan) =>
      _write(() => _plansBox.put(plan.id, plan));
  Future<void> deletePlan(String id) => _write(() => _plansBox.delete(id));

  // --- Exercises ---
  List<Exercise> getAllExercises() => _exercisesBox.values.toList();
  Exercise? getExercise(String id) => _exercisesBox.get(id);
  Future<void> saveExercise(Exercise exercise) =>
      _write(() => _exercisesBox.put(exercise.id, exercise));
  Future<void> deleteExercise(String id) =>
      _write(() => _exercisesBox.delete(id));

  // --- Workout Logs ---
  List<WorkoutLog> getAllWorkoutLogs() => _workoutLogsBox.values.toList();
  WorkoutLog? getWorkoutLog(String id) => _workoutLogsBox.get(id);
  Future<void> saveWorkoutLog(WorkoutLog log) =>
      _write(() => _workoutLogsBox.put(log.id, log));
  Future<void> deleteWorkoutLog(String id) =>
      _write(() => _workoutLogsBox.delete(id));

  // --- Active Workout Cache ---
  ActiveWorkout? getActiveWorkout() {
    if (_activeWorkoutBox.isEmpty) return null;
    return _activeWorkoutBox.get('current') ?? _activeWorkoutBox.getAt(0);
  }

  Future<void> saveActiveWorkout(ActiveWorkout workout) async {
    await _write(() => _activeWorkoutBox.put('current', workout));
  }

  Future<void> clearActiveWorkout() async {
    await _write(() => _activeWorkoutBox.clear());
  }

  // --- Settings ---
  int getRestTime() {
    return _settingsBox.get('rest_time', defaultValue: 90) as int;
  }

  Future<void> saveRestTime(int seconds) async {
    await _write(() => _settingsBox.put('rest_time', seconds));
  }

  // --- Profile & Appearance ---
  Future<void> saveProfile({
    String? name,
    int? age,
    String? gender,
    double? height,
    double? weight,
  }) {
    final values = <String, dynamic>{
      'user_name': name,
      'user_age': age,
      'user_height': height,
      'user_weight': weight,
    };
    if (gender != null) {
      values['user_gender'] = gender;
    }
    return _write(() => _settingsBox.putAll(values));
  }

  String? getUserName() => _settingsBox.get('user_name') as String?;
  Future<void> saveUserName(String name) async =>
      _write(() => _settingsBox.put('user_name', name));

  int? getUserAge() => _settingsBox.get('user_age') as int?;
  Future<void> saveUserAge(int age) async =>
      _write(() => _settingsBox.put('user_age', age));

  String? getUserGender() => _settingsBox.get('user_gender') as String?;
  Future<void> saveUserGender(String gender) async =>
      _write(() => _settingsBox.put('user_gender', gender));

  double? getUserHeight() => _settingsBox.get('user_height') as double?;
  Future<void> saveUserHeight(double height) async =>
      _write(() => _settingsBox.put('user_height', height));

  double? getUserWeight() => _settingsBox.get('user_weight') as double?;
  Future<void> saveUserWeight(double weight) async =>
      _write(() => _settingsBox.put('user_weight', weight));

  String getThemeMode() =>
      _settingsBox.get('theme_mode', defaultValue: 'system') as String;
  Future<void> saveThemeMode(String mode) async =>
      _write(() => _settingsBox.put('theme_mode', mode));

  // --- Workout Preferences ---
  bool getKeepScreenAwake() =>
      _settingsBox.get('keep_screen_awake', defaultValue: true) as bool;
  Future<void> saveKeepScreenAwake(bool keepAwake) async =>
      _write(() => _settingsBox.put('keep_screen_awake', keepAwake));

  bool getPlayTimerSound() =>
      _settingsBox.get('play_timer_sound', defaultValue: true) as bool;
  Future<void> savePlayTimerSound(bool playSound) async =>
      _write(() => _settingsBox.put('play_timer_sound', playSound));

  // --- Workout Schedule ---

  /// Returns null if no schedule has been configured yet.
  WorkoutSchedule? getWorkoutSchedule() {
    if (_workoutScheduleBox.isEmpty) return null;
    return _workoutScheduleBox.get('current') ?? _workoutScheduleBox.getAt(0);
  }

  Future<void> saveWorkoutSchedule(WorkoutSchedule schedule) async {
    await _write(() => _workoutScheduleBox.put('current', schedule));
  }

  Future<void> deleteWorkoutSchedule() async {
    await _write(() => _workoutScheduleBox.clear());
  }

  // --- Onboarding ---

  bool isOnboardingCompleted() =>
      _settingsBox.get('onboarding_completed', defaultValue: false) as bool;

  Future<void> setOnboardingCompleted() async =>
      _write(() => _settingsBox.put('onboarding_completed', true));

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
    _workoutScheduleBox = await Hive.openBox<WorkoutSchedule>(
      _workoutScheduleBoxName,
    );
    _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);
  }
}
