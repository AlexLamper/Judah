import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../domain/judah_state.dart';

/// Placeholder flat-2D Judah, drawn in code so every stage x mood x scene
/// combination exists from day one. Swap for the final illustrations once the
/// design variants are chosen: only [JudahArt] has to change.
class JudahArt extends StatelessWidget {
  const JudahArt({
    super.key,
    required this.stage,
    required this.mood,
    required this.scene,
    this.showScene = true,
  });

  final Stage stage;
  final Mood mood;
  final Scene scene;
  final bool showScene;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _JudahPainter(stage, mood, scene, showScene),
      child: const SizedBox.expand(),
    );
  }
}

class SceneColors {
  const SceneColors(this.top, this.bottom, this.ground);
  final Color top;
  final Color bottom;
  final Color ground;

  static SceneColors of(Scene s) => switch (s) {
        Scene.morning =>
          const SceneColors(Color(0xFFFFD9B8), Color(0xFFFFF4E6), Color(0xFFE8C98F)),
        Scene.day =>
          const SceneColors(Color(0xFFA9D8F5), Color(0xFFEAF6FD), Color(0xFFD9B979)),
        Scene.evening =>
          const SceneColors(Color(0xFFF59E6B), Color(0xFFB9789E), Color(0xFFB98A5A)),
        Scene.night =>
          const SceneColors(Color(0xFF1E2A4F), Color(0xFF3A3F75), Color(0xFF5B4A6E)),
      };
}

class _JudahPainter extends CustomPainter {
  _JudahPainter(this.stage, this.mood, this.scene, this.showScene);

  final Stage stage;
  final Mood mood;
  final Scene scene;
  final bool showScene;

