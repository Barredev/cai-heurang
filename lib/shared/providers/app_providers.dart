// lib/shared/providers/app_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/app_repository.dart';
import '../../data/models/profile_model.dart';
import '../../data/models/water_log_model.dart';
import '../../data/models/sweet_log_model.dart';
import '../../data/models/streak_model.dart';
import '../../core/constants/app_constants.dart';

// ────────────────────────────────────────────────────────────
// REPOSITORY
// ────────────────────────────────────────────────────────────

final repoProvider = Provider<AppRepository>((_) => AppRepository());

// ────────────────────────────────────────────────────────────
// ACTIVE PROFILE
// ────────────────────────────────────────────────────────────

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileModel?>((ref) {
  return ProfileNotifier(ref.read(repoProvider));
});

class ProfileNotifier extends StateNotifier<ProfileModel?> {
  final AppRepository _repo;
  ProfileNotifier(this._repo) : super(_repo.getActiveProfile());

  void reload() => state = _repo.getActiveProfile();

  Future<void> create({
    required String name,
    required String gender,
    required int    age,
    required String condition,
    required int    targetMl,
  }) async {
    final p = await _repo.createProfile(
      name: name, gender: gender, age: age,
      condition: condition, targetMl: targetMl,
    );
    _repo.setOnboarded();
    state = p;
  }

  Future<void> updateTargetMl(int newMl) async {
    final p = state;
    if (p == null) return;
    p.targetMl = newMl;
    await _repo.saveProfile(p);
    state = p;
  }

  Future<void> updateName(String name) async {
    final p = state;
    if (p == null) return;
    p.name = name;
    await _repo.saveProfile(p);
    state = p;
  }
}

// ────────────────────────────────────────────────────────────
// DAILY WATER
// ────────────────────────────────────────────────────────────

class DailyWaterState {
  final int               totalMl;
  final int               targetMl;
  final List<WaterLogModel> recentLogs;
  final bool              targetReachedThisLog;
  final bool              leveledUpThisLog;

  const DailyWaterState({
    this.totalMl              = 0,
    this.targetMl             = 2000,
    this.recentLogs           = const [],
    this.targetReachedThisLog = false,
    this.leveledUpThisLog     = false,
  });

  double get progress     => targetMl > 0 ? (totalMl / targetMl).clamp(0.0, 1.0) : 0;
  int    get remainingMl  => (targetMl - totalMl).clamp(0, targetMl);
  int    get glassLogged  => totalMl ~/ AppConstants.glassMl;

  DailyWaterState copyWith({
    int?               totalMl,
    int?               targetMl,
    List<WaterLogModel>? recentLogs,
    bool?              targetReachedThisLog,
    bool?              leveledUpThisLog,
  }) => DailyWaterState(
    totalMl:              totalMl              ?? this.totalMl,
    targetMl:             targetMl             ?? this.targetMl,
    recentLogs:           recentLogs           ?? this.recentLogs,
    targetReachedThisLog: targetReachedThisLog ?? this.targetReachedThisLog,
    leveledUpThisLog:     leveledUpThisLog     ?? this.leveledUpThisLog,
  );
}

final dailyWaterProvider =
    StateNotifierProvider<DailyWaterNotifier, DailyWaterState>((ref) {
  final repo    = ref.read(repoProvider);
  final profile = ref.read(profileProvider);
  return DailyWaterNotifier(repo, profile?.id ?? '', profile?.targetMl ?? 2000);
});

class DailyWaterNotifier extends StateNotifier<DailyWaterState> {
  final AppRepository _repo;
  final String        _profileId;

  DailyWaterNotifier(this._repo, this._profileId, int targetMl)
      : super(DailyWaterState(targetMl: targetMl)) {
    _load();
  }

  void _load() {
    final profile = _repo.getActiveProfile();
    if (profile == null) return;
    state = state.copyWith(
      totalMl:    _repo.getTodayTotalMl(_profileId),
      targetMl:   profile.targetMl,
      recentLogs: _repo.getTodayWaterLogs(_profileId),
    );
  }

  Future<void> log() async {
    final result = await _repo.logWater();
    _load();
    state = state.copyWith(
      targetReachedThisLog: result.targetReached,
      leveledUpThisLog:     result.leveledUp,
    );
  }

  void clearFlags() => state = state.copyWith(
    targetReachedThisLog: false,
    leveledUpThisLog:     false,
  );
}

// ────────────────────────────────────────────────────────────
// SWEET DRINK
// ────────────────────────────────────────────────────────────

