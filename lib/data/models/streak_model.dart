// lib/data/models/streak_model.dart
import 'package:hive/hive.dart';

part 'streak_model.g.dart';

@HiveType(typeId: 3)
class StreakModel extends HiveObject {
  @HiveField(0) late String id;              // '{profileId}_{YYYY-MM-DD}'
  @HiveField(1) late String profileId;
  @HiveField(2) late String date;            // 'YYYY-MM-DD'
  @HiveField(3) late bool   targetReached;
  @HiveField(4) late int    shieldsAvailable;
  @HiveField(5) late bool   shieldUsedToday;
  @HiveField(6) late int    currentStreak;
  @HiveField(7) late int    longestStreak;

  StreakModel({
    required this.id,
    required this.profileId,
    required this.date,
    this.targetReached    = false,
    this.shieldsAvailable = 0,
    this.shieldUsedToday  = false,
    this.currentStreak    = 0,
    this.longestStreak    = 0,
  });
}