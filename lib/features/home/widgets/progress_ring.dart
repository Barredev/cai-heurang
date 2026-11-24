// lib/features/home/widgets/progress_ring.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ProgressRing extends StatelessWidget {
  final double progress; // 0.0 – 1.0
  final double size;
  final double strokeWidth;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 200,
    this.strokeWidth = 14,
  });

  @override
  Widget build(BuildContext context) {
    final target = progress.clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: target),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (_, animatedProgress, __) {
        return SizedBox(
          width:  size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(
              progress:    animatedProgress,
              strokeWidth: strokeWidth,
              bgColor:     AppColors.primaryLight.withValues(alpha: 0.32),
              fgColor:     animatedProgress >= 1.0
                  ? AppColors.success
                  : AppColors.primary,
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color  bgColor;
  final Color  fgColor;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.bgColor,
    required this.fgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background ring
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, 2 * math.pi, false,
      Paint()
        ..color       = bgColor
        ..strokeWidth = strokeWidth
        ..style       = PaintingStyle.stroke
        ..strokeCap   = StrokeCap.round,
    );

    // Progress ring
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        Paint()
          ..color       = fgColor
          ..strokeWidth = strokeWidth
          ..style       = PaintingStyle.stroke
          ..strokeCap   = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.fgColor != fgColor;
}
