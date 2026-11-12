import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/app_store.dart';
import '../../data/verses.dart';
import '../../domain/judah_state.dart';
import '../providers.dart';
import '../share_card.dart';
import '../theme.dart';

class VerseScreen extends ConsumerWidget {
  const VerseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verse = ref.watch(todayVerseProvider);
    final s = ref.watch(appStateProvider);
    final done = ref.watch(judahViewProvider).doneToday.contains(DailyTask.verse);
    final notifier = ref.read(appStateProvider.notifier);
    final text = Theme.of(context).textTheme;
    final fav = s.favorites.contains(verse.ref);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's verse"),
        actions: [
          IconButton(
            tooltip: fav ? 'Remove from favorites' : 'Save to favorites',
            icon: Icon(fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: fav ? Colors.redAccent : null),
            onPressed: () => notifier.toggleFavorite(verse.ref),
          ),
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => shareVerse(context, ref, verse),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Text(
                          verse.text(s.translation),
                          textAlign: TextAlign.center,
                          style: text.headlineSmall?.copyWith(height: 1.4, fontSize: 25),
                        ),
                        const SizedBox(height: 20),
                        Text('${verse.ref} (${s.translation.label})',
                            style: text.titleMedium?.copyWith(color: JudahColors.goldDark)),
                      ],
                    ),
                  ),
                ),
              ),
              SegmentedButton<Translation>(
                segments: [
                  for (final t in Translation.values)
                    ButtonSegment(value: t, label: Text(t.label)),
                ],
                selected: {s.translation},
                onSelectionChanged: (v) => notifier.setTranslation(v.first),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (!done) notifier.complete(DailyTask.verse);
                  context.pop();
                },
                child: Text(done ? 'Back to Judah' : 'Amen, I read it'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
