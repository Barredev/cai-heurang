import 'dart:io';

import 'package:caiheurang/core/constants/app_constants.dart';
import 'package:caiheurang/core/utils/achievement_share_service.dart';
import 'package:caiheurang/core/utils/notification_service.dart';
import 'package:caiheurang/data/models/daily_summary_model.dart';
import 'package:caiheurang/data/models/profile_model.dart';
import 'package:caiheurang/data/models/streak_model.dart';
import 'package:caiheurang/data/models/sweet_log_model.dart';
import 'package:caiheurang/data/models/water_log_model.dart';
import 'package:caiheurang/data/repositories/app_repository.dart';
import 'package:caiheurang/shared/providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  late Directory tempDir;
  late AppRepository repo;

  setUpAll(() async {
    await initializeDateFormatting('id');
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ProfileModelAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(WaterLogModelAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(SweetLogModelAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(StreakModelAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(DailySummaryModelAdapter());
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('caiheurang_test_');
    Hive.init(tempDir.path);
    await Future.wait([
      Hive.openBox<ProfileModel>(AppConstants.boxProfiles),
      Hive.openBox<WaterLogModel>(AppConstants.boxWaterLogs),
      Hive.openBox<SweetLogModel>(AppConstants.boxSweetLogs),
      Hive.openBox<StreakModel>(AppConstants.boxStreaks),
      Hive.openBox<DailySummaryModel>(AppConstants.boxDailySummaries),
      Hive.openBox(AppConstants.boxSettings),
    ]);
    repo = AppRepository();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Indonesian date formatting works after initialization', () {
    final formatted = DateFormat('EEE, d MMM', 'id').format(DateTime(2026, 5, 15));
    expect(formatted, isNotEmpty);
  });

  test('Daily target bonus XP and flag trigger only once per day', () async {
    // Target 500ml = 2 gelas
    final profile = await repo.createProfile(
      name: 'Budi',
      gender: 'male',
      age: 25,
      condition: 'none',
      targetMl: 500,
    );
    final day1 = DateTime(2026, 5, 10, 10, 0); // jam normal (bukan golden hour)

    final r1 = await repo.logWater(now: day1);
    expect(r1.targetReached, isFalse);
    expect(repo.getActiveProfile()!.totalXp, AppConstants.xpPerGlass);

    final r2 = await repo.logWater(now: day1.add(const Duration(minutes: 10)));
    expect(r2.targetReached, isTrue);
    expect(
      repo.getActiveProfile()!.totalXp,
      AppConstants.xpPerGlass * 2 + AppConstants.xpDailyComplete,
    );
    expect(repo.getTodayStreak(profile.id, now: day1)!.currentStreak, 1);

    // Gelas ke-3 walau certificateShared == false TIDAK boleh dapat bonus lagi
    final r3 = await repo.logWater(now: day1.add(const Duration(minutes: 20)));
    expect(r3.targetReached, isFalse);
    expect(
      repo.getActiveProfile()!.totalXp,
      AppConstants.xpPerGlass * 3 + AppConstants.xpDailyComplete,
    );
  });

  test('Recovery bonus XP is only awarded on the first glass after a missed day', () async {
    final profile = await repo.createProfile(
      name: 'Siti',
      gender: 'female',
      age: 28,
      condition: 'none',
      targetMl: 1000,
    );
    final day1 = DateTime(2026, 5, 10, 10, 0);
    final day2 = DateTime(2026, 5, 11, 10, 0);

    // Hari 1 buka app tapi tidak mencapai target
    await repo.processStreakOnOpen(profile.id, now: day1);

    // Hari 2 gelas pertama dapat recovery bonus
    await repo.logWater(now: day2);
    expect(
      repo.getActiveProfile()!.totalXp,
      AppConstants.xpPerGlass + AppConstants.xpRecovery,
    );

    // Hari 2 gelas kedua TIDAK dapat recovery bonus lagi
    await repo.logWater(now: day2.add(const Duration(minutes: 30)));
    expect(
      repo.getActiveProfile()!.totalXp,
      AppConstants.xpPerGlass * 2 + AppConstants.xpRecovery,
    );
  });

  test('longestStreak is preserved even after missing multiple days', () async {
    final profile = await repo.createProfile(
      name: 'Andi',
      gender: 'male',
      age: 30,
      condition: 'none',
      targetMl: 250, // 1 gelas langsung target
    );

    // 3 hari berturut-turut tercapai -> streak 3, longestStreak 3, bonus milestone 3 (+50 XP)
    await repo.logWater(now: DateTime(2026, 5, 1, 10, 0));
    await repo.logWater(now: DateTime(2026, 5, 2, 10, 0));
    await repo.logWater(now: DateTime(2026, 5, 3, 10, 0));

    final day3Streak = repo.getTodayStreak(profile.id, now: DateTime(2026, 5, 3, 10, 0))!;
    expect(day3Streak.currentStreak, 3);
    expect(day3Streak.longestStreak, 3);

    // Absen 3 hari (buka lagi tanggal 7 Mei)
    final day7Streak = await repo.processStreakOnOpen(
      profile.id,
      now: DateTime(2026, 5, 7, 10, 0),
    );
    expect(day7Streak.currentStreak, 0);
    expect(day7Streak.longestStreak, 3);
  });

  test('Shield protects streak on 1 missed day and decrements shield count', () async {
    final profile = await repo.createProfile(
      name: 'Rina',
      gender: 'female',
      age: 26,
      condition: 'none',
      targetMl: 250,
    );

    // 7 hari berturut-turut -> dapat 1 shield
    for (int d = 1; d <= 7; d++) {
      await repo.logWater(now: DateTime(2026, 5, d, 10, 0));
    }
    final day7 = repo.getTodayStreak(profile.id, now: DateTime(2026, 5, 7, 10, 0))!;
    expect(day7.currentStreak, 7);
    expect(day7.shieldsAvailable, 1);

    // Absen tanggal 8, buka lagi tanggal 9 -> shield terpakai, streak tetap 7
    final day9 = await repo.processStreakOnOpen(
      profile.id,
      now: DateTime(2026, 5, 9, 10, 0),
    );
    expect(day9.shieldUsedToday, isTrue);
    expect(day9.shieldsAvailable, 0);
    expect(day9.currentStreak, 7);
    expect(day9.longestStreak, 7);
  });

  test('Undo/delete water and sweet logs reverts ml, XP, and sugar', () async {
    final profile = await repo.createProfile(
      name: 'Dedi',
      gender: 'male',
      age: 24,
      condition: 'none',
      targetMl: 2000,
    );
    final now = DateTime(2026, 5, 15, 10, 0);

    await repo.logWater(now: now);
    final waterLogs = repo.getTodayWaterLogs(profile.id, now: now);
    expect(waterLogs.length, 1);
    expect(repo.getTodayTotalMl(profile.id, now: now), 250);
    expect(repo.getActiveProfile()!.totalXp, AppConstants.xpPerGlass);

    final deletedWater = await repo.deleteWaterLog(waterLogs.first.id);
    expect(deletedWater, isTrue);
    expect(repo.getTodayWaterLogs(profile.id, now: now), isEmpty);
    expect(repo.getTodayTotalMl(profile.id, now: now), 0);
    expect(repo.getActiveProfile()!.totalXp, 0);

    final sweet = await repo.logSweetDrink(
      profileId: profile.id,
      drinkType: 'tea',
      now: now,
    );
    expect(repo.getTodaySugarG(profile.id, now: now), 17.0);

    final deletedSweet = await repo.deleteSweetLog(sweet.id);
    expect(deletedSweet, isTrue);
    expect(repo.getTodaySugarG(profile.id, now: now), 0.0);
    expect(repo.getTodaySweetLogs(profile.id, now: now), isEmpty);
  });

  test('Riverpod providers react live on profile creation, log, and undo', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(profileProvider), isNull);

    await container.read(profileProvider.notifier).create(
      name: 'Asep',
      gender: 'male',
      age: 22,
      condition: 'none',
      targetMl: 500,
    );

    expect(container.read(profileProvider)?.name, 'Asep');
    expect(container.read(dailyWaterProvider).targetMl, 500);

    await container.read(dailyWaterProvider.notifier).log();
    expect(container.read(dailyWaterProvider).totalMl, 250);
    expect(container.read(profileProvider)!.totalXp, greaterThan(0));

    final logId = container.read(dailyWaterProvider).recentLogs.first.id;
    await container.read(dailyWaterProvider.notifier).deleteLog(logId);
    expect(container.read(dailyWaterProvider).totalMl, 0);
    expect(container.read(profileProvider)!.totalXp, 0);

    await container.read(profileProvider.notifier).updateTargetMl(1500);
    expect(container.read(profileProvider)!.targetMl, 1500);
    expect(container.read(dailyWaterProvider).targetMl, 1500);
  });

  test('Notification timezone resolves Indonesia WIB/WITA/WIT offsets', () {
    expect(
      NotificationService.configureLocalTimezone(
        overrideOffset: const Duration(hours: 7),
      ).name,
      'Asia/Jakarta',
    );
    expect(
      NotificationService.configureLocalTimezone(
        overrideOffset: const Duration(hours: 8),
      ).name,
      'Asia/Makassar',
    );
    expect(
      NotificationService.configureLocalTimezone(
        overrideOffset: const Duration(hours: 9),
      ).name,
      'Asia/Jayapura',
    );
  });

  test('computeReminderSlots shifts past hours to tomorrow instead of dropping them', () {
    final evening = DateTime(2026, 5, 15, 18, 30);
    final slots = NotificationService.computeReminderSlots(
      now: evening,
      intervalHours: 2,
    );

    // 06, 08, 10, 12, 14, 16, 18, 20 -> 8 slots total
    expect(slots.length, 8);
    expect(slots.every((s) => s.isAfter(evening)), isTrue);
    // 20:00 masih hari yang sama (15 Mei), 06:00..18:00 digeser ke besok (16 Mei)
    expect(slots.where((s) => s.day == 15).map((s) => s.hour), [20]);
    expect(slots.where((s) => s.day == 16).length, 7);
  });

  test('Reminder settings and checkAndResetDaily persist properly', () async {
    await repo.createProfile(
      name: 'Nadia',
      gender: 'female',
      age: 23,
      condition: 'none',
      targetMl: 1600,
    );

    expect(repo.remindersEnabled, isTrue);
    expect(repo.reminderIntervalHours, 2);

    repo.setRemindersEnabled(false);
    repo.setReminderIntervalHours(3);
    expect(repo.remindersEnabled, isFalse);
    expect(repo.reminderIntervalHours, 3);

    final day1 = DateTime(2026, 5, 15, 9, 0);
    final first = await repo.checkAndResetDaily(now: day1);
    expect(first.didReset, isTrue);

    final sameDay = await repo.checkAndResetDaily(now: day1.add(const Duration(hours: 4)));
    expect(sameDay.didReset, isFalse);

    final nextDay = await repo.checkAndResetDaily(now: DateTime(2026, 5, 16, 7, 0));
    expect(nextDay.didReset, isTrue);
  });

  test('Achievement share text formats properly for all card types', () {
    final streakText = AchievementShareService.buildShareText(
      type: AchievementCardType.streak,
      name: 'Budi',
      streakDays: 7,
      totalMl: 2000,
      targetMl: 2000,
      currentLevel: 3,
    );
    expect(streakText, contains('7 hari streak'));
    expect(streakText, contains('#CaiHeurang'));

    final levelText = AchievementShareService.buildShareText(
      type: AchievementCardType.levelUp,
      name: 'Budi',
      streakDays: 7,
      totalMl: 2000,
      targetMl: 2000,
      currentLevel: 5,
    );
    expect(levelText, contains('Bunga Mekar'));
  });

  test('Multi-profile family CRUD isolates data and prevents deleting last profile', () async {
    final ayah = await repo.createProfile(
      name: 'Ayah',
      gender: 'male',
      age: 38,
      condition: 'none',
      targetMl: 2000,
    );
    await repo.logWater(now: DateTime(2026, 5, 15, 10, 0));

    // Tidak boleh menghapus satu-satunya profil
    expect(await repo.deleteProfile(ayah.id), isFalse);

    final ibu = await repo.createProfile(
      name: 'Ibu',
      gender: 'female',
      age: 35,
      condition: 'breastfeeding',
      targetMl: 2160,
    );
    expect(repo.getAllProfiles().length, 2);
    expect(repo.getActiveProfile()!.id, ibu.id);
    // Data air Ibu terpisah dari Ayah
    expect(repo.getTodayTotalMl(ibu.id, now: DateTime(2026, 5, 15, 10, 0)), 0);
    expect(repo.getTodayTotalMl(ayah.id, now: DateTime(2026, 5, 15, 10, 0)), 250);

    // Pindah kembali ke Ayah
    final switched = await repo.switchProfile(ayah.id);
    expect(switched?.id, ayah.id);
    expect(repo.getActiveProfile()!.name, 'Ayah');

    // Hapus profil aktif (Ayah) -> otomatis pindah ke Ibu
    expect(await repo.deleteProfile(ayah.id), isTrue);
    expect(repo.getAllProfiles().length, 1);
    expect(repo.getActiveProfile()!.id, ibu.id);
  });

  test('Riverpod multi-profile switching updates water and profile state cleanly', () async {
    repo.setRemindersEnabled(false); // Hindari panggilan platform channel di unit test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(profileProvider.notifier).create(
      name: 'Ayah',
      gender: 'male',
      age: 38,
      condition: 'none',
      targetMl: 2000,
    );
    final ayahId = container.read(profileProvider)!.id;
    await container.read(dailyWaterProvider.notifier).log();
    expect(container.read(dailyWaterProvider).totalMl, 250);

    // Tambah profil Adik -> otomatis aktif dengan 0 ml dan target 960 ml
    await container.read(profileProvider.notifier).addFamilyProfile(
      name: 'Adik',
      gender: 'male',
      age: 7,
      condition: 'none',
      targetMl: 960,
    );
    expect(container.read(profilesListProvider).length, 2);
    expect(container.read(profileProvider)!.name, 'Adik');
    expect(container.read(dailyWaterProvider).totalMl, 0);
    expect(container.read(dailyWaterProvider).targetMl, 960);

    // Pindah balik ke Ayah -> 250 ml kembali muncul
    await container.read(profileProvider.notifier).switchProfile(ayahId);
    expect(container.read(profileProvider)!.name, 'Ayah');
    expect(container.read(dailyWaterProvider).totalMl, 250);
    expect(container.read(dailyWaterProvider).targetMl, 2000);
  });
}
