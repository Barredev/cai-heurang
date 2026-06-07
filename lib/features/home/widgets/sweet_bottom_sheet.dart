// lib/features/home/widgets/sweet_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/app_providers.dart';

class SweetBottomSheet extends ConsumerStatefulWidget {
  const SweetBottomSheet({super.key});
  @override
  ConsumerState<SweetBottomSheet> createState() => _SweetBottomSheetState();
}

class _SweetBottomSheetState extends ConsumerState<SweetBottomSheet> {
  String? _selected;
  final _nameCtrl = TextEditingController();

  final _drinks = [
    'tea', 'coffee', 'packaged', 'juice', 'energy', 'condensed_milk', 'other',
  ];

  Future<void> _log() async {
    if (_selected == null) return;
    await ref.read(sweetProvider.notifier).log(
      drinkType: _selected!,
      drinkName: _selected == 'other' ? _nameCtrl.text.trim() : null,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Log Minuman Manis',
            style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Pilih jenis minumanmu',
            style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),

          Wrap(
            spacing: 8, runSpacing: 8,
            children: _drinks.map((type) {
              final label = AppConstants.drinkLabel[type] ?? type;
              final emoji = AppConstants.drinkEmoji[type] ?? '🫗';
              final sugar = AppConstants.sugarEstimateG[type];
              final sel   = _selected == type;

              return GestureDetector(
                onTap: () => setState(() => _selected = type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color:  sel ? AppColors.sweetAmber.withOpacity(0.15)
                                : AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: sel ? AppColors.sweetAmber : AppColors.primaryLight,
                      width: sel ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 4),
                      Text(label,
                        style: TextStyle(
                          fontFamily:  'Nunito',
                          fontSize:    11,
                          fontWeight:  FontWeight.w600,
                          color: sel ? AppColors.sweetAmber : AppColors.textPrimary,
                        )),
                      if (sugar != null)
                        Text('~${sugar.toInt()}g gula',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize:   10,
                            color: AppColors.textHint,
                          )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // Input nama jika 'other'
          if (_selected == 'other') ...[
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama minumannya apa?',
                prefixIcon: Icon(Icons.local_drink_outlined),
              ),
            ),
          ],

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selected != null ? _log : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sweetAmber,
                disabledBackgroundColor: AppColors.textHint.withOpacity(0.3),
              ),
              child: const Text('Catat 📝'),
            ),
          ),
        ],
      ),
    );
  }
}