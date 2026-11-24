// lib/features/home/widgets/plant_widget.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/app_providers.dart';

class PlantWidget extends StatefulWidget {
  final int       level;
  final PlantMood mood;
  final double    size;
  final bool      showMoodBadge;
  final bool      animate;

  const PlantWidget({
    super.key,
    required this.level,
    required this.mood,
    this.size = 130,
    this.showMoodBadge = true,
    this.animate = true,
  });

  @override
  State<PlantWidget> createState() => _PlantWidgetState();
}

class _PlantWidgetState extends State<PlantWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    if (widget.animate) {
      _ctrl.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant PlantWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.animate && _ctrl.isAnimating) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _moodLabel => switch (widget.mood) {
    PlantMood.celebrating => 'Yeay! Segar banget! 🎉',
    PlantMood.happy       => 'Seneng banget~ 😊',
    PlantMood.normal      => '',
    PlantMood.thirsty     => 'Haus nih... 😢',
    PlantMood.sleeping    => 'ZZZ... 😴',
  };

  Color get _bgColor => switch (widget.mood) {
    PlantMood.celebrating => AppColors.success.withValues(alpha: 0.16),
    PlantMood.happy       => AppColors.primaryLight.withValues(alpha: 0.34),
    PlantMood.normal      => AppColors.primaryLight.withValues(alpha: 0.2),
    PlantMood.thirsty     => AppColors.warning.withValues(alpha: 0.18),
    PlantMood.sleeping    => AppColors.textHint.withValues(alpha: 0.14),
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 450),
          width:  widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: _bgColor,
            shape: BoxShape.circle,
          ),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => CustomPaint(
              size: Size.square(widget.size),
              painter: _PlantPainter(
                level: widget.level.clamp(1, 7),
                mood:  widget.mood,
                phase: widget.animate ? _ctrl.value : 0.0,
              ),
            ),
          ),
        ),
        if (widget.showMoodBadge && _moodLabel.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Text(
              _moodLabel,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PlantPainter extends CustomPainter {
  final int       level;
  final PlantMood mood;
  final double    phase;

  _PlantPainter({
    required this.level,
    required this.mood,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final wave = math.sin(phase * 2 * math.pi);
    final sway = switch (mood) {
      PlantMood.celebrating => wave * 0.075,
      PlantMood.happy       => wave * 0.045,
      PlantMood.normal      => wave * 0.025,
      PlantMood.thirsty     => 0.04 + wave * 0.01, // agak terkulai
      PlantMood.sleeping    => wave * 0.012,
    };
    final bounceY = mood == PlantMood.celebrating
        ? -math.sin(phase * 2 * math.pi).abs() * h * 0.035
        : 0.0;

    final soilY = h * 0.61 + bounceY;

    // 1. Bagian tanaman (berputar lembut di pangkal tanah)
    canvas.save();
    canvas.translate(cx, soilY);
    canvas.rotate(sway);
    _drawPlantStage(canvas, w, h);
    canvas.restore();

    // 2. Pot terakota + tanah + ekspresi wajah
    _drawPot(canvas, cx, soilY, w, h);

    // 3. Efek mood (sparkles / tetes keringat / Zzz)
    _drawMoodEffects(canvas, cx, soilY, w, h, wave);
  }

  void _drawPlantStage(Canvas canvas, double w, double h) {
    final droop = mood == PlantMood.thirsty ? 0.28 : 0.0;
    final leafPrimary = mood == PlantMood.thirsty
        ? const Color(0xFF9FB86A)
        : const Color(0xFF4BB87E);
    final leafLight = mood == PlantMood.thirsty
        ? const Color(0xFFB7C983)
        : const Color(0xFF7AD69E);
    final leafDark = mood == PlantMood.thirsty
        ? const Color(0xFF7D9650)
        : const Color(0xFF2F9464);

    switch (level) {
      case 1: // Biji
        final seedPaint = Paint()..color = const Color(0xFFA66B3E);
        final seedHighlight = Paint()..color = const Color(0xFFC78958);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(0, -h * 0.035),
            width: w * 0.19,
            height: h * 0.13,
          ),
          seedPaint,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(-w * 0.03, -h * 0.055),
            width: w * 0.06,
            height: h * 0.035,
          ),
          seedHighlight,
        );
        // Ujung tunas kecil mengintip
        _drawLeaf(
          canvas,
          origin: Offset(0, -h * 0.085),
          length: h * 0.08,
          width: w * 0.06,
          angle: -0.35 + droop,
          color: leafLight,
        );
        break;

      case 2: // Tunas
        _drawStem(canvas, h * 0.19, w * 0.032, leafDark);
        _drawLeaf(
          canvas,
          origin: Offset(0, -h * 0.16),
          length: h * 0.13,
          width: w * 0.09,
          angle: -0.95 - droop,
          color: leafPrimary,
        );
        _drawLeaf(
          canvas,
          origin: Offset(0, -h * 0.16),
          length: h * 0.13,
          width: w * 0.09,
          angle: 0.95 + droop,
          color: leafLight,
        );
        break;

      case 3: // Kuncup
        _drawStem(canvas, h * 0.27, w * 0.034, leafDark);
        _drawLeaf(
          canvas,
          origin: Offset(0, -h * 0.13),
          length: h * 0.14,
          width: w * 0.09,
          angle: -1.05 - droop,
          color: leafPrimary,
        );
        _drawLeaf(
          canvas,
          origin: Offset(0, -h * 0.16),
          length: h * 0.14,
          width: w * 0.09,
          angle: 1.0 + droop,
          color: leafLight,
        );
        _drawBud(canvas, Offset(0, -h * 0.27), w * 0.085, const Color(0xFFFF8FAB));
        break;

      case 4: // Kuncup Besar
        _drawStem(canvas, h * 0.31, w * 0.036, leafDark);
        _drawLeaf(
          canvas,
          origin: Offset(0, -h * 0.10),
          length: h * 0.16,
          width: w * 0.10,
          angle: -1.15 - droop,
          color: leafDark,
        );
        _drawLeaf(
          canvas,
          origin: Offset(0, -h * 0.12),
          length: h * 0.16,
          width: w * 0.10,
          angle: 1.12 + droop,
          color: leafPrimary,
        );
        _drawLeaf(
          canvas,
          origin: Offset(0, -h * 0.21),
          length: h * 0.13,
          width: w * 0.085,
          angle: -0.78 - droop,
          color: leafLight,
        );
        _drawLeaf(
          canvas,
          origin: Offset(0, -h * 0.22),
          length: h * 0.13,
          width: w * 0.085,
          angle: 0.78 + droop,
          color: leafLight,
        );
        _drawBud(canvas, Offset(0, -h * 0.31), w * 0.115, const Color(0xFFFF7AA2));
        break;

      case 5: // Bunga Mekar
        _drawStem(canvas, h * 0.31, w * 0.036, leafDark);
        _drawLeaf(
          canvas,
          origin: Offset(0, -h * 0.11),
          length: h * 0.16,
          width: w * 0.10,
          angle: -1.1 - droop,
          color: leafPrimary,
        );
        _drawLeaf(
          canvas,
          origin: Offset(0, -h * 0.14),
          length: h * 0.16,
          width: w * 0.10,
          angle: 1.08 + droop,
          color: leafLight,
        );
        _drawBlossom(canvas, Offset(0, -h * 0.32), w * 0.135);
        break;

      case 6: // Pohon Muda
        _drawTrunk(canvas, h * 0.25, w * 0.075);
        _drawCanopy(
          canvas,
          center: Offset(0, -h * 0.29),
          radius: w * 0.20,
          primary: leafPrimary,
          light: leafLight,
          dark: leafDark,
          withFruits: false,
        );
        break;

      default: // Level 7 — Pohon Rindang
        _drawTrunk(canvas, h * 0.26, w * 0.09);
        _drawCanopy(
          canvas,
          center: Offset(0, -h * 0.31),
          radius: w * 0.24,
          primary: leafPrimary,
          light: leafLight,
          dark: leafDark,
          withFruits: true,
        );
        break;
    }
  }

  void _drawStem(Canvas canvas, double height, double strokeW, Color color) {
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-strokeW * 0.7, -height * 0.5, 0, -height);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawLeaf(
    Canvas canvas, {
    required Offset origin,
    required double length,
    required double width,
    required double angle,
    required Color color,
  }) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(angle);
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-width, -length * 0.5, 0, -length)
      ..quadraticBezierTo(width, -length * 0.5, 0, 0);
    canvas.drawPath(path, Paint()..color = color);
    // Tulang daun tipis
    canvas.drawLine(
      Offset.zero,
      Offset(0, -length * 0.75),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..strokeWidth = math.max(1.0, width * 0.1),
    );
    canvas.restore();
  }

  void _drawBud(Canvas canvas, Offset center, double r, Color petalColor) {
    canvas.drawOval(
      Rect.fromCenter(center: center, width: r * 1.35, height: r * 1.7),
      Paint()..color = petalColor,
    );
    // Kelopak hijau di pangkal kuncup
    final sepal = Path()
      ..moveTo(center.dx - r * 0.65, center.dy + r * 0.35)
      ..quadraticBezierTo(center.dx, center.dy + r * 1.05, center.dx + r * 0.65, center.dy + r * 0.35)
      ..quadraticBezierTo(center.dx, center.dy + r * 0.55, center.dx - r * 0.65, center.dy + r * 0.35);
    canvas.drawPath(sepal, Paint()..color = const Color(0xFF2F9464));
  }

  void _drawBlossom(Canvas canvas, Offset center, double r) {
    final petalPaint = Paint()..color = const Color(0xFFFF8FAB);
    final innerPetal = Paint()..color = const Color(0xFFFFB3C6);
    for (int i = 0; i < 5; i++) {
      final a = (i * 2 * math.pi / 5) - math.pi / 2;
      final px = center.dx + math.cos(a) * r * 0.72;
      final py = center.dy + math.sin(a) * r * 0.72;
      canvas.drawCircle(Offset(px, py), r * 0.56, petalPaint);
      canvas.drawCircle(Offset(px, py), r * 0.30, innerPetal);
    }
    canvas.drawCircle(center, r * 0.44, Paint()..color = const Color(0xFFFFD166));
    canvas.drawCircle(
      center + Offset(-r * 0.12, -r * 0.12),
      r * 0.14,
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  void _drawTrunk(Canvas canvas, double height, double baseW) {
    final path = Path()
      ..moveTo(-baseW * 0.55, 0)
      ..quadraticBezierTo(-baseW * 0.32, -height * 0.55, -baseW * 0.25, -height)
      ..lineTo(baseW * 0.25, -height)
      ..quadraticBezierTo(baseW * 0.32, -height * 0.55, baseW * 0.55, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF9C6644));
  }

  void _drawCanopy(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color primary,
    required Color light,
    required Color dark,
    required bool withFruits,
  }) {
    canvas.drawCircle(center + Offset(-radius * 0.58, radius * 0.18), radius * 0.64, Paint()..color = dark);
    canvas.drawCircle(center + Offset(radius * 0.58, radius * 0.18), radius * 0.62, Paint()..color = dark);
    canvas.drawCircle(center, radius * 0.78, Paint()..color = primary);
    canvas.drawCircle(center + Offset(-radius * 0.36, -radius * 0.22), radius * 0.54, Paint()..color = light);
    canvas.drawCircle(center + Offset(radius * 0.32, -radius * 0.18), radius * 0.48, Paint()..color = light);

    if (withFruits) {
      final blossomDot = Paint()..color = const Color(0xFFFFD166);
      final coralDot   = Paint()..color = const Color(0xFFFF8FAB);
      canvas.drawCircle(center + Offset(-radius * 0.48, radius * 0.08), radius * 0.13, coralDot);
      canvas.drawCircle(center + Offset(radius * 0.42, -radius * 0.10), radius * 0.12, blossomDot);
      canvas.drawCircle(center + Offset(0, -radius * 0.42), radius * 0.13, coralDot);
      canvas.drawCircle(center + Offset(radius * 0.12, radius * 0.22), radius * 0.11, blossomDot);
    }
  }

  void _drawPot(Canvas canvas, double cx, double soilY, double w, double h) {
    final potTopW = w * 0.44;
    final potBotW = w * 0.30;
    final potH    = h * 0.25;
    final rimH    = h * 0.065;

    // Tanah elips
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, soilY),
        width: potTopW * 0.94,
        height: h * 0.07,
      ),
      Paint()..color = const Color(0xFF6B4E3D),
    );

    // Badan pot
    final bodyPath = Path()
      ..moveTo(cx - potTopW * 0.48, soilY + rimH * 0.4)
      ..lineTo(cx + potTopW * 0.48, soilY + rimH * 0.4)
      ..lineTo(cx + potBotW * 0.5, soilY + potH)
      ..quadraticBezierTo(cx, soilY + potH + h * 0.03, cx - potBotW * 0.5, soilY + potH)
      ..close();
    canvas.drawPath(bodyPath, Paint()..color = const Color(0xFFE08763));

    // Rim pot
    final rimRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, soilY + rimH * 0.35),
        width: potTopW * 1.06,
        height: rimH,
      ),
      Radius.circular(rimH * 0.45),
    );
    canvas.drawRRect(rimRect, Paint()..color = const Color(0xFFEC9B79));

    // Wajah kawaii pada badan pot
    final faceY = soilY + potH * 0.58;
    final eyeDx = w * 0.075;
    final facePaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, w * 0.017)
      ..strokeCap = StrokeCap.round;

    final cheekPaint = Paint()..color = const Color(0xFFFF9E9E).withValues(alpha: 0.65);

    switch (mood) {
      case PlantMood.celebrating:
      case PlantMood.happy:
        // Mata ^ ^
        for (final sign in [-1, 1]) {
          final ex = cx + sign * eyeDx;
          final arc = Path()
            ..moveTo(ex - w * 0.028, faceY)
            ..quadraticBezierTo(ex, faceY - h * 0.032, ex + w * 0.028, faceY);
          canvas.drawPath(arc, facePaint);
          canvas.drawCircle(Offset(ex + sign * w * 0.032, faceY + h * 0.026), w * 0.024, cheekPaint);
        }
        // Senyum lebar
        final smile = Path()
          ..moveTo(cx - w * 0.04, faceY + h * 0.025)
          ..quadraticBezierTo(cx, faceY + h * 0.068, cx + w * 0.04, faceY + h * 0.025);
        canvas.drawPath(smile, facePaint);
        break;

      case PlantMood.normal:
        final dotPaint = Paint()..color = const Color(0xFF3E2723);
        for (final sign in [-1, 1]) {
          final ex = cx + sign * eyeDx;
          canvas.drawCircle(Offset(ex, faceY - h * 0.005), w * 0.019, dotPaint);
          canvas.drawCircle(
            Offset(ex - w * 0.006, faceY - h * 0.011),
            w * 0.006,
            Paint()..color = Colors.white,
          );
          canvas.drawCircle(Offset(ex + sign * w * 0.03, faceY + h * 0.024), w * 0.02, cheekPaint);
        }
        final smile = Path()
          ..moveTo(cx - w * 0.032, faceY + h * 0.024)
          ..quadraticBezierTo(cx, faceY + h * 0.052, cx + w * 0.032, faceY + h * 0.024);
        canvas.drawPath(smile, facePaint);
        break;

      case PlantMood.thirsty:
        final dotPaint = Paint()..color = const Color(0xFF3E2723);
        for (final sign in [-1, 1]) {
          final ex = cx + sign * eyeDx;
          canvas.drawCircle(Offset(ex, faceY), w * 0.018, dotPaint);
        }
        // Mulut sedih/haus
        final frown = Path()
          ..moveTo(cx - w * 0.034, faceY + h * 0.046)
          ..quadraticBezierTo(cx, faceY + h * 0.02, cx + w * 0.034, faceY + h * 0.046);
        canvas.drawPath(frown, facePaint);
        break;

      case PlantMood.sleeping:
        // Mata terpejam u u
        for (final sign in [-1, 1]) {
          final ex = cx + sign * eyeDx;
          final arc = Path()
            ..moveTo(ex - w * 0.025, faceY)
            ..quadraticBezierTo(ex, faceY + h * 0.024, ex + w * 0.025, faceY);
          canvas.drawPath(arc, facePaint);
        }
        canvas.drawCircle(
          Offset(cx, faceY + h * 0.036),
          w * 0.014,
          facePaint..style = PaintingStyle.stroke,
        );
        break;
    }
  }

  void _drawMoodEffects(
    Canvas canvas,
    double cx,
    double soilY,
    double w,
    double h,
    double wave,
  ) {
    if (mood == PlantMood.celebrating) {
      final starPaint = Paint()..color = const Color(0xFFFFD166);
      final scale = 0.8 + 0.35 * wave.abs();
      _drawSparkle(canvas, Offset(cx - w * 0.30, h * 0.25), w * 0.045 * scale, starPaint);
      _drawSparkle(canvas, Offset(cx + w * 0.31, h * 0.28), w * 0.04 * scale, starPaint);
      _drawSparkle(canvas, Offset(cx + w * 0.22, h * 0.16), w * 0.03 * scale, Paint()..color = const Color(0xFFFF8FAB));
    } else if (mood == PlantMood.thirsty) {
      // Tetes keringat biru kecil
      final dropCenter = Offset(cx + w * 0.24, soilY + h * 0.04 + wave * h * 0.015);
      final drop = Path()
        ..moveTo(dropCenter.dx, dropCenter.dy - h * 0.045)
        ..quadraticBezierTo(dropCenter.dx + w * 0.04, dropCenter.dy + h * 0.01, dropCenter.dx, dropCenter.dy + h * 0.032)
        ..quadraticBezierTo(dropCenter.dx - w * 0.04, dropCenter.dy + h * 0.01, dropCenter.dx, dropCenter.dy - h * 0.045);
      canvas.drawPath(drop, Paint()..color = const Color(0xFF63B3ED));
    } else if (mood == PlantMood.sleeping) {
      final tp = TextPainter(
        text: TextSpan(
          text: 'zZ',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: w * 0.11,
            color: AppColors.textHint,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx + w * 0.20, h * 0.22 + wave * h * 0.02));
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - r)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + r, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + r)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - r, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - r);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PlantPainter old) =>
      old.level != level || old.mood != mood || old.phase != phase;
}
