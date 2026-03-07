import 'dart:async';
import '../../domain/error/failure.dart';
import '../../domain/models/mushaf_type.dart';
import '../../domain/models/result.dart';
import '../../domain/models/theme.dart';
import '../../domain/repository/preferences_repository.dart';
import '../local/dao/preferences_dao.dart';

/// Default implementation of PreferencesRepository.
class DefaultPreferencesRepository implements PreferencesRepository {
  final PreferencesDao _dao;

  DefaultPreferencesRepository(this._dao);

  // Mushaf preferences
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
  bool _showAudioPlayer = true;

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
  final _showAudioPlayerController = StreamController<bool>.broadcast();

  /// Initialize state from the DAO.
  Future<void> initialize() async {
    _mushafType = await _dao.getMushafType() ?? MushafType.hafs1441;
    _currentPage = await _dao.getCurrentPage() ?? 1;
    _lastReadChapter = await _dao.getLastReadChapter();
    
    final verseChapter = await _dao.getLastReadVerseChapter();
    final verseNumber = await _dao.getLastReadVerseNumber();
    if (verseChapter != null && verseNumber != null) {
      _lastReadVerse = (verseChapter, verseNumber);
    }

    _fontSizeMultiplier = await _dao.getFontSizeMultiplier() ?? 1.0;
    _showTranslation = await _dao.getShowTranslation() ?? false;
    _selectedReciterId = await _dao.getSelectedReciterId() ?? 1;
    _playbackSpeed = await _dao.getPlaybackSpeed() ?? 1.0;
    _repeatMode = await _dao.getRepeatMode() ?? false;
    _themeConfig = await _dao.getThemeConfig() ?? const ThemeConfig();
    _showAudioPlayer = await _dao.getShowAudioPlayer() ?? true;

    // Emit initial values
    _mushafTypeController.add(_mushafType);
    _currentPageController.add(_currentPage);
    _lastReadChapterController.add(_lastReadChapter);
    _lastReadVerseController.add(_lastReadVerse);
    _fontSizeController.add(_fontSizeMultiplier);
    _showTranslationController.add(_showTranslation);
    _reciterIdController.add(_selectedReciterId);
    _playbackSpeedController.add(_playbackSpeed);
    _repeatModeController.add(_repeatMode);
    _themeConfigController.add(_themeConfig);
    _showAudioPlayerController.add(_showAudioPlayer);
  }

  // ========== Mushaf Reading Preferences ==========

  @override
  Stream<MushafType> getMushafTypeStream() => _mushafTypeController.stream;

  @override
  Future<Result<void>> setMushafType(MushafType mushafType) => Result.runCatching(
        () async {
          _mushafType = mushafType;
          await _dao.saveMushafType(mushafType);
          _mushafTypeController.add(mushafType);
        },
        failureMapper: (e) => PreferenceFailure('Failed to save Mushaf type', e),
      );

  @override
  Stream<int> getCurrentPageStream() => _currentPageController.stream;

  @override
  Future<Result<void>> setCurrentPage(int pageNumber) => Result.runCatching(
        () async {
          _currentPage = pageNumber;
          await _dao.saveCurrentPage(pageNumber);
          _currentPageController.add(pageNumber);
        },
        failureMapper: (e) => PreferenceFailure('Failed to save current page', e),
      );

  @override
  Stream<int?> getLastReadChapterStream() => _lastReadChapterController.stream;

  @override
  Future<Result<void>> setLastReadChapter(int chapterNumber) => Result.runCatching(
        () async {
          _lastReadChapter = chapterNumber;
          await _dao.saveLastReadChapter(chapterNumber);
          _lastReadChapterController.add(chapterNumber);
        },
        failureMapper: (e) =>
            PreferenceFailure('Failed to save last read chapter', e),
      );

  @override
  Stream<(int, int)?> getLastReadVerseStream() =>
      _lastReadVerseController.stream;

  @override
  Future<Result<void>> setLastReadVerse(int chapterNumber, int verseNumber) =>
      Result.runCatching(
        () async {
          _lastReadVerse = (chapterNumber, verseNumber);
          await _dao.saveLastReadVerse(chapterNumber, verseNumber);
          _lastReadVerseController.add(_lastReadVerse);
        },
        failureMapper: (e) =>
            PreferenceFailure('Failed to save last read verse', e),
      );

