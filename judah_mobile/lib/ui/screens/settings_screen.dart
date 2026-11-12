import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/app_store.dart';
import '../../data/verses.dart';
import '../../services/notifications.dart';
import '../../services/purchases.dart';
import '../theme.dart';
import '../topic_picker.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final lib = ref.watch(verseLibraryProvider);
    final n = ref.read(appStateProvider.notifier);
    final text = Theme.of(context).textTheme;
    final time = TimeOfDay(hour: s.reminderHour, minute: s.reminderMinute);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Section('Judah Pro', [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.isPro ? 'Pro is active' : 'Unlock home screen widgets'),
              trailing: s.isPro
                  ? const Icon(Icons.verified_rounded, color: JudahColors.done)
                  : const Icon(Icons.chevron_right_rounded),
              onTap: s.isPro
                  ? null
                  : () async {
                      if (await JudahPurchases.showPaywall()) n.setPro(true);
                    },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Restore purchases'),
              onTap: () async {
                final pro = await JudahPurchases.restore();
                if (pro) n.setPro(true);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(pro ? 'Judah Pro restored.' : 'No purchase found.'),
                  ));
                }
              },
            ),
            if (kDebugMode && !JudahPurchases.configured)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Debug: Pro without RevenueCat'),
                value: s.isPro,
                onChanged: n.setPro,
              ),
          ]),
          _Section('Verse topics', [
            Text('Your daily verse comes from these topics. None selected means all.',
                style: text.bodyMedium),
            const SizedBox(height: 10),
            TopicPicker(topics: lib.topics, selected: s.topics, onChanged: n.setTopics),
          ]),
          _Section('Translation', [
            SegmentedButton<Translation>(
              segments: [
                for (final t in Translation.values)
                  ButtonSegment(
                    value: t,
                    label: Text(t == Translation.kjv ? 'King James (KJV)' : 'World English (WEB)'),
                  ),
              ],
              selected: {s.translation},
              onSelectionChanged: (v) => n.setTranslation(v.first),
            ),
          ]),
          _Section('Morning verse', [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Notification time'),
              trailing: Text(time.format(context), style: text.titleMedium),
              onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: time);
                if (picked == null) return;
                await MorningVerse.requestPermission();
                n.setReminder(picked.hour, picked.minute);
              },
            ),
          ]),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.children);
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}
