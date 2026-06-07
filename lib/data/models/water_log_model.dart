// lib/data/models/water_log_model.dart
import 'package:hive/hive.dart';

part 'water_log_model.g.dart';

@HiveType(typeId: 1)
class WaterLogModel extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String profileId;
  @HiveField(2) late String timestamp;   // ISO 8601
  @HiveField(3) late int    glassCount;  // selalu 1
  @HiveField(4) late int    xpEarned;
  @HiveField(5) late String sessionType; // 'normal'|'golden_morning'|'golden_noon'|'golden_eve'|'recovery'

  WaterLogModel({
    required this.id,
    required this.profileId,
    required this.timestamp,
    this.glassCount = 1,
    required this.xpEarned,
    required this.sessionType,
  });
}