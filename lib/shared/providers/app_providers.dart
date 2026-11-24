// lib/shared/providers/app_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/app_repository.dart';
import '../../data/models/profile_model.dart';
import '../../data/models/water_log_model.dart';
import '../../data/models/sweet_log_model.dart';
import '../../data/models/streak_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/notification_service.dart';

// ────────────────────────────────────────────────────────────
// REPOSITORY
// ────────────────────────────────────────────────────────────

final repoProvider = Provider<AppRepository>((_) => AppRepository());

// ────────────────────────────────────────────────────────────
// PROFILES LIST (MULTI-PROFIL KELUARGA)
// ────────────────────────────────────────────────────────────

final profilesListProvider =
    StateNotifierProvider<ProfilesListNotifier, List<ProfileModel>>((ref) {
  return ProfilesListNotifier(ref.read(repoProvider));
});

class ProfilesListNotifier extends StateNotifier<List<ProfileModel>> {
  final AppRepository _repo;
  ProfilesListNotifier(this._repo) : super(_repo.getAllProfiles());

  void reload() => state = _repo.getAllProfiles();
}

// ────────────────────────────────────────────────────────────
// ACTIVE PROFILE
// ────────────────────────────────────────────────────────────

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileModel?>((ref) {
  return ProfileNotifier(ref, ref.read(repoProvider));
});

class ProfileNotifier extends StateNotifier<ProfileModel?> {
  final Ref           _ref;
  final AppRepository _repo;
  ProfileNotifier(this._ref, this._repo) : super(_repo.getActiveProfile());

  void reload() {
    state = _repo.getActiveProfile();
    _ref.read(profilesListProvider.notifier).reload();
  }

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
    _ref.read(profilesListProvider.notifier).reload();
  }

  Future<void> addFamilyProfile({
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
    await _repo.processStreakOnOpen(p.id);
    state = _repo.getActiveProfile();
    _ref.read(profilesListProvider.notifier).reload();
    await _syncRemindersFor(state);
  }

  Future<void> switchProfile(String profileId) async {
    final switched = await _repo.switchProfile(profileId);
    if (switched == null) return;
    state = switched;
    _ref.read(profilesListProvider.notifier).reload();
    await _syncRemindersFor(switched);
  }

  Future<bool> deleteProfile(String profileId) async {
    final deleted = await _repo.deleteProfile(profileId);
    if (!deleted) return false;
    state = _repo.getActiveProfile();
    _ref.read(profilesListProvider.notifier).reload();
    await _syncRemindersFor(state);
    return true;
  }

  Future<void> updateTargetMl(int newMl) async {
    final p = _repo.getActiveProfile();
    if (p == null) return;
    p.targetMl = newMl;
    await _repo.saveProfile(p);
    state = _repo.getActiveProfile();
    _ref.read(profilesListProvider.notifier).reload();
  }

  Future<void> updateName(String name) async {
    final p = _repo.getActiveProfile();
    if (p == null) return;
    p.name = name;
    await _repo.saveProfile(p);
    state = _repo.getActiveProfile();
    _ref.read(profilesListProvider.notifier).reload();
  }

  Future<void> updateProfile({
    required String name,
    required int targetMl,
    required int age,
  }) async {
    final p = _repo.getActiveProfile();
    if (p == null) return;
    p.name     = name;
    p.targetMl = targetMl;
    p.age      = age;
    await _repo.saveProfile(p);
    final updated = _repo.getActiveProfile();
    state = updated;
    _ref.read(profilesListProvider.notifier).reload();
    await _syncRemindersFor(updated);
  }

  Future<void> _syncRemindersFor(ProfileModel? profile) async {
    if (profile != null && _repo.remindersEnabled) {
      final phase = AppConstants.plantPhaseNames[
          (profile.currentLevel - 1)
              .clamp(0, AppConstants.plantPhaseNames.length - 1)];
      await NotificationService.scheduleWaterReminders(
        profileName:    profile.name,
        plantPhaseName: phase,
        intervalHours:  _repo.reminderIntervalHours,
      );
    }
  }
}

