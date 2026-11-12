import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/judah_state.dart';

enum Translation { kjv, web }

extension TranslationLabel on Translation {
  String get label => switch (this) {
        Translation.kjv => 'KJV',
        Translation.web => 'WEB',
      };
}

class Topic {
  const Topic(this.id, this.label);
  final String id;
  final String label;
}

class Verse {
  const Verse({
    required this.ref,
    required this.book,
    required this.chapter,
    required this.start,
    required this.end,
    required this.kjv,
    required this.web,
    required this.topics,
  });

  factory Verse.fromJson(Map<String, dynamic> j) => Verse(
        ref: j['ref'] as String,
        book: j['book'] as int,
        chapter: j['chapter'] as int,
        start: j['start'] as int,
        end: j['end'] as int,
        kjv: j['kjv'] as String,
        web: j['web'] as String,
        topics: (j['topics'] as List).cast<String>(),
      );

  final String ref;
  final int book; // 0-based index into the bundled Bible
  final int chapter;
  final int start;
  final int end;
  final String kjv;
  final String web;
  final List<String> topics;

  String text(Translation t) => t == Translation.kjv ? kjv : web;
}

class VerseLibrary {
  VerseLibrary(this.topics, this.verses);

  final List<Topic> topics;
  final List<Verse> verses;

  static Future<VerseLibrary> load() async {
    final raw = jsonDecode(await rootBundle.loadString('assets/verses.json'))
        as Map<String, dynamic>;
    return VerseLibrary(
      (raw['topics'] as List)
          .map((t) => Topic(t['id'] as String, t['label'] as String))
          .toList(),
      (raw['verses'] as List)
          .map((v) => Verse.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }

  Verse byRef(String ref) => verses.firstWhere((v) => v.ref == ref);

  /// The verse of the day for [day], drawn from the chosen [topicIds] (all
  /// topics when empty). The pool is shuffled with a fixed seed so the order
  /// feels random but is the same on every device and in the widget.
  Verse verseOfDay(Day day, Set<String> topicIds) {
    var pool = topicIds.isEmpty
        ? verses
        : verses.where((v) => v.topics.any(topicIds.contains)).toList();
    if (pool.isEmpty) pool = verses;
    final order = List<int>.generate(pool.length, (i) => i);
    _seededShuffle(order, 7);
    return pool[order[day.epochDay % pool.length]];
  }

  static void _seededShuffle(List<int> list, int seed) {
    // Small LCG, stable across Dart versions (dart:math Random is not
    // guaranteed to be).
    var state = seed;
    for (var i = list.length - 1; i > 0; i--) {
      state = (state * 1103515245 + 12345) & 0x7fffffff;
      final j = state % (i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }
}

/// The full Bible text, loaded only when a chapter is opened.
class BibleText {
  BibleText(this.books);

  final List<BibleBook> books;

  static final Map<Translation, BibleText> _cache = {};

  static Future<BibleText> load(Translation t) async {
    final cached = _cache[t];
    if (cached != null) return cached;
    final raw = await rootBundle.loadString('assets/bible/${t.name}.json');
    final parsed = await compute(_parse, raw);
    return _cache[t] = parsed;
  }

  static BibleText _parse(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return BibleText(
      (j['books'] as List)
          .map(
            (b) => BibleBook(
              b['name'] as String,
              (b['chapters'] as List)
                  .map((c) => (c as List).cast<String>())
                  .toList(),
            ),
          )
          .toList(),
    );
  }
}

class BibleBook {
  BibleBook(this.name, this.chapters);
  final String name;
  final List<List<String>> chapters;
}
