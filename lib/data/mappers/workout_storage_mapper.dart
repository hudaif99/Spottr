import '../../domain/models/workout_models.dart' as domain;
import '../models/active_workout.dart';
import '../models/exercise.dart';
import '../models/plan.dart';
import '../models/set_log.dart';
import '../models/workout_day.dart';
import '../models/workout_log.dart';
import '../models/workout_schedule.dart';

extension StoredExerciseMapping on Exercise {
  domain.Exercise toDomain() => domain.Exercise(
    id: id,
    name: name,
    targetSets: targetSets,
    targetReps: targetReps,
    targetWeight: targetWeight,
    restDurationSeconds: restDurationSeconds,
    imageUrl: imageUrl,
    note: note,
    useDefaultRest: useDefaultRest,
  );
}

extension ExerciseStorageMapping on domain.Exercise {
  Exercise toStorage() => Exercise(
    id: id,
    name: name,
    targetSets: targetSets,
    targetReps: targetReps,
    targetWeight: targetWeight,
    restDurationSeconds: restDurationSeconds,
    imageUrl: imageUrl,
    note: note,
    useDefaultRest: useDefaultRest,
  );
}

extension StoredSetMapping on SetLog {
  domain.SetLog toDomain() => domain.SetLog(
    id: id,
    reps: reps,
    weight: weight,
    isCompleted: isCompleted,
    isWarmup: isWarmup,
    isDropSet: isDropSet,
  );
}

extension SetStorageMapping on domain.SetLog {
  SetLog toStorage() => SetLog(
    id: id,
    reps: reps,
    weight: weight,
    isCompleted: isCompleted,
    isWarmup: isWarmup,
    isDropSet: isDropSet,
  );
}

extension StoredDayMapping on WorkoutDay {
  domain.WorkoutDay toDomain() => domain.WorkoutDay(
    id: id,
    name: name,
    notes: notes,
    exercises: exercises.map((exercise) => exercise.toDomain()).toList(),
  );
}

extension DayStorageMapping on domain.WorkoutDay {
  WorkoutDay toStorage() => WorkoutDay(
    id: id,
    name: name,
    notes: notes,
    exercises: exercises.map((exercise) => exercise.toStorage()).toList(),
  );
}

extension StoredPlanMapping on Plan {
  domain.Plan toDomain() => domain.Plan(
    id: id,
    name: name,
    isActive: isActive,
    createdAt: createdAt,
    days: days.map((day) => day.toDomain()).toList(),
  );
}

extension PlanStorageMapping on domain.Plan {
  Plan toStorage() => Plan(
    id: id,
    name: name,
    isActive: isActive,
    createdAt: createdAt,
    days: days.map((day) => day.toStorage()).toList(),
  );
}

Map<String, List<domain.SetLog>> _domainSets(Map<String, List<SetLog>> logs) =>
    {
      for (final entry in logs.entries)
        entry.key: entry.value.map((set) => set.toDomain()).toList(),
    };

Map<String, List<SetLog>> _storedSets(Map<String, List<domain.SetLog>> logs) =>
    {
      for (final entry in logs.entries)
        entry.key: entry.value.map((set) => set.toStorage()).toList(),
    };

extension StoredLogMapping on WorkoutLog {
  domain.WorkoutLog toDomain() => domain.WorkoutLog(
    id: id,
    planId: planId,
    dayId: dayId,
    dayName: dayName,
    startTime: startTime,
    endTime: endTime,
    exerciseLogs: _domainSets(exerciseLogs),
    exerciseNames: exerciseNames,
  );
}

extension LogStorageMapping on domain.WorkoutLog {
  WorkoutLog toStorage() => WorkoutLog(
    id: id,
    planId: planId,
    dayId: dayId,
    dayName: dayName,
    startTime: startTime,
    endTime: endTime,
    exerciseLogs: _storedSets(exerciseLogs),
    exerciseNames: Map.of(exerciseNames),
  );
}

extension StoredActiveWorkoutMapping on ActiveWorkout {
  domain.ActiveWorkout toDomain() => domain.ActiveWorkout(
    workoutLogId: workoutLogId,
    planId: planId,
    day: day.toDomain(),
    startTime: startTime,
    restUntil: restUntil,
    exerciseLogs: _domainSets(exerciseLogs),
    previousExerciseLogs: _domainSets(previousExerciseLogs),
  );
}

extension ActiveWorkoutStorageMapping on domain.ActiveWorkout {
  ActiveWorkout toStorage() => ActiveWorkout(
    workoutLogId: workoutLogId,
    planId: planId,
    day: day.toStorage(),
    startTime: startTime,
    restUntil: restUntil,
    exerciseLogs: _storedSets(exerciseLogs),
    previousExerciseLogs: _storedSets(previousExerciseLogs),
  );
}

extension StoredScheduleMapping on WorkoutSchedule {
  domain.WorkoutSchedule toDomain() => domain.WorkoutSchedule(
    workoutHour: workoutHour,
    workoutMinute: workoutMinute,
    workoutDays: workoutDays,
    remindersEnabled: remindersEnabled,
    notificationPermissionStatus: notificationPermissionStatus,
  );
}

extension ScheduleStorageMapping on domain.WorkoutSchedule {
  WorkoutSchedule toStorage() => WorkoutSchedule(
    workoutHour: workoutHour,
    workoutMinute: workoutMinute,
    workoutDays: List.of(workoutDays),
    remindersEnabled: remindersEnabled,
    notificationPermissionStatus: notificationPermissionStatus,
  );
}
