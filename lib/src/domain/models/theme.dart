/// Theme mode for the application.
/// Public API - exposed to library consumers.
enum MushafThemeMode {
  light,
  dark,
  system, // Follow system theme
}

/// Color scheme options.
/// Public API - exposed to library consumers.
enum MushafColorScheme { defaultScheme, warm, cool, sepia }

/// Theme configuration.
/// Public API - exposed to library consumers.
class ThemeConfig {
  final MushafThemeMode mode;
  final MushafColorScheme colorScheme;
  final bool useAmoled; // Pure black for AMOLED screens

  const ThemeConfig({
    this.mode = MushafThemeMode.system,
    this.colorScheme = MushafColorScheme.defaultScheme,
    this.useAmoled = false,
  });
}
