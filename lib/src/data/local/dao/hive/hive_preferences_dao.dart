import 'dart:async';
import 'package:hive/hive.dart';

import '../../../../domain/models/mushaf_type.dart';
import '../../../../domain/models/theme.dart';

class HivePreferencesDao {
  static const String _boxName = 'preferences';
  Box? _box;

  Future<Box> get _openBox async {
    _box ??= await Hive.openBox(_boxName);
    return _box!;
  }

  // Keys
  static const _kMushafType = 'mushafType';
  static const _kCurrentPage = 'currentPage';
  static const _kLastReadChapter = 'lastReadChapter';
  static const _kLastReadVerseChapter = 'lastReadVerseChapter';
  static const _kLastReadVerseNumber = 'lastReadVerseNumber';
  static const _kFontSizeMultiplier = 'fontSizeMultiplier';
  static const _kShowTranslation = 'showTranslation';
  static const _kSelectedReciterId = 'selectedReciterId';
  static const _kPlaybackSpeed = 'playbackSpeed';
  static const _kRepeatMode = 'repeatMode';
  static const _kLastAudioChapter = 'lastAudioChapter';
  static const _kLastAudioVerse = 'lastAudioVerse';
  static const _kLastAudioPositionMs = 'lastAudioPositionMs';
  static const _kThemeMode = 'themeMode';
  static const _kColorScheme = 'colorScheme';
  static const _kUseAmoled = 'useAmoled';

  // Mushaf Reading

  Future<MushafType> getMushafType() async {
    final box = await _openBox;
    final index = box.get(_kMushafType, defaultValue: 0) as int;
    return MushafType.values[index.clamp(0, MushafType.values.length - 1)];
  }

  Future<void> setMushafType(MushafType type) async {
    final box = await _openBox;
    await box.put(_kMushafType, type.index);
  }

  Future<int> getCurrentPage() async {
    final box = await _openBox;
    return box.get(_kCurrentPage, defaultValue: 1) as int;
  }

  Future<void> setCurrentPage(int page) async {
    final box = await _openBox;
    await box.put(_kCurrentPage, page);
  }

  Future<int?> getLastReadChapter() async {
    final box = await _openBox;
    return box.get(_kLastReadChapter) as int?;
  }

  Future<void> setLastReadChapter(int chapter) async {
    final box = await _openBox;
    await box.put(_kLastReadChapter, chapter);
  }

  Future<(int, int)?> getLastReadVerse() async {
    final box = await _openBox;
    final ch = box.get(_kLastReadVerseChapter) as int?;
    final v = box.get(_kLastReadVerseNumber) as int?;
    if (ch != null && v != null) return (ch, v);
    return null;
  }

  Future<void> setLastReadVerse(int chapter, int verse) async {
    final box = await _openBox;
    await box.put(_kLastReadVerseChapter, chapter);
    await box.put(_kLastReadVerseNumber, verse);
  }

  Future<double> getFontSizeMultiplier() async {
    final box = await _openBox;
    return (box.get(_kFontSizeMultiplier, defaultValue: 1.0) as num)
        .toDouble();
  }

  Future<void> setFontSizeMultiplier(double multiplier) async {
    final box = await _openBox;
    await box.put(_kFontSizeMultiplier, multiplier);
  }

  Future<bool> getShowTranslation() async {
    final box = await _openBox;
    return box.get(_kShowTranslation, defaultValue: false) as bool;
  }

  Future<void> setShowTranslation(bool show) async {
    final box = await _openBox;
    await box.put(_kShowTranslation, show);
  }

  // Audio

  Future<int> getSelectedReciterId() async {
    final box = await _openBox;
    return box.get(_kSelectedReciterId, defaultValue: 1) as int;
  }

  Future<void> setSelectedReciterId(int id) async {
    final box = await _openBox;
    await box.put(_kSelectedReciterId, id);
  }

  Future<double> getPlaybackSpeed() async {
    final box = await _openBox;
    return (box.get(_kPlaybackSpeed, defaultValue: 1.0) as num).toDouble();
  }

  Future<void> setPlaybackSpeed(double speed) async {
    final box = await _openBox;
    await box.put(_kPlaybackSpeed, speed);
  }

  Future<bool> getRepeatMode() async {
    final box = await _openBox;
    return box.get(_kRepeatMode, defaultValue: false) as bool;
  }

  Future<void> setRepeatMode(bool enabled) async {
    final box = await _openBox;
    await box.put(_kRepeatMode, enabled);
  }

  Future<int?> getLastAudioChapter() async {
    final box = await _openBox;
    return box.get(_kLastAudioChapter) as int?;
  }

  Future<void> setLastAudioChapter(int? chapter) async {
    final box = await _openBox;
    if (chapter != null) {
      await box.put(_kLastAudioChapter, chapter);
    } else {
      await box.delete(_kLastAudioChapter);
    }
  }

  Future<int?> getLastAudioVerse() async {
    final box = await _openBox;
    return box.get(_kLastAudioVerse) as int?;
  }

  Future<void> setLastAudioVerse(int? verse) async {
    final box = await _openBox;
    if (verse != null) {
      await box.put(_kLastAudioVerse, verse);
    } else {
      await box.delete(_kLastAudioVerse);
    }
  }

  Future<int> getLastAudioPositionMs() async {
    final box = await _openBox;
    return box.get(_kLastAudioPositionMs, defaultValue: 0) as int;
  }

  Future<void> setLastAudioPositionMs(int ms) async {
    final box = await _openBox;
    await box.put(_kLastAudioPositionMs, ms);
  }

  // Theme

  Future<ThemeConfig> getThemeConfig() async {
    final box = await _openBox;
    final modeIndex = box.get(_kThemeMode, defaultValue: 2) as int;
    final schemeIndex = box.get(_kColorScheme, defaultValue: 0) as int;
    final useAmoled = box.get(_kUseAmoled, defaultValue: false) as bool;

    return ThemeConfig(
      mode: MushafThemeMode
          .values[modeIndex.clamp(0, MushafThemeMode.values.length - 1)],
      colorScheme: MushafColorScheme
          .values[schemeIndex.clamp(0, MushafColorScheme.values.length - 1)],
      useAmoled: useAmoled,
    );
  }

  Future<void> setThemeMode(MushafThemeMode mode) async {
    final box = await _openBox;
    await box.put(_kThemeMode, mode.index);
  }

  Future<void> setColorScheme(MushafColorScheme scheme) async {
    final box = await _openBox;
    await box.put(_kColorScheme, scheme.index);
  }

  Future<void> setUseAmoled(bool enabled) async {
    final box = await _openBox;
    await box.put(_kUseAmoled, enabled);
  }

  Future<void> updateThemeConfig(ThemeConfig config) async {
    final box = await _openBox;
    await box.put(_kThemeMode, config.mode.index);
    await box.put(_kColorScheme, config.colorScheme.index);
    await box.put(_kUseAmoled, config.useAmoled);
  }

  // General

  Future<void> clearAll() async {
    final box = await _openBox;
    await box.clear();
  }
}
