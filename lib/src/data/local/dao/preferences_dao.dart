import '../../../domain/models/mushaf_type.dart';
import '../../../domain/models/theme.dart';

/// Data Access Object interface for user preferences persistence.
abstract class PreferencesDao {
  // Reading
  Future<int> getCurrentPage();
  Future<void> setCurrentPage(int page);

  Future<MushafType> getMushafType();
  Future<void> setMushafType(MushafType type);

  Future<int?> getLastReadChapter();
  Future<void> setLastReadChapter(int chapter);

  Future<(int, int)?> getLastReadVerse();
  Future<void> setLastReadVerse(int chapter, int verse);

  Future<double> getFontSizeMultiplier();
  Future<void> setFontSizeMultiplier(double multiplier);

  Future<bool> getShowTranslation();
  Future<void> setShowTranslation(bool show);

  // Audio
  Future<int> getSelectedReciterId();
  Future<void> setSelectedReciterId(int id);

  Future<double> getPlaybackSpeed();
  Future<void> setPlaybackSpeed(double speed);

  Future<bool> getRepeatMode();
  Future<void> setRepeatMode(bool enabled);

  Future<int?> getLastAudioChapter();
  Future<void> setLastAudioChapter(int? chapter);

  Future<int?> getLastAudioVerse();
  Future<void> setLastAudioVerse(int? verse);

  Future<int> getLastAudioPositionMs();
  Future<void> setLastAudioPositionMs(int ms);

  // Theme
  Future<ThemeConfig> getThemeConfig();
  Future<void> setThemeConfig(ThemeConfig config);

  // General
  Future<void> clearAll();
}
