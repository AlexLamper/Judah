import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/app_store.dart';
import '../../domain/judah_state.dart';
import '../../services/notifications.dart';
import '../../services/purchases.dart';
import '../judah_art.dart';
import '../theme.dart';
import '../topic_picker.dart';

/// Short onboarding: meet Judah, pick topics, morning verse, then the paywall.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;
  Set<String> _topics = {};

  void _next() => _pages.nextPage(
      duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);

  Future<void> _finish() async {
    final n = ref.read(appStateProvider.notifier);
    n.finishOnboarding(topics: _topics);
    final pro = await JudahPurchases.showPaywall();
    if (pro) n.setPro(true);
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final lib = ref.watch(verseLibraryProvider);
    final text = Theme.of(context).textTheme;

    final pages = <({Widget body, String button, VoidCallback onPressed})>[
      (
        body: _Page(
          art: const JudahArt(stage: Stage.cub, mood: Mood.happy, scene: Scene.morning),
          title: 'Meet Judah',
          subtitle:
              'A little lion cub who lives on your home screen. He grows when you read your Bible and pray.',
        ),
        button: 'Hi Judah!',
        onPressed: _next,
      ),
      (
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text('What do you need\nto hear from God?', style: text.displaySmall?.copyWith(fontSize: 30)),
                const SizedBox(height: 8),
                Text('Pick a few topics for your daily verse.', style: text.bodyMedium),
                const SizedBox(height: 20),
                TopicPicker(
                  topics: lib.topics,
                  selected: _topics,
                  onChanged: (t) => setState(() => _topics = t),
                ),
              ],
            ),
          ),
        ),
        button: _topics.isEmpty ? 'Surprise me' : 'Continue',
        onPressed: _next,
      ),
      (
        body: _Page(
          art: const JudahArt(stage: Stage.cub, mood: Mood.sleepy, scene: Scene.night),
          title: 'A verse every morning',
          subtitle:
              'Judah brings you a new verse each morning. You can change the time in settings.',
        ),
        button: 'Turn on morning verse',
        onPressed: () async {
          await MorningVerse.requestPermission();
          _next();
        },
      ),
      (
        body: _Page(
          art: const JudahArt(stage: Stage.adult, mood: Mood.happy, scene: Scene.day),
          title: 'Grow him into a lion',
          subtitle:
              'Read the verse, pray and read the chapter. In one week Judah becomes the Lion of Judah. Skip a day and he will miss you!',
        ),
        button: 'Start with Judah',
        onPressed: _finish,
      ),
    ];

    final current = pages[_page];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _page = p),
                children: [for (final p in pages) p.body],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < pages.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: i == _page ? 22 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: i == _page ? JudahColors.goldDark : JudahColors.line,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: current.onPressed, child: Text(current.button)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.art, required this.title, required this.subtitle});
  final Widget art;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: ClipRRect(borderRadius: BorderRadius.circular(28), child: art),
          ),
          const SizedBox(height: 28),
          Text(title,
              textAlign: TextAlign.center,
              style: text.displaySmall?.copyWith(fontSize: 32)),
          const SizedBox(height: 10),
          Text(subtitle,
              textAlign: TextAlign.center, style: text.bodyLarge?.copyWith(fontSize: 17)),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
