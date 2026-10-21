import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminder_copy.dart';
import '../domain/reminder_plan.dart';

/// Delivers reminders on the phone. Nothing leaves the device.
abstract interface class ReminderScheduler {
  /// Asks the system for permission. True when notifications may be shown.
  Future<bool> requestPermission();

  /// Replaces everything scheduled with [plan] (an empty plan cancels all).
  Future<void> replaceAll(List<PlannedReminder> plan);

  Future<void> cancelAll();

  /// Debug builds only: shows [reminder]'s text after [delay], to check
  /// delivery on a device without waiting for its date.
  Future<void> debugShowSoon(PlannedReminder reminder, Duration delay);
}

/// [ReminderScheduler] on `flutter_local_notifications`, in the phone's
/// time zone.
class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _ready;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Reminders',
      channelDescription: 'Phase and period reminders',
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> _init() => _ready ??= () async {
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } on Object catch (e) {
      // An unknown zone name: keep UTC rather than fail; times may be off
      // by the zone offset until the next launch.
      debugPrint('Time zone not found ($e); reminders use UTC');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        // The monochrome app-icon mark: status-bar icons are drawn from
        // their alpha only.
        android: AndroidInitializationSettings(
          '@drawable/ic_launcher_monochrome',
        ),
        // Permission is asked when the user turns reminders on.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }();

  @override
  Future<bool> requestPermission() async {
    await _init();
    if (Platform.isIOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, sound: true) ??
          false;
    }
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    return false;
  }

  @override
  Future<void> replaceAll(List<PlannedReminder> plan) async {
    await _init();
    await _plugin.cancelAll();
    for (final r in plan) {
      final text = reminderText(r);
      await _plugin.zonedSchedule(
        id: r.id,
        title: text.title,
        body: text.body,
        scheduledDate: tz.TZDateTime(
          tz.local,
          r.date.year,
          r.date.month,
          r.date.day,
          reminderHour,
        ),
        notificationDetails: _details,
        // Inexact: no exact-alarm permission needed, and a few minutes
        // either way doesn't matter for a morning reminder.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<void> cancelAll() async {
    await _init();
    await _plugin.cancelAll();
  }

  @override
  Future<void> debugShowSoon(PlannedReminder reminder, Duration delay) async {
    assert(kDebugMode);
    await _init();
    final text = reminderText(reminder);
    await _plugin.zonedSchedule(
      id: 1,
      title: text.title,
      body: text.body,
      scheduledDate: tz.TZDateTime.now(tz.local).add(delay),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
