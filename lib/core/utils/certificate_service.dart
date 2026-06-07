// lib/core/utils/certificate_service.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_constants.dart';

class CertificateService {
  /// Buat gambar sertifikat dan langsung share ke WhatsApp.
  /// [key] adalah GlobalKey yang dipasang di RepaintBoundary widget.
  static Future<void> shareFromWidget(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final tempDir = await getTemporaryDirectory();
      final file =
          File('${tempDir.path}/caiheurang_cert_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Aku berhasil minum cukup air hari ini! 💧🌱 #CaiHeurang',
      );
    } catch (e) {
      debugPrint('Certificate share error: $e');
    }
  }

  /// Buat sertifikat sebagai widget — wrap ini dengan RepaintBoundary + GlobalKey
  static Widget buildCertificate({
    required String name,
    required int    totalMl,
    required int    targetMl,
    required int    currentLevel,
    required int    streakDays,
    required int    weeklyScore,
    DateTime?       date,
  }) {
    final dt         = date ?? DateTime.now();
    final dateStr    = '${dt.day}/${dt.month}/${dt.year}';
    final phaseName  = AppConstants.plantPhaseNames[currentLevel - 1];
    final plantEmoji = _plantEmoji(currentLevel);

    return Container(
      width:   360,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB2DED9), Color(0xFF6BBFB5)],
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          const Text('💧 CaiHeurang', style: TextStyle(
            fontFamily: 'Nunito', fontSize: 14,
            fontWeight: FontWeight.w700, color: Colors.white70,
          )),
          const SizedBox(height: 12),

          // Tanaman
          Text(plantEmoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 8),

          // Nama & level
          Text(name, style: const TextStyle(
            fontFamily: 'Nunito', fontSize: 22,
            fontWeight: FontWeight.w800, color: Colors.white,
          )),
          Text('Level $currentLevel · $phaseName', style: const TextStyle(
            fontFamily: 'Nunito', fontSize: 13, color: Colors.white70,
          )),
          const SizedBox(height: 16),

          // Divider
          Container(height: 1, color: Colors.white30),
          const SizedBox(height: 16),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _CertStat(emoji: '💧', value: '$totalMl ml', label: 'hari ini'),
              _CertStat(emoji: '🔥', value: '$streakDays hari', label: 'streak'),
              _CertStat(emoji: '⭐', value: '$weeklyScore/7', label: 'minggu ini'),
            ],
          ),
          const SizedBox(height: 16),

          Container(height: 1, color: Colors.white30),
          const SizedBox(height: 12),

          // Footer
          Text('Target $targetMl ml tercapai! 🎉', style: const TextStyle(
            fontFamily: 'Nunito', fontSize: 13,
            fontWeight: FontWeight.w700, color: Colors.white,
          )),
          const SizedBox(height: 4),
          Text(dateStr, style: const TextStyle(
            fontFamily: 'Nunito', fontSize: 11, color: Colors.white60,
          )),
        ],
      ),
    );
  }

  static String _plantEmoji(int level) => switch (level) {
    1 => '🌰', 2 => '🌱', 3 => '🌿',
    4 => '🪴', 5 => '🌸', 6 => '🌳',
    _ => '🌲',
  };
}

class _CertStat extends StatelessWidget {
  final String emoji, value, label;
  const _CertStat({required this.emoji, required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(
        fontFamily: 'Nunito', fontWeight: FontWeight.w800,
        fontSize: 15, color: Colors.white,
      )),
      Text(label, style: const TextStyle(
        fontFamily: 'Nunito', fontSize: 10, color: Colors.white70,
      )),
    ],
  );
}