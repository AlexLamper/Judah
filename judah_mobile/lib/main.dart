import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/app_store.dart';
import 'data/verses.dart';
import 'services/notifications.dart';
import 'services/purchases.dart';
import 'services/widget_sync.dart';
import 'ui/screens/chapter_screen.dart';
import 'ui/screens/favorites_screen.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/screens/prayer_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/today_screen.dart';
import 'ui/screens/verse_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final library = await VerseLibrary.load();
  await Future.wait([WidgetSync.init(), MorningVerse.init()]);

  final container = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(prefs),
    verseLibraryProvider.overrideWithValue(library),
  ]);

  await JudahPurchases.init(
    onChange: (pro) => container.read(appStateProvider.notifier).setPro(pro),
  );

  runApp(UncontrolledProviderScope(container: container, child: const JudahApp()));
}

class JudahApp extends ConsumerStatefulWidget {
  const JudahApp({super.key});

  @override
  ConsumerState<JudahApp> createState() => _JudahAppState();
}

class _JudahAppState extends ConsumerState<JudahApp> with WidgetsBindingObserver {
  late final GoRouter _router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final onboarded = ref.read(appStateProvider).onboarded;
      if (!onboarded && state.matchedLocation != '/onboarding') return '/onboarding';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const TodayScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/verse', builder: (_, _) => const VerseScreen()),
      GoRoute(path: '/prayer', builder: (_, _) => const PrayerScreen()),
      GoRoute(path: '/chapter', builder: (_, _) => const ChapterScreen()),
      GoRoute(path: '/favorites', builder: (_, _) => const FavoritesScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    ],
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshAll());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back to the app is the moment to top up the widget's verses and
    // the scheduled morning notifications.
    if (state == AppLifecycleState.resumed) _refreshAll();
  }

  void _refreshAll() {
    final s = ref.read(appStateProvider);
    final lib = ref.read(verseLibraryProvider);
    WidgetSync.sync(s, lib, ref.read(sharedPrefsProvider));
    if (s.onboarded) MorningVerse.reschedule(s, lib);
  }

  @override
  Widget build(BuildContext context) {
    // Every change (task done, topic, translation, Pro) reaches the widget
    // right away; notifications only when what they say changed.
    ref.listen(appStateProvider, (prev, next) {
      final lib = ref.read(verseLibraryProvider);
      WidgetSync.sync(next, lib, ref.read(sharedPrefsProvider));
      if (prev == null ||
          prev.topics != next.topics ||
          prev.translation != next.translation ||
          prev.reminderHour != next.reminderHour ||
          prev.reminderMinute != next.reminderMinute ||
          prev.onboarded != next.onboarded) {
        if (next.onboarded) MorningVerse.reschedule(next, lib);
      }
    });

    return MaterialApp.router(
      title: 'Judah',
      debugShowCheckedModeBanner: false,
      theme: judahTheme(),
      routerConfig: _router,
    );
  }
}
