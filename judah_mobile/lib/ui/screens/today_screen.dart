import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/app_store.dart';
import '../../domain/content.dart';
import '../../domain/judah_state.dart';
import '../../services/purchases.dart';
import '../judah_art.dart';
import '../providers.dart';
import '../theme.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final j = ref.watch(judahViewProvider);
    final verse = ref.watch(todayVerseProvider);
    final isPro = ref.watch(appStateProvider.select((s) => s.isPro));
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Row(
              children: [
                Text('Today', style: text.displaySmall?.copyWith(fontSize: 30)),
                const Spacer(),
                if (j.streak > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text('🔥 ${j.streak}', style: text.titleMedium),
                  ),
                IconButton(
                  tooltip: 'Favorites',
                  icon: const Icon(Icons.favorite_border_rounded),
                  onPressed: () => context.push('/favorites'),
                ),
                IconButton(
                  tooltip: 'Settings',
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => context.push('/settings'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _JudahCard(view: j),
            const SizedBox(height: 20),
            _TaskTile(
              done: j.doneToday.contains(DailyTask.verse),
              icon: Icons.menu_book_rounded,
              title: "Read today's verse",
              subtitle: verse.ref,
              onTap: () => context.push('/verse'),
            ),
            _TaskTile(
              done: j.doneToday.contains(DailyTask.prayer),
              icon: Icons.volunteer_activism_rounded,
              title: 'Pray with Judah',
              subtitle: 'A short guided prayer, about 1 minute',
              onTap: () => context.push('/prayer'),
            ),
            _TaskTile(
              done: j.doneToday.contains(DailyTask.chapter),
              icon: Icons.auto_stories_rounded,
              title: 'Read the chapter',
              subtitle: 'The whole chapter around today\'s verse',
              onTap: () => context.push('/chapter'),
            ),
            if (!isPro) ...[
              const SizedBox(height: 12),
              _WidgetUpsell(onTap: () async {
                final pro = await JudahPurchases.showPaywall();
                if (pro) ref.read(appStateProvider.notifier).setPro(true);
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _JudahCard extends StatelessWidget {
  const _JudahCard({required this.view});
  final JudahView view;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final next = progressToNextStage(view.growthDays);
    return Container(
      decoration: BoxDecoration(
        color: JudahColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: JudahColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.35,
            child: JudahArt(stage: view.stage, mood: view.mood, scene: view.scene),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judahLine(mood: view.mood, doneToday: view.doneToday, stage: view.stage),
                  style: text.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Judah · ${stageLabel(view.stage)}', style: text.bodyMedium),
                    const Spacer(),
                    if (view.stage != Stage.adult)
                      Text('${(next * 100).round()}%', style: text.bodyMedium),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: next,
                    minHeight: 10,
                    color: JudahColors.gold,
                    backgroundColor: JudahColors.line,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.done,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool done;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: JudahColors.card,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: done ? JudahColors.done : JudahColors.line, width: 1.5),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: done
                      ? JudahColors.done.withValues(alpha: 0.15)
                      : JudahColors.gold.withValues(alpha: 0.18),
                  child: Icon(done ? Icons.check_rounded : icon,
                      color: done ? JudahColors.done : JudahColors.goldDark),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.titleMedium),
                      const SizedBox(height: 2),
                      Text(subtitle, style: text.bodyMedium),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: JudahColors.inkSoft),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WidgetUpsell extends StatelessWidget {
  const _WidgetUpsell({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: JudahColors.gold.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('🦁', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Put Judah on your home screen', style: text.titleMedium),
                    Text('Unlock the widgets with Judah Pro', style: text.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.lock_open_rounded, color: JudahColors.goldDark),
            ],
          ),
        ),
      ),
    );
  }
}
