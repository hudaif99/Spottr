import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:spottr/data/datasources/local_database_service.dart';
import 'package:spottr/data/models/active_workout.dart';
import 'package:spottr/data/models/exercise.dart';
import 'package:spottr/data/models/plan.dart';
import 'package:spottr/data/models/set_log.dart';
import 'package:spottr/data/models/workout_day.dart';
import 'package:spottr/data/models/workout_log.dart';
import 'package:spottr/data/repositories/workout_repository_impl.dart';

class _ClassicSetAdapter extends SetLogAdapter {
  @override
  void write(BinaryWriter writer, SetLog set) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(set.id)
      ..writeByte(1)
      ..write(set.reps)
      ..writeByte(2)
      ..write(set.weight)
      ..writeByte(3)
      ..write(set.isCompleted)
      ..writeByte(4)
      ..write(set.isWarmup)
      ..writeByte(5)
      ..write(set.isDropSet);
  }
}

class _ClassicExerciseAdapter extends ExerciseAdapter {
  @override
  void write(BinaryWriter writer, Exercise exercise) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(exercise.id)
      ..writeByte(1)
      ..write(exercise.name)
      ..writeByte(2)
      ..write(exercise.targetSets)
      ..writeByte(3)
      ..write(exercise.targetReps)
      ..writeByte(4)
      ..write(exercise.targetWeight)
      ..writeByte(5)
      ..write(exercise.restDurationSeconds)
      ..writeByte(6)
      ..write(exercise.imageUrl);
  }
}

class _ClassicLogAdapter extends WorkoutLogAdapter {
  @override
  void write(BinaryWriter writer, WorkoutLog log) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(log.id)
      ..writeByte(1)
      ..write(log.planId)
      ..writeByte(2)
      ..write(log.dayId)
      ..writeByte(3)
      ..write(log.dayName)
      ..writeByte(4)
      ..write(log.startTime)
      ..writeByte(5)
      ..write(log.endTime)
      ..writeByte(6)
      ..write(log.exerciseLogs);
  }
}

class _ClassicActiveAdapter extends ActiveWorkoutAdapter {
  @override
  void write(BinaryWriter writer, ActiveWorkout workout) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(workout.workoutLogId)
      ..writeByte(1)
      ..write(workout.planId)
      ..writeByte(2)
      ..write(workout.day)
      ..writeByte(3)
      ..write(workout.startTime)
      ..writeByte(4)
      ..write(workout.exerciseLogs)
      ..writeByte(5)
      ..write(workout.previousExerciseLogs);
  }
}

class _BeforeIdentityExerciseAdapter extends ExerciseAdapter {
  @override
  void write(BinaryWriter writer, Exercise value) {
    final fields = [
      value.id,
      value.name,
      value.targetSets,
      value.targetReps,
      value.targetWeight,
      value.restDurationSeconds,
      value.imageUrl,
      value.note,
      value.useDefaultRest,
    ];
    writer.writeByte(fields.length);
    for (var index = 0; index < fields.length; index++) {
      writer
        ..writeByte(index)
        ..write(fields[index]);
    }
  }
}

class _BeforeIdentityLogAdapter extends WorkoutLogAdapter {
  @override
  void write(BinaryWriter writer, WorkoutLog value) {
    final fields = [
      value.id,
      value.planId,
      value.dayId,
      value.dayName,
      value.startTime,
      value.endTime,
      value.exerciseLogs,
      value.exerciseNames,
    ];
    writer.writeByte(fields.length);
    for (var index = 0; index < fields.length; index++) {
      writer
        ..writeByte(index)
        ..write(fields[index]);
    }
  }
}

