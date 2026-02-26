import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/mushaf_type.dart';
import '../../domain/models/theme.dart';
import '../../domain/repository/preferences_repository.dart';

/// Default implementation of PreferencesRepository using SharedPreferences.
/// Persists all preferences to device storage.
class DefaultPreferencesRepository implements PreferencesRepository {
  // SharedPreferences instance
  SharedPreferences? _prefs;

  // Mushaf preferences — backing fields for Stream-based state.
  MushafType _mushafType = MushafType.hafs1441;
  int _currentPage = 1;
  int? _lastReadChapter;
  (int, int)? _lastReadVerse;
  double _fontSizeMultiplier = 1.0;
  bool _showTranslation = false;

  // Audio preferences
  int _selectedReciterId = 1;
  double _playbackSpeed = 1.0;
  bool _repeatMode = false;
  int? _lastAudioChapter;
  int? _lastAudioVerse;
  int _lastAudioPositionMs = 0;

  // Theme preferences
  ThemeConfig _themeConfig = const ThemeConfig();

  // Stream controllers
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

  // Keys for SharedPreferences
  static const _keyMushafType = 'mushaf_type';
  static const _keyCurrentPage = 'current_page';
  static const _keyLastReadChapter = 'last_read_chapter';
  static const _keyLastReadVerseChapter = 'last_read_verse_chapter';
  static const _keyLastReadVerseNumber = 'last_read_verse_number';
  static const _keyFontSizeMultiplier = 'font_size_multiplier';
  static const _keyShowTranslation = 'show_translation';
  static const _keySelectedReciterId = 'selected_reciter_id';
  static const _keyPlaybackSpeed = 'playback_speed';
  static const _keyRepeatMode = 'repeat_mode';
  static const _keyLastAudioChapter = 'last_audio_chapter';
  static const _keyLastAudioVerse = 'last_audio_verse';
  static const _keyLastAudioPositionMs = 'last_audio_position_ms';
  static const _keyThemeMode = 'theme_mode';
  static const _keyColorScheme = 'color_scheme';
  static const _keyAmoledMode = 'amoled_mode';

