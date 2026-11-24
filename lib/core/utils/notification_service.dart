// lib/core/utils/notification_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../constants/app_constants.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _tzInitialized = false;

  static Future<void> init() async {
    configureLocalTimezone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: android,
        iOS: ios,
      ),
    );
  }

  /// Deteksi dan set lokasi timezone lokal berdasarkan UTC offset perangkat
  /// (memprioritaskan zona waktu Indonesia: WIB/WITA/WIT).
  static tz.Location configureLocalTimezone({Duration? overrideOffset}) {
    if (!_tzInitialized) {
      tz_data.initializeTimeZones();
      _tzInitialized = true;
    }

    final offsetMs = (overrideOffset ?? DateTime.now().timeZoneOffset).inMilliseconds;
    const preferredByOffsetHours = <int, String>{
      7: 'Asia/Jakarta',
      8: 'Asia/Makassar',
      9: 'Asia/Jayapura',
    };

    tz.Location? resolved;
    final offsetHours = offsetMs ~/ Duration.millisecondsPerHour;
    if (offsetMs % Duration.millisecondsPerHour == 0) {
      final preferredName = preferredByOffsetHours[offsetHours];
      if (preferredName != null &&
          tz.timeZoneDatabase.locations.containsKey(preferredName)) {
        resolved = tz.getLocation(preferredName);
      }
    }

    if (resolved == null) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      for (final loc in tz.timeZoneDatabase.locations.values) {
        if (loc.timeZone(nowMs).offset == offsetMs) {
          resolved = loc;
          break;
        }
      }
    }

    resolved ??= tz.UTC;
    tz.setLocalLocation(resolved);
    return resolved;
  }

  /// Hitung daftar jadwal notifikasi harian (06:00–22:00).
  /// Jam yang sudah lewat hari ini digeser ke besok agar tetap aktif berulang tiap hari.
  static List<DateTime> computeReminderSlots({
    required DateTime now,
    int intervalHours = 2,
  }) {
    final safeInterval = intervalHours.clamp(1, 6);
    final slots = <DateTime>[];

    for (
      int hour = AppConstants.quietHourEnd;
      hour < AppConstants.quietHourStart;
      hour += safeInterval
    ) {
      var scheduled = DateTime(now.year, now.month, now.day, hour);
      if (!scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      slots.add(scheduled);
    }
    return slots;
  }

  static Future<void> requestPermission() async {
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Notification permission error: $e');
    }
  }

  /// Jadwalkan pengingat minum setiap [intervalHours] jam
  static Future<void> scheduleWaterReminders({
    required String profileName,
    required String plantPhaseName,
    int intervalHours = 2,
  }) async {
    configureLocalTimezone();
    await cancelAllWaterReminders();

    final slots = computeReminderSlots(
      now: DateTime.now(),
      intervalHours: intervalHours,
    );

    int id = 100;
    for (final scheduled in slots) {
      final tzTime = tz.TZDateTime(
        tz.local,
        scheduled.year,
        scheduled.month,
        scheduled.day,
        scheduled.hour,
        scheduled.minute,
      );

      try {
        await _plugin.zonedSchedule(
          id,
          'CaiHeurang 💧',
          '$profileName, si $plantPhaseName lagi kehausan nih~ yuk minum! 🥰',
          tzTime,
          _notifDetails('water_reminder', 'Pengingat Minum'),
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (_) {
        // Fallback jika izin exact alarm ditolak di Android 14+
        try {
          await _plugin.zonedSchedule(
            id,
            'CaiHeurang 💧',
            '$profileName, si $plantPhaseName lagi kehausan nih~ yuk minum! 🥰',
            tzTime,
            _notifDetails('water_reminder', 'Pengingat Minum'),
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        } catch (e) {
          debugPrint('Schedule reminder error (id $id): $e');
        }
      }
      id++;
    }
  }

  /// Notifikasi streak milestone
  static Future<void> showStreakMilestone(
    int days,
    String name,
  ) async {
    final title =
        AppConstants.streakMilestoneName[days] ??
            'Streak $days hari!';

    try {
      await _plugin.show(
        200,
        'Selamat $name! $title',
        '$days hari berturut-turut minum cukup air. Keren banget! 🎉',
        _notifDetails('streak', 'Milestone Streak'),
      );
    } catch (e) {
      debugPrint('Streak notification error: $e');
    }
  }

  /// Notifikasi shield terpakai
  static Future<void> showShieldUsed(
    int remaining,
    String name,
  ) async {
    try {
      await _plugin.show(
        201,
        'Perisai Streak Melindungimu! 🛡️',
        'Kemarin $name absen, tapi perisai otomatis terpakai. '
        'Sisa $remaining perisai ya~',
        _notifDetails('shield', 'Perisai Streak'),
      );
    } catch (e) {
      debugPrint('Shield notification error: $e');
    }
  }

  /// Notifikasi level naik
  static Future<void> showLevelUp(
    String phaseName,
    String name,
  ) async {
    try {
      await _plugin.show(
        202,
        'Si tanaman berevolusi! 🌱✨',
        '$name, tanamanmu sekarang jadi $phaseName! '
        'Terus semangat~',
        _notifDetails('level_up', 'Evolusi Tanaman'),
      );
    } catch (e) {
      debugPrint('Level up notification error: $e');
    }
  }

  static Future<void> cancelAllWaterReminders() async {
    for (int i = 100; i < 120; i++) {
      try {
        await _plugin.cancel(i);
      } catch (_) {}
    }
  }

  static NotificationDetails _notifDetails(
    String channelId,
    String channelName,
  ) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }
}