import 'package:flutter/material.dart';

class TileColors {
  final Color correct;
  final Color present;
  final Color absent;
  final Color emptyBorder;

  const TileColors({
    required this.correct,
    required this.present,
    required this.absent,
    required this.emptyBorder,
  });

  // Matches the Wordie mockups: mint correct, warm yellow present,
  // soft lavender-grey for absent/borders.
  static const classic = TileColors(
    correct: Color(0xFFA8E6C9),
    present: Color(0xFFF5DE8B),
    absent: Color(0xFFD8D6EC),
    emptyBorder: Color(0xFFD8D6EC),
  );

  // High-contrast / colorblind-friendly alternative (Profile setting).
  static const highContrast = TileColors(
    correct: Color(0xFFE8820C),
    present: Color(0xFF3B82F6),
    absent: Color(0xFF8A8A8A),
    emptyBorder: Color(0xFF8A8A8A),
  );
}

class KeyboardColors {
  static const background = Color(0xFFFBEEF7);
  static const keyA = Color(0xFFC9C8F5); // lavender - unused letter
  static const keyB = Color(0xFFEBD6F2); // pink-lavender - unused letter
  static const border = Color(0xFFD8D6EC);
  static const textColor = Color(0xFF423B54);
}

class BrandColors {
  static const background = Color(0xFFFDF2F8);
  static const primary = Color(0xFF7C6FD1); // duel/leaderboard accent (indigo)
  static const accentMint = Color(0xFFA8E6C9);
  static const accentGold = Color(0xFFF5DE8B);
  static const textDark = Color(0xFF2E2A3D);
  static const border = Color(0xFFD8D6EC);
}

class AppTheme {
  static ThemeData light() => ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: BrandColors.background,
        colorSchemeSeed: BrandColors.primary,
        fontFamily: 'Roboto',
      );

  static ThemeData dark() => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: BrandColors.primary,
        scaffoldBackgroundColor: const Color(0xFF17151F),
      );
}
