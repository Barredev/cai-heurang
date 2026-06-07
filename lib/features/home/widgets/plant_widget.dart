// lib/features/home/widgets/plant_widget.dart
import 'package:flutter/material.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class PlantWidget extends StatelessWidget {
  final int       level;
  final PlantMood mood;
  final double    size;

  const PlantWidget({
    super.key,
    required this.level,
    required this.mood,
    this.size = 120,
  });

  // Emoji representasi tiap level & mood
  String get _emoji {
    final base = switch (level) {
      1 => '🌰',
      2 => '🌱',
      3 => '🌿',
      4 => '🪴',
      5 => '🌸',
      6 => '🌳',
      _ => '🌲',
    };

    return switch (mood) {
      PlantMood.celebrating => '$base✨',
      PlantMood.happy       => base,
      PlantMood.normal      => base,
      PlantMood.thirsty     => base,
      PlantMood.sleeping    => base,
    };
  }

  String get _moodLabel => switch (mood) {
    PlantMood.celebrating => 'Yeay! 🎉',
    PlantMood.happy       => 'Seneng banget~',
    PlantMood.normal      => '',
    PlantMood.thirsty     => 'Haus nih... 😢',
    PlantMood.sleeping    => 'ZZZ... 😴',
  };

  Color get _bgColor => switch (mood) {
    PlantMood.celebrating => AppColors.success.withOpacity(0.15),
    PlantMood.happy       => AppColors.primaryLight.withOpacity(0.3),
    PlantMood.normal      => AppColors.primaryLight.withOpacity(0.15),
    PlantMood.thirsty     => AppColors.warning.withOpacity(0.15),
    PlantMood.sleeping    => AppColors.textHint.withOpacity(0.1),
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width:  size,
          height: size,
          decoration: BoxDecoration(
            color:  _bgColor,
            shape:  BoxShape.circle,
          ),
          child: Center(
            child: Text(_emoji,
              style: TextStyle(fontSize: size * 0.45)),
          ),
        ),
        if (_moodLabel.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
              )],
            ),
            child: Text(_moodLabel,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              )),
          ),
        ],
      ],
    );
  }
}