import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:judah/data/verses.dart';
import 'package:judah/domain/judah_state.dart';

void main() {
  final monday = Day(2026, 11, 16);
  DateTime at(Day d, int hour, [int minute = 0]) =>
      DateTime(d.year, d.month, d.day, hour, minute);

  Progress readOn(List<Day> days) {
    var p = const Progress();
    for (final d in days) {
      p = p.withTask(d, DailyTask.verse, at(d, 9));
    }
    return p;
  }

  group('growth', () {
    test('cub, young lion and adult after 0, 3 and 7 verse days', () {
      expect(stageFor(0), Stage.cub);
      expect(stageFor(2), Stage.cub);
      expect(stageFor(3), Stage.young);
      expect(stageFor(6), Stage.young);
      expect(stageFor(7), Stage.adult);
      expect(stageFor(100), Stage.adult);
    });

    test('only days with the verse read count, and doing it twice counts once', () {
      var p = const Progress()
          .withTask(monday, DailyTask.prayer, at(monday, 8))
          .withTask(monday.add(1), DailyTask.verse, at(monday.add(1), 8))
          .withTask(monday.add(1), DailyTask.verse, at(monday.add(1), 9));
      expect(p.growthDays, 1);
    });

    test('missed days never take growth away', () {
      final p = readOn([monday, monday.add(1), monday.add(2)]);
      expect(stageFor(p.growthDays), Stage.young);
      // ten days later he is sad, but still a young lion
      final later = at(monday.add(12), 12);
      expect(moodFor(p, later), Mood.sad);
      expect(stageFor(p.growthDays), Stage.young);
    });
  });

  group('mood', () {
    test('new users start happy', () {
      expect(moodFor(const Progress(), at(monday, 12)), Mood.happy);
    });

    test('happy the day after, sad once a whole day was skipped', () {
      final p = readOn([monday]);
      expect(moodFor(p, at(monday.add(1), 12)), Mood.happy);
      expect(moodFor(p, at(monday.add(2), 12)), Mood.sad);
    });

    test('coming back makes Judah happy again straight away', () {
      final p = readOn([monday]).withTask(
          monday.add(5), DailyTask.chapter, at(monday.add(5), 12));
      expect(moodFor(p, at(monday.add(5), 12, 5)), Mood.happy);
    });

    test('sleepy at night, even when sad', () {
      final p = readOn([monday]);
      expect(moodFor(p, at(monday.add(4), 23)), Mood.sleepy);
      expect(moodFor(p, at(monday.add(4), 3)), Mood.sleepy);
    });

    test('praying for 30 minutes after a prayer, also at night', () {
      final prayed = at(monday, 22, 10);
      final p = const Progress().withTask(monday, DailyTask.prayer, prayed);
      expect(moodFor(p, prayed.add(const Duration(minutes: 10))), Mood.praying);
      expect(moodFor(p, prayed.add(const Duration(minutes: 31))), Mood.sleepy);
    });
  });

  test('scene follows the clock', () {
    expect(sceneFor(at(monday, 6)), Scene.morning);
    expect(sceneFor(at(monday, 12)), Scene.day);
    expect(sceneFor(at(monday, 19)), Scene.evening);
    expect(sceneFor(at(monday, 22)), Scene.night);
    expect(sceneFor(at(monday, 4)), Scene.night);
  });

  test('streak counts back from today or yesterday', () {
    final p = readOn([monday, monday.add(1), monday.add(2)]);
    expect(p.streak(monday.add(2)), 3);
    expect(p.streak(monday.add(3)), 3); // not read yet today: still alive
    expect(p.streak(monday.add(4)), 0);
  });

  test('progress survives a save and load', () {
    final p = readOn([monday]).withTask(monday, DailyTask.prayer, at(monday, 10));
    final back = Progress.fromJson(
        jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>);
    expect(back.on(monday), {DailyTask.verse, DailyTask.prayer});
    expect(back.lastPrayerAt, p.lastPrayerAt);
  });

  group('verse of the day', () {
    late VerseLibrary lib;
    setUpAll(() {
      final raw = jsonDecode(File('assets/verses.json').readAsStringSync())
          as Map<String, dynamic>;
      lib = VerseLibrary(
        (raw['topics'] as List).map((t) => Topic(t['id'], t['label'])).toList(),
        (raw['verses'] as List)
            .map((v) => Verse.fromJson(v as Map<String, dynamic>))
            .toList(),
      );
    });

    test('has at least 15 topics', () {
      expect(lib.topics.length, greaterThanOrEqualTo(15));
    });

    test('same verse all day, different on most days', () {
      final a = lib.verseOfDay(monday, {});
      expect(lib.verseOfDay(monday, {}), same(a));
      final week = {for (var i = 0; i < 7; i++) lib.verseOfDay(monday.add(i), {}).ref};
      expect(week.length, greaterThan(5));
    });

    test('respects the chosen topics', () {
      for (var i = 0; i < 30; i++) {
        final v = lib.verseOfDay(monday.add(i), {'anxiety'});
        expect(v.topics, contains('anxiety'));
      }
    });

    test('every verse has text in both translations', () {
      for (final v in lib.verses) {
        expect(v.kjv.trim(), isNotEmpty, reason: v.ref);
        expect(v.web.trim(), isNotEmpty, reason: v.ref);
      }
    });
  });
}
