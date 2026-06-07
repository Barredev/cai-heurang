// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'streak_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StreakModelAdapter extends TypeAdapter<StreakModel> {
  @override
  final int typeId = 3;

  @override
  StreakModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StreakModel(
      id: fields[0] as String,
      profileId: fields[1] as String,
      date: fields[2] as String,
      targetReached: fields[3] as bool,
      shieldsAvailable: fields[4] as int,
      shieldUsedToday: fields[5] as bool,
      currentStreak: fields[6] as int,
      longestStreak: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, StreakModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.profileId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.targetReached)
      ..writeByte(4)
      ..write(obj.shieldsAvailable)
      ..writeByte(5)
      ..write(obj.shieldUsedToday)
      ..writeByte(6)
      ..write(obj.currentStreak)
      ..writeByte(7)
      ..write(obj.longestStreak);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreakModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
