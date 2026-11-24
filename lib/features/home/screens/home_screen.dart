// lib/features/home/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/achievement_share_service.dart';
import '../../../shared/providers/app_providers.dart';
import '../../profile/widgets/family_profile_sheets.dart';
import '../widgets/achievement_share_sheet.dart';
import '../widgets/plant_widget.dart';
import '../widgets/progress_ring.dart';
import '../widgets/mini_history.dart';
import '../widgets/sweet_bottom_sheet.dart';
import '../widgets/reward_dialog.dart';
import '../widgets/sweet_warning_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapAnim;
  late Animation<double>   _scaleAnim;

  @override
  void initState() {
    super.initState();
    _tapAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _tapAnim, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _tapAnim.dispose();
    super.dispose();
  }

  Future<void> _onLogWater() async {
    // Haptic + animasi tombol
    HapticFeedback.mediumImpact();
    _tapAnim.forward().then((_) => _tapAnim.reverse());

    await ref.read(dailyWaterProvider.notifier).log();

    final water = ref.read(dailyWaterProvider);

    if (!mounted) return;

    if (water.leveledUpThisLog) {
      final profile = ref.read(profileProvider);
      final wantShare = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => RewardDialog.levelUp(
          phaseName: AppConstants.plantPhaseNames[
              (profile?.currentLevel ?? 1) - 1],
        ),
      );
      if (wantShare == true && mounted) {
        await showAchievementShareSheet(
          context,
          initialType: AchievementCardType.levelUp,
        );
      }
    }

    if (water.targetReachedThisLog && mounted) {
      final streakDays = ref.read(streakProvider)?.currentStreak ?? 1;
      final profileId  = ref.read(profileProvider)?.id ?? '';
      final wantShare  = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => RewardDialog.dailyComplete(streakDays: streakDays),
      );
      if (wantShare == true && mounted) {
        await showAchievementShareSheet(
          context,
          initialType: streakDays >= 2
              ? AchievementCardType.streak
              : AchievementCardType.dailyTarget,
          onShared: () {
            if (profileId.isNotEmpty) {
              ref.read(repoProvider).markCertificateShared(profileId);
            }
          },
        );
      }
    }

    if (water.leveledUpThisLog || water.targetReachedThisLog) {
      ref.read(dailyWaterProvider.notifier).clearFlags();
    }
  }

  Future<void> _onLogSweet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SweetBottomSheet(),
    );

    // Cek warning setelah sheet ditutup
    final sweet = ref.read(sweetProvider);
    if (sweet.pendingWarningLevel > 0 && mounted) {
      await showDialog(
        context: context,
        builder: (_) => SweetWarningDialog(
          level: sweet.pendingWarningLevel,
          name:  ref.read(profileProvider)?.name ?? '',
        ),
      );
      ref.read(sweetProvider.notifier).clearWarning();
    }
  }

  @override
  Widget build(BuildContext context) {
    final greeting = ref.watch(greetingProvider);
    final water    = ref.watch(dailyWaterProvider);
    final streak   = ref.watch(streakProvider);
    final mood     = ref.watch(plantMoodProvider);
    final profile  = ref.watch(profileProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App bar ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => showFamilySwitcherSheet(context),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    greeting,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 20,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                            Text(
                              'Level ${profile?.currentLevel ?? 1} · '
                              '${AppConstants.plantPhaseNames[(profile?.currentLevel ?? 1) - 1]}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Streak badge — tap untuk share achievement streak ala TikTok
                    if ((streak?.currentStreak ?? 0) > 0)
                      GestureDetector(
                        onTap: () => showAchievementShareSheet(
                          context,
                          initialType: AchievementCardType.streak,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.streakFire.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(children: [
                            const Text('🔥', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                            Text('${streak?.currentStreak}',
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w700,
                                color: AppColors.streakFire,
                              )),
                          ]),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Tanaman + progress ring ───────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ProgressRing(
                        progress: water.progress,
                        size:     220,
                      ),
                      PlantWidget(
                        level: profile?.currentLevel ?? 1,
                        mood:  mood,
                        size:  130,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Info ml ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Center(
                child: Text(
                  '${water.totalMl} / ${water.targetMl} ml',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 32),
                  child: Text(
                    water.remainingMl > 0
                        ? 'Sisa ${water.remainingMl} ml lagi~ 💪'
                        : 'Target hari ini tercapai! 🎉',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),

            // ── Tombol +1 Gelas ──────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: GestureDetector(
                    onTap: _onLogWater,
                    child: Container(
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end:   Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(36),
                        boxShadow: [
                          BoxShadow(
                            color:  AppColors.primary.withValues(alpha: 0.4),
                            blurRadius:   16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('💧', style: TextStyle(fontSize: 24)),
                          SizedBox(width: 10),
                          Text('+1 Gelas',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            )),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Tombol minuman manis ──────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 12, 32, 0),
                child: OutlinedButton.icon(
                  onPressed: _onLogSweet,
                  icon: const Text('🍵', style: TextStyle(fontSize: 16)),
                  label: const Text('Log Minuman Manis'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.sweetAmber,
                    side: const BorderSide(color: AppColors.sweetAmber),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            // ── Mini history ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: MiniHistory(
                  profileId: profile?.id ?? '',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}