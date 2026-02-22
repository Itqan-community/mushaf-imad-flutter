import 'package:flutter/material.dart';

/// Reading theme for Mushaf pages.
/// Controls background color, text color, and other visual settings.
enum ReadingTheme { light, dark, sepia, warmDark }

/// Color presets for reading themes.
class MushafColors {
  MushafColors._();

  // Light theme
  static const lightBackground = Color(0xFFFFF8E1);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF1B1B1B);
  static const lightSecondaryText = Color(0xFF666666);

  // Dark theme
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkText = Color(0xFFE0E0E0);
  static const darkSecondaryText = Color(0xFF999999);

  // Sepia theme
  static const sepiaBackground = Color(0xFFF5E6CC);
  static const sepiaSurface = Color(0xFFF5E6CC);
  static const sepiaText = Color(0xFF5B4636);
  static const sepiaSecondaryText = Color(0xFF8B7355);

  // Warm dark theme
  static const warmDarkBackground = Color(0xFF1A1410);
  static const warmDarkSurface = Color(0xFF2A2018);
  static const warmDarkText = Color(0xFFD4C4A8);
  static const warmDarkSecondaryText = Color(0xFF9A8A70);

  // AMOLED
  static const amoledBackground = Color(0xFF000000);
  static const amoledSurface = Color(0xFF0A0A0A);

  // Accent colors
  static const primaryGold = Color(0xFFD4A574);
  static const primaryGreen = Color(0xFF2E7D32);
  static const highlightYellow = Color(0x33FFD700);
  static const highlightBlue = Color(0x334A90D9);
}

/// Color scheme data for a reading theme.
class ReadingThemeData {
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textColor;
  final Color secondaryTextColor;
  final Color accentColor;
  final Color highlightColor;

  const ReadingThemeData({
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.accentColor,
    required this.highlightColor,
  });

  /// Get theme data for a reading theme.
  static ReadingThemeData fromTheme(ReadingTheme theme) {
    return switch (theme) {
      ReadingTheme.light => const ReadingThemeData(
        backgroundColor: MushafColors.lightBackground,
        surfaceColor: MushafColors.lightSurface,
        textColor: MushafColors.lightText,
        secondaryTextColor: MushafColors.lightSecondaryText,
        accentColor: MushafColors.primaryGold,
        highlightColor: MushafColors.highlightYellow,
      ),
      ReadingTheme.dark => const ReadingThemeData(
        backgroundColor: MushafColors.darkBackground,
        surfaceColor: MushafColors.darkSurface,
        textColor: MushafColors.darkText,
        secondaryTextColor: MushafColors.darkSecondaryText,
        accentColor: MushafColors.primaryGold,
        highlightColor: MushafColors.highlightBlue,
      ),
      ReadingTheme.sepia => const ReadingThemeData(
        backgroundColor: MushafColors.sepiaBackground,
        surfaceColor: MushafColors.sepiaSurface,
        textColor: MushafColors.sepiaText,
        secondaryTextColor: MushafColors.sepiaSecondaryText,
        accentColor: MushafColors.primaryGold,
        highlightColor: MushafColors.highlightYellow,
      ),
      ReadingTheme.warmDark => const ReadingThemeData(
        backgroundColor: MushafColors.warmDarkBackground,
        surfaceColor: MushafColors.warmDarkSurface,
        textColor: MushafColors.warmDarkText,
        secondaryTextColor: MushafColors.warmDarkSecondaryText,
        accentColor: MushafColors.primaryGold,
        highlightColor: MushafColors.highlightBlue,
      ),
    };
  }
}
