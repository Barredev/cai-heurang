// lib/data/models/profile_model.dart
import 'package:hive/hive.dart';

part 'profile_model.g.dart';

@HiveType(typeId: 0)
class ProfileModel extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String name;
  @HiveField(2) late String gender;     // 'male' | 'female'
  @HiveField(3) late int    age;
  @HiveField(4) late String condition;  // 'none' | 'pregnant' | 'breastfeeding'
  @HiveField(5) late int    targetMl;
  @HiveField(6) late int    totalXp;
  @HiveField(7) late int    currentLevel;
  @HiveField(8) late String createdAt;

  ProfileModel({
    required this.id,
    required this.name,
    required this.gender,
    required this.age,
    required this.condition,
    required this.targetMl,
    this.totalXp = 0,
    this.currentLevel = 1,
    required this.createdAt,
  });
}