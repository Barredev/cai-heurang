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

  bool get remindersEnabled =>
      _settings.get(AppConstants.keyRemindersEnabled, defaultValue: true);
  void setRemindersEnabled(bool enabled) =>
      _settings.put(AppConstants.keyRemindersEnabled, enabled);

  int get reminderIntervalHours =>
      _settings.get(AppConstants.keyReminderIntervalHours, defaultValue: 2);
  void setReminderIntervalHours(int hours) =>
      _settings.put(AppConstants.keyReminderIntervalHours, hours.clamp(1, 6));

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
    if (id == null) return null;
    final p = _profiles.get(id);
    return p != null ? _cloneProfile(p) : null;
  }

  List<ProfileModel> getAllProfiles() {
    final list = _profiles.values.map(_cloneProfile).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future<ProfileModel?> switchProfile(String profileId, {DateTime? now}) async {
    if (!_profiles.containsKey(profileId)) return null;
    setActiveProfileId(profileId);
    await processStreakOnOpen(profileId, now: now);
    return getActiveProfile();
  }

  /// Hapus profil anggota keluarga beserta seluruh datanya.
  /// Mengembalikan false jika hanya tersisa 1 profil.
  Future<bool> deleteProfile(String profileId) async {
    if (_profiles.length <= 1 || !_profiles.containsKey(profileId)) {
      return false;
    }

    await _profiles.delete(profileId);

    // Bersihkan semua data terkait profil tersebut
    final waterKeys = _water.values
        .where((l) => l.profileId == profileId)
        .map((l) => l.id)
        .toList();
    if (waterKeys.isNotEmpty) await _water.deleteAll(waterKeys);

    final sweetKeys = _sweet.values
        .where((l) => l.profileId == profileId)
        .map((l) => l.id)
        .toList();
    if (sweetKeys.isNotEmpty) await _sweet.deleteAll(sweetKeys);

    final streakKeys = _streaks.values
        .where((s) => s.profileId == profileId)
        .map((s) => s.id)
        .toList();
    if (streakKeys.isNotEmpty) await _streaks.deleteAll(streakKeys);

    final summaryKeys = _summaries.values
        .where((s) => s.profileId == profileId)
        .map((s) => s.id)
        .toList();
    if (summaryKeys.isNotEmpty) await _summaries.deleteAll(summaryKeys);

    // Jika yang dihapus adalah profil aktif, pindah ke profil pertama yang tersisa
    if (activeProfileId == profileId) {
      final remaining = getAllProfiles();
      if (remaining.isNotEmpty) {
        setActiveProfileId(remaining.first.id);
      }
    }

    return true;
  }

  Future<void> saveProfile(ProfileModel p) => _profiles.put(p.id, _cloneProfile(p));

  // ════════════════════════════════════════════════════════════
  // WATER LOG
  // ════════════════════════════════════════════════════════════

  /// Mencatat +1 gelas. Mengembalikan status target tercapai, level naik, & milestone streak.
  Future<({bool targetReached, bool leveledUp, int? milestoneDays})> logWater({DateTime? now}) async {
    final profile = getActiveProfile();
    if (profile == null) {
      return (targetReached: false, leveledUp: false, milestoneDays: null);
    }

    final dt      = now ?? DateTime.now();
    final session = AppConstants.sessionType(dt);

    // Pastikan record streak hari ini sudah ada
    final todayStreak = await processStreakOnOpen(profile.id, now: dt);

    // Cek apakah ini gelas pertama hari ini (untuk recovery bonus 1x/hari)
    final isFirstGlassToday = getTodayWaterLogs(profile.id, now: dt).isEmpty;

    // Hitung XP
    int xp = AppConstants.xpPerGlass;
    if (session != 'normal') xp += AppConstants.xpGoldenHourBonus;

    // Cek recovery bonus (kemarin absen tanpa shield — hanya 1x di gelas pertama)
    final yesterday = _dateStr(dt.subtract(const Duration(days: 1)));
    final yKey      = '${profile.id}_$yesterday';
    final yStreak   = _streaks.get(yKey);
    final isRecovery = isFirstGlassToday &&
        yStreak != null &&
        !yStreak.targetReached &&
        !yStreak.shieldUsedToday;
    if (isRecovery) {
      xp += AppConstants.xpRecovery;
    }

    final log = WaterLogModel(
      id:          _uuid.v4(),
      profileId:   profile.id,
      timestamp:   dt.toIso8601String(),
      xpEarned:    xp,
      sessionType: isRecovery && session == 'normal' ? 'recovery' : session,
    );
    await _water.put(log.id, log);

    // Update XP & level profil
    final oldLevel       = profile.currentLevel;
    profile.totalXp     += xp;
    profile.currentLevel = AppConstants.calculateLevel(profile.totalXp);

    // Update daily summary
    final summary = _getOrCreateSummary(profile.id, dt);
    summary.totalMl    += AppConstants.glassMl;
    summary.totalXpDay += xp;
    await _summaries.put(summary.id, summary);

    // Cek target harian — hanya dipicu sekali per hari berdasarkan streak.targetReached
    bool targetReached = false;
    int? milestoneDays;
    if (summary.totalMl >= profile.targetMl && !todayStreak.targetReached) {
      targetReached = true;
      todayStreak.targetReached = true;
      todayStreak.currentStreak += 1;
      if (todayStreak.currentStreak > todayStreak.longestStreak) {
        todayStreak.longestStreak = todayStreak.currentStreak;
      }

      // Bonus XP daily complete
      int bonusXp = AppConstants.xpDailyComplete;

      // Cek bonus milestone streak (3, 7, 14, 30 hari)
      final milestoneXp = AppConstants.streakMilestoneXp[todayStreak.currentStreak];
      if (milestoneXp != null) {
        bonusXp += milestoneXp;
        milestoneDays = todayStreak.currentStreak;
      }

      // Cek dapat shield baru tiap kelipatan 7 hari
      if (todayStreak.currentStreak > 0 &&
          todayStreak.currentStreak % AppConstants.shieldEveryNDays == 0) {
        todayStreak.shieldsAvailable =
            (todayStreak.shieldsAvailable + 1).clamp(0, AppConstants.maxShields);
      }

      await _streaks.put(todayStreak.id, todayStreak);

      profile.totalXp     += bonusXp;
      profile.currentLevel = AppConstants.calculateLevel(profile.totalXp);
      summary.totalXpDay  += bonusXp;
      await _summaries.put(summary.id, summary);
    }

    await saveProfile(profile);

    return (
      targetReached: targetReached,
      leveledUp:     profile.currentLevel > oldLevel,
      milestoneDays: milestoneDays,
    );
  }

  /// Hapus / undo satu catatan air minum
  Future<bool> deleteWaterLog(String logId) async {
    final log = _water.get(logId);
    if (log == null) return false;

    await _water.delete(logId);

    final logDt   = DateTime.parse(log.timestamp);
    final summary = _getOrCreateSummary(log.profileId, logDt);
    summary.totalMl    = (summary.totalMl - log.glassCount * AppConstants.glassMl).clamp(0, 1000000);
    summary.totalXpDay = (summary.totalXpDay - log.xpEarned).clamp(0, 10000000);
    await _summaries.put(summary.id, summary);

    final existingProfile = _profiles.get(log.profileId);
    if (existingProfile != null) {
      final profile        = _cloneProfile(existingProfile);
      profile.totalXp      = (profile.totalXp - log.xpEarned).clamp(0, 100000000);
      profile.currentLevel = AppConstants.calculateLevel(profile.totalXp);
      await saveProfile(profile);
    }

    return true;
  }

  List<WaterLogModel> getTodayWaterLogs(String profileId, {DateTime? now}) {
    final today = _dateStr(now ?? DateTime.now());
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

  int getTodayTotalMl(String profileId, {DateTime? now}) =>
      _getOrCreateSummary(profileId, now ?? DateTime.now()).totalMl;

  // ════════════════════════════════════════════════════════════
  // SWEET LOG
  // ════════════════════════════════════════════════════════════

  Future<SweetLogModel> logSweetDrink({
    required String profileId,
    required String drinkType,
    String? drinkName,
    DateTime? now,
  }) async {
    final profile  = _profiles.get(profileId) ?? getActiveProfile();
    final sugarG   = AppConstants.sugarEstimateG[drinkType]; // null jika 'other'
    final dt       = now ?? DateTime.now();

    // Tentukan warning level
    int warningLevel = 0;
    if (sugarG != null && profile != null) {
      final summary      = _getOrCreateSummary(profileId, dt);
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
      timestamp:        dt.toIso8601String(),
      drinkType:        drinkType,
      drinkName:        drinkName,
      estimatedSugarG:  sugarG,
      warningLevel:     warningLevel,
    );
    await _sweet.put(log.id, log);

    // Update daily summary
    if (sugarG != null) {
      final summary = _getOrCreateSummary(profileId, dt);
      summary.sugarG += sugarG;
      await _summaries.put(summary.id, summary);
    }

    return log;
  }

  /// Hapus / undo satu catatan minuman manis
  Future<bool> deleteSweetLog(String logId) async {
    final log = _sweet.get(logId);
    if (log == null) return false;

    await _sweet.delete(logId);

    if (log.estimatedSugarG != null) {
      final logDt   = DateTime.parse(log.timestamp);
      final summary = _getOrCreateSummary(log.profileId, logDt);
      summary.sugarG = (summary.sugarG - log.estimatedSugarG!).clamp(0.0, 10000.0);
      await _summaries.put(summary.id, summary);
    }

    return true;
  }

  List<SweetLogModel> getTodaySweetLogs(String profileId, {DateTime? now}) {
    final today = _dateStr(now ?? DateTime.now());
    return _sweet.values
        .where((l) => l.profileId == profileId && l.timestamp.startsWith(today))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  double getTodaySugarG(String profileId, {DateTime? now}) =>
      _getOrCreateSummary(profileId, now ?? DateTime.now()).sugarG;

  // ════════════════════════════════════════════════════════════
  // STREAK
  // ════════════════════════════════════════════════════════════

  /// Dipanggil sekali saat app dibuka (atau saat log pertama hari ini).
  /// Mempertahankan longestStreak walau absen > 1 hari dan menangani shield.
  Future<StreakModel> processStreakOnOpen(String profileId, {DateTime? now}) async {
    final dt       = now ?? DateTime.now();
    final today    = _dateStr(dt);
    final todayKey = '${profileId}_$today';

    // Sudah diproses hari ini
    if (_streaks.containsKey(todayKey)) {
      return _cloneStreak(_streaks.get(todayKey)!);
    }

    // Ambil seluruh riwayat streak sebelum hari ini untuk menjaga longestStreak
    final pastStreaks = _streaks.values
        .where((s) => s.profileId == profileId && s.date.compareTo(today) < 0)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    int longestStreak = 0;
    for (final s in pastStreaks) {
      if (s.longestStreak > longestStreak) longestStreak = s.longestStreak;
      if (s.currentStreak > longestStreak) longestStreak = s.currentStreak;
    }

    final lastStreak = pastStreaks.isNotEmpty ? pastStreaks.first : null;
    int  currentStreak = 0;
    int  shields       = lastStreak?.shieldsAvailable ?? 0;
    bool shieldUsed    = false;

    if (lastStreak != null) {
      final lastDt  = DateTime.parse(lastStreak.date);
      final todayDt = DateTime(dt.year, dt.month, dt.day);
      final diffDays = todayDt
          .difference(DateTime(lastDt.year, lastDt.month, lastDt.day))
          .inDays;

      // Kompatibilitas data lama (jika targetReached == true tapi currentStreak belum sempat ditambah)
      final effectiveLastStreak =
          (lastStreak.targetReached && lastStreak.currentStreak == 0)
              ? 1
              : lastStreak.currentStreak;
      if (effectiveLastStreak > longestStreak) {
        longestStreak = effectiveLastStreak;
      }

      final missedDays = lastStreak.targetReached ? diffDays - 1 : diffDays;

      if (missedDays <= 0) {
        currentStreak = effectiveLastStreak;
      } else if (effectiveLastStreak > 0 && shields >= missedDays) {
        shields      -= missedDays;
        shieldUsed    = true;
        currentStreak = effectiveLastStreak;
      } else {
        currentStreak = 0;
      }
    }

    final todayStreak = StreakModel(
      id:               todayKey,
      profileId:        profileId,
      date:             today,
      targetReached:    false,
      shieldsAvailable: shields,
      shieldUsedToday:  shieldUsed,
      currentStreak:    currentStreak,
      longestStreak:    longestStreak,
    );
    await _streaks.put(todayKey, todayStreak);
    return _cloneStreak(todayStreak);
  }

  StreakModel? getTodayStreak(String profileId, {DateTime? now}) {
    final s = _streaks.get('${profileId}_${_dateStr(now ?? DateTime.now())}');
    return s != null ? _cloneStreak(s) : null;
  }

  // ════════════════════════════════════════════════════════════
  // DAILY SUMMARY
  // ════════════════════════════════════════════════════════════

  DailySummaryModel _getOrCreateSummary(String profileId, DateTime dt) {
    final key = '${profileId}_${_dateStr(dt)}';
    final existing = _summaries.get(key);
    if (existing != null) return _cloneSummary(existing);
    return DailySummaryModel(
      id:            key,
      profileId:     profileId,
      date:          _dateStr(dt),
      lastResetDate: _dateStr(dt),
    );
  }

  List<DailySummaryModel> getWeeklySummaries(String profileId, {DateTime? now}) {
    final base   = now ?? DateTime.now();
    final result = <DailySummaryModel>[];
    for (int i = 0; i < 7; i++) {
      final dt  = base.subtract(Duration(days: i));
      final key = '${profileId}_${_dateStr(dt)}';
      final s   = _summaries.get(key);
      if (s != null) result.add(_cloneSummary(s));
    }
    return result;
  }

  int calculateWeeklyScore(String profileId, {DateTime? now}) {
    final profile = _profiles.get(profileId) ?? getActiveProfile();
    if (profile == null) return 0;
    return getWeeklySummaries(profileId, now: now)
        .where((s) => s.totalMl >= profile.targetMl)
        .length;
  }

  Future<void> markCertificateShared(String profileId, {DateTime? now}) async {
    final key = '${profileId}_${_dateStr(now ?? DateTime.now())}';
    final s   = _summaries.get(key);
    if (s != null) {
      final updated = _cloneSummary(s)..certificateShared = true;
      await _summaries.put(key, updated);
    }
  }

  // ════════════════════════════════════════════════════════════
  // DAILY RESET — via app-open check (bukan workmanager)
  // ════════════════════════════════════════════════════════════

  Future<({bool didReset, StreakModel? todayStreak})> checkAndResetDaily({
    DateTime? now,
  }) async {
    final dt        = now ?? DateTime.now();
    final today     = _dateStr(dt);
    final profileId = activeProfileId;
    if (lastResetDate == today || profileId == null) {
      return (didReset: false, todayStreak: null);
    }

    setLastResetDate(today);

    // Proses streak harian untuk seluruh profil keluarga
    StreakModel? activeStreak;
    for (final p in _profiles.values) {
      final s = await processStreakOnOpen(p.id, now: dt);
      if (p.id == profileId) {
        activeStreak = s;
      }
    }
    return (didReset: true, todayStreak: activeStreak);
  }

  // ════════════════════════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════════════════════════

  ProfileModel _cloneProfile(ProfileModel p) => ProfileModel(
    id:           p.id,
    name:         p.name,
    gender:       p.gender,
    age:          p.age,
    condition:    p.condition,
    targetMl:     p.targetMl,
    totalXp:      p.totalXp,
    currentLevel: p.currentLevel,
    createdAt:    p.createdAt,
  );

  StreakModel _cloneStreak(StreakModel s) => StreakModel(
    id:               s.id,
    profileId:        s.profileId,
    date:             s.date,
    targetReached:    s.targetReached,
    shieldsAvailable: s.shieldsAvailable,
    shieldUsedToday:  s.shieldUsedToday,
    currentStreak:    s.currentStreak,
    longestStreak:    s.longestStreak,
  );

  DailySummaryModel _cloneSummary(DailySummaryModel s) => DailySummaryModel(
    id:                s.id,
    profileId:         s.profileId,
    date:              s.date,
    totalMl:           s.totalMl,
    totalXpDay:        s.totalXpDay,
    weeklyScore:       s.weeklyScore,
    sugarG:            s.sugarG,
    certificateShared: s.certificateShared,
    lastResetDate:     s.lastResetDate,
  );

  String _dateStr(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}