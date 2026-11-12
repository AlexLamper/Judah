import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/judah_state.dart';
import 'verses.dart';

/// Everything the app remembers. No account: it all lives on the device.
class AppState {
  const AppState({
    required this.onboarded,
    required this.topics,
    required this.translation,
    required this.favorites,
    required this.progress,
    required this.isPro,
    required this.reminderHour,
    required this.reminderMinute,
  });

  final bool onboarded;
  final Set<String> topics;
  final Translation translation;
  final List<String> favorites; // verse refs, newest first
  final Progress progress;
  final bool isPro;
  final int reminderHour;
  final int reminderMinute;

  AppState copyWith({
    bool? onboarded,
    Set<String>? topics,
    Translation? translation,
    List<String>? favorites,
    Progress? progress,
    bool? isPro,
    int? reminderHour,
    int? reminderMinute,
  }) =>
      AppState(
        onboarded: onboarded ?? this.onboarded,
        topics: topics ?? this.topics,
        translation: translation ?? this.translation,
        favorites: favorites ?? this.favorites,
        progress: progress ?? this.progress,
        isPro: isPro ?? this.isPro,
        reminderHour: reminderHour ?? this.reminderHour,
        reminderMinute: reminderMinute ?? this.reminderMinute,
      );
}

/// Overridden in main() with the instance loaded before runApp.
final sharedPrefsProvider =
    Provider<SharedPreferences>((ref) => throw UnimplementedError());

/// Overridden in main() with the loaded verse list.
final verseLibraryProvider =
    Provider<VerseLibrary>((ref) => throw UnimplementedError());

final appStateProvider =
    NotifierProvider<AppStateNotifier, AppState>(AppStateNotifier.new);

class AppStateNotifier extends Notifier<AppState> {
  SharedPreferences get _prefs => ref.read(sharedPrefsProvider);

  @override
  AppState build() {
    final p = _prefs;
    final progressRaw = p.getString('progress');
    return AppState(
      onboarded: p.getBool('onboarded') ?? false,
      topics: (p.getStringList('topics') ?? const []).toSet(),
      translation: Translation.values.firstWhere(
        (t) => t.name == p.getString('translation'),
        orElse: () => Translation.kjv,
      ),
      favorites: p.getStringList('favorites') ?? const [],
      progress: progressRaw == null
          ? const Progress()
          : Progress.fromJson(jsonDecode(progressRaw) as Map<String, dynamic>),
      // Cached so the widget and UI are right offline; RevenueCat refreshes it.
      isPro: p.getBool('isPro') ?? false,
      reminderHour: p.getInt('reminderHour') ?? 8,
      reminderMinute: p.getInt('reminderMinute') ?? 0,
    );
  }

  void finishOnboarding({required Set<String> topics}) {
    _prefs.setBool('onboarded', true);
    _prefs.setStringList('topics', topics.toList());
    state = state.copyWith(onboarded: true, topics: topics);
  }

  void setTopics(Set<String> topics) {
    _prefs.setStringList('topics', topics.toList());
    state = state.copyWith(topics: topics);
  }

  void setTranslation(Translation t) {
    _prefs.setString('translation', t.name);
    state = state.copyWith(translation: t);
  }

  void setReminder(int hour, int minute) {
    _prefs.setInt('reminderHour', hour);
    _prefs.setInt('reminderMinute', minute);
    state = state.copyWith(reminderHour: hour, reminderMinute: minute);
  }

  void toggleFavorite(String verseRef) {
    final next = [...state.favorites];
    if (!next.remove(verseRef)) next.insert(0, verseRef);
    _prefs.setStringList('favorites', next);
    state = state.copyWith(favorites: next);
  }

  void complete(DailyTask task, {DateTime? at}) {
    final now = at ?? DateTime.now();
    final next = state.progress.withTask(Day.of(now), task, now);
    _prefs.setString('progress', jsonEncode(next.toJson()));
    state = state.copyWith(progress: next);
  }

  void setPro(bool isPro) {
    if (isPro == state.isPro) return;
    _prefs.setBool('isPro', isPro);
    state = state.copyWith(isPro: isPro);
  }
}
