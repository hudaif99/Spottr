// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SetLogAdapter extends TypeAdapter<SetLog> {
  @override
  final int typeId = 0;

  @override
  SetLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SetLog(
      id: fields[0] as String,
      reps: fields[1] as int,
      weight: fields[2] as double,
      isCompleted: fields[3] as bool,
      isWarmup: fields[4] as bool,
      isDropSet: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SetLog obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.reps)
      ..writeByte(2)
      ..write(obj.weight)
      ..writeByte(3)
      ..write(obj.isCompleted)
      ..writeByte(4)
      ..write(obj.isWarmup)
      ..writeByte(5)
      ..write(obj.isDropSet);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
