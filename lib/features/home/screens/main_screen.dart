// lib/features/home/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/notification_service.dart';
import '../../../shared/providers/app_providers.dart';
import 'home_screen.dart';
import '../../stats/screens/stats_screen.dart';
import '../../profile/screens/profile_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});
  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with WidgetsBindingObserver {
  int _tab = 0;

  static const _tabs = [
    HomeScreen(),
    StatsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Proses streak saat app dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(streakProvider.notifier).processOnOpen();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleAppResumed();
    }
  }

  Future<void> _handleAppResumed() async {
    final repo = ref.read(repoProvider);
    final resetResult = await repo.checkAndResetDaily();
    if (!mounted) return;

    if (resetResult.didReset &&
        resetResult.todayStreak?.shieldUsedToday == true) {
      final profile = repo.getActiveProfile();
      if (profile != null) {
        await NotificationService.showShieldUsed(
          resetResult.todayStreak!.shieldsAvailable,
          profile.name,
        );
      }
    }

    // Refresh seluruh state harian & berbasis waktu (greeting + plant mood)
    ref.read(profileProvider.notifier).reload();
    ref.read(streakProvider.notifier).reload();
    ref.read(dailyWaterProvider.notifier).reload();
    ref.read(sweetProvider.notifier).reload();
    ref.invalidate(greetingProvider);
    ref.invalidate(plantMoodProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _tabs),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: BottomNavigationBar(
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart_rounded),
              label: 'Statistik',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}