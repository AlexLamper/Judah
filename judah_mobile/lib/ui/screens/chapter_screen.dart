import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/app_store.dart';
import '../../data/verses.dart';
import '../../domain/judah_state.dart';
import '../providers.dart';
import '../theme.dart';

/// The chapter today's verse comes from, with the verse itself highlighted.
class ChapterScreen extends ConsumerWidget {
  const ChapterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verse = ref.watch(todayVerseProvider);
    final translation = ref.watch(appStateProvider.select((s) => s.translation));
    final done = ref.watch(judahViewProvider).doneToday.contains(DailyTask.chapter);

    return Scaffold(
      appBar: AppBar(title: const Text('Read the chapter')),
      body: FutureBuilder<BibleText>(
        future: BibleText.load(translation),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final book = snap.data!.books[verse.book];
          final verses = book.chapters[verse.chapter - 1];
          final text = Theme.of(context).textTheme;
          return ListView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
            children: [
              Text('${book.name} ${verse.chapter}', style: text.displaySmall?.copyWith(fontSize: 28)),
              Text(translation.label, style: text.bodyMedium),
              const SizedBox(height: 16),
              for (var i = 0; i < verses.length; i++)
                _VerseLine(
                  number: i + 1,
                  text: verses[i],
                  highlighted: i + 1 >= verse.start && i + 1 <= verse.end,
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  if (!done) {
                    ref.read(appStateProvider.notifier).complete(DailyTask.chapter);
                  }
                  context.pop();
                },
                child: Text(done ? 'Back to Judah' : "I've read the chapter"),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VerseLine extends StatelessWidget {
  const _VerseLine({required this.number, required this.text, required this.highlighted});
  final int number;
  final String text;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 17);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: highlighted ? const EdgeInsets.all(8) : EdgeInsets.zero,
      decoration: highlighted
          ? BoxDecoration(
              color: JudahColors.gold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            )
          : null,
      child: Text.rich(
        TextSpan(children: [
          TextSpan(
            text: '$number ',
            style: style.copyWith(
                fontSize: 12, color: JudahColors.goldDark, fontWeight: FontWeight.w800),
          ),
          TextSpan(text: text, style: style),
        ]),
      ),
    );
  }
}
