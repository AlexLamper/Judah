import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' hide Day;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/app_store.dart';
import '../data/verses.dart';
import '../domain/judah_state.dart';

/// The one notification Judah sends: the morning verse.
///
/// Each day's verse is different, so instead of one repeating notification the
/// next [daysAhead] mornings are scheduled one by one with that day's verse.
/// Every app open reschedules them, so they never run out for active users.
class MorningVerse {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const daysAhead = 14;
  static bool _ready = false;

  static bool get _supported => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  static Future<void> init() async {
    if (!_supported) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Asked for in onboarding, after Judah is introduced.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  static Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      if (Platform.isIOS) {
        return await _plugin
                .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin>()
                ?.requestPermissions(alert: true, badge: false, sound: true) ??
            false;
      }
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          true;
    } catch (e) {
      debugPrint('Notification permission failed: $e');
      return false;
    }
  }

  static Future<void> reschedule(AppState s, VerseLibrary lib) async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
      final now = DateTime.now();
      for (var i = 0; i < daysAhead; i++) {
        final d = now.add(Duration(days: i));
        // A local DateTime handles DST; scheduling the exact instant in UTC
        // then fires at the right wall-clock time in any timezone.
        final at = DateTime(d.year, d.month, d.day, s.reminderHour, s.reminderMinute);
        if (!at.isAfter(now)) continue;
        final v = lib.verseOfDay(Day.of(at), s.topics);
        await _plugin.zonedSchedule(
          id: i,
          scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
          title: 'Judah has your verse 🦁',
          body: '${v.text(s.translation)} - ${v.ref}',
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'morning_verse',
              'Morning verse',
              channelDescription: 'Your daily Bible verse from Judah',
              importance: Importance.defaultImportance,
              styleInformation: BigTextStyleInformation(''),
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint('Scheduling morning verse failed: $e');
    }
  }
}
