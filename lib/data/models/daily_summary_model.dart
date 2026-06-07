// lib/data/models/daily_summary_model.dart
import 'package:hive/hive.dart';

part 'daily_summary_model.g.dart';

@HiveType(typeId: 4)
class DailySummaryModel extends HiveObject {
  @HiveField(0) late String id;              // '{profileId}_{YYYY-MM-DD}'
  @HiveField(1) late String profileId;
  @HiveField(2) late String date;            // 'YYYY-MM-DD'
  @HiveField(3) late int    totalMl;
  @HiveField(4) late int    totalXpDay;
  @HiveField(5) late int    weeklyScore;
  @HiveField(6) late double sugarG;
  @HiveField(7) late bool   certificateShared;
  @HiveField(8) late String lastResetDate;

  DailySummaryModel({
    required this.id,
    required this.profileId,
    required this.date,
    this.totalMl          = 0,
    this.totalXpDay       = 0,
    this.weeklyScore      = 0,
    this.sugarG           = 0.0,
    this.certificateShared = false,
    required this.lastResetDate,
  });
}