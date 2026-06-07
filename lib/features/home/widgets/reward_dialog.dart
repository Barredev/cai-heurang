// lib/features/home/widgets/reward_dialog.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class RewardDialog extends StatelessWidget {
  final String emoji;
  final String title;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onButton;
  final VoidCallback? onDismiss;

  const RewardDialog._({
    required this.emoji,
    required this.title,
    required this.message,
    this.buttonLabel,
    this.onButton,
    this.onDismiss,
  });

  // Factory: target harian tercapai
  factory RewardDialog.dailyComplete({
    required String profileId,
    required VoidCallback onShared,
  }) => RewardDialog._(
    emoji:       '🎉',
    title:       'Target Tercapai!',
    message:     'Kamu berhasil minum cukup air hari ini!\nPamerkan ke grup keluarga yuk~ 😄',
    buttonLabel: 'Pamer ke WhatsApp! 📱',
    onButton:    onShared,
  );

  // Factory: level naik
  factory RewardDialog.levelUp({required String phaseName}) => RewardDialog._(
    emoji:   '🌱✨',
    title:   'Tanamanmu Berevolusi!',
    message: 'Sekarang sudah jadi $phaseName!\nTerus semangat minum airnya ya~ 💪',
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
                  onPressed: () {
                    onButton?.call();
                    Navigator.pop(context);
                  },
                  child: Text(buttonLabel!),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(buttonLabel != null ? 'Nanti saja' : 'Oke! 👍'),
            ),
          ],
        ),
      ),
    );
  }
}