// lib/features/profile/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/achievement_share_service.dart';
import '../../../../data/models/profile_model.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../home/widgets/achievement_share_sheet.dart';
import '../../home/widgets/plant_widget.dart';
import '../widgets/family_profile_sheets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _openEditProfile(
    BuildContext context,
    ProfileModel profile,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(profile: profile),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile   = ref.watch(profileProvider);
    final profiles  = ref.watch(profilesListProvider);
    final streak    = ref.watch(streakProvider);
    final reminders = ref.watch(reminderSettingsProvider);

    if (profile == null) return const SizedBox.shrink();

    final safeLevel =
        profile.currentLevel.clamp(1, AppConstants.plantPhaseNames.length);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil 🌱'),
        actions: [
          IconButton(
            onPressed: () => _openEditProfile(context, profile),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit profil',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar tanaman kustom sesuai level
            PlantWidget(
              level: safeLevel,
              mood: PlantMood.happy,
              size: 112,
              showMoodBadge: false,
              animate: false,
            ),
            const SizedBox(height: 12),
            Text(
              profile.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              'Level $safeLevel · ${AppConstants.plantPhaseNames[safeLevel - 1]}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),

            // Stats row
            Row(children: [
              _StatCard(
                label: 'Total XP',
                value: '${profile.totalXp}',
                emoji: '⭐',
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Streak',
                value: '${streak?.currentStreak ?? 0} hari',
                emoji: '🔥',
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Rekor',
                value: '${streak?.longestStreak ?? 0} hari',
                emoji: '🏆',
              ),
            ]),
            const SizedBox(height: 16),

            // CTA Share Achievement ala TikTok Streak
            GestureDetector(
              onTap: () => showAchievementShareSheet(
                context,
                initialType: AchievementCardType.streak,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF28193D), Color(0xFFD94A2A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bagikan Streak & Achievement',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Buat kartu streak kece siap share ke Story!',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.ios_share_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Multi-Profil Keluarga
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Anggota Keluarga 👨‍👩‍👧‍👦',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${profiles.length} profil',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...profiles.map((member) {
                          final isActive = member.id == profile.id;
                          final memberLv = member.currentLevel.clamp(
                            1,
                            AppConstants.plantPhaseNames.length,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                              onTap: () {
                                if (!isActive) {
                                  ref
                                      .read(profileProvider.notifier)
                                      .switchProfile(member.id);
                                }
                              },
                              onLongPress: profiles.length > 1
                                  ? () async {
                                      final ok = await confirmDeleteFamilyProfile(
                                        context,
                                        member,
                                      );
                                      if (ok) {
                                        await ref
                                            .read(profileProvider.notifier)
                                            .deleteProfile(member.id);
                                      }
                                    }
                                  : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.bgSurface
                                      : AppColors.bgMain,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isActive
                                        ? AppColors.primary
                                        : const Color(0xFFE2E8F0),
                                    width: isActive ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      AppConstants.plantEmoji(memberLv),
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(width: 6),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          member.name,
                                          style: TextStyle(
                                            fontFamily: 'Nunito',
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: isActive
                                                ? AppColors.primaryDark
                                                : AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          'Lv.$memberLv',
                                          style: const TextStyle(
                                            fontFamily: 'Nunito',
                                            fontSize: 10,
                                            color: AppColors.textHint,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        // Tombol tambah anggota keluarga
                        GestureDetector(
                          onTap: () => showAddFamilyProfileSheet(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.primaryLight),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  size: 18,
                                  color: AppColors.primaryDark,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Tambah',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (profiles.length > 1) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Tap untuk pindah profil · Tekan lama untuk menghapus profil',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Info profil (tap untuk edit)
            _InfoTile(
              icon: Icons.water_drop_outlined,
              label: 'Target harian',
              value: '${profile.targetMl} ml',
              onTap: () => _openEditProfile(context, profile),
            ),
            _InfoTile(
              icon: Icons.person_outline,
              label: 'Usia',
              value: '${profile.age} tahun',
              onTap: () => _openEditProfile(context, profile),
            ),
            _InfoTile(
              icon: Icons.shield_outlined,
              label: 'Streak shield',
              value: '${streak?.shieldsAvailable ?? 0} tersisa',
            ),
            const SizedBox(height: 14),

            // Pengaturan pengingat minum
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.notifications_active_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Pengingat Minum',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Switch(
                        value: reminders.enabled,
                        activeThumbColor: AppColors.primary,
                        onChanged: (v) => ref
                            .read(reminderSettingsProvider.notifier)
                            .setEnabled(v),
                      ),
                    ],
                  ),
                  Text(
                    reminders.enabled
                        ? 'Aktif setiap ${reminders.intervalHours} jam (06:00 – 22:00)'
                        : 'Pengingat dimatikan sementara',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                        ),
                  ),
                  if (reminders.enabled) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [1, 2, 3, 4].map((hours) {
                        final selected = reminders.intervalHours == hours;
                        return ChoiceChip(
                          label: Text('$hours jam'),
                          selected: selected,
                          selectedColor: AppColors.primaryLight,
                          labelStyle: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: selected
                                ? AppColors.primaryDark
                                : AppColors.textSecondary,
                          ),
                          onSelected: (_) => ref
                              .read(reminderSettingsProvider.notifier)
                              .setIntervalHours(hours),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Disclaimer
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                '⚠️ Target air berdasarkan panduan WHO & IOM. '
                'Konsultasikan dengan dokter jika kamu punya kondisi '
                'kesehatan tertentu.',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  final ProfileModel profile;
  const _EditProfileSheet({required this.profile});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _targetCtrl;
  late int _age;

  @override
  void initState() {
    super.initState();
    _nameCtrl   = TextEditingController(text: widget.profile.name);
    _targetCtrl = TextEditingController(text: '${widget.profile.targetMl}');
    _age        = widget.profile.age;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  int get _minTarget => AppConstants.minimumWaterMl(
        gender: widget.profile.gender,
        age: _age,
        condition: widget.profile.condition,
      );

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Nama tidak boleh kosong')));
      return;
    }

    final parsedTarget = int.tryParse(_targetCtrl.text.trim()) ?? _minTarget;
    final finalTarget  = parsedTarget < _minTarget ? _minTarget : parsedTarget;

    await ref.read(profileProvider.notifier).updateProfile(
          name: name,
          targetMl: finalTarget,
          age: _age,
        );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui ✓'),
            duration: Duration(seconds: 2),
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
            Text('Edit Profil', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama panggilan',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),

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
              value: _age.toDouble().clamp(4, 99),
              min: 4,
              max: 99,
              divisions: 95,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _age = v.round()),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _targetCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Target air harian',
                helperText: 'Minimum rekomendasi WHO/IOM: $_minTarget ml',
                suffixText: 'ml',
                prefixIcon: const Icon(Icons.water_drop_outlined),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() {
                  _targetCtrl.text = '$_minTarget';
                }),
                child: Text('Pakai rekomendasi ($_minTarget ml)'),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Simpan Perubahan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, emoji;
  const _StatCard({
    required this.label,
    required this.value,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
          ]),
        ),
      );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final VoidCallback? onTap;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textHint,
              ),
            ],
          ]),
        ),
      );
}
