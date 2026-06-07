// lib/features/stats/screens/stats_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/app_providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile  = ref.watch(profileProvider);
    final repo     = ref.read(repoProvider);
    final summaries = profile != null
        ? repo.getWeeklySummaries(profile.id)
        : [];
    final weeklyScore = profile != null
        ? repo.calculateWeeklyScore(profile.id)
        : 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik 📊')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weekly score card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(children: [
                Text('Minggu ini', style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: Colors.white70)),
                const SizedBox(height: 4),
                Text('$weeklyScore/7 hari',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white, fontSize: 36,
                  )),
                Text(AppConstants.weeklyScoreLabel(weeklyScore),
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white70,
                    fontSize: 14,
                  )),
              ]),
            ),
            const SizedBox(height: 24),

            // Level progress
            if (profile != null) ...[
              Text('Level ${profile.currentLevel} — '
                '${AppConstants.plantPhaseNames[profile.currentLevel - 1]}',
                style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: AppConstants.levelProgress(
                      profile.totalXp, profile.currentLevel),
                  minHeight: 12,
                  backgroundColor: AppColors.primaryLight.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: 4),
              Text('${profile.totalXp} XP · '
                '${AppConstants.xpToNextLevel(profile.totalXp, profile.currentLevel)} XP lagi ke level berikut',
                style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
            ],

            // 7 hari terakhir
            Text('7 Hari Terakhir',
              style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (summaries.isEmpty)
              const Center(child: Text('Belum ada data minggu ini.'))
            else
              ...summaries.map((s) {
                final dt   = DateTime.parse(s.date);
                final label = DateFormat('EEE, d MMM', 'id').format(dt);
                final pct  = profile != null && profile.targetMl > 0
                    ? (s.totalMl / profile.targetMl).clamp(0.0, 1.0)
                    : 0.0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(label, style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        Text('${s.totalMl} ml',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w700,
                            color: pct >= 1.0 ? AppColors.success : AppColors.textSecondary,
                          )),
                      ]),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 6,
                          backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation(
                            pct >= 1.0 ? AppColors.success : AppColors.primary,
                          ),
                        ),
                      ),
                      if (s.sugarG > 0) ...[
                        const SizedBox(height: 4),
                        Text('🍵 Gula hari ini: ~${s.sugarG.toInt()}g',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            color: AppColors.sweetAmber,
                          )),
                      ],
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}