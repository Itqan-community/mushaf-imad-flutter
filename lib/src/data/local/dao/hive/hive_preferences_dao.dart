import 'package:hive/hive.dart';

import '../../../../domain/models/mushaf_type.dart';
import '../../../../domain/models/theme.dart';
import '../preferences_dao.dart';

/// Hive-backed implementation of [PreferencesDao].
///
/// All preferences are stored in a single Hive box named `preferences`.
/// Keys are defined as constants to avoid typos.
class HivePreferencesDao implements PreferencesDao {
  static const String _boxName = 'preferences';

  // Key constants
  static const _kCurrentPage = 'current_page';
  static const _kMushafType = 'mushaf_type';
  static const _kLastReadChapter = 'last_read_chapter';
  static const _kLastReadVerseChapter = 'last_read_verse_chapter';
  static const _kLastReadVerseNumber = 'last_read_verse_number';
  static const _kFontSizeMultiplier = 'font_size_multiplier';
  static const _kShowTranslation = 'show_translation';
  static const _kSelectedReciterId = 'selected_reciter_id';
  static const _kPlaybackSpeed = 'playback_speed';
  static const _kRepeatMode = 'repeat_mode';
  static const _kLastAudioChapter = 'last_audio_chapter';
  static const _kLastAudioVerse = 'last_audio_verse';
  static const _kLastAudioPositionMs = 'last_audio_position_ms';
  static const _kThemeMode = 'theme_mode';
  static const _kColorScheme = 'color_scheme';
  static const _kUseAmoled = 'use_amoled';

  Future<Box> get _box async => Hive.openBox(_boxName);

  // ── Reading ──────────────────────────────────────────────────────────────

  @override
  Future<int> getCurrentPage() async {
    final box = await _box;
    return (box.get(_kCurrentPage, defaultValue: 1) as int).clamp(1, 604);
  }

  @override
  Future<void> setCurrentPage(int page) async {
    final box = await _box;
    await box.put(_kCurrentPage, page.clamp(1, 604));
  }

  @override
  Future<MushafType> getMushafType() async {
    final box = await _box;
    final index = box.get(_kMushafType, defaultValue: 0) as int;
    return MushafType.values[index.clamp(0, MushafType.values.length - 1)];
  }

  @override
  Future<void> setMushafType(MushafType type) async {
    final box = await _box;
    await box.put(_kMushafType, type.index);
  }

  @override
  Future<int?> getLastReadChapter() async {
    final box = await _box;
    return box.get(_kLastReadChapter) as int?;
  }

  @override
  Future<void> setLastReadChapter(int chapter) async {
    final box = await _box;
    await box.put(_kLastReadChapter, chapter);
  }

  @override
  Future<(int, int)?> getLastReadVerse() async {
    final box = await _box;
    final ch = box.get(_kLastReadVerseChapter) as int?;
    final v = box.get(_kLastReadVerseNumber) as int?;
    if (ch == null || v == null) return null;
    return (ch, v);
  }

  @override
  Future<void> setLastReadVerse(int chapter, int verse) async {
    final box = await _box;
    await box.put(_kLastReadVerseChapter, chapter);
    await box.put(_kLastReadVerseNumber, verse);
  }

  @override
  Future<double> getFontSizeMultiplier() async {
    final box = await _box;
    return (box.get(_kFontSizeMultiplier, defaultValue: 1.0) as num).toDouble();
  }

  @override
  Future<void> setFontSizeMultiplier(double multiplier) async {
    final box = await _box;
    await box.put(_kFontSizeMultiplier, multiplier.clamp(0.5, 2.0));
  }

  @override
  Future<bool> getShowTranslation() async {
    final box = await _box;
    return box.get(_kShowTranslation, defaultValue: false) as bool;
  }

  @override
  Future<void> setShowTranslation(bool show) async {
    final box = await _box;
    await box.put(_kShowTranslation, show);
  }

  // ── Audio ─────────────────────────────────────────────────────────────────

  @override
  Future<int> getSelectedReciterId() async {
    final box = await _box;
    return box.get(_kSelectedReciterId, defaultValue: 1) as int;
  }

  @override
  Future<void> setSelectedReciterId(int id) async {
    final box = await _box;
    await box.put(_kSelectedReciterId, id);
  }

  @override
  Future<double> getPlaybackSpeed() async {
    final box = await _box;
    return (box.get(_kPlaybackSpeed, defaultValue: 1.0) as num).toDouble();
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    final box = await _box;
    await box.put(_kPlaybackSpeed, speed);
  }

  @override
  Future<bool> getRepeatMode() async {
    final box = await _box;
    return box.get(_kRepeatMode, defaultValue: false) as bool;
  }

  @override
  Future<void> setRepeatMode(bool enabled) async {
    final box = await _box;
    await box.put(_kRepeatMode, enabled);
  }

  @override
  Future<int?> getLastAudioChapter() async {
    final box = await _box;
    return box.get(_kLastAudioChapter) as int?;
  }

  @override
  Future<void> setLastAudioChapter(int? chapter) async {
    final box = await _box;
    if (chapter == null) {
      await box.delete(_kLastAudioChapter);
    } else {
      await box.put(_kLastAudioChapter, chapter);
    }
  }

  @override
  Future<int?> getLastAudioVerse() async {
    final box = await _box;
    return box.get(_kLastAudioVerse) as int?;
  }

  @override
  Future<void> setLastAudioVerse(int? verse) async {
    final box = await _box;
    if (verse == null) {
      await box.delete(_kLastAudioVerse);
    } else {
      await box.put(_kLastAudioVerse, verse);
    }
  }

  @override
  Future<int> getLastAudioPositionMs() async {
    final box = await _box;
    return box.get(_kLastAudioPositionMs, defaultValue: 0) as int;
  }

  @override
  Future<void> setLastAudioPositionMs(int ms) async {
    final box = await _box;
    await box.put(_kLastAudioPositionMs, ms);
  }

  // ── Theme ─────────────────────────────────────────────────────────────────

  @override
  Future<ThemeConfig> getThemeConfig() async {
    final box = await _box;
    final modeIndex = box.get(_kThemeMode, defaultValue: MushafThemeMode.system.index) as int;
    final schemeIndex = box.get(_kColorScheme, defaultValue: MushafColorScheme.defaultScheme.index) as int;
    final amoled = box.get(_kUseAmoled, defaultValue: false) as bool;
    return ThemeConfig(
      mode: MushafThemeMode.values[modeIndex.clamp(0, MushafThemeMode.values.length - 1)],
      colorScheme: MushafColorScheme.values[schemeIndex.clamp(0, MushafColorScheme.values.length - 1)],
      useAmoled: amoled,
    );
  }

  @override
  Future<void> setThemeConfig(ThemeConfig config) async {
    final box = await _box;
    await box.put(_kThemeMode, config.mode.index);
    await box.put(_kColorScheme, config.colorScheme.index);
    await box.put(_kUseAmoled, config.useAmoled);
  }

  // ── General ───────────────────────────────────────────────────────────────

  @override
  Future<void> clearAll() async {
    final box = await _box;
    await box.clear();
  }
}
