import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/app_store.dart';
import '../data/verses.dart';
import '../domain/judah_state.dart';
import '../ui/judah_art.dart';

/// Pushes everything the home screen and lock screen widgets need.
///
/// The widgets keep working while the app is closed: they get the verses for
/// the next [daysAhead] days and one picture of Judah per mood and time of
/// day, then pick the right ones themselves using the same rules as
/// [moodFor] and [sceneFor] (see the native widget code).
class WidgetSync {
  static const appGroupId = 'group.com.getjudah.app';
  static const iOSKind = 'JudahWidget';
  static const androidProviders = [
    'com.getjudah.app.widget.JudahSmallWidget',
    'com.getjudah.app.widget.JudahMediumWidget',
    'com.getjudah.app.widget.JudahLargeWidget',
  ];
  static const daysAhead = 14;

  /// Mood/scene pairs the widget can show. Praying only exists in the app.
  static const images = <(Mood, Scene)>[
    (Mood.happy, Scene.morning),
    (Mood.happy, Scene.day),
    (Mood.happy, Scene.evening),
    (Mood.sad, Scene.morning),
    (Mood.sad, Scene.day),
    (Mood.sad, Scene.evening),
    (Mood.sleepy, Scene.night),
  ];

  static bool get _supported => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  static Future<void> init() async {
    if (!_supported) return;
    await HomeWidget.setAppGroupId(appGroupId);
  }

  static Future<void> sync(AppState s, VerseLibrary lib, SharedPreferences prefs) async {
    if (!_supported) return;
    try {
      final today = Day.of(DateTime.now());
      final stage = stageFor(s.progress.growthDays);

      final upcoming = <String, Map<String, String>>{};
      for (var i = 0; i < daysAhead; i++) {
        final day = today.add(i);
        final v = lib.verseOfDay(day, s.topics);
        upcoming[day.key] = {'ref': v.ref, 'text': v.text(s.translation)};
      }

      final lastVerseDay = s.progress.on(today).contains(DailyTask.verse)
          ? today
          : (s.progress.on(today.add(-1)).contains(DailyTask.verse)
              ? today.add(-1)
              : null);

      await Future.wait([
        HomeWidget.saveWidgetData('pro', s.isPro),
        HomeWidget.saveWidgetData('stage', stage.name),
        HomeWidget.saveWidgetData('verses', jsonEncode(upcoming)),
        HomeWidget.saveWidgetData('translation', s.translation.label),
        HomeWidget.saveWidgetData(
            'lastActive', s.progress.lastActiveDay?.key ?? ''),
        HomeWidget.saveWidgetData('streak', s.progress.streak(today)),
        HomeWidget.saveWidgetData('streakDay', lastVerseDay?.key ?? ''),
        HomeWidget.saveWidgetData(
          'doneToday',
          s.progress.on(today).map((t) => t.name).join(','),
        ),
        HomeWidget.saveWidgetData('today', today.key),
      ]);

      // Pictures depend only on the stage, so render them once per stage.
      if (prefs.getString('widgetArtStage') != stage.name) {
        for (final (mood, scene) in images) {
          await HomeWidget.renderFlutterWidget(
            SizedBox(
              width: 300,
              height: 300,
              child: JudahArt(stage: stage, mood: mood, scene: scene),
            ),
            key: 'img_${mood.name}_${scene.name}',
            logicalSize: const Size(300, 300),
            pixelRatio: 2,
          );
        }
        await prefs.setString('widgetArtStage', stage.name);
      }

      if (Platform.isIOS) {
        await HomeWidget.updateWidget(iOSName: iOSKind);
      } else {
        for (final provider in androidProviders) {
          await HomeWidget.updateWidget(qualifiedAndroidName: provider);
        }
      }
    } catch (e, st) {
      // A widget that fails to refresh must never break the app itself.
      debugPrint('Widget sync failed: $e\n$st');
    }
  }
}
