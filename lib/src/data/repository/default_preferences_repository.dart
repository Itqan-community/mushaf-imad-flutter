import 'dart:async';

import '../../domain/models/mushaf_type.dart';
import '../../domain/models/theme.dart';
import '../../domain/repository/preferences_repository.dart';
import '../local/dao/hive/hive_preferences_dao.dart';
import '../local/dao/preferences_dao.dart';

/// Default implementation of [PreferencesRepository].
///
/// Persists all preferences via [PreferencesDao] (Hive-backed by default)
/// and exposes reactive [Stream]s via broadcast [StreamController]s.
class DefaultPreferencesRepository implements PreferencesRepository {
  final PreferencesDao _dao;

  // Stream controllers — broadcast so multiple listeners are supported
  final _mushafTypeController = StreamController<MushafType>.broadcast();
  final _currentPageController = StreamController<int>.broadcast();
  final _lastReadChapterController = StreamController<int?>.broadcast();
  final _lastReadVerseController = StreamController<(int, int)?>.broadcast();
  final _fontSizeController = StreamController<double>.broadcast();
  final _showTranslationController = StreamController<bool>.broadcast();
  final _reciterIdController = StreamController<int>.broadcast();
  final _playbackSpeedController = StreamController<double>.broadcast();
  final _repeatModeController = StreamController<bool>.broadcast();
  final _lastAudioChapterController = StreamController<int?>.broadcast();
  final _lastAudioVerseController = StreamController<int?>.broadcast();
  final _lastAudioPositionController = StreamController<int>.broadcast();
  final _themeConfigController = StreamController<ThemeConfig>.broadcast();

  DefaultPreferencesRepository({PreferencesDao? dao})
      : _dao = dao ?? HivePreferencesDao();

  // ── Mushaf Reading ────────────────────────────────────────────────────────

  @override
  Stream<MushafType> getMushafTypeStream() => _mushafTypeController.stream;

  @override
  Future<void> setMushafType(MushafType mushafType) async {
    await _dao.setMushafType(mushafType);
    _mushafTypeController.add(mushafType);
  }

  @override
  Stream<int> getCurrentPageStream() => _currentPageController.stream;

  @override
  Future<int> getCurrentPage() => _dao.getCurrentPage();

  @override
  Future<void> setCurrentPage(int pageNumber) async {
    await _dao.setCurrentPage(pageNumber);
    _currentPageController.add(pageNumber);
  }

  @override
  Stream<int?> getLastReadChapterStream() => _lastReadChapterController.stream;

  @override
  Future<void> setLastReadChapter(int chapterNumber) async {
    await _dao.setLastReadChapter(chapterNumber);
    _lastReadChapterController.add(chapterNumber);
  }

  @override
  Stream<(int, int)?> getLastReadVerseStream() =>
      _lastReadVerseController.stream;

  @override
  Future<void> setLastReadVerse(int chapterNumber, int verseNumber) async {
    await _dao.setLastReadVerse(chapterNumber, verseNumber);
    _lastReadVerseController.add((chapterNumber, verseNumber));
  }

  @override
  Stream<double> getFontSizeMultiplierStream() => _fontSizeController.stream;

  @override
  Future<void> setFontSizeMultiplier(double multiplier) async {
    await _dao.setFontSizeMultiplier(multiplier);
    _fontSizeController.add(multiplier);
  }

  @override
  Stream<bool> getShowTranslationStream() => _showTranslationController.stream;

  @override
  Future<void> setShowTranslation(bool show) async {
    await _dao.setShowTranslation(show);
    _showTranslationController.add(show);
  }

  // ── Audio ─────────────────────────────────────────────────────────────────

  @override
  Stream<int> getSelectedReciterIdStream() => _reciterIdController.stream;

  @override
  Future<int> getSelectedReciterId() => _dao.getSelectedReciterId();

  @override
  Future<void> setSelectedReciterId(int reciterId) async {
    await _dao.setSelectedReciterId(reciterId);
    _reciterIdController.add(reciterId);
  }

  @override
  Stream<double> getPlaybackSpeedStream() => _playbackSpeedController.stream;

  @override
  Future<double> getPlaybackSpeed() => _dao.getPlaybackSpeed();

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    await _dao.setPlaybackSpeed(speed);
    _playbackSpeedController.add(speed);
  }

  @override
  Stream<bool> getRepeatModeStream() => _repeatModeController.stream;

  @override
  Future<bool> getRepeatMode() => _dao.getRepeatMode();

  @override
  Future<void> setRepeatMode(bool enabled) async {
    await _dao.setRepeatMode(enabled);
    _repeatModeController.add(enabled);
  }

  @override
  Stream<int?> getLastAudioChapterStream() =>
      _lastAudioChapterController.stream;

  @override
  Future<int?> getLastAudioChapter() => _dao.getLastAudioChapter();

  @override
  Future<void> setLastAudioChapter(int? chapterNumber) async {
    await _dao.setLastAudioChapter(chapterNumber);
    _lastAudioChapterController.add(chapterNumber);
  }

  @override
  Stream<int?> getLastAudioVerseStream() => _lastAudioVerseController.stream;

  @override
  Future<int?> getLastAudioVerse() => _dao.getLastAudioVerse();

  @override
  Future<void> setLastAudioVerse(int? verseNumber) async {
    await _dao.setLastAudioVerse(verseNumber);
    _lastAudioVerseController.add(verseNumber);
  }

  @override
  Stream<int> getLastAudioPositionMsStream() =>
      _lastAudioPositionController.stream;

  @override
  Future<int> getLastAudioPositionMs() => _dao.getLastAudioPositionMs();

  @override
  Future<void> setLastAudioPositionMs(int positionMs) async {
    await _dao.setLastAudioPositionMs(positionMs);
    _lastAudioPositionController.add(positionMs);
  }

  // ── Theme ─────────────────────────────────────────────────────────────────

  @override
  Stream<ThemeConfig> getThemeConfigStream() => _themeConfigController.stream;

  @override
  Future<ThemeConfig> getThemeConfig() => _dao.getThemeConfig();

  @override
  Future<void> setThemeMode(MushafThemeMode mode) async {
    final current = await _dao.getThemeConfig();
    final updated = ThemeConfig(
      mode: mode,
      colorScheme: current.colorScheme,
      useAmoled: current.useAmoled,
    );
    await _dao.setThemeConfig(updated);
    _themeConfigController.add(updated);
  }

  @override
  Future<void> setColorScheme(MushafColorScheme scheme) async {
    final current = await _dao.getThemeConfig();
    final updated = ThemeConfig(
      mode: current.mode,
      colorScheme: scheme,
      useAmoled: current.useAmoled,
    );
    await _dao.setThemeConfig(updated);
    _themeConfigController.add(updated);
  }

  @override
  Future<void> setAmoledMode(bool enabled) async {
    final current = await _dao.getThemeConfig();
    final updated = ThemeConfig(
      mode: current.mode,
      colorScheme: current.colorScheme,
      useAmoled: enabled,
    );
    await _dao.setThemeConfig(updated);
    _themeConfigController.add(updated);
  }

  @override
  Future<void> updateThemeConfig(ThemeConfig config) async {
    await _dao.setThemeConfig(config);
    _themeConfigController.add(config);
  }

  // ── General ───────────────────────────────────────────────────────────────

  @override
  Future<void> clearAll() async {
    await _dao.clearAll();
  }
}
