// lib/core/utils/achievement_share_service.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/app_constants.dart';

enum AchievementCardType { streak, dailyTarget, levelUp }

class AchievementShareService {
  /// Tangkap widget achievement dari [key] (RepaintBoundary) sebagai PNG 3x
  /// lalu buka native share sheet (WhatsApp, TikTok, IG Story, dll).
  static Future<bool> shareFromWidget(
    GlobalKey key, {
    required String shareText,
  }) async {
    try {
      final context = key.currentContext;
      if (context == null) return false;

      final boundary =
          context.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return false;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return false;

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/caiheurang_achievement_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareText,
      );
      return true;
    } catch (e) {
      debugPrint('Achievement share error: $e');
      return false;
    }
  }

  static String buildShareText({
    required AchievementCardType type,
    required String name,
    required int streakDays,
    required int totalMl,
    required int targetMl,
    required int currentLevel,
  }) {
    final phaseName = AppConstants.plantPhaseNames[
        (currentLevel - 1).clamp(0, AppConstants.plantPhaseNames.length - 1)];
    return switch (type) {
      AchievementCardType.streak =>
        '🔥 $streakDays hari streak minum air bareng CaiHeurang! '
            'Tanaman $name sekarang Level $currentLevel ($phaseName). '
            'Yuk jaga hidrasi! 💧 #CaiHeurang #StreakAir',
      AchievementCardType.dailyTarget =>
        '💧 Target $targetMl ml hari ini tercapai ($totalMl ml)! '
            'Streak $streakDays hari jalan terus 🔥 #CaiHeurang',
      AchievementCardType.levelUp =>
        '🌱✨ Tanaman $name baru aja berevolusi jadi Level $currentLevel · $phaseName! '
            'Minum air tiap hari makin seru 💧 #CaiHeurang',
    };
  }

  static String? _milestoneBadge(int streakDays) {
    int? matched;
    for (final days in AppConstants.streakMilestoneName.keys) {
      if (streakDays >= days) matched = days;
    }
    return matched != null ? AppConstants.streakMilestoneName[matched] : null;
  }

  /// Kartu achievement bergaya TikTok Streak / Story siap share.
  static Widget buildCard({
    required AchievementCardType type,
    required String name,
    required int totalMl,
    required int targetMl,
    required int currentLevel,
    required int totalXp,
    required int streakDays,
    required int longestStreak,
    required int weeklyScore,
    DateTime? date,
  }) {
    final dt = date ?? DateTime.now();
    final safeLevel =
        currentLevel.clamp(1, AppConstants.plantPhaseNames.length);
    final phaseName = AppConstants.plantPhaseNames[safeLevel - 1];
    final plantEmoji = AppConstants.plantEmoji(safeLevel);
    final pct = targetMl > 0 ? ((totalMl / targetMl) * 100).round().clamp(0, 999) : 0;
    final milestone = _milestoneBadge(streakDays);

    String dateLabel;
    try {
      dateLabel = DateFormat('d MMM yyyy', 'id').format(dt);
    } catch (_) {
      dateLabel = '${dt.day}/${dt.month}/${dt.year}';
    }

    final (List<Color> bgColors, Color glowColor, String tagLabel) = switch (type) {
      AchievementCardType.streak => (
        const [Color(0xFF191326), Color(0xFF3E182A), Color(0xFFD94A2A)],
        const Color(0xFFFF7A2F),
        '🔥 STREAK ACHIEVEMENT',
      ),
      AchievementCardType.dailyTarget => (
        const [Color(0xFF0E2930), Color(0xFF1B5F61), Color(0xFF4FB3A6)],
        const Color(0xFF68E1C8),
        '💧 DAILY TARGET CLEAR',
      ),
      AchievementCardType.levelUp => (
        const [Color(0xFF1A1635), Color(0xFF3B2A72), Color(0xFF569D95)],
        const Color(0xFFB8A9FF),
        '✨ PLANT EVOLUTION',
      ),
    };

    return Container(
      width: 328,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            // Dekorasi aura atas-kanan
            Positioned(
              top: -48,
              right: -36,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      glowColor.withValues(alpha: 0.42),
                      glowColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Dekorasi aura bawah-kiri
            Positioned(
              bottom: -56,
              left: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.16),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header pill
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tagLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateLabel,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Hero section sesuai tipe achievement
                  _buildHero(
                    type: type,
                    glowColor: glowColor,
                    streakDays: streakDays,
                    longestStreak: longestStreak,
                    totalMl: totalMl,
                    targetMl: targetMl,
                    pct: pct,
                    safeLevel: safeLevel,
                    phaseName: phaseName,
                    plantEmoji: plantEmoji,
                    milestone: milestone,
                  ),

                  const SizedBox(height: 22),

                  // Glassmorphic stats strip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        _MiniMetric(
                          emoji: '💧',
                          value: '$totalMl ml',
                          label: 'hari ini',
                        ),
                        _MetricDivider(),
                        _MiniMetric(
                          emoji: '🔥',
                          value: '$streakDays hr',
                          label: 'streak',
                        ),
                        _MetricDivider(),
                        _MiniMetric(
                          emoji: '⭐',
                          value: '$weeklyScore/7',
                          label: 'minggu ini',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Footer user + branding
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            plantEmoji,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Lv.$safeLevel $phaseName · $totalXp XP',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        '💧 CaiHeurang',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildHero({
    required AchievementCardType type,
    required Color glowColor,
    required int streakDays,
    required int longestStreak,
    required int totalMl,
    required int targetMl,
    required int pct,
    required int safeLevel,
    required String phaseName,
    required String plantEmoji,
    required String? milestone,
  }) {
    switch (type) {
      case AchievementCardType.streak:
        return Column(
          children: [
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: glowColor.withValues(alpha: 0.22),
                border: Border.all(
                  color: glowColor.withValues(alpha: 0.75),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.5),
                    blurRadius: 26,
                  ),
                ],
              ),
              child: const Center(
                child: Text('🔥', style: TextStyle(fontSize: 56)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$streakDays',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 64,
                height: 0.95,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'HARI STREAK HIDRASI!',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Color(0xFFFFD4A0),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                milestone ?? 'Rekor terbaik: $longestStreak hari 🏆',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );

      case AchievementCardType.dailyTarget:
        return Column(
          children: [
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: glowColor.withValues(alpha: 0.2),
                border: Border.all(
                  color: glowColor.withValues(alpha: 0.75),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.45),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: const Center(
                child: Text('💧', style: TextStyle(fontSize: 54)),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '$pct%',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 58,
                height: 0.95,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              totalMl >= targetMl
                  ? 'TARGET HARIAN TERCAPAI! 🎉'
                  : 'PROGRES HIDRASI HARI INI',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: Color(0xFFC8F7EE),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$totalMl / $targetMl ml terhidrasi',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );

      case AchievementCardType.levelUp:
        return Column(
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: glowColor.withValues(alpha: 0.22),
                border: Border.all(
                  color: glowColor.withValues(alpha: 0.8),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.5),
                    blurRadius: 26,
                  ),
                ],
              ),
              child: Center(
                child: Text(plantEmoji, style: const TextStyle(fontSize: 58)),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              phaseName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 30,
                height: 1.05,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'LEVEL $safeLevel UNLOCKED ✨',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: Color(0xFFDAD3FF),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Tumbuh subur berkat rutin minum air!',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
    }
  }
}

class _MiniMetric extends StatelessWidget {
  final String emoji, value, label;
  const _MiniMetric({
    required this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.68),
              ),
            ),
          ],
        ),
      );
}

class _MetricDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 30,
        color: Colors.white.withValues(alpha: 0.14),
      );
}
