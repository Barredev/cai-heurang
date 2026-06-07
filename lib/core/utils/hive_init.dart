// lib/core/utils/hive_init.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/profile_model.dart';
import '../../data/models/water_log_model.dart';
import '../../data/models/sweet_log_model.dart';
import '../../data/models/streak_model.dart';
import '../../data/models/daily_summary_model.dart';
import '../constants/app_constants.dart';

class HiveInit {
  static Future<void> init() async {
    await Hive.initFlutter();

    // Daftarkan semua adapter (generated oleh build_runner)
    Hive.registerAdapter(ProfileModelAdapter());
    Hive.registerAdapter(WaterLogModelAdapter());
    Hive.registerAdapter(SweetLogModelAdapter());
    Hive.registerAdapter(StreakModelAdapter());
    Hive.registerAdapter(DailySummaryModelAdapter());

    // Buka semua box
    await Future.wait([
      Hive.openBox<ProfileModel>(AppConstants.boxProfiles),
      Hive.openBox<WaterLogModel>(AppConstants.boxWaterLogs),
      Hive.openBox<SweetLogModel>(AppConstants.boxSweetLogs),
      Hive.openBox<StreakModel>(AppConstants.boxStreaks),
      Hive.openBox<DailySummaryModel>(AppConstants.boxDailySummaries),
      Hive.openBox(AppConstants.boxSettings),
    ]);
  }
}