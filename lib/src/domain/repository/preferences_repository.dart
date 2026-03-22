import '../models/mushaf_type.dart';
import '../models/theme.dart';

/// Repository for all user preferences and settings.
/// Public API - exposed to library consumers.
///
/// Consolidated repository for:
/// - Mushaf reading preferences (page, chapter, verse, font size, translation)
/// - Audio preferences (reciter, playback speed, repeat mode)
/// - Theme preferences (theme mode, color scheme, AMOLED mode)
abstract class PreferencesRepository {
  // ========== Mushaf Reading Preferences ==========

  /// Get the selected Mushaf type as a Stream.
  Stream<MushafType> getMushafTypeStream();

  /// Set the selected Mushaf type.
  Future<void> setMushafType(MushafType mushafType);

  /// Get the current page number as a Stream.
  Stream<int> getCurrentPageStream();

  /// Get the current page number.
  Future<int> getCurrentPage();

  /// Set the current page number.
  Future<void> setCurrentPage(int pageNumber);

  /// Get the last read chapter number as a Stream.
  Stream<int?> getLastReadChapterStream();

  /// Set the last read chapter number.
  Future<void> setLastReadChapter(int chapterNumber);

  /// Get the last read verse as a Stream. Returns (chapterNumber, verseNumber).
  Stream<(int, int)?> getLastReadVerseStream();

  /// Set the last read verse.
  Future<void> setLastReadVerse(int chapterNumber, int verseNumber);

  /// Get the font size multiplier as a Stream.
  Stream<double> getFontSizeMultiplierStream();

  /// Set the font size multiplier (0.5 to 2.0).
  Future<void> setFontSizeMultiplier(double multiplier);

  /// Get whether to show translation.
  Stream<bool> getShowTranslationStream();

  /// Set whether to show translation.
  Future<void> setShowTranslation(bool show);

  // ========== Audio Preferences ==========

  /// Observe the selected reciter ID.
  Stream<int> getSelectedReciterIdStream();

  /// Get the selected reciter ID.
  Future<int> getSelectedReciterId();

  /// Set the selected reciter ID.
  Future<void> setSelectedReciterId(int reciterId);

  /// Observe the selected playback speed.
  Stream<double> getPlaybackSpeedStream();

  /// Get the selected playback speed.
  Future<double> getPlaybackSpeed();

  /// Set the playback speed (0.5 - 3.0).
  Future<void> setPlaybackSpeed(double speed);

  /// Observe repeat mode.
  Stream<bool> getRepeatModeStream();

  /// Get repeat mode.
  Future<bool> getRepeatMode();

  /// Set repeat mode.
  Future<void> setRepeatMode(bool enabled);

  /// Observe last played audio chapter.
  Stream<int?> getLastAudioChapterStream();

  /// Get last played audio chapter.
  Future<int?> getLastAudioChapter();

  /// Set last played audio chapter.
  Future<void> setLastAudioChapter(int? chapterNumber);

  /// Observe last played audio verse.
  Stream<int?> getLastAudioVerseStream();

  /// Get last played audio verse.
  Future<int?> getLastAudioVerse();

  /// Set last played audio verse.
  Future<void> setLastAudioVerse(int? verseNumber);

  /// Observe last audio playback position in milliseconds.
  Stream<int> getLastAudioPositionMsStream();

  /// Get last audio playback position in milliseconds.
  Future<int> getLastAudioPositionMs();

  /// Set last audio playback position.
  Future<void> setLastAudioPositionMs(int positionMs);

  // ========== Theme Preferences ==========

  /// Observe theme configuration.
  Stream<ThemeConfig> getThemeConfigStream();

  /// Get current theme configuration.
  Future<ThemeConfig> getThemeConfig();

  /// Set theme mode.
  Future<void> setThemeMode(MushafThemeMode mode);

  /// Set color scheme.
  Future<void> setColorScheme(MushafColorScheme scheme);

  /// Set AMOLED mode (pure black for dark theme).
  Future<void> setAmoledMode(bool enabled);

  /// Update complete theme configuration.
  Future<void> updateThemeConfig(ThemeConfig config);

  // ========== General ==========

  /// Clear all preferences.
  Future<void> clearAll();
}
