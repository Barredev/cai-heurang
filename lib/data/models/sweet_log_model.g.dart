// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sweet_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SweetLogModelAdapter extends TypeAdapter<SweetLogModel> {
  @override
  final int typeId = 2;

  @override
  SweetLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SweetLogModel(
      id: fields[0] as String,
      profileId: fields[1] as String,
      timestamp: fields[2] as String,
      drinkType: fields[3] as String,
      drinkName: fields[4] as String?,
      estimatedSugarG: fields[5] as double?,
      warningLevel: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SweetLogModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.profileId)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.drinkType)
      ..writeByte(4)
      ..write(obj.drinkName)
      ..writeByte(5)
      ..write(obj.estimatedSugarG)
      ..writeByte(6)
      ..write(obj.warningLevel);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SweetLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
