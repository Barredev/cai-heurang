// lib/features/home/widgets/sweet_warning_dialog.dart
import 'package:flutter/material.dart';

class SweetWarningDialog extends StatelessWidget {
  final int    level; // 1 atau 2
  final String name;

  const SweetWarningDialog({
    super.key,
    required this.level,
    required this.name,
  });

  String get _emoji   => level >= 2 ? '🥺' : '🌿';
  String get _title   => level >= 2
      ? 'Gulanya sudah lumayan banyak~'
      : 'Agak manis nih hari ini';
  String get _message => level >= 2
      ? 'Wah $name, gulanya udah lumayan banyak hari ini. '
        'Si tanaman doain semoga besok bisa lebih segar ya~ 🥺 '
        'Minum air putih dulu yuk!'
      : '$name, si tanaman ngerasa agak... manis nih hari ini hehe. '
        'Nanti minum air putih lagi ya biar seimbang~ 🌿';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(_title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(_message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Oke, makasih! 💧'),
            ),
          ],
        ),
      ),
    );
  }
}