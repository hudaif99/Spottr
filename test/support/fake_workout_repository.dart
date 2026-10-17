import 'dart:async';
import 'package:spottr/domain/models/active_workout.dart';
import 'package:spottr/domain/models/plan.dart';
import 'package:spottr/domain/models/workout_log.dart';
import 'package:spottr/domain/models/workout_schedule.dart';
import 'package:spottr/domain/models/exercise.dart';
import 'package:spottr/domain/repositories/workout_repository.dart';

class FakeWorkoutRepository implements WorkoutRepository {
  ActiveWorkout? active;
  final logs = <WorkoutLog>[];
  final plans = <Plan>[];
  final exercises = <Exercise>[];
  bool failSave = false;
  bool failClear = false;
  bool failHistory = false;
  int logWrites = 0;
  int concurrentWrites = 0;
  int maxConcurrentWrites = 0;
  Completer<void>? saveGate;
  Completer<void>? planSaveGate;
  int defaultRestTime = 90;
  @override
  Future<List<Exercise>> getExercises() async => [...exercises];
  @override
  int getDefaultRestTime() => defaultRestTime;

  @override
  ActiveWorkout? getActiveWorkout() => active;
  @override
  Future<List<WorkoutLog>> getWorkoutLogs() async => [...logs];
  @override
  Future<void> saveActiveWorkout(ActiveWorkout workout) async {
    concurrentWrites++;
    if (concurrentWrites > maxConcurrentWrites) {
      maxConcurrentWrites = concurrentWrites;
    }
    try {
      await saveGate?.future;
      if (failSave) throw StateError('Storage unavailable');
      active = workout;
    } finally {
      concurrentWrites--;
    }
  }

  @override
  Future<void> clearActiveWorkout() async {
    if (failClear) throw StateError('Storage unavailable');
    active = null;
  }

  @override
  Future<void> saveWorkoutLog(WorkoutLog log) async {
    if (failHistory) throw StateError('Storage unavailable');
    logWrites++;
    logs.removeWhere((old) => old.id == log.id);
    logs.add(log);
  }

  @override
  Future<WorkoutSchedule?> getScheduleForToday() async => null;
  @override
  Future<List<Plan>> getPlans() async => [...plans];
  @override
  Future<Plan?> getActivePlan() async =>
      plans.where((plan) => plan.isActive).firstOrNull;
  @override
  Future<void> savePlan(Plan plan) async {
    await planSaveGate?.future;
    if (failSave) throw StateError('Storage unavailable');
    plans.removeWhere((old) => old.id == plan.id);
    plans.add(plan);
  }

  @override
  Future<void> setActivePlan(String id) async {
    for (var index = 0; index < plans.length; index++) {
      plans[index] = plans[index].copyWith(isActive: plans[index].id == id);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
