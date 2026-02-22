// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_workout.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActiveWorkoutAdapter extends TypeAdapter<ActiveWorkout> {
  @override
  final int typeId = 5;

  @override
  ActiveWorkout read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActiveWorkout(
      workoutLogId: fields[0] as String,
      planId: fields[1] as String,
      day: fields[2] as WorkoutDay,
      startTime: fields[3] as DateTime,
      exerciseLogs: (fields[4] as Map).map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as List).cast<SetLog>())),
      previousExerciseLogs: (fields[5] as Map).map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as List).cast<SetLog>())),
    );
  }

  @override
  void write(BinaryWriter writer, ActiveWorkout obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.workoutLogId)
      ..writeByte(1)
      ..write(obj.planId)
      ..writeByte(2)
      ..write(obj.day)
      ..writeByte(3)
      ..write(obj.startTime)
      ..writeByte(4)
      ..write(obj.exerciseLogs)
      ..writeByte(5)
      ..write(obj.previousExerciseLogs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveWorkoutAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
