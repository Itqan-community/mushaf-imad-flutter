import '../models/mushaf_type.dart';
import '../models/result.dart';
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
  Future<Result<void>> setMushafType(MushafType mushafType);

  /// Get the current page number as a Stream.
  Stream<int> getCurrentPageStream();

  /// Set the current page number.
  Future<Result<void>> setCurrentPage(int pageNumber);

  /// Get the last read chapter number as a Stream.
  Stream<int?> getLastReadChapterStream();

  /// Set the last read chapter number.
  Future<Result<void>> setLastReadChapter(int chapterNumber);

  /// Get the last read verse as a Stream. Returns (int chapterNumber, int verseNumber).
  Stream<(int, int)?> getLastReadVerseStream();

  /// Set the last read verse.
  Future<Result<void>> setLastReadVerse(int chapterNumber, int verseNumber);

  /// Get the font size multiplier as a Stream.
  Stream<double> getFontSizeMultiplierStream();

  /// Set the font size multiplier (0.5 to 2.0).
  Future<Result<void>> setFontSizeMultiplier(double multiplier);

  /// Get whether to show translation.
  Stream<bool> getShowTranslationStream();

  /// Set whether to show translation.
  Future<Result<void>> setShowTranslation(bool show);

  // ========== Audio Preferences ==========

  /// Observe the selected reciter ID.
  Stream<int> getSelectedReciterIdStream();

  /// Get the selected reciter ID.
  Future<Result<int>> getSelectedReciterId();

  /// Set the selected reciter ID.
  Future<Result<void>> setSelectedReciterId(int reciterId);

  /// Observe the selected playback speed.
  Stream<double> getPlaybackSpeedStream();

  /// Get the selected playback speed.
  Future<Result<double>> getPlaybackSpeed();

  /// Set the playback speed (0.5 - 3.0).
  Future<Result<void>> setPlaybackSpeed(double speed);

  /// Observe repeat mode.
  Stream<bool> getRepeatModeStream();

  /// Get repeat mode.
  Future<Result<bool>> getRepeatMode();

  /// Set repeat mode.
  Future<Result<void>> setRepeatMode(bool enabled);

  /// Observe last played audio chapter.
  Stream<int?> getLastAudioChapterStream();

  /// Get last played audio chapter.
  Future<Result<int?>> getLastAudioChapter();

  /// Set last played audio chapter.
  Future<Result<void>> setLastAudioChapter(int? chapterNumber);

  /// Observe last played audio verse.
  Stream<int?> getLastAudioVerseStream();

  /// Get last played audio verse.
  Future<Result<int?>> getLastAudioVerse();

  /// Set last played audio verse.
  Future<Result<void>> setLastAudioVerse(int? verseNumber);

  /// Observe last audio playback position in milliseconds.
  Stream<int> getLastAudioPositionMsStream();

  /// Get last audio playback position in milliseconds.
  Future<Result<int>> getLastAudioPositionMs();

  /// Set last audio playback position.
  Future<Result<void>> setLastAudioPositionMs(int positionMs);

  /// Observe whether to show the audio player bar.
  Stream<bool> getShowAudioPlayerStream();

  /// Get whether to show the audio player bar.
  Future<Result<bool>> getShowAudioPlayer();

  /// Set whether to show the audio player bar.
  Future<Result<void>> setShowAudioPlayer(bool show);

  // ========== Theme Preferences ==========

  /// Observe theme configuration.
  Stream<ThemeConfig> getThemeConfigStream();

  /// Get current theme configuration.
  Future<Result<ThemeConfig>> getThemeConfig();

  /// Set theme mode.
  Future<Result<void>> setThemeMode(MushafThemeMode mode);

  /// Set color scheme.
  Future<Result<void>> setColorScheme(MushafColorScheme scheme);

  /// Set AMOLED mode (pure black for dark theme).
  Future<Result<void>> setAmoledMode(bool enabled);

  /// Update complete theme configuration.
  Future<Result<void>> updateThemeConfig(ThemeConfig config);

  // ========== General ==========

  /// Clear all preferences.
  Future<Result<void>> clearAll();
}
