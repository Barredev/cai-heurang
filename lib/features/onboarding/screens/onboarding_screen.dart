// lib/features/onboarding/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/notification_service.dart';
import '../../../shared/providers/app_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  // Form fields
  final _nameCtrl = TextEditingController();
  String _gender    = 'male';
  int    _age       = 25;
  String _condition = 'none';
  int?   _targetMl;     // null = pakai kalkulasi
  bool   _useCustom = false;
  final _customTargetCtrl = TextEditingController();

  int get _calculatedTarget => AppConstants.minimumWaterMl(
    gender: _gender, age: _age, condition: _condition,
  );

  void _next() {
    if (_page < 4) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prev() {
    if (_page > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finish() async {
    final target = _useCustom && _customTargetCtrl.text.isNotEmpty
        ? int.tryParse(_customTargetCtrl.text) ?? _calculatedTarget
        : _calculatedTarget;

    final minLimit = AppConstants.minimumWaterMl(
      gender: _gender, age: _age, condition: _condition,
    );
    final finalTarget = target < minLimit ? minLimit : target;

    await ref.read(profileProvider.notifier).create(
      name:      _nameCtrl.text.trim(),
      gender:    _gender,
      age:       _age,
      condition: _condition,
      targetMl:  finalTarget,
    );

    await NotificationService.requestPermission();

    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRouter.main);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageCtrl,
          physics:    const NeverScrollableScrollPhysics(),
          onPageChanged: (i) => setState(() => _page = i),
          children: [
            _SplashPage(onNext: _next),
            _NamePage(ctrl: _nameCtrl, onNext: () {
              if (_nameCtrl.text.trim().isEmpty) return;
              _next();
            }),
            _DataPage(
              gender:    _gender,
              age:       _age,
              condition: _condition,
              onGenderChanged:    (v) => setState(() => _gender = v),
              onAgeChanged:       (v) => setState(() => _age = v),
              onConditionChanged: (v) => setState(() => _condition = v),
              onNext: _next,
              onBack: _prev,
            ),
            _TargetPage(
              calculatedTarget: _calculatedTarget,
              useCustom:        _useCustom,
              customCtrl:       _customTargetCtrl,
              onToggleCustom:   (v) => setState(() => _useCustom = v),
              onNext: _next,
              onBack: _prev,
              minimumMl: AppConstants.minimumWaterMl(
                gender: _gender, age: _age, condition: _condition,
              ),
            ),
            _WelcomePage(
              name:       _nameCtrl.text.trim(),
              onFinish:   _finish,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Page 1: Splash ────────────────────────────────────────────
class _SplashPage extends StatelessWidget {
  final VoidCallback onNext;
  const _SplashPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💧', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 24),
          Text('CaiHeurang',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: AppColors.primary, fontSize: 36,
            )),
          const SizedBox(height: 8),
          Text('Air Jernih untuk Keluarga Sehat',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center),
          const SizedBox(height: 48),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('Mulai Yuk! 🌱'),
            )),
        ],
      ),
    );
  }
}

// ── Page 2: Nama ──────────────────────────────────────────────
class _NamePage extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onNext;
  const _NamePage({required this.ctrl, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('👋', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('Halo! Siapa namamu?',
            style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Nama ini akan dipakai untuk sapaan & notifikasi.',
            style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 32),
          TextField(
            controller:      ctrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nama kamu',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('Lanjut →'),
            )),
        ],
      ),
    );
  }
}

