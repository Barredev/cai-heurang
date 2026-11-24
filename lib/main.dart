// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/utils/hive_init.dart';
import 'core/utils/notification_service.dart';
import 'data/repositories/app_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi format tanggal lokal Indonesia (untuk DateFormat(..., 'id'))
  await initializeDateFormatting('id');

  // Paksa orientasi portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Status bar transparan
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:       Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Init Hive
  await HiveInit.init();

  // Init Notifikasi
  await NotificationService.init();

  // Jalankan reset harian & sinkronisasi pengingat jika sudah onboarding
  final repo = AppRepository();
  final resetResult = await repo.checkAndResetDaily();
  final activeProfile = repo.getActiveProfile();
  if (resetResult.didReset &&
      resetResult.todayStreak?.shieldUsedToday == true &&
      activeProfile != null) {
    await NotificationService.showShieldUsed(
      resetResult.todayStreak!.shieldsAvailable,
      activeProfile.name,
    );
  }
  if (repo.isOnboarded && activeProfile != null && repo.remindersEnabled) {
    final phase = AppConstants.plantPhaseNames[
        (activeProfile.currentLevel - 1)
            .clamp(0, AppConstants.plantPhaseNames.length - 1)];
    await NotificationService.scheduleWaterReminders(
      profileName:    activeProfile.name,
      plantPhaseName: phase,
      intervalHours:  repo.reminderIntervalHours,
    );
  }

  runApp(
    const ProviderScope(child: CaiHeurangApp()),
  );
}

class CaiHeurangApp extends ConsumerWidget {
  const CaiHeurangApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo        = AppRepository();
    final initialRoute = repo.isOnboarded
        ? AppRouter.main
        : AppRouter.onboarding;

    return MaterialApp(
      title:         'CaiHeurang',
      debugShowCheckedModeBanner: false,
      theme:         AppTheme.theme,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute:  initialRoute,
    );
  }
}