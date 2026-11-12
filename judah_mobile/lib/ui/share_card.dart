import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../data/app_store.dart';
import '../data/verses.dart';
import '../domain/judah_state.dart';
import 'judah_art.dart';
import 'providers.dart';
import 'theme.dart';

/// Shows the story-sized verse card and shares it as an image.
/// Every shared card carries the Judah name and site: free marketing.
Future<void> shareVerse(BuildContext context, WidgetRef ref, Verse verse) {
  final s = ref.read(appStateProvider);
  final j = ref.read(judahViewProvider);
  final boundary = GlobalKey();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: JudahColors.sand,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.55,
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: RepaintBoundary(
                  key: boundary,
                  child: VerseCard(
                    text: verse.text(s.translation),
                    reference: '${verse.ref} ${s.translation.label}',
                    stage: j.stage,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.ios_share_rounded),
              label: const Text('Share'),
              onPressed: () async {
                final obj = boundary.currentContext?.findRenderObject();
                if (obj is! RenderRepaintBoundary) return;
                final image = await obj.toImage(pixelRatio: 1080 / obj.size.width);
                final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
                if (bytes == null) return;
                await SharePlus.instance.share(ShareParams(
                  files: [
                    XFile.fromData(bytes.buffer.asUint8List(),
                        mimeType: 'image/png', name: 'judah-verse.png'),
                  ],
                  text: '${verse.ref} - via Judah, getjudah.com',
                ));
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class VerseCard extends StatelessWidget {
  const VerseCard({super.key, required this.text, required this.reference, required this.stage});
  final String text;
  final String reference;
  final Stage stage;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final u = c.maxWidth / 100; // scale everything with the card width
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4 * u),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFD9B8), Color(0xFFFFF4E6)],
          ),
        ),
        padding: EdgeInsets.all(8 * u),
        child: Column(
          children: [
            const Spacer(),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w600,
                fontSize: (text.length > 160 ? 6 : 7.4) * u,
                height: 1.35,
                color: JudahColors.ink,
              ),
            ),
            SizedBox(height: 5 * u),
            Text(
              reference,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: 4.4 * u,
                color: JudahColors.goldDark,
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 34 * u,
              child: JudahArt(
                  stage: stage, mood: Mood.happy, scene: Scene.morning, showScene: false),
            ),
            Text(
              'Judah · getjudah.com',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: 3.6 * u,
                color: JudahColors.inkSoft,
              ),
            ),
          ],
        ),
      );
    });
  }
}
