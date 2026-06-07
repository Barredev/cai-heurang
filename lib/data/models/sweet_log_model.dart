// lib/data/models/sweet_log_model.dart
import 'package:hive/hive.dart';

part 'sweet_log_model.g.dart';

@HiveType(typeId: 2)
class SweetLogModel extends HiveObject {
  @HiveField(0) late String  id;
  @HiveField(1) late String  profileId;
  @HiveField(2) late String  timestamp;
  @HiveField(3) late String  drinkType;        // 'tea'|'coffee'|'packaged'|'juice'|'energy'|'condensed_milk'|'other'
  @HiveField(4)      String? drinkName;        // hanya jika drinkType == 'other'
  @HiveField(5)      double? estimatedSugarG;  // null jika drinkType == 'other'
  @HiveField(6) late int     warningLevel;     // 0 | 1 | 2

  SweetLogModel({
    required this.id,
    required this.profileId,
    required this.timestamp,
    required this.drinkType,
    this.drinkName,
    this.estimatedSugarG,
    this.warningLevel = 0,
  });
}