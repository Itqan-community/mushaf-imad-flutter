import 'package:hive_flutter/hive_flutter.dart';
import '../../../../domain/models/mushaf_type.dart';
import '../../../../domain/models/theme.dart';
import '../preferences_dao.dart';

/// Hive implementation of [PreferencesDao].
class HivePreferencesDao implements PreferencesDao {
  static const String boxName = 'mushaf_preferences';
  
  // Keys
  static const String keyMushafType = 'mushaf_type';
  static const String keyCurrentPage = 'current_page';
  static const String keyLastReadChapter = 'last_read_chapter';
  static const String keyLastReadVerseChapter = 'last_read_verse_chapter';
  static const String keyLastReadVerseNumber = 'last_read_verse_number';
  static const String keyFontSizeMultiplier = 'font_size_multiplier';
  static const String keyShowTranslation = 'show_translation';
  static const String keyReciterId = 'reciter_id';
  static const String keyPlaybackSpeed = 'playback_speed';
  static const String keyRepeatMode = 'repeat_mode';
  static const String keyThemeMode = 'theme_mode';
  static const String keyColorScheme = 'color_scheme';
  static const String keyUseAmoled = 'use_amoled';
  static const String keyShowAudioPlayer = 'show_audio_player';

  Box get _box => Hive.box(boxName);

  @override
  Future<MushafType?> getMushafType() async {
    final index = _box.get(keyMushafType) as int?;
    if (index == null) return null;
    return MushafType.values[index];
  }

  @override
  Future<void> saveMushafType(MushafType type) async {
    await _box.put(keyMushafType, type.index);
  }

  @override
  Future<int?> getCurrentPage() async => _box.get(keyCurrentPage) as int?;

  @override
  Future<void> saveCurrentPage(int page) async => await _box.put(keyCurrentPage, page);

  @override
  Future<int?> getLastReadChapter() async => _box.get(keyLastReadChapter) as int?;

  @override
  Future<void> saveLastReadChapter(int? chapter) async => await _box.put(keyLastReadChapter, chapter);

  @override
  Future<int?> getLastReadVerseChapter() async => _box.get(keyLastReadVerseChapter) as int?;

  @override
  Future<int?> getLastReadVerseNumber() async => _box.get(keyLastReadVerseNumber) as int?;

  @override
  Future<void> saveLastReadVerse(int? chapter, int? verse) async {
    await _box.put(keyLastReadVerseChapter, chapter);
    await _box.put(keyLastReadVerseNumber, verse);
  }

  @override
  Future<double?> getFontSizeMultiplier() async => _box.get(keyFontSizeMultiplier) as double?;

  @override
  Future<void> saveFontSizeMultiplier(double multiplier) async => await _box.put(keyFontSizeMultiplier, multiplier);

  @override
  Future<bool?> getShowTranslation() async => _box.get(keyShowTranslation) as bool?;

  @override
  Future<void> saveShowTranslation(bool show) async => await _box.put(keyShowTranslation, show);

  @override
  Future<int?> getSelectedReciterId() async => _box.get(keyReciterId) as int?;

  @override
  Future<void> saveSelectedReciterId(int reciterId) async => await _box.put(keyReciterId, reciterId);

  @override
  Future<double?> getPlaybackSpeed() async => _box.get(keyPlaybackSpeed) as double?;

  @override
  Future<void> savePlaybackSpeed(double speed) async => await _box.put(keyPlaybackSpeed, speed);

  @override
  Future<bool?> getRepeatMode() async => _box.get(keyRepeatMode) as bool?;

  @override
  Future<void> saveRepeatMode(bool enabled) async => await _box.put(keyRepeatMode, enabled);

  @override
  Future<bool?> getShowAudioPlayer() async => _box.get(keyShowAudioPlayer) as bool?;

  @override
  Future<void> saveShowAudioPlayer(bool show) async => await _box.put(keyShowAudioPlayer, show);

  @override
  Future<ThemeConfig?> getThemeConfig() async {
    final modeIndex = _box.get(keyThemeMode) as int?;
    final schemeIndex = _box.get(keyColorScheme) as int?;
    final amoled = _box.get(keyUseAmoled) as bool?;

    if (modeIndex == null && schemeIndex == null && amoled == null) return null;

    return ThemeConfig(
      mode: modeIndex != null ? MushafThemeMode.values[modeIndex] : MushafThemeMode.system,
      colorScheme: schemeIndex != null ? MushafColorScheme.values[schemeIndex] : MushafColorScheme.defaultScheme,
      useAmoled: amoled ?? false,
    );
  }

  @override
  Future<void> saveThemeConfig(ThemeConfig config) async {
    await _box.put(keyThemeMode, config.mode.index);
    await _box.put(keyColorScheme, config.colorScheme.index);
    await _box.put(keyUseAmoled, config.useAmoled);
  }

  @override
  Future<void> clearAll() async => await _box.clear();
}
