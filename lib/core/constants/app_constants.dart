// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  // ────────────────────────────────────────────────────────────
  // HIVE BOX NAMES
  // ────────────────────────────────────────────────────────────
  static const String boxProfiles       = 'profiles';
  static const String boxWaterLogs      = 'water_logs';
  static const String boxSweetLogs      = 'sweet_logs';
  static const String boxStreaks         = 'streaks';
  static const String boxDailySummaries = 'daily_summaries';
  static const String boxSettings       = 'settings';

  // ────────────────────────────────────────────────────────────
  // SETTINGS KEYS
  // ────────────────────────────────────────────────────────────
  static const String keyIsOnboarded           = 'is_onboarded';
  static const String keyActiveProfileId       = 'active_profile_id';
  static const String keyLastResetDate         = 'last_reset_date';
  static const String keyRemindersEnabled      = 'reminders_enabled';
  static const String keyReminderIntervalHours = 'reminder_interval_hours';

  // ────────────────────────────────────────────────────────────
  // XP SISTEM
  // ────────────────────────────────────────────────────────────
  static const int xpPerGlass          = 10;
  static const int xpGoldenHourBonus   = 5;
  static const int xpDailyComplete     = 25;
  static const int xpStreakStart       = 5;
  static const int xpRecovery          = 20;

  // ────────────────────────────────────────────────────────────
  // LEVEL THRESHOLDS (index 0 = level 1)
  // ────────────────────────────────────────────────────────────
  static const List<int> levelThresholds = [
    0,      // Level 1 - Biji
    200,    // Level 2 - Tunas
    600,    // Level 3 - Kuncup
    1500,   // Level 4 - Kuncup Besar
    3000,   // Level 5 - Bunga Mekar
    6000,   // Level 6 - Pohon Muda
    12000,  // Level 7 - Pohon Rindang
  ];

  static const List<String> plantPhaseNames = [
    'Biji',
    'Tunas',
    'Kuncup',
    'Kuncup Besar',
    'Bunga Mekar',
    'Pohon Muda',
    'Pohon Rindang',
  ];

  static String plantEmoji(int level) => switch (level) {
    1 => '🌰',
    2 => '🌱',
    3 => '🌿',
    4 => '🪴',
    5 => '🌸',
    6 => '🌳',
    _ => '🌲',
  };

  // Level 1–7, dihitung dari totalXp
  static int calculateLevel(int totalXp) {
    for (int i = levelThresholds.length - 1; i >= 0; i--) {
      if (totalXp >= levelThresholds[i]) return i + 1;
    }
    return 1;
  }

  static int xpToNextLevel(int totalXp, int currentLevel) {
    if (currentLevel >= levelThresholds.length) return 0;
    return levelThresholds[currentLevel] - totalXp;
  }

  static double levelProgress(int totalXp, int currentLevel) {
    if (currentLevel >= levelThresholds.length) return 1.0;
    final current = levelThresholds[currentLevel - 1];
    final next    = levelThresholds[currentLevel];
    return ((totalXp - current) / (next - current)).clamp(0.0, 1.0);
  }

  // ────────────────────────────────────────────────────────────
  // STREAK MILESTONES
  // ────────────────────────────────────────────────────────────
  static const Map<int, int> streakMilestoneXp = {
    3:  50,
    7:  150,
    14: 350,
    30: 800,
  };

  static const Map<int, String> streakMilestoneName = {
    3:  'Pemula Rajin 🥉',
    7:  'Si Konsisten 🥈',
    14: 'Jagoan Air 🥇',
    30: 'Legenda Keluarga 👑',
  };

  static const int shieldEveryNDays = 7;
  static const int maxShields       = 3;

  // ────────────────────────────────────────────────────────────
  // GOLDEN HOUR (jam mulai inklusif, jam selesai eksklusif)
  // ────────────────────────────────────────────────────────────
  static const List<List<int>> goldenHours = [
    [6, 9],    // pagi
    [12, 13],  // siang
    [16, 18],  // sore
  ];

  static String sessionType(DateTime dt) {
    final h = dt.hour;
    if (h >= 6  && h < 9)  return 'golden_morning';
    if (h >= 12 && h < 13) return 'golden_noon';
    if (h >= 16 && h < 18) return 'golden_eve';
    return 'normal';
  }

  // ────────────────────────────────────────────────────────────
  // MINUMAN MANIS
  // ────────────────────────────────────────────────────────────

  // Estimasi gula (gram) per sajian – rata-rata
  static const Map<String, double> sugarEstimateG = {
    'tea':            17.0,
    'coffee':         12.0,
    'packaged':       24.0,
    'juice':          22.0,
    'energy':         15.0,
    'condensed_milk': 12.0,
  };

  static const Map<String, String> drinkLabel = {
    'tea':            'Es teh manis',
    'coffee':         'Kopi manis',
    'packaged':       'Minuman kemasan',
    'juice':          'Jus buah',
    'energy':         'Minuman energi',
    'condensed_milk': 'Susu kental manis',
    'other':          'Minuman lain',
  };

  static const Map<String, String> drinkEmoji = {
    'tea':            '🍵',
    'coffee':         '☕',
    'packaged':       '🥤',
    'juice':          '🍊',
    'energy':         '⚡',
    'condensed_milk': '🥛',
    'other':          '🫗',
  };

  // Batas gula harian (gram) berdasarkan usia – WHO
  static double sugarLimitG(int age) {
    if (age <= 6)  return 19.0;
    if (age <= 10) return 24.0;
    return 25.0;
  }

  // ────────────────────────────────────────────────────────────
  // TARGET AIR (ml) – WHO / IOM
  // ────────────────────────────────────────────────────────────
  static int minimumWaterMl({
    required String gender,
    required int age,
    required String condition,
  }) {
    if (condition == 'breastfeeding') return 2160;
    if (condition == 'pregnant')      return 1840;
    if (age <= 8)  return 960;
    if (age <= 13) return 1280;
    if (age <= 18) return 1520;
    if (age >= 60) return 1600;
    return gender == 'male' ? 2000 : 1600;
  }

  static const int glassMl = 250;

  // ────────────────────────────────────────────────────────────
  // NOTIFIKASI
  // ────────────────────────────────────────────────────────────
  static const int quietHourStart = 22; // tidak notif 22:00 – 06:00
  static const int quietHourEnd   = 6;

  // ────────────────────────────────────────────────────────────
  // WEEKLY SCORE
  // ────────────────────────────────────────────────────────────
  static String weeklyScoreLabel(int score) {
    if (score == 7) return 'Sempurna! ⭐⭐⭐';
    if (score >= 5) return 'Luar Biasa ⭐⭐';
    if (score >= 3) return 'Lumayan Nih ⭐';
    return 'Ayo semangat minggu depan!';
  }
}