// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_schedule.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkoutScheduleAdapter extends TypeAdapter<WorkoutSchedule> {
  @override
  final int typeId = 6;

  @override
  WorkoutSchedule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutSchedule(
      workoutHour: fields[0] as int,
      workoutMinute: fields[1] as int,
      workoutDays: (fields[2] as List).cast<int>(),
      remindersEnabled: fields[3] as bool,
      notificationPermissionStatus: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutSchedule obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.workoutHour)
      ..writeByte(1)
      ..write(obj.workoutMinute)
      ..writeByte(2)
      ..write(obj.workoutDays)
      ..writeByte(3)
      ..write(obj.remindersEnabled)
      ..writeByte(4)
      ..write(obj.notificationPermissionStatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutScheduleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