// ────────────────────────────────────────────────────────────
// REMINDER SETTINGS
// ────────────────────────────────────────────────────────────

class ReminderSettingsState {
  final bool enabled;
  final int  intervalHours;

  const ReminderSettingsState({
    required this.enabled,
    required this.intervalHours,
  });

  ReminderSettingsState copyWith({
    bool? enabled,
    int?  intervalHours,
  }) => ReminderSettingsState(
    enabled:       enabled       ?? this.enabled,
    intervalHours: intervalHours ?? this.intervalHours,
  );
}

final reminderSettingsProvider =
    StateNotifierProvider<ReminderSettingsNotifier, ReminderSettingsState>((ref) {
  return ReminderSettingsNotifier(ref, ref.read(repoProvider));
});

class ReminderSettingsNotifier extends StateNotifier<ReminderSettingsState> {
  final Ref           _ref;
  final AppRepository _repo;

  ReminderSettingsNotifier(this._ref, this._repo)
      : super(ReminderSettingsState(
          enabled:       _repo.remindersEnabled,
          intervalHours: _repo.reminderIntervalHours,
        ));

  Future<void> setEnabled(bool enabled) async {
    _repo.setRemindersEnabled(enabled);
    state = state.copyWith(enabled: enabled);
    if (enabled) {
      await NotificationService.requestPermission();
      await syncSchedule();
    } else {
      await NotificationService.cancelAllWaterReminders();
    }
  }

  Future<void> setIntervalHours(int hours) async {
    final safe = hours.clamp(1, 6);
    _repo.setReminderIntervalHours(safe);
    state = state.copyWith(intervalHours: safe);
    if (state.enabled) {
      await syncSchedule();
    }
  }

  Future<void> syncSchedule() async {
    if (!state.enabled) {
      await NotificationService.cancelAllWaterReminders();
      return;
    }
    final profile = _ref.read(profileProvider) ?? _repo.getActiveProfile();
    if (profile == null) return;
    final phase = AppConstants.plantPhaseNames[
        (profile.currentLevel - 1).clamp(0, AppConstants.plantPhaseNames.length - 1)];
    await NotificationService.scheduleWaterReminders(
      profileName:    profile.name,
      plantPhaseName: phase,
      intervalHours:  state.intervalHours,
    );
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
  final repo      = ref.read(repoProvider);
  final profileId = ref.watch(profileProvider.select((p) => p?.id ?? ''));
  final profile   = ref.read(profileProvider);
  final notifier  = DailyWaterNotifier(
    ref,
    repo,
    profileId,
    profile?.targetMl ?? 2000,
  );

  ref.listen<int?>(
    profileProvider.select((p) => p?.targetMl),
    (_, nextTarget) {
      if (nextTarget != null) notifier.syncTarget(nextTarget);
    },
  );

  return notifier;
});

class DailyWaterNotifier extends StateNotifier<DailyWaterState> {
  final Ref           _ref;
  final AppRepository _repo;
  final String        _profileId;

  DailyWaterNotifier(this._ref, this._repo, this._profileId, int targetMl)
      : super(DailyWaterState(targetMl: targetMl)) {
    _load();
  }

  void _load() {
    if (_profileId.isEmpty) return;
    final profile = _repo.getActiveProfile();
    if (profile == null) return;
    state = state.copyWith(
      totalMl:    _repo.getTodayTotalMl(_profileId),
      targetMl:   profile.targetMl,
      recentLogs: _repo.getTodayWaterLogs(_profileId),
    );
  }

  void reload() => _load();

  void syncTarget(int targetMl) {
    if (!mounted) return;
    if (state.targetMl != targetMl) {
      state = state.copyWith(targetMl: targetMl);
    }
  }

