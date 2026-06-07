// lib/data/repositories/app_repository.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/profile_model.dart';
import '../models/water_log_model.dart';
import '../models/sweet_log_model.dart';
import '../models/streak_model.dart';
import '../models/daily_summary_model.dart';
import '../../core/constants/app_constants.dart';

class AppRepository {
  static const _uuid = Uuid();

  // ── Box getters ───────────────────────────────────────────
  Box<ProfileModel>      get _profiles  => Hive.box(AppConstants.boxProfiles);
  Box<WaterLogModel>     get _water     => Hive.box(AppConstants.boxWaterLogs);
  Box<SweetLogModel>     get _sweet     => Hive.box(AppConstants.boxSweetLogs);
  Box<StreakModel>        get _streaks   => Hive.box(AppConstants.boxStreaks);
  Box<DailySummaryModel> get _summaries => Hive.box(AppConstants.boxDailySummaries);
  Box                    get _settings  => Hive.box(AppConstants.boxSettings);

  // ════════════════════════════════════════════════════════════
  // SETTINGS
  // ════════════════════════════════════════════════════════════

  bool    get isOnboarded     => _settings.get(AppConstants.keyIsOnboarded, defaultValue: false);
  void    setOnboarded()      => _settings.put(AppConstants.keyIsOnboarded, true);

  String? get activeProfileId => _settings.get(AppConstants.keyActiveProfileId);
  void    setActiveProfileId(String id) => _settings.put(AppConstants.keyActiveProfileId, id);

  String  get lastResetDate   => _settings.get(AppConstants.keyLastResetDate, defaultValue: '');
  void    setLastResetDate(String d) => _settings.put(AppConstants.keyLastResetDate, d);

  // ════════════════════════════════════════════════════════════
  // PROFILE
  // ════════════════════════════════════════════════════════════

  Future<ProfileModel> createProfile({
    required String name,
    required String gender,
    required int    age,
    required String condition,
    required int    targetMl,
  }) async {
    final p = ProfileModel(
      id:           _uuid.v4(),
      name:         name,
      gender:       gender,
      age:          age,
      condition:    condition,
      targetMl:     targetMl,
      createdAt:    DateTime.now().toIso8601String(),
    );
    await _profiles.put(p.id, p);
    setActiveProfileId(p.id);
    return p;
  }

  ProfileModel? getActiveProfile() {
    final id = activeProfileId;
    return id != null ? _profiles.get(id) : null;
  }

  Future<void> saveProfile(ProfileModel p) => _profiles.put(p.id, p);

  // ════════════════════════════════════════════════════════════
  // WATER LOG
  // ════════════════════════════════════════════════════════════

  /// Mencatat +1 gelas. Mengembalikan apakah level naik.
  Future<({bool targetReached, bool leveledUp})> logWater() async {
    final profile = getActiveProfile();
    if (profile == null) return (targetReached: false, leveledUp: false);

    final now     = DateTime.now();
    final session = AppConstants.sessionType(now);

    // Hitung XP
    int xp = AppConstants.xpPerGlass;
    if (session != 'normal') xp += AppConstants.xpGoldenHourBonus;

    // Cek recovery bonus (kemarin skip)
    final yesterday = _dateStr(now.subtract(const Duration(days: 1)));
    final yKey      = '${profile.id}_$yesterday';
    final yStreak   = _streaks.get(yKey);
    if (yStreak != null && !yStreak.targetReached && !yStreak.shieldUsedToday) {
      xp += AppConstants.xpRecovery;
    }

    final log = WaterLogModel(
      id:          _uuid.v4(),
      profileId:   profile.id,
      timestamp:   now.toIso8601String(),
      xpEarned:    xp,
      sessionType: session,
    );
    await _water.put(log.id, log);

    // Update XP & level profil
    final oldLevel    = profile.currentLevel;
    profile.totalXp  += xp;
    profile.currentLevel = AppConstants.calculateLevel(profile.totalXp);
    await saveProfile(profile);

    // Update daily summary
    final summary = _getOrCreateSummary(profile.id, now);
    summary.totalMl    += AppConstants.glassMl;
    summary.totalXpDay += xp;
    await _summaries.put(summary.id, summary);

    // Cek target harian
    bool targetReached = false;
    if (summary.totalMl >= profile.targetMl && !summary.certificateShared) {
      targetReached = true;
      await _markTargetReachedOnStreak(profile.id, now);
      // Bonus XP daily complete
      profile.totalXp += AppConstants.xpDailyComplete;
      profile.currentLevel = AppConstants.calculateLevel(profile.totalXp);
      summary.totalXpDay  += AppConstants.xpDailyComplete;
      await saveProfile(profile);
      await _summaries.put(summary.id, summary);
    }

    return (
      targetReached: targetReached,
      leveledUp:     profile.currentLevel > oldLevel,
    );
  }

