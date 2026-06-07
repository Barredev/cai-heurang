// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_summary_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailySummaryModelAdapter extends TypeAdapter<DailySummaryModel> {
  @override
  final int typeId = 4;

  @override
  DailySummaryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailySummaryModel(
      id: fields[0] as String,
      profileId: fields[1] as String,
      date: fields[2] as String,
      totalMl: fields[3] as int,
      totalXpDay: fields[4] as int,
      weeklyScore: fields[5] as int,
      sugarG: fields[6] as double,
      certificateShared: fields[7] as bool,
      lastResetDate: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DailySummaryModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.profileId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.totalMl)
      ..writeByte(4)
      ..write(obj.totalXpDay)
      ..writeByte(5)
      ..write(obj.weeklyScore)
      ..writeByte(6)
      ..write(obj.sugarG)
      ..writeByte(7)
      ..write(obj.certificateShared)
      ..writeByte(8)
      ..write(obj.lastResetDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailySummaryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
