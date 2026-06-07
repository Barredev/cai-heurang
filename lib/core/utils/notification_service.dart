// lib/core/utils/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../constants/app_constants.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();

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

  static Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Jadwalkan pengingat minum setiap [intervalHours] jam
  static Future<void> scheduleWaterReminders({
    required String profileName,
    required String plantPhaseName,
    int intervalHours = 2,
  }) async {
    await cancelAllWaterReminders();

    final now = DateTime.now();
    int id = 100;

    for (
      int hour = AppConstants.quietHourEnd;
      hour < AppConstants.quietHourStart;
      hour += intervalHours
    ) {
      final scheduled = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
      );

      if (scheduled.isBefore(now)) continue;

      await _plugin.zonedSchedule(
        id++,
        'CaiHeurang 💧',
        '$profileName, si $plantPhaseName lagi kehausan nih~ yuk minum! 🥰',
        tz.TZDateTime.from(scheduled, tz.local),
        _notifDetails('water_reminder'),

        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,

        androidScheduleMode:
            AndroidScheduleMode.exactAllowWhileIdle,

        matchDateTimeComponents:
            DateTimeComponents.time,
      );
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

    await _plugin.show(
      200,
      'Selamat $name! $title',
      '$days hari berturut-turut minum cukup air. Keren banget! 🎉',
      _notifDetails('streak'),
    );
  }

  /// Notifikasi shield terpakai
  static Future<void> showShieldUsed(
    int remaining,
    String name,
  ) async {
    await _plugin.show(
      201,
      'Perisai Streak Melindungimu! 🛡️',
      'Kemarin $name absen, tapi perisai otomatis terpakai. '
      'Sisa $remaining perisai ya~',
      _notifDetails('shield'),
    );
  }

  /// Notifikasi level naik
  static Future<void> showLevelUp(
    String phaseName,
    String name,
  ) async {
    await _plugin.show(
      202,
      'Si tanaman berevolusi! 🌱✨',
      '$name, tanamanmu sekarang jadi $phaseName! '
      'Terus semangat~',
      _notifDetails('level_up'),
    );
  }

  static Future<void> cancelAllWaterReminders() async {
    for (int i = 100; i < 200; i++) {
      await _plugin.cancel(i);
    }
  }

  static NotificationDetails _notifDetails(
    String channel,
  ) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel,
        channel,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }
}