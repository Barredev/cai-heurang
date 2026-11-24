// lib/features/profile/widgets/family_profile_sheets.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/profile_model.dart';
import '../../../shared/providers/app_providers.dart';
import '../../home/widgets/plant_widget.dart';

/// Bottom sheet cepat untuk pindah profil anggota keluarga (dari Beranda / Profil).
Future<void> showFamilySwitcherSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _FamilySwitcherSheet(),
  );
}

/// Bottom sheet untuk menambah anggota keluarga baru.
Future<void> showAddFamilyProfileSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AddFamilyProfileSheet(),
  );
}

class _FamilySwitcherSheet extends ConsumerWidget {
  const _FamilySwitcherSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active   = ref.watch(profileProvider);
    final profiles = ref.watch(profilesListProvider);
    final repo     = ref.read(repoProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textHint.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Profil Keluarga 👨‍👩‍👧‍👦',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Pilih anggota keluarga untuk melihat & mencatat hidrasi.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            ...profiles.map((p) {
              final isSelected = p.id == active?.id;
              final todayMl    = repo.getTodayTotalMl(p.id);
              final safeLevel  = p.currentLevel
                  .clamp(1, AppConstants.plantPhaseNames.length);
              final phaseName  = AppConstants.plantPhaseNames[safeLevel - 1];

              return InkWell(
                onTap: () async {
                  if (!isSelected) {
                    await ref.read(profileProvider.notifier).switchProfile(p.id);
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.bgSurface
                        : AppColors.bgCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : const Color(0xFFE2E8F0),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      PlantWidget(
                        level: safeLevel,
                        mood: todayMl >= p.targetMl
                            ? PlantMood.celebrating
                            : PlantMood.happy,
                        size: 50,
                        showMoodBadge: false,
                        animate: false,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Lv.$safeLevel $phaseName · $todayMl / ${p.targetMl} ml',
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showAddFamilyProfileSheet(context);
                },
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Tambah Anggota Keluarga'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddFamilyProfileSheet extends ConsumerStatefulWidget {
  const _AddFamilyProfileSheet();

  @override
  ConsumerState<_AddFamilyProfileSheet> createState() =>
      _AddFamilyProfileSheetState();
}

class _AddFamilyProfileSheetState
    extends ConsumerState<_AddFamilyProfileSheet> {
  final _nameCtrl   = TextEditingController();
  final _targetCtrl = TextEditingController();

  String _gender    = 'male';
  int    _age       = 25;
  String _condition = 'none';
  bool   _useCustom = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  int get _recommendedTarget => AppConstants.minimumWaterMl(
        gender: _gender,
        age: _age,
        condition: _condition,
      );

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Isi nama anggota keluarga dulu ya~')),
        );
      return;
    }

    final parsed = _useCustom && _targetCtrl.text.trim().isNotEmpty
        ? int.tryParse(_targetCtrl.text.trim()) ?? _recommendedTarget
        : _recommendedTarget;
    final finalTarget =
        parsed < _recommendedTarget ? _recommendedTarget : parsed;

    await ref.read(profileProvider.notifier).addFamilyProfile(
          name: name,
          gender: _gender,
          age: _age,
          condition: _condition,
          targetMl: finalTarget,
        );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Profil $name berhasil ditambahkan! 🌱'),
            duration: const Duration(seconds: 2),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textHint.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tambah Anggota Keluarga 👨‍👩‍👧‍👦',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Tiap anggota punya target air, tanaman, dan streak sendiri.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama panggilan (mis. Ibu, Ayah, Adik)',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),

            Text('Jenis kelamin', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Laki-laki'),
                  selected: _gender == 'male',
                  selectedColor: AppColors.primaryLight,
                  onSelected: (_) => setState(() {
                    _gender = 'male';
                    _condition = 'none';
                  }),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('Perempuan'),
                  selected: _gender == 'female',
                  selectedColor: AppColors.primaryLight,
                  onSelected: (_) => setState(() => _gender = 'female'),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Text('Usia', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text(
                  '$_age tahun',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
              ],
            ),
            Slider(
              value: _age.toDouble(),
              min: 4,
              max: 99,
              divisions: 95,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _age = v.round()),
            ),

            if (_gender == 'female') ...[
              Text('Kondisi khusus', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ('none', 'Tidak ada'),
                  ('pregnant', 'Hamil 🤰'),
                  ('breastfeeding', 'Menyusui 🤱'),
                ].map((e) {
                  return ChoiceChip(
                    label: Text(e.$2),
                    selected: _condition == e.$1,
                    selectedColor: AppColors.primaryLight,
                    onSelected: (_) => setState(() => _condition = e.$1),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primaryLight),
              ),
              child: Row(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Rekomendasi WHO/IOM: $_recommendedTarget ml/hari',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _useCustom,
              activeThumbColor: AppColors.primary,
              title: const Text('Atur target manual'),
              onChanged: (v) => setState(() => _useCustom = v),
            ),
            if (_useCustom) ...[
              TextField(
                controller: _targetCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Target custom (ml)',
                  helperText: 'Minimum $_recommendedTarget ml',
                  suffixText: 'ml',
                ),
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Simpan & Pakai Profil 🌱'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog konfirmasi hapus profil anggota keluarga.
Future<bool> confirmDeleteFamilyProfile(
  BuildContext context,
  ProfileModel profile,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text('Hapus profil ${profile.name}?'),
      content: const Text(
        'Semua catatan minum, streak, dan progres tanaman milik profil ini akan ikut dihapus.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
  return result == true;
}
