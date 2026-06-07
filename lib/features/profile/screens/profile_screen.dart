// lib/features/profile/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/app_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final streak  = ref.watch(streakProvider);

    if (profile == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Profil 🌱')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  AppConstants.plantPhaseNames[profile.currentLevel - 1]
                      .substring(0, 1),
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(profile.name,
              style: Theme.of(context).textTheme.headlineMedium),
            Text('Level ${profile.currentLevel} · '
              '${AppConstants.plantPhaseNames[profile.currentLevel - 1]}',
              style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),

            // Stats row
            Row(children: [
              _StatCard(
                label: 'Total XP',
                value: '${profile.totalXp}',
                emoji: '⭐',
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Streak',
                value: '${streak?.currentStreak ?? 0} hari',
                emoji: '🔥',
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Rekor',
                value: '${streak?.longestStreak ?? 0} hari',
                emoji: '🏆',
              ),
            ]),
            const SizedBox(height: 24),

            // Info profil
            _InfoTile(
              icon: Icons.water_drop_outlined,
              label: 'Target harian',
              value: '${profile.targetMl} ml',
            ),
            _InfoTile(
              icon: Icons.person_outline,
              label: 'Usia',
              value: '${profile.age} tahun',
            ),
            _InfoTile(
              icon: Icons.shield_outlined,
              label: 'Streak shield',
              value: '${streak?.shieldsAvailable ?? 0} tersisa',
            ),
            const SizedBox(height: 24),

            // Disclaimer
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                '⚠️ Target air berdasarkan panduan WHO & IOM. '
                'Konsultasikan dengan dokter jika kamu punya kondisi '
                'kesehatan tertentu.',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, emoji;
  const _StatCard({required this.label, required this.value, required this.emoji});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(
          fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 14,
        )),
        Text(label, style: const TextStyle(
          fontFamily: 'Nunito', fontSize: 11, color: AppColors.textHint,
        )),
      ]),
    ),
  );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String   label, value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Row(children: [
      Icon(icon, color: AppColors.primary, size: 20),
      const SizedBox(width: 12),
      Text(label, style: const TextStyle(fontFamily: 'Nunito', fontSize: 14)),
      const Spacer(),
      Text(value, style: const TextStyle(
        fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 14,
      )),
    ]),
  );
}