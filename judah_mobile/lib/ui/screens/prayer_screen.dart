import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/app_store.dart';
import '../../domain/content.dart';
import '../../domain/judah_state.dart';
import '../judah_art.dart';
import '../providers.dart';
import '../theme.dart';

/// Guided prayer: one line at a time, Judah praying alongside.
class PrayerScreen extends ConsumerStatefulWidget {
  const PrayerScreen({super.key});

  @override
  ConsumerState<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends ConsumerState<PrayerScreen> {
  int _line = 0;

  @override
  Widget build(BuildContext context) {
    final verse = ref.watch(todayVerseProvider);
    final j = ref.watch(judahViewProvider);
    final s = ref.watch(appStateProvider);
    final topic = verse.topics.firstWhere(s.topics.contains, orElse: () => verse.topics.first);
    final lines = guidedPrayer(topic, verse.ref);
    final last = _line == lines.length - 1;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Pray with Judah')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: JudahArt(
                    stage: j.stage, mood: Mood.praying, scene: j.scene, showScene: false),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      lines[_line],
                      key: ValueKey(_line),
                      textAlign: TextAlign.center,
                      style: text.headlineSmall?.copyWith(height: 1.4),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < lines.length; i++)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i <= _line ? JudahColors.goldDark : JudahColors.line,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if (!last) {
                    setState(() => _line++);
                    return;
                  }
                  ref.read(appStateProvider.notifier).complete(DailyTask.prayer);
                  context.pop();
                },
                child: Text(last ? 'Amen' : 'Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