  List<WaterLogModel> getTodayWaterLogs(String profileId) {
    final today = _dateStr(DateTime.now());
    return _water.values
        .where((l) => l.profileId == profileId && l.timestamp.startsWith(today))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Gabungan water + sweet log 3 entri terbaru untuk mini history
  List<dynamic> getRecentMixedLogs(String profileId, {int limit = 3}) {
    final logs = <dynamic>[
      ..._water.values.where((l) => l.profileId == profileId),
      ..._sweet.values.where((l) => l.profileId == profileId),
    ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs.take(limit).toList();
  }

  int getTodayTotalMl(String profileId) =>
      _getOrCreateSummary(profileId, DateTime.now()).totalMl;

  // ════════════════════════════════════════════════════════════
  // SWEET LOG
  // ════════════════════════════════════════════════════════════

  Future<SweetLogModel> logSweetDrink({
    required String profileId,
    required String drinkType,
    String? drinkName,
  }) async {
    final profile  = getActiveProfile();
    final sugarG   = AppConstants.sugarEstimateG[drinkType]; // null jika 'other'
    final now      = DateTime.now();

    // Tentukan warning level
    int warningLevel = 0;
    if (sugarG != null && profile != null) {
      final summary      = _getOrCreateSummary(profileId, now);
      final currentSugar = summary.sugarG;
      final limit        = AppConstants.sugarLimitG(profile.age);
      final totalAfter   = currentSugar + sugarG;

      if (totalAfter >= limit && currentSugar < limit) {
        warningLevel = 2;
      } else if (totalAfter >= limit * 0.5 && currentSugar < limit * 0.5) {
        warningLevel = 1;
      }
    }

    final log = SweetLogModel(
      id:               _uuid.v4(),
      profileId:        profileId,
      timestamp:        now.toIso8601String(),
      drinkType:        drinkType,
      drinkName:        drinkName,
      estimatedSugarG:  sugarG,
      warningLevel:     warningLevel,
    );
    await _sweet.put(log.id, log);

    // Update daily summary
    if (sugarG != null) {
      final summary = _getOrCreateSummary(profileId, now);
      summary.sugarG += sugarG;
      await _summaries.put(summary.id, summary);
    }

    return log;
  }

  List<SweetLogModel> getTodaySweetLogs(String profileId) {
    final today = _dateStr(DateTime.now());
    return _sweet.values
        .where((l) => l.profileId == profileId && l.timestamp.startsWith(today))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  double getTodaySugarG(String profileId) =>
      _getOrCreateSummary(profileId, DateTime.now()).sugarG;

  // ════════════════════════════════════════════════════════════
  // STREAK
  // ════════════════════════════════════════════════════════════

  /// Dipanggil sekali saat app dibuka. Handles shield logic.
  Future<StreakModel> processStreakOnOpen(String profileId) async {
    final today     = _dateStr(DateTime.now());
    final yesterday = _dateStr(DateTime.now().subtract(const Duration(days: 1)));
    final todayKey  = '${profileId}_$today';
    final yKey      = '${profileId}_$yesterday';

    // Sudah diproses hari ini
    if (_streaks.containsKey(todayKey)) return _streaks.get(todayKey)!;

    final yStreak = _streaks.get(yKey);

    int  currentStreak  = yStreak?.currentStreak ?? 0;
    int  longestStreak  = yStreak?.longestStreak ?? 0;
    int  shields        = yStreak?.shieldsAvailable ?? 0;
    bool shieldUsed     = false;

    if (yStreak != null && !yStreak.targetReached) {
      if (shields > 0) {
        shields--;
        shieldUsed = true;
        // streak tidak putus
      } else {
        currentStreak = 0;
      }
    } else if (yStreak?.targetReached == true) {
      currentStreak++;
      // Cek milestone
      final bonus = AppConstants.streakMilestoneXp[currentStreak];
      if (bonus != null) {
        final profile = getActiveProfile();
        if (profile != null) {
          profile.totalXp     += bonus;
          profile.currentLevel = AppConstants.calculateLevel(profile.totalXp);
          await saveProfile(profile);
        }
      }
      // Cek dapat shield baru
      if (currentStreak % AppConstants.shieldEveryNDays == 0) {
        shields = (shields + 1).clamp(0, AppConstants.maxShields);
      }
    }

    if (currentStreak > longestStreak) longestStreak = currentStreak;

    final todayStreak = StreakModel(
      id:               todayKey,
      profileId:        profileId,
      date:             today,
      shieldsAvailable: shields,
      shieldUsedToday:  shieldUsed,
      currentStreak:    currentStreak,
      longestStreak:    longestStreak,
    );
    await _streaks.put(todayKey, todayStreak);
    return todayStreak;
  }

  StreakModel? getTodayStreak(String profileId) =>
      _streaks.get('${profileId}_${_dateStr(DateTime.now())}');

  Future<void> _markTargetReachedOnStreak(String profileId, DateTime dt) async {
    final key    = '${profileId}_${_dateStr(dt)}';
    final streak = _streaks.get(key);
    if (streak != null && !streak.targetReached) {
      streak.targetReached = true;
      await _streaks.put(key, streak);
    }
  }

  // ════════════════════════════════════════════════════════════
  // DAILY SUMMARY
  // ════════════════════════════════════════════════════════════

  DailySummaryModel _getOrCreateSummary(String profileId, DateTime dt) {
    final key = '${profileId}_${_dateStr(dt)}';
    return _summaries.get(key) ?? DailySummaryModel(
      id:            key,
      profileId:     profileId,
      date:          _dateStr(dt),
      lastResetDate: _dateStr(dt),
    );
  }

  List<DailySummaryModel> getWeeklySummaries(String profileId) {
    final result = <DailySummaryModel>[];
    for (int i = 0; i < 7; i++) {
      final dt  = DateTime.now().subtract(Duration(days: i));
      final key = '${profileId}_${_dateStr(dt)}';
      final s   = _summaries.get(key);
      if (s != null) result.add(s);
    }
    return result;
  }

  int calculateWeeklyScore(String profileId) {
    final profile = getActiveProfile();
    if (profile == null) return 0;
    return getWeeklySummaries(profileId)
        .where((s) => s.totalMl >= profile.targetMl)
        .length;
  }

  Future<void> markCertificateShared(String profileId) async {
    final key = '${profileId}_${_dateStr(DateTime.now())}';
    final s   = _summaries.get(key);
    if (s != null) {
      s.certificateShared = true;
      await _summaries.put(key, s);
    }
  }

  // ════════════════════════════════════════════════════════════
  // DAILY RESET — via app-open check (bukan workmanager)
  // ════════════════════════════════════════════════════════════

  Future<void> checkAndResetDaily() async {
    final today     = _dateStr(DateTime.now());
    final profileId = activeProfileId;
    if (lastResetDate == today || profileId == null) return;

    setLastResetDate(today);
    await processStreakOnOpen(profileId);
  }

  // ════════════════════════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════════════════════════

  String _dateStr(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}