  static const fur = Color(0xFFF2B65A);
  static const furShade = Color(0xFFDE9A3C);
  static const mane = Color(0xFFB8642B);
  static const maneLight = Color(0xFFCF7A35);
  static const ink = Color(0xFF4A2E1C);
  static const muzzle = Color(0xFFFFE3B8);

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height);
    if (showScene) _scene(canvas, size);

    final scale = switch (stage) {
      Stage.cub => 0.62,
      Stage.young => 0.8,
      Stage.adult => 1.0,
    };
    final r = s * 0.2 * scale; // head radius
    final groundY = showScene ? size.height * 0.86 : size.height * 0.95;
    final cx = size.width / 2;
    final bodyH = r * 1.25;
    final headC = Offset(cx, groundY - bodyH - r * 0.75);

    if (mood == Mood.praying) {
      canvas.drawCircle(
        headC,
        r * 2.1,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFFFFF3C4).withValues(alpha: 0.9),
            const Color(0xFFFFF3C4).withValues(alpha: 0),
          ]).createShader(Rect.fromCircle(center: headC, radius: r * 2.1)),
      );
    }

    // body + tail
    final body = Rect.fromCenter(
      center: Offset(cx, groundY - bodyH / 2),
      width: r * 2.0,
      height: bodyH,
    );
    final tail = Path()
      ..moveTo(body.right - r * 0.2, body.center.dy)
      ..quadraticBezierTo(body.right + r * 0.9, body.center.dy - r * 0.1,
          body.right + r * 0.7, body.top - r * 0.2);
    canvas.drawPath(
      tail,
      Paint()
        ..color = furShade
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.14
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
        Offset(body.right + r * 0.7, body.top - r * 0.25), r * 0.17, Paint()..color = mane);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(r * 0.8)),
      Paint()..color = fur,
    );
    // paws
    final pawY = groundY - r * 0.12;
    for (final dx in [-0.55, 0.55]) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx + dx * r, pawY), width: r * 0.6, height: r * 0.3),
        Paint()..color = furShade,
      );
    }

    // mane
    if (stage != Stage.cub) {
      final petals = stage == Stage.adult ? 14 : 10;
      final maneR = r * (stage == Stage.adult ? 1.5 : 1.25);
      for (var i = 0; i < petals; i++) {
        final a = i * 2 * math.pi / petals;
        canvas.drawCircle(
          headC + Offset(math.cos(a), math.sin(a)) * (maneR - r * 0.32),
          r * 0.42,
          Paint()..color = i.isEven ? mane : maneLight,
        );
      }
      canvas.drawCircle(headC, maneR - r * 0.3, Paint()..color = mane);
    }

    // ears
    for (final dx in [-0.72, 0.72]) {
      final c = headC + Offset(dx * r, -0.72 * r);
      canvas.drawCircle(c, r * 0.3, Paint()..color = fur);
      canvas.drawCircle(c, r * 0.16, Paint()..color = furShade);
    }

    // head + muzzle
    canvas.drawCircle(headC, r, Paint()..color = fur);
    canvas.drawOval(
      Rect.fromCenter(
          center: headC + Offset(0, r * 0.38), width: r * 1.05, height: r * 0.7),
      Paint()..color = muzzle,
    );
    // nose
    final nose = Path()
      ..moveTo(headC.dx - r * 0.15, headC.dy + r * 0.18)
      ..lineTo(headC.dx + r * 0.15, headC.dy + r * 0.18)
      ..lineTo(headC.dx, headC.dy + r * 0.33)
      ..close();
    canvas.drawPath(nose, Paint()..color = ink);

    _face(canvas, headC, r);

    if (mood == Mood.praying) {
      // paws folded under the chin
      for (final dx in [-0.16, 0.16]) {
        canvas.drawOval(
          Rect.fromCenter(
              center: headC + Offset(dx * r, r * 1.02),
              width: r * 0.34,
              height: r * 0.56),
          Paint()..color = furShade,
        );
      }
    }
    if (mood == Mood.sleepy) _zzz(canvas, headC + Offset(r * 1.2, -r * 1.1), r);
  }

  void _face(Canvas canvas, Offset c, double r) {
    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.08
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = ink;
    final eyeY = c.dy - r * 0.15;
    final eyeDx = r * 0.38;
    final eyeR = stage == Stage.cub ? r * 0.13 : r * 0.1;

    for (final dir in [-1, 1]) {
      final e = Offset(c.dx + dir * eyeDx, eyeY);
      switch (mood) {
        case Mood.happy:
          canvas.drawCircle(e, eyeR, fill);
          canvas.drawCircle(e + Offset(-eyeR * 0.3, -eyeR * 0.35), eyeR * 0.35,
              Paint()..color = Colors.white);
        case Mood.sad:
          canvas.drawCircle(e + Offset(0, eyeR * 0.3), eyeR * 0.85, fill);
          // worried brow
          canvas.drawLine(
            // inner end raised = worried (outer end raised would read angry)
            e + Offset(-dir * eyeR * 1.2, -eyeR * 2.3),
            e + Offset(dir * eyeR * 1.4, -eyeR * 1.5),
            stroke,
          );
        case Mood.sleepy:
        case Mood.praying:
          canvas.drawArc(
            Rect.fromCenter(center: e, width: eyeR * 2.6, height: eyeR * 2),
            0.15,
            math.pi - 0.3,
            false,
            stroke,
          );
      }
    }

    final mouthC = c + Offset(0, r * 0.48);
    switch (mood) {
      case Mood.happy:
        canvas.drawArc(
          Rect.fromCenter(center: mouthC, width: r * 0.5, height: r * 0.3),
          0.2,
          math.pi - 0.4,
          false,
          stroke,
        );
        // cheeks
        for (final dir in [-1, 1]) {
          canvas.drawCircle(
            c + Offset(dir * r * 0.62, r * 0.18),
            r * 0.12,
            Paint()..color = const Color(0x55FF7A7A),
          );
        }
      case Mood.sad:
        canvas.drawArc(
          Rect.fromCenter(
              center: mouthC + Offset(0, r * 0.12), width: r * 0.4, height: r * 0.25),
          math.pi + 0.3,
          math.pi - 0.6,
          false,
          stroke,
        );
        // tear
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(c.dx + eyeDx + r * 0.05, eyeY + r * 0.3),
              width: r * 0.12,
              height: r * 0.2),
          Paint()..color = const Color(0xFF7CC3F0),
        );
      case Mood.sleepy:
        canvas.drawCircle(mouthC, r * 0.06, fill);
      case Mood.praying:
        canvas.drawArc(
          Rect.fromCenter(center: mouthC, width: r * 0.3, height: r * 0.18),
          0.2,
          math.pi - 0.4,
          false,
          stroke,
        );
    }
  }

  void _zzz(Canvas canvas, Offset at, double r) {
    for (var i = 0; i < 3; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: 'z',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9 - i * 0.2),
            fontSize: r * (0.4 + i * 0.15),
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, at + Offset(i * r * 0.3, -i * r * 0.35));
    }
  }

  void _scene(Canvas canvas, Size size) {
    final c = SceneColors.of(scene);
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.top, c.bottom],
        ).createShader(rect),
    );
    final w = size.width, h = size.height;
    switch (scene) {
      case Scene.morning:
        canvas.drawCircle(Offset(w * 0.18, h * 0.6), h * 0.12,
            Paint()..color = const Color(0xFFFFB566));
      case Scene.day:
        canvas.drawCircle(Offset(w * 0.82, h * 0.2), h * 0.09,
            Paint()..color = const Color(0xFFFFE07A));
      case Scene.evening:
        canvas.drawCircle(Offset(w * 0.8, h * 0.66), h * 0.13,
            Paint()..color = const Color(0xFFFFC27A));
      case Scene.night:
        canvas.drawCircle(Offset(w * 0.8, h * 0.2), h * 0.08,
            Paint()..color = const Color(0xFFFFF4C9));
        canvas.drawCircle(Offset(w * 0.83, h * 0.18), h * 0.07,
            Paint()..color = c.top);
        final star = Paint()..color = Colors.white.withValues(alpha: 0.85);
        for (final p in const [
          Offset(0.12, 0.15), Offset(0.3, 0.3), Offset(0.5, 0.12),
          Offset(0.65, 0.35), Offset(0.2, 0.45), Offset(0.92, 0.42),
        ]) {
          canvas.drawCircle(Offset(w * p.dx, h * p.dy), h * 0.01, star);
        }
    }
    final hill = Path()
      ..moveTo(0, h * 0.82)
      ..quadraticBezierTo(w * 0.5, h * 0.74, w, h * 0.84)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hill, Paint()..color = c.ground);
  }

  @override
  bool shouldRepaint(_JudahPainter old) =>
      old.stage != stage ||
      old.mood != mood ||
      old.scene != scene ||
      old.showScene != showScene;
}
