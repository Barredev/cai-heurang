// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/utils/hive_init.dart';
import 'core/utils/notification_service.dart';
import 'data/repositories/app_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // Jalankan reset harian jika perlu
  final repo = AppRepository();
  await repo.checkAndResetDaily();

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