// ── Page 3: Data diri ─────────────────────────────────────────
class _DataPage extends StatelessWidget {
  final String   gender;
  final int      age;
  final String   condition;
  final ValueChanged<String> onGenderChanged;
  final ValueChanged<int>    onAgeChanged;
  final ValueChanged<String> onConditionChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _DataPage({
    required this.gender, required this.age, required this.condition,
    required this.onGenderChanged, required this.onAgeChanged,
    required this.onConditionChanged, required this.onNext, required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text('📋', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('Data diri', style: Theme.of(context).textTheme.headlineMedium),
          Text('Untuk menghitung kebutuhan air harianmu.',
            style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 32),

          // Gender
          Text('Jenis kelamin', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(children: [
            _GenderChip(label: 'Laki-laki', value: 'male',
              selected: gender == 'male', onTap: () => onGenderChanged('male')),
            const SizedBox(width: 12),
            _GenderChip(label: 'Perempuan', value: 'female',
              selected: gender == 'female', onTap: () => onGenderChanged('female')),
          ]),
          const SizedBox(height: 24),

          // Usia
          Text('Usia', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Slider(
              value:  age.toDouble(),
              min:    4, max: 99, divisions: 95,
              activeColor: AppColors.primary,
              onChanged: (v) => onAgeChanged(v.round()),
            )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('$age th',
                style: Theme.of(context).textTheme.titleMedium),
            ),
          ]),
          const SizedBox(height: 24),

          // Kondisi khusus (hanya perempuan)
          if (gender == 'female') ...[
            Text('Kondisi khusus', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...[
              ('none', 'Tidak ada'),
              ('pregnant', 'Sedang hamil 🤰'),
              ('breastfeeding', 'Sedang menyusui 🤱'),
            ].map((e) => RadioListTile<String>(
              value:    e.$1,
              groupValue: condition,
              title: Text(e.$2),
              activeColor: AppColors.primary,
              onChanged: (v) => onConditionChanged(v!),
            )),
            const SizedBox(height: 16),
          ],

          Row(children: [
            TextButton(onPressed: onBack, child: const Text('← Kembali')),
            const Spacer(),
            ElevatedButton(onPressed: onNext, child: const Text('Lanjut →')),
          ]),
        ],
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label, value;
  final bool   selected;
  final VoidCallback onTap;
  const _GenderChip({required this.label, required this.value,
    required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color:  selected ? AppColors.primary : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.primaryLight,
            width: 2,
          ),
        ),
        child: Text(label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          )),
      ),
    );
  }
}

// ── Page 4: Target air ────────────────────────────────────────
class _TargetPage extends StatelessWidget {
  final int    calculatedTarget;
  final bool   useCustom;
  final TextEditingController customCtrl;
  final ValueChanged<bool> onToggleCustom;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final int    minimumMl;

  const _TargetPage({
    required this.calculatedTarget, required this.useCustom,
    required this.customCtrl, required this.onToggleCustom,
    required this.onNext, required this.onBack, required this.minimumMl,
  });

  @override
  Widget build(BuildContext context) {
    final glasses = (calculatedTarget / AppConstants.glassMl).ceil();
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎯', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('Target air harianmu',
            style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Berdasarkan panduan WHO & IOM',
            style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primaryLight),
            ),
            child: Column(children: [
              Text('$calculatedTarget ml',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppColors.primary, fontSize: 40,
                )),
              Text('± $glasses gelas per hari',
                style: Theme.of(context).textTheme.bodyLarge),
            ]),
          ),
          const SizedBox(height: 16),

          Text(
            '⚠️ Angka ini berdasarkan panduan WHO & IOM. '
            'Konsultasikan dengan dokter jika punya kondisi kesehatan tertentu.',
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          SwitchListTile(
            value:   useCustom,
            onChanged: onToggleCustom,
            title: const Text('Atur manual'),
            activeColor: AppColors.primary,
          ),
          if (useCustom) ...[
            TextField(
              controller: customCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Target custom (ml)',
                helperText: 'Minimum $minimumMl ml',
                suffixText: 'ml',
              ),
            ),
          ],
          const SizedBox(height: 32),

          Row(children: [
            TextButton(onPressed: onBack, child: const Text('← Kembali')),
            const Spacer(),
            ElevatedButton(onPressed: onNext, child: const Text('Pakai ini ✓')),
          ]),
        ],
      ),
    );
  }
}

// ── Page 5: Welcome ───────────────────────────────────────────
class _WelcomePage extends StatelessWidget {
  final String       name;
  final VoidCallback onFinish;
  const _WelcomePage({required this.name, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌱', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 24),
          Text('Selamat datang, $name!',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            'Biji tanaman kecilmu sudah menunggu~\n'
            'Ayo mulai perjalanan hidup sehat bersama CaiHeurang! 💧',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: onFinish,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              child: const Text('Yuk Mulai! 🚀', style: TextStyle(fontSize: 18)),
            )),
        ],
      ),
    );
  }
}