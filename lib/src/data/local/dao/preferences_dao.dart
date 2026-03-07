import '../../../domain/models/mushaf_type.dart';
import '../../../domain/models/theme.dart';

/// Data Access Object interface for user preferences.
/// Abstraction layer for persisting settings.
abstract class PreferencesDao {
  // Mushaf
  Future<MushafType?> getMushafType();
  Future<void> saveMushafType(MushafType type);

  Future<int?> getCurrentPage();
  Future<void> saveCurrentPage(int page);

  Future<int?> getLastReadChapter();
  Future<void> saveLastReadChapter(int? chapter);

  Future<int?> getLastReadVerseChapter();
  Future<int?> getLastReadVerseNumber();
  Future<void> saveLastReadVerse(int? chapter, int? verse);

  Future<double?> getFontSizeMultiplier();
  Future<void> saveFontSizeMultiplier(double multiplier);

  Future<bool?> getShowTranslation();
  Future<void> saveShowTranslation(bool show);

  // Audio
  Future<int?> getSelectedReciterId();
  Future<void> saveSelectedReciterId(int reciterId);

  Future<double?> getPlaybackSpeed();
  Future<void> savePlaybackSpeed(double speed);

  Future<bool?> getRepeatMode();
  Future<void> saveRepeatMode(bool enabled);

  Future<bool?> getShowAudioPlayer();
  Future<void> saveShowAudioPlayer(bool show);

  // Theme
  Future<ThemeConfig?> getThemeConfig();
  Future<void> saveThemeConfig(ThemeConfig config);

  // General
  Future<void> clearAll();
}
