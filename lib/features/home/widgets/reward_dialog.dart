// lib/features/home/widgets/reward_dialog.dart
import 'package:flutter/material.dart';

class RewardDialog extends StatelessWidget {
  final String emoji;
  final String title;
  final String message;
  final String? buttonLabel;

  const RewardDialog._({
    required this.emoji,
    required this.title,
    required this.message,
    this.buttonLabel,
  });

  // Factory: target harian tercapai
  factory RewardDialog.dailyComplete({
    int streakDays = 1,
  }) => RewardDialog._(
    emoji:       '🔥🎉',
    title:       'Target Tercapai!',
    message:     streakDays > 1
        ? 'Streak kamu naik jadi $streakDays hari berturut-turut!\nYuk bagikan achievement-mu~ 🔥'
        : 'Kamu berhasil minum cukup air hari ini!\nYuk bagikan achievement-mu~ 😄',
    buttonLabel: 'Bagikan Achievement 🔥',
  );

  // Factory: level naik
  factory RewardDialog.levelUp({required String phaseName}) => RewardDialog._(
    emoji:       '🌱✨',
    title:       'Tanamanmu Berevolusi!',
    message:     'Sekarang sudah jadi $phaseName!\nTerus semangat minum airnya ya~ 💪',
    buttonLabel: 'Bagikan Evolusi ✨',
  );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center),
            const SizedBox(height: 24),
            if (buttonLabel != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(buttonLabel!),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(buttonLabel != null ? 'Nanti saja' : 'Oke! 👍'),
            ),
          ],
        ),
      ),
    );
  }
}