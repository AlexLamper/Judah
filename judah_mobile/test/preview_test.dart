// Renders the placeholder art and main screens to PNGs for a quick visual
// check: flutter test test/preview_test.dart --dart-define=PREVIEW_DIR=/tmp/judah
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judah/data/app_store.dart';
import 'package:judah/data/verses.dart';
import 'package:judah/domain/judah_state.dart';
import 'package:judah/ui/judah_art.dart';
import 'package:judah/ui/screens/today_screen.dart';
import 'package:judah/ui/share_card.dart';
import 'package:judah/ui/theme.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

const dir = String.fromEnvironment('PREVIEW_DIR');

Future<void> loadFonts() async {
  for (final (family, files) in [
    ('Nunito', ['Nunito-600', 'Nunito-700', 'Nunito-800']),
    ('Fredoka', ['Fredoka-500', 'Fredoka-600', 'Fredoka-700']),
  ]) {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(Future.value(
          ByteData.view(File('assets/fonts/$f.ttf').readAsBytesSync().buffer)));
    }
    await loader.load();
  }
  final roboto = File('${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}'
      '/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf');
  if (roboto.existsSync()) {
    await (FontLoader('Roboto')
          ..addFont(Future.value(ByteData.view(roboto.readAsBytesSync().buffer))))
        .load();
  }
  final icons = File('${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}'
      '/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    await (FontLoader('MaterialIcons')
          ..addFont(Future.value(ByteData.view(icons.readAsBytesSync().buffer))))
        .load();
  }
}

Future<void> snap(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const Key('shot')));
  final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 2));
  final bytes = await tester.runAsync(() => image!.toByteData(format: ui.ImageByteFormat.png));
  File('$dir/$name.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  if (dir.isEmpty) return;
  setUpAll(loadFonts);

  testWidgets('art grid', (tester) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(RepaintBoundary(
      key: const Key('shot'),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: GridView.count(
          crossAxisCount: 4,
          children: [
            for (final stage in Stage.values)
              for (final (mood, scene) in const [
                (Mood.happy, Scene.morning),
                (Mood.sad, Scene.day),
                (Mood.praying, Scene.evening),
                (Mood.sleepy, Scene.night),
              ])
                JudahArt(stage: stage, mood: mood, scene: scene),
          ],
        ),
      ),
    ));
    await snap(tester, 'art_grid');
  });

  testWidgets('today screen and share card', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    final raw = jsonDecode(File('assets/verses.json').readAsStringSync())
        as Map<String, dynamic>;
    final lib = VerseLibrary(
      (raw['topics'] as List).map((t) => Topic(t['id'], t['label'])).toList(),
      (raw['verses'] as List).map((v) => Verse.fromJson(v)).toList(),
    );
    final today = Day.of(DateTime.now());
    final progress = Progress()
        .withTask(today.add(-3), DailyTask.verse, DateTime.now())
        .withTask(today.add(-2), DailyTask.verse, DateTime.now())
        .withTask(today.add(-1), DailyTask.verse, DateTime.now())
        .withTask(today, DailyTask.verse, DateTime.now());
    SharedPreferences.setMockInitialValues({
      'onboarded': true,
      'progress': jsonEncode(progress.toJson()),
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        verseLibraryProvider.overrideWithValue(lib),
      ],
      child: RepaintBoundary(
        key: const Key('shot'),
        child: MaterialApp(theme: judahTheme(), home: const TodayScreen()),
      ),
    ));
    await tester.pump();
    await snap(tester, 'today');

    final v = lib.verseOfDay(today, {});
    await tester.pumpWidget(RepaintBoundary(
      key: const Key('shot'),
      child: Center(
        child: SizedBox(
          width: 270,
          height: 480,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: VerseCard(text: v.kjv, reference: '${v.ref} KJV', stage: Stage.young),
          ),
        ),
      ),
    ));
    await snap(tester, 'share_card');
  });
}
