import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/app_store.dart';
import '../share_card.dart';
import '../theme.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final lib = ref.watch(verseLibraryProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: s.favorites.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Tap the heart on a verse to keep it here.',
                  textAlign: TextAlign.center,
                  style: text.bodyLarge,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: s.favorites.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final v = lib.byRef(s.favorites[i]);
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: JudahColors.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: JudahColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.text(s.translation), style: text.bodyLarge),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(v.ref,
                              style: text.titleMedium?.copyWith(color: JudahColors.goldDark)),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Share',
                            icon: const Icon(Icons.ios_share_rounded),
                            onPressed: () => shareVerse(context, ref, v),
                          ),
                          IconButton(
                            tooltip: 'Remove',
                            icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
                            onPressed: () =>
                                ref.read(appStateProvider.notifier).toggleFavorite(v.ref),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