  /// Initialize the repository by loading preferences from SharedPreferences.
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadAllPreferences();
  }

  /// Load all preferences from SharedPreferences.
  Future<void> _loadAllPreferences() async {
    if (_prefs == null) return;

    // Load Mushaf preferences
    final mushafTypeIndex = _prefs!.getInt(_keyMushafType);
    if (mushafTypeIndex != null && mushafTypeIndex >= 0 && mushafTypeIndex < MushafType.values.length) {
      _mushafType = MushafType.values[mushafTypeIndex];
    }

    _currentPage = _prefs!.getInt(_keyCurrentPage) ?? 1;
    _lastReadChapter = _prefs!.getInt(_keyLastReadChapter);

    final lastVerseChapter = _prefs!.getInt(_keyLastReadVerseChapter);
    final lastVerseNumber = _prefs!.getInt(_keyLastReadVerseNumber);
    if (lastVerseChapter != null && lastVerseNumber != null) {
      _lastReadVerse = (lastVerseChapter, lastVerseNumber);
    }

    _fontSizeMultiplier = _prefs!.getDouble(_keyFontSizeMultiplier) ?? 1.0;
    _showTranslation = _prefs!.getBool(_keyShowTranslation) ?? false;

    // Load Audio preferences
    _selectedReciterId = _prefs!.getInt(_keySelectedReciterId) ?? 1;
    _playbackSpeed = _prefs!.getDouble(_keyPlaybackSpeed) ?? 1.0;
    _repeatMode = _prefs!.getBool(_keyRepeatMode) ?? false;
    final lastAudioChapterValue = _prefs!.getInt(_keyLastAudioChapter);
    _lastAudioChapter = lastAudioChapterValue == -1 ? null : lastAudioChapterValue;
    final lastAudioVerseValue = _prefs!.getInt(_keyLastAudioVerse);
    _lastAudioVerse = lastAudioVerseValue == -1 ? null : lastAudioVerseValue;
    _lastAudioPositionMs = _prefs!.getInt(_keyLastAudioPositionMs) ?? 0;

    // Load Theme preferences
    final themeModeIndex = _prefs!.getInt(_keyThemeMode);
    final colorSchemeIndex = _prefs!.getInt(_keyColorScheme);
    final amoledMode = _prefs!.getBool(_keyAmoledMode) ?? false;

    _themeConfig = ThemeConfig(
      mode: themeModeIndex != null && themeModeIndex >= 0 && themeModeIndex < MushafThemeMode.values.length
          ? MushafThemeMode.values[themeModeIndex]
          : MushafThemeMode.system,
      colorScheme: colorSchemeIndex != null && colorSchemeIndex >= 0 && colorSchemeIndex < MushafColorScheme.values.length
          ? MushafColorScheme.values[colorSchemeIndex]
          : MushafColorScheme.green,
      useAmoled: amoledMode,
    );

    // Emit loaded values to streams
    _mushafTypeController.add(_mushafType);
    _currentPageController.add(_currentPage);
    _lastReadChapterController.add(_lastReadChapter);
    _lastReadVerseController.add(_lastReadVerse);
    _fontSizeController.add(_fontSizeMultiplier);
    _showTranslationController.add(_showTranslation);
    _reciterIdController.add(_selectedReciterId);
    _playbackSpeedController.add(_playbackSpeed);
    _repeatModeController.add(_repeatMode);
    _lastAudioChapterController.add(_lastAudioChapter);
    _lastAudioVerseController.add(_lastAudioVerse);
    _lastAudioPositionController.add(_lastAudioPositionMs);
    _themeConfigController.add(_themeConfig);
  }

  // ========== Mushaf Reading Preferences ==========

  @override
  Stream<MushafType> getMushafTypeStream() => _mushafTypeController.stream;

  @override
  Future<void> setMushafType(MushafType mushafType) async {
    _mushafType = mushafType;
    await _prefs?.setInt(_keyMushafType, mushafType.index);
    _mushafTypeController.add(mushafType);
  }

  @override
  Stream<int> getCurrentPageStream() => _currentPageController.stream;

  @override
  Future<int> getCurrentPage() async => _currentPage;

  @override
  Future<void> setCurrentPage(int pageNumber) async {
    _currentPage = pageNumber;
    await _prefs?.setInt(_keyCurrentPage, pageNumber);
    _currentPageController.add(pageNumber);
  }

  @override
  Stream<int?> getLastReadChapterStream() => _lastReadChapterController.stream;

  @override
  Future<void> setLastReadChapter(int chapterNumber) async {
    _lastReadChapter = chapterNumber;
    await _prefs?.setInt(_keyLastReadChapter, chapterNumber);
    _lastReadChapterController.add(chapterNumber);
  }

  @override
  Stream<(int, int)?> getLastReadVerseStream() =>
      _lastReadVerseController.stream;

  @override
  Future<void> setLastReadVerse(int chapterNumber, int verseNumber) async {
    _lastReadVerse = (chapterNumber, verseNumber);
    await _prefs?.setInt(_keyLastReadVerseChapter, chapterNumber);
    await _prefs?.setInt(_keyLastReadVerseNumber, verseNumber);
    _lastReadVerseController.add(_lastReadVerse);
  }

  @override
  Stream<double> getFontSizeMultiplierStream() => _fontSizeController.stream;

  @override
  Future<void> setFontSizeMultiplier(double multiplier) async {
    _fontSizeMultiplier = multiplier;
    await _prefs?.setDouble(_keyFontSizeMultiplier, multiplier);
    _fontSizeController.add(multiplier);
  }

  @override
  Stream<bool> getShowTranslationStream() => _showTranslationController.stream;

  @override
  Future<void> setShowTranslation(bool show) async {
    _showTranslation = show;
    await _prefs?.setBool(_keyShowTranslation, show);
    _showTranslationController.add(show);
  }

  // ========== Audio Preferences ==========

  @override
  Stream<int> getSelectedReciterIdStream() => _reciterIdController.stream;

  @override
  Future<int> getSelectedReciterId() async => _selectedReciterId;

  @override
  Future<void> setSelectedReciterId(int reciterId) async {
    _selectedReciterId = reciterId;
    await _prefs?.setInt(_keySelectedReciterId, reciterId);
    _reciterIdController.add(reciterId);
  }

  @override
  Stream<double> getPlaybackSpeedStream() => _playbackSpeedController.stream;

  @override
  Future<double> getPlaybackSpeed() async => _playbackSpeed;

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    await _prefs?.setDouble(_keyPlaybackSpeed, speed);
    _playbackSpeedController.add(speed);
  }

  @override
  Stream<bool> getRepeatModeStream() => _repeatModeController.stream;

  @override
  Future<bool> getRepeatMode() async => _repeatMode;

  @override
  Future<void> setRepeatMode(bool enabled) async {
    _repeatMode = enabled;
    await _prefs?.setBool(_keyRepeatMode, enabled);
    _repeatModeController.add(enabled);
  }

  @override
  Stream<int?> getLastAudioChapterStream() =>
      _lastAudioChapterController.stream;

  @override
  Future<int?> getLastAudioChapter() async => _lastAudioChapter;

  @override
  Future<void> setLastAudioChapter(int? chapterNumber) async {
    _lastAudioChapter = chapterNumber;
    await _prefs?.setInt(_keyLastAudioChapter, chapterNumber ?? -1);
    _lastAudioChapterController.add(chapterNumber);
  }

  @override
  Stream<int?> getLastAudioVerseStream() => _lastAudioVerseController.stream;

  @override
  Future<int?> getLastAudioVerse() async => _lastAudioVerse;

  @override
  Future<void> setLastAudioVerse(int? verseNumber) async {
    _lastAudioVerse = verseNumber;
    await _prefs?.setInt(_keyLastAudioVerse, verseNumber ?? -1);
    _lastAudioVerseController.add(verseNumber);
  }

  @override
  Stream<int> getLastAudioPositionMsStream() =>
      _lastAudioPositionController.stream;

  @override
  Future<int> getLastAudioPositionMs() async => _lastAudioPositionMs;

  @override
  Future<void> setLastAudioPositionMs(int positionMs) async {
    _lastAudioPositionMs = positionMs;
    await _prefs?.setInt(_keyLastAudioPositionMs, positionMs);
    _lastAudioPositionController.add(positionMs);
  }

  // ========== Theme Preferences ==========

  @override
  Stream<ThemeConfig> getThemeConfigStream() => _themeConfigController.stream;

  @override
  Future<ThemeConfig> getThemeConfig() async => _themeConfig;

  @override
  Future<void> setThemeMode(MushafThemeMode mode) async {
    _themeConfig = ThemeConfig(
      mode: mode,
      colorScheme: _themeConfig.colorScheme,
      useAmoled: _themeConfig.useAmoled,
    );
    await _prefs?.setInt(_keyThemeMode, mode.index);
    _themeConfigController.add(_themeConfig);
  }

  @override
  Future<void> setColorScheme(MushafColorScheme scheme) async {
    _themeConfig = ThemeConfig(
      mode: _themeConfig.mode,
      colorScheme: scheme,
      useAmoled: _themeConfig.useAmoled,
    );
    await _prefs?.setInt(_keyColorScheme, scheme.index);
    _themeConfigController.add(_themeConfig);
  }

  @override
  Future<void> setAmoledMode(bool enabled) async {
    _themeConfig = ThemeConfig(
      mode: _themeConfig.mode,
      colorScheme: _themeConfig.colorScheme,
      useAmoled: enabled,
    );
    await _prefs?.setBool(_keyAmoledMode, enabled);
    _themeConfigController.add(_themeConfig);
  }

  @override
  Future<void> updateThemeConfig(ThemeConfig config) async {
    _themeConfig = config;
    await _prefs?.setInt(_keyThemeMode, config.mode.index);
    await _prefs?.setInt(_keyColorScheme, config.colorScheme.index);
    await _prefs?.setBool(_keyAmoledMode, config.useAmoled);
    _themeConfigController.add(config);
  }

  // ========== General ==========

  @override
  Future<void> clearAll() async {
    _mushafType = MushafType.hafs1441;
    _currentPage = 1;
    _lastReadChapter = null;
    _lastReadVerse = null;
    _fontSizeMultiplier = 1.0;
    _showTranslation = false;
    _selectedReciterId = 1;
    _playbackSpeed = 1.0;
    _repeatMode = false;
    _lastAudioChapter = null;
    _lastAudioVerse = null;
    _lastAudioPositionMs = 0;
    _themeConfig = const ThemeConfig();

    await _prefs?.clear();

    // Emit cleared values
    _mushafTypeController.add(_mushafType);
    _currentPageController.add(_currentPage);
    _lastReadChapterController.add(_lastReadChapter);
    _lastReadVerseController.add(_lastReadVerse);
    _fontSizeController.add(_fontSizeMultiplier);
    _showTranslationController.add(_showTranslation);
    _reciterIdController.add(_selectedReciterId);
    _playbackSpeedController.add(_playbackSpeed);
    _repeatModeController.add(_repeatMode);
    _lastAudioChapterController.add(_lastAudioChapter);
    _lastAudioVerseController.add(_lastAudioVerse);
    _lastAudioPositionController.add(_lastAudioPositionMs);
    _themeConfigController.add(_themeConfig);
  }

  /// Get the current page number (for loading last read position).
  Future<int> getCurrentPage() async => _currentPage;
}