void main() {
  test(
    'classic plans, history, and numeric-key session survive new fields and keyed saves',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'spottr_storage_',
      );
      addTearDown(() async {
        await Hive.close();
        Hive.resetAdapters();
        await directory.delete(recursive: true);
      });
      Hive.init(directory.path);
      Hive.registerAdapter(_ClassicSetAdapter());
      Hive.registerAdapter(_ClassicExerciseAdapter());
      Hive.registerAdapter(WorkoutDayAdapter());
      Hive.registerAdapter(PlanAdapter());
      Hive.registerAdapter(_ClassicLogAdapter());
      Hive.registerAdapter(_ClassicActiveAdapter());
      final exercise = Exercise(
        id: 'exercise',
        name: 'Cable kickback',
        targetWeight: 12.5,
      );
      final day = WorkoutDay(
        id: 'day',
        name: 'Lower body',
        exercises: [exercise],
      );
      final sets = {
        'exercise': [
          SetLog(id: 'set', reps: 10, weight: 12.5, isCompleted: true),
        ],
      };
      final date = DateTime(2026, 10, 10);
      final plans = await Hive.openBox<Plan>('plans_box');
      await plans.put('plan', Plan(id: 'plan', name: 'Classic', days: [day]));
      final logs = await Hive.openBox<WorkoutLog>('workout_logs_box');
      await logs.put(
        'old',
        WorkoutLog(
          id: 'old',
          planId: 'plan',
          dayId: day.id,
          dayName: day.name,
          startTime: date,
          endTime: date.add(const Duration(minutes: 30)),
          exerciseLogs: sets,
        ),
      );
      final active = await Hive.openBox<ActiveWorkout>('active_workout_box');
      await active.add(
        ActiveWorkout(
          workoutLogId: 'current',
          planId: 'plan',
          day: day,
          startTime: date,
          exerciseLogs: sets,
        ),
      );
      await Hive.close();
      Hive.registerAdapter<SetLog>(SetLogAdapter(), override: true);
      Hive.registerAdapter<Exercise>(ExerciseAdapter(), override: true);
      Hive.registerAdapter<WorkoutLog>(WorkoutLogAdapter(), override: true);
      Hive.registerAdapter<ActiveWorkout>(
        ActiveWorkoutAdapter(),
        override: true,
      );
      final database = LocalDatabaseService();
      await database.init(path: directory.path);
      expect(
        database.getAllPlans().single.days.single.exercises.single.note,
        '',
      );
      expect(database.getAllWorkoutLogs().single.exerciseNames, isEmpty);
      expect(database.getAllWorkoutLogs().single.exerciseIdentities, isEmpty);
      expect(
        database.getAllPlans().single.days.single.exercises.single.identityId,
        isNull,
      );
      expect(database.getAllWorkoutLogs().single.totalVolume, 125);
      expect(database.getActiveWorkout()!.restUntil, isNull);
      final repository = WorkoutRepositoryImpl(database);
      final mappedPlan = (await repository.getPlans()).single;
      final mappedLog = (await repository.getWorkoutLogs()).single;
      final mappedActive = repository.getActiveWorkout()!;
      expect(mappedPlan.days.single.exercises.single.note, '');
      expect(mappedPlan.days.single.exercises.single.useDefaultRest, isTrue);
      expect(
        mappedPlan.days.single.exercises.single.identityId,
        'catalog:cable-kickback',
      );
      expect(mappedLog.exerciseNames, isEmpty);
      expect(mappedLog.exerciseIdentities, isEmpty);
      expect(mappedLog.totalVolume, 125);
      expect(mappedActive.exerciseLogs['exercise']!.single.id, 'set');
      expect(
        mappedActive.exerciseLogs['exercise']!.single.canInheritWeight,
        isFalse,
      );
      expect(
        mappedLog.exerciseLogs['exercise']!.single.canInheritWeight,
        isFalse,
      );
      await repository.savePlan(mappedPlan);
      await repository.saveWorkoutLog(mappedLog);
      await repository.saveActiveWorkout(mappedActive);
      await Hive.close();
      await database.init(path: directory.path);
      expect(database.getAllPlans().single.id, 'plan');
      expect(database.getAllWorkoutLogs().single.totalVolume, 125);
      expect(repository.getActiveWorkout()!.workoutLogId, 'current');
      final restUntil = date.add(const Duration(seconds: 90));
      await database.saveActiveWorkout(
        ActiveWorkout(
          workoutLogId: 'current',
          planId: 'plan',
          day: day.copyWith(
            exercises: [exercise.copyWith(note: 'Pulley at knee level')],
          ),
          startTime: date,
          exerciseLogs: sets,
          restUntil: restUntil,
        ),
      );
      await Hive.close();
      await database.init(path: directory.path);
      expect(
        database.getActiveWorkout()!.day.exercises.single.note,
        'Pulley at knee level',
      );
      expect(database.getActiveWorkout()!.restUntil, restUntil);
      await database.clearActiveWorkout();
      expect(database.getActiveWorkout(), isNull);
      expect(database.getAllWorkoutLogs().length, 1);
      await database.saveUserGender('unspecified');
      await database.saveProfile(
        name: 'Alex',
        age: 30,
        height: 180,
        weight: 80,
      );
      await Hive.close();
      await database.init(path: directory.path);
      expect(database.getUserName(), 'Alex');
      expect(database.getUserHeight(), 180);
      await database.saveProfile();
      await Hive.close();
      await database.init(path: directory.path);
      expect(database.getUserName(), isNull);
      expect(database.getUserAge(), isNull);
      expect(database.getUserHeight(), isNull);
      expect(database.getUserWeight(), isNull);
      expect(database.getUserGender(), 'unspecified');
      await Hive.close();
      Hive.registerAdapter<Exercise>(
        _BeforeIdentityExerciseAdapter(),
        override: true,
      );
      Hive.registerAdapter<WorkoutLog>(
        _BeforeIdentityLogAdapter(),
        override: true,
      );
      await database.init(path: directory.path);
      await database.savePlan(
        Plan(
          id: 'plan',
          name: 'Before identity',
          days: [
            day.copyWith(
              exercises: [
                exercise.copyWith(
                  note: 'Keep this setup cue',
                  useDefaultRest: false,
                  restDurationSeconds: 135,
                ),
              ],
            ),
          ],
        ),
      );
      await database.saveWorkoutLog(
        WorkoutLog(
          id: 'old',
          planId: 'plan',
          dayId: day.id,
          dayName: day.name,
          startTime: date,
          exerciseLogs: sets,
          exerciseNames: {'exercise': 'Historical cable name'},
        ),
      );
      await Hive.close();
      Hive.registerAdapter<Exercise>(ExerciseAdapter(), override: true);
      Hive.registerAdapter<WorkoutLog>(WorkoutLogAdapter(), override: true);
      await database.init(path: directory.path);
      final beforeIdentity =
          (await repository.getPlans()).single.days.single.exercises.single;
      expect(beforeIdentity.note, 'Keep this setup cue');
      expect(beforeIdentity.useDefaultRest, isFalse);
      expect(beforeIdentity.restDurationSeconds, 135);
      expect(beforeIdentity.identityId, 'catalog:cable-kickback');
      final oldLog = (await repository.getWorkoutLogs()).single;
      expect(oldLog.exerciseNames['exercise'], 'Historical cable name');
      expect(oldLog.exerciseIdentities, isEmpty);
      expect(oldLog.totalVolume, 125);
    },
  );
}