  Future<void> log() async {
    final result = await _repo.logWater();
    _load();
    _ref.read(profileProvider.notifier).reload();
    _ref.read(streakProvider.notifier).reload();
    state = state.copyWith(
      targetReachedThisLog: result.targetReached,
      leveledUpThisLog:     result.leveledUp,
    );

    final profile = _ref.read(profileProvider);
    if (profile != null) {
      if (result.leveledUp) {
        final phase = AppConstants.plantPhaseNames[
            (profile.currentLevel - 1).clamp(0, AppConstants.plantPhaseNames.length - 1)];
        await NotificationService.showLevelUp(phase, profile.name);
        if (_repo.remindersEnabled) {
          await NotificationService.scheduleWaterReminders(
            profileName:    profile.name,
            plantPhaseName: phase,
            intervalHours:  _repo.reminderIntervalHours,
          );
        }
      }
      if (result.milestoneDays != null) {
        await NotificationService.showStreakMilestone(
          result.milestoneDays!,
          profile.name,
        );
      }
    }
  }

  Future<bool> deleteLog(String logId) async {
    final removed = await _repo.deleteWaterLog(logId);
    if (!removed) return false;
    _load();
    _ref.read(profileProvider.notifier).reload();
    _ref.read(streakProvider.notifier).reload();
    return true;
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
  final repo      = ref.read(repoProvider);
  final profileId = ref.watch(profileProvider.select((p) => p?.id ?? ''));
  final profile   = ref.read(profileProvider);
  final notifier  = SweetNotifier(repo, profileId, profile?.age ?? 18);

  ref.listen<int?>(
    profileProvider.select((p) => p?.age),
    (_, nextAge) {
      if (nextAge != null) notifier.syncAge(nextAge);
    },
  );

  return notifier;
});

class SweetNotifier extends StateNotifier<SweetState> {
  final AppRepository _repo;
  final String        _profileId;

  SweetNotifier(this._repo, this._profileId, int age)
      : super(SweetState(sugarLimit: AppConstants.sugarLimitG(age))) {
    _load();
  }

  void _load() {
    if (_profileId.isEmpty) return;
    state = state.copyWith(
      todaySugarG: _repo.getTodaySugarG(_profileId),
      todayLogs:   _repo.getTodaySweetLogs(_profileId),
    );
  }

  void reload() => _load();

  void syncAge(int age) {
    if (!mounted) return;
    final limit = AppConstants.sugarLimitG(age);
    if (state.sugarLimit != limit) {
      state = state.copyWith(sugarLimit: limit);
    }
  }

  Future<void> log({required String drinkType, String? drinkName}) async {
    if (_profileId.isEmpty) return;
    final result = await _repo.logSweetDrink(
      profileId: _profileId,
      drinkType: drinkType,
      drinkName: drinkName,
    );
    _load();
    state = state.copyWith(pendingWarningLevel: result.warningLevel);
  }

  Future<bool> deleteLog(String logId) async {
    final removed = await _repo.deleteSweetLog(logId);
    if (!removed) return false;
    _load();
    return true;
  }

  void clearWarning() => state = state.copyWith(pendingWarningLevel: 0);
}

// ────────────────────────────────────────────────────────────
// STREAK
// ────────────────────────────────────────────────────────────

final streakProvider =
    StateNotifierProvider<StreakNotifier, StreakModel?>((ref) {
  final repo      = ref.read(repoProvider);
  final profileId = ref.watch(profileProvider.select((p) => p?.id ?? ''));
  return StreakNotifier(repo, profileId);
});

class StreakNotifier extends StateNotifier<StreakModel?> {
  final AppRepository _repo;
  final String        _profileId;

  StreakNotifier(this._repo, this._profileId)
      : super(_profileId.isEmpty ? null : _repo.getTodayStreak(_profileId));

  Future<bool> processOnOpen() async {
    if (_profileId.isEmpty) return false;
    final alreadyProcessed = _repo.getTodayStreak(_profileId) != null;
    final streak = await _repo.processStreakOnOpen(_profileId);
    state = streak;

    final shieldJustUsed = !alreadyProcessed && streak.shieldUsedToday;
    if (shieldJustUsed) {
      final profile = _repo.getActiveProfile();
      if (profile != null) {
        await NotificationService.showShieldUsed(
          streak.shieldsAvailable,
          profile.name,
        );
      }
    }
    return shieldJustUsed;
  }

  void reload() {
    if (_profileId.isEmpty) return;
    state = _repo.getTodayStreak(_profileId);
  }
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