  @override
  Stream<double> getFontSizeMultiplierStream() => _fontSizeController.stream;

  @override
  Future<Result<void>> setFontSizeMultiplier(double multiplier) =>
      Result.runCatching(
        () async {
          _fontSizeMultiplier = multiplier;
          await _dao.saveFontSizeMultiplier(multiplier);
          _fontSizeController.add(multiplier);
        },
        failureMapper: (e) =>
            PreferenceFailure('Failed to save font size multiplier', e),
      );

  @override
  Stream<bool> getShowTranslationStream() => _showTranslationController.stream;

  @override
  Future<Result<void>> setShowTranslation(bool show) => Result.runCatching(
        () async {
          _showTranslation = show;
          await _dao.saveShowTranslation(show);
          _showTranslationController.add(show);
        },
        failureMapper: (e) => PreferenceFailure('Failed to save translation preference', e),
      );

  // ========== Audio Preferences ==========

  @override
  Stream<int> getSelectedReciterIdStream() => _reciterIdController.stream;

  @override
  Future<Result<int>> getSelectedReciterId() => Result.runCatching(
        () async => _selectedReciterId,
        failureMapper: (e) => PreferenceFailure('Failed to get reciter ID', e),
      );

  @override
  Future<Result<void>> setSelectedReciterId(int reciterId) => Result.runCatching(
        () async {
          _selectedReciterId = reciterId;
          await _dao.saveSelectedReciterId(reciterId);
          _reciterIdController.add(reciterId);
        },
        failureMapper: (e) => PreferenceFailure('Failed to save reciter ID', e),
      );

  @override
  Stream<double> getPlaybackSpeedStream() => _playbackSpeedController.stream;

  @override
  Future<Result<double>> getPlaybackSpeed() => Result.runCatching(
        () async => _playbackSpeed,
        failureMapper: (e) => PreferenceFailure('Failed to get playback speed', e),
      );

  @override
  Future<Result<void>> setPlaybackSpeed(double speed) => Result.runCatching(
        () async {
          _playbackSpeed = speed;
          await _dao.savePlaybackSpeed(speed);
          _playbackSpeedController.add(speed);
        },
        failureMapper: (e) => PreferenceFailure('Failed to save playback speed', e),
      );

  @override
  Stream<bool> getRepeatModeStream() => _repeatModeController.stream;

  @override
  Future<Result<bool>> getRepeatMode() => Result.runCatching(
        () async => _repeatMode,
        failureMapper: (e) => PreferenceFailure('Failed to get repeat mode', e),
      );

  @override
  Future<Result<void>> setRepeatMode(bool enabled) => Result.runCatching(
        () async {
          _repeatMode = enabled;
          await _dao.saveRepeatMode(enabled);
          _repeatModeController.add(enabled);
        },
        failureMapper: (e) => PreferenceFailure('Failed to save repeat mode', e),
      );

  @override
  Stream<int?> getLastAudioChapterStream() =>
      _lastAudioChapterController.stream;

  @override
  Future<Result<int?>> getLastAudioChapter() => Result.runCatching(
        () async => _lastAudioChapter,
        failureMapper: (e) => PreferenceFailure('Failed to get last audio chapter', e),
      );

  @override
  Future<Result<void>> setLastAudioChapter(int? chapterNumber) => Result.runCatching(
        () async {
          _lastAudioChapter = chapterNumber;
          _lastAudioChapterController.add(chapterNumber);
        },
        failureMapper: (e) => PreferenceFailure('Failed to set last audio chapter', e),
      );

  @override
  Stream<int?> getLastAudioVerseStream() => _lastAudioVerseController.stream;

  @override
  Future<Result<int?>> getLastAudioVerse() => Result.runCatching(
        () async => _lastAudioVerse,
        failureMapper: (e) => PreferenceFailure('Failed to get last audio verse', e),
      );

  @override
  Future<Result<void>> setLastAudioVerse(int? verseNumber) => Result.runCatching(
        () async {
          _lastAudioVerse = verseNumber;
          _lastAudioVerseController.add(verseNumber);
        },
        failureMapper: (e) => PreferenceFailure('Failed to set last audio verse', e),
      );

  @override
  Stream<int> getLastAudioPositionMsStream() =>
      _lastAudioPositionController.stream;

