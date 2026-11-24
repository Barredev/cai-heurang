// lib/features/home/widgets/achievement_share_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/achievement_share_service.dart';
import '../../../shared/providers/app_providers.dart';

/// Tampilkan bottom sheet preview & share kartu achievement ala TikTok Streak.
Future<void> showAchievementShareSheet(
  BuildContext context, {
  AchievementCardType initialType = AchievementCardType.streak,
  VoidCallback? onShared,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AchievementShareSheet(
      initialType: initialType,
      onShared: onShared,
    ),
  );
}

class AchievementShareSheet extends ConsumerStatefulWidget {
  final AchievementCardType initialType;
  final VoidCallback? onShared;

  const AchievementShareSheet({
    super.key,
    this.initialType = AchievementCardType.streak,
    this.onShared,
  });

  @override
  ConsumerState<AchievementShareSheet> createState() =>
      _AchievementShareSheetState();
}

class _AchievementShareSheetState extends ConsumerState<AchievementShareSheet> {
  final GlobalKey _cardKey = GlobalKey();
  late AchievementCardType _selectedType;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  Future<void> _onShare() async {
    if (_isSharing) return;
    final profile = ref.read(profileProvider);
    if (profile == null) return;

    setState(() => _isSharing = true);
    final water = ref.read(dailyWaterProvider);
    final streak = ref.read(streakProvider);

    final shareText = AchievementShareService.buildShareText(
      type: _selectedType,
      name: profile.name,
      streakDays: streak?.currentStreak ?? 0,
      totalMl: water.totalMl,
      targetMl: profile.targetMl,
      currentLevel: profile.currentLevel,
    );

    final shared = await AchievementShareService.shareFromWidget(
      _cardKey,
      shareText: shareText,
    );

    if (shared) {
      widget.onShared?.call();
    }

    if (mounted) {
      setState(() => _isSharing = false);
      if (shared) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final water = ref.watch(dailyWaterProvider);
    final streak = ref.watch(streakProvider);
    final repo = ref.read(repoProvider);

    if (profile == null) return const SizedBox.shrink();

    final weeklyScore = repo.calculateWeeklyScore(profile.id);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Bagikan Achievement 🔥',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Pilih kartu yang mau dipamerkan ke Story atau chat!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),

            // Switcher gaya kartu
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TypeChip(
                  label: '🔥 Streak',
                  selected: _selectedType == AchievementCardType.streak,
                  onTap: () =>
                      setState(() => _selectedType = AchievementCardType.streak),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: '💧 Target',
                  selected: _selectedType == AchievementCardType.dailyTarget,
                  onTap: () => setState(
                    () => _selectedType = AchievementCardType.dailyTarget,
                  ),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: '🌱 Evolusi',
                  selected: _selectedType == AchievementCardType.levelUp,
                  onTap: () => setState(
                    () => _selectedType = AchievementCardType.levelUp,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Preview kartu dalam RepaintBoundary
            FittedBox(
              fit: BoxFit.scaleDown,
              child: RepaintBoundary(
                key: _cardKey,
                child: AchievementShareService.buildCard(
                  type: _selectedType,
                  name: profile.name,
                  totalMl: water.totalMl,
                  targetMl: profile.targetMl,
                  currentLevel: profile.currentLevel,
                  totalXp: profile.totalXp,
                  streakDays: streak?.currentStreak ?? 0,
                  longestStreak: streak?.longestStreak ?? 0,
                  weeklyScore: weeklyScore,
                ),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSharing ? null : _onShare,
                icon: _isSharing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.ios_share_rounded, size: 20),
                label: Text(_isSharing ? 'Menyiapkan gambar...' : 'Bagikan Sekarang 🚀'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedType == AchievementCardType.streak
                      ? AppColors.streakFire
                      : AppColors.primary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.textPrimary : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.textPrimary : AppColors.primaryLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
