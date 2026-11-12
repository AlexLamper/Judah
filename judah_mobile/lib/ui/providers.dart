import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_store.dart';
import '../data/verses.dart';
import '../domain/judah_state.dart';

/// Ticks every minute so mood and scene follow the clock while the app is open.
final clockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
});

DateTime _now(Ref ref) => ref.watch(clockProvider).value ?? DateTime.now();

final todayVerseProvider = Provider<Verse>((ref) {
  final s = ref.watch(appStateProvider);
  final lib = ref.watch(verseLibraryProvider);
  return lib.verseOfDay(Day.of(_now(ref)), s.topics);
});

class JudahView {
  const JudahView(this.stage, this.mood, this.scene, this.growthDays, this.doneToday, this.streak);
  final Stage stage;
  final Mood mood;
  final Scene scene;
  final int growthDays;
  final Set<DailyTask> doneToday;
  final int streak;
}

final judahViewProvider = Provider<JudahView>((ref) {
  final p = ref.watch(appStateProvider).progress;
  final now = _now(ref);
  final today = Day.of(now);
  return JudahView(
    stageFor(p.growthDays),
    moodFor(p, now),
    sceneFor(now),
    p.growthDays,
    p.on(today),
    p.streak(today),
  );
});
