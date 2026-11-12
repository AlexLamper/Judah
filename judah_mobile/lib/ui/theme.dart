import 'package:material_ui/material_ui.dart';

/// Placeholder palette ("warm golden/sand"). The final colours come from the
/// design variants; everything reads from here so swapping is one file.
class JudahColors {
  static const sand = Color(0xFFFFF7EC);
  static const card = Colors.white;
  static const gold = Color(0xFFF2A93B);
  static const goldDark = Color(0xFFC97E14);
  static const mane = Color(0xFFB8642B);
  static const ink = Color(0xFF3B2A1E);
  static const inkSoft = Color(0xFF7A6656);
  static const done = Color(0xFF5BAF6E);
  static const line = Color(0xFFF0E2CF);
}

ThemeData judahTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: JudahColors.gold,
    primary: JudahColors.goldDark,
    surface: JudahColors.sand,
  );
  const body = 'Nunito';
  const display = 'Fredoka';
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: JudahColors.sand,
    fontFamily: body,
    textTheme: const TextTheme(
      displaySmall: TextStyle(
          fontFamily: display, fontWeight: FontWeight.w700, color: JudahColors.ink),
      headlineSmall: TextStyle(
          fontFamily: display, fontWeight: FontWeight.w600, color: JudahColors.ink),
      titleLarge: TextStyle(
          fontFamily: display, fontWeight: FontWeight.w600, color: JudahColors.ink),
      titleMedium: TextStyle(fontWeight: FontWeight.w800, color: JudahColors.ink),
      bodyLarge: TextStyle(fontWeight: FontWeight.w600, color: JudahColors.ink, height: 1.45),
      bodyMedium: TextStyle(fontWeight: FontWeight.w600, color: JudahColors.inkSoft),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: JudahColors.sand,
      foregroundColor: JudahColors.ink,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
          fontFamily: display,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: JudahColors.ink),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: JudahColors.goldDark,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        textStyle: const TextStyle(
            fontFamily: body, fontWeight: FontWeight.w800, fontSize: 17),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: JudahColors.gold.withValues(alpha: 0.25),
      side: const BorderSide(color: JudahColors.line),
      labelStyle: const TextStyle(
          fontFamily: body, fontWeight: FontWeight.w700, color: JudahColors.ink),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