class SweetState {
  final double             todaySugarG;
  final double             sugarLimit;
  final int                pendingWarningLevel; // 0 = tidak ada dialog
  final List<SweetLogModel> todayLogs;

  const SweetState({
    this.todaySugarG         = 0,
    this.sugarLimit          = 25,
    this.pendingWarningLevel = 0,
    this.todayLogs           = const [],
  });

  double get sugarPercent => sugarLimit > 0
      ? (todaySugarG / sugarLimit).clamp(0.0, 1.5)
      : 0;

  SweetState copyWith({
    double?             todaySugarG,
    double?             sugarLimit,
    int?                pendingWarningLevel,
    List<SweetLogModel>? todayLogs,
  }) => SweetState(
    todaySugarG:         todaySugarG         ?? this.todaySugarG,
    sugarLimit:          sugarLimit          ?? this.sugarLimit,
    pendingWarningLevel: pendingWarningLevel ?? this.pendingWarningLevel,
    todayLogs:           todayLogs          ?? this.todayLogs,
  );
}

final sweetProvider =
    StateNotifierProvider<SweetNotifier, SweetState>((ref) {
  final repo    = ref.read(repoProvider);
  final profile = ref.read(profileProvider);
  return SweetNotifier(repo, profile?.id ?? '', profile?.age ?? 18);
});

class SweetNotifier extends StateNotifier<SweetState> {
  final AppRepository _repo;
  final String        _profileId;
  final int           _age;

  SweetNotifier(this._repo, this._profileId, this._age)
      : super(SweetState(sugarLimit: AppConstants.sugarLimitG(_age))) {
    _load();
  }

  void _load() => state = state.copyWith(
    todaySugarG: _repo.getTodaySugarG(_profileId),
    todayLogs:   _repo.getTodaySweetLogs(_profileId),
  );

  Future<void> log({required String drinkType, String? drinkName}) async {
    final result = await _repo.logSweetDrink(
      profileId: _profileId,
      drinkType: drinkType,
      drinkName: drinkName,
    );
    _load();
    state = state.copyWith(pendingWarningLevel: result.warningLevel);
  }

  void clearWarning() => state = state.copyWith(pendingWarningLevel: 0);
}

// ────────────────────────────────────────────────────────────
// STREAK
// ────────────────────────────────────────────────────────────

final streakProvider =
    StateNotifierProvider<StreakNotifier, StreakModel?>((ref) {
  final repo    = ref.read(repoProvider);
  final profile = ref.read(profileProvider);
  return StreakNotifier(repo, profile?.id ?? '');
});

class StreakNotifier extends StateNotifier<StreakModel?> {
  final AppRepository _repo;
  final String        _profileId;

  StreakNotifier(this._repo, this._profileId)
      : super(_repo.getTodayStreak(_profileId));

  Future<void> processOnOpen() async {
    state = await _repo.processStreakOnOpen(_profileId);
  }

  void reload() => state = _repo.getTodayStreak(_profileId);
}

// ────────────────────────────────────────────────────────────
// PLANT MOOD
// ────────────────────────────────────────────────────────────

enum PlantMood { celebrating, happy, normal, thirsty, sleeping }

final plantMoodProvider = Provider<PlantMood>((ref) {
  final water = ref.watch(dailyWaterProvider);
  final p     = water.progress;

  final last  = water.recentLogs.isNotEmpty ? water.recentLogs.first : null;
  final minsSinceLast = last != null
      ? DateTime.now().difference(DateTime.parse(last.timestamp)).inMinutes
      : 9999;

  if (p >= 1.0)                             return PlantMood.celebrating;
  if (p >= 0.75)                            return PlantMood.happy;
  if (p >= 0.25 && minsSinceLast <= 120)    return PlantMood.normal;
  if (p > 0     && minsSinceLast > 120)     return PlantMood.thirsty;
  if (p == 0    && minsSinceLast > 360)     return PlantMood.sleeping;
  return PlantMood.normal;
});

// ────────────────────────────────────────────────────────────
// GREETING
// ────────────────────────────────────────────────────────────

final greetingProvider = Provider<String>((ref) {
  final profile = ref.watch(profileProvider);
  final name    = profile?.name ?? '';
  final hour    = DateTime.now().hour;

  if (hour < 6)  return 'Tengah malem masih terjaga, $name? 🌙';
  if (hour < 11) return 'Wilujeng énjing, $name! ☀️';
  if (hour < 15) return 'Wilujeng siang, $name! 🌤️';
  if (hour < 19) return 'Wilujeng sonten, $name! 🌇';
  return 'Wilujeng wengi, $name! 🌙';
});