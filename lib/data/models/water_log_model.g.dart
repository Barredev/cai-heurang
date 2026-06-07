// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'water_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WaterLogModelAdapter extends TypeAdapter<WaterLogModel> {
  @override
  final int typeId = 1;

  @override
  WaterLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WaterLogModel(
      id: fields[0] as String,
      profileId: fields[1] as String,
      timestamp: fields[2] as String,
      glassCount: fields[3] as int,
      xpEarned: fields[4] as int,
      sessionType: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, WaterLogModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.profileId)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.glassCount)
      ..writeByte(4)
      ..write(obj.xpEarned)
      ..writeByte(5)
      ..write(obj.sessionType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaterLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