  @override
  Future<Result<int>> getLastAudioPositionMs() => Result.runCatching(
        () async => _lastAudioPositionMs,
        failureMapper: (e) => PreferenceFailure('Failed to get last audio position', e),
      );

  @override
  Future<Result<void>> setLastAudioPositionMs(int positionMs) => Result.runCatching(
        () async {
          _lastAudioPositionMs = positionMs;
          _lastAudioPositionController.add(positionMs);
        },
        failureMapper: (e) => PreferenceFailure('Failed to set last audio position', e),
      );

  @override
  Stream<bool> getShowAudioPlayerStream() => _showAudioPlayerController.stream;

  @override
  Future<Result<bool>> getShowAudioPlayer() => Result.runCatching(
        () async => _showAudioPlayer,
        failureMapper: (e) => PreferenceFailure('Failed to get audio player visibility', e),
      );

  @override
  Future<Result<void>> setShowAudioPlayer(bool show) => Result.runCatching(
        () async {
          _showAudioPlayer = show;
          await _dao.saveShowAudioPlayer(show);
          _showAudioPlayerController.add(show);
        },
        failureMapper: (e) => PreferenceFailure('Failed to set audio player visibility', e),
      );

  // ========== Theme Preferences ==========

  @override
  Stream<ThemeConfig> getThemeConfigStream() => _themeConfigController.stream;

  @override
  Future<Result<ThemeConfig>> getThemeConfig() => Result.runCatching(
        () async => _themeConfig,
        failureMapper: (e) => PreferenceFailure('Failed to get theme configuration', e),
      );

  @override
  Future<Result<void>> setThemeMode(MushafThemeMode mode) => Result.runCatching(
        () async {
          _themeConfig = ThemeConfig(
            mode: mode,
            colorScheme: _themeConfig.colorScheme,
            useAmoled: _themeConfig.useAmoled,
          );
          await _dao.saveThemeConfig(_themeConfig);
          _themeConfigController.add(_themeConfig);
        },
        failureMapper: (e) => PreferenceFailure('Failed to save theme mode', e),
      );

  @override
  Future<Result<void>> setColorScheme(MushafColorScheme scheme) =>
      Result.runCatching(
        () async {
          _themeConfig = ThemeConfig(
            mode: _themeConfig.mode,
            colorScheme: scheme,
            useAmoled: _themeConfig.useAmoled,
          );
          await _dao.saveThemeConfig(_themeConfig);
          _themeConfigController.add(_themeConfig);
        },
        failureMapper: (e) => PreferenceFailure('Failed to save color scheme', e),
      );

  @override
  Future<Result<void>> setAmoledMode(bool enabled) => Result.runCatching(
        () async {
          _themeConfig = ThemeConfig(
            mode: _themeConfig.mode,
            colorScheme: _themeConfig.colorScheme,
            useAmoled: enabled,
          );
          await _dao.saveThemeConfig(_themeConfig);
          _themeConfigController.add(_themeConfig);
        },
        failureMapper: (e) => PreferenceFailure('Failed to save AMOLED mode', e),
      );

  @override
  Future<Result<void>> updateThemeConfig(ThemeConfig config) => Result.runCatching(
        () async {
          _themeConfig = config;
          await _dao.saveThemeConfig(config);
          _themeConfigController.add(config);
        },
        failureMapper: (e) => PreferenceFailure('Failed to update theme configuration', e),
      );

  // ========== General ==========

  @override
  Future<Result<void>> clearAll() => Result.runCatching(
        () async {
          await _dao.clearAll();
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
          _showAudioPlayer = true;
          _themeConfig = const ThemeConfig();

          // Emit reset values
          _mushafTypeController.add(_mushafType);
          _currentPageController.add(_currentPage);
          _lastReadChapterController.add(_lastReadChapter);
          _lastReadVerseController.add(_lastReadVerse);
          _fontSizeController.add(_fontSizeMultiplier);
          _showTranslationController.add(_showTranslation);
          _reciterIdController.add(_selectedReciterId);
          _playbackSpeedController.add(_playbackSpeed);
          _repeatModeController.add(_repeatMode);
          _themeConfigController.add(_themeConfig);
          _showAudioPlayerController.add(_showAudioPlayer);
        },
        failureMapper: (e) => PreferenceFailure('Failed to clear preferences', e),
      );
}
