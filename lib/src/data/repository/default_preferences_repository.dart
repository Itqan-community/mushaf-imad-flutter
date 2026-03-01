import 'dart:async';

import '../../../imad_flutter.dart';
import '../../domain/models/mushaf_type.dart';
import '../../domain/models/theme.dart';
import '../../domain/repository/preferences_repository.dart';

/// Default implementation of PreferencesRepository.
/// Uses in-memory state with Stream-based reactivity.
/// For production, replace with SharedPreferences or Hive-backed implementation.
class DefaultPreferencesRepository implements PreferencesRepository {
  // Mushaf preferences — backing fields for Stream-based state.
  // Values are currently written via setters and emitted to StreamControllers.
  // Will be persisted via Hive when integrated.
  // ignore: unused_field
  MushafType _mushafType = MushafType.hafs1441;
  // ignore: unused_field
  int _currentPage = 1;
  // ignore: unused_field
  int? _lastReadChapter;
  (int, int)? _lastReadVerse;
  // ignore: unused_field
  double _fontSizeMultiplier = 1.0;
  // ignore: unused_field
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
  final ReadingHistoryDao _readingHistoryDao;

  DefaultPreferencesRepository(this._readingHistoryDao);

  // ========== Mushaf Reading Preferences ==========

  @override
  Future<int> getCurrentPage() async {
    final lastPosition = await _readingHistoryDao.getLastReadPosition(_mushafType);
    if (lastPosition != null) {
      _currentPage = lastPosition.pageNumber;
      return _currentPage;
    }
    return _currentPage;
  }

  @override
  Stream<MushafType> getMushafTypeStream() => _mushafTypeController.stream;

  @override
  Future<void> setMushafType(MushafType mushafType) async {
    _mushafType = mushafType;
    _mushafTypeController.add(mushafType);
  }

  @override
  Stream<int> getCurrentPageStream() => _currentPageController.stream;

  @override
  Future<void> setCurrentPage(int pageNumber) async {
    _currentPage = pageNumber;
    _currentPageController.add(pageNumber);


    await _readingHistoryDao.saveLastReadPosition(
      LastReadPosition(
        mushafType: _mushafType,
        pageNumber: pageNumber,
        chapterNumber: 1,
        verseNumber: 1,
        lastReadAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
  @override
  Stream<int?> getLastReadChapterStream() => _lastReadChapterController.stream;

  @override
  Future<void> setLastReadChapter(int chapterNumber) async {
    _lastReadChapter = chapterNumber;
    _lastReadChapterController.add(chapterNumber);
  }

  @override
  Stream<(int, int)?> getLastReadVerseStream() =>
      _lastReadVerseController.stream;

  @override
  Future<void> setLastReadVerse(int chapterNumber, int verseNumber) async {
    _lastReadVerse = (chapterNumber, verseNumber);
    _lastReadVerseController.add(_lastReadVerse);
  }

  @override
  Stream<double> getFontSizeMultiplierStream() => _fontSizeController.stream;

  @override
  Future<void> setFontSizeMultiplier(double multiplier) async {
    _fontSizeMultiplier = multiplier;
    _fontSizeController.add(multiplier);
  }

  @override
  Stream<bool> getShowTranslationStream() => _showTranslationController.stream;

  @override
  Future<void> setShowTranslation(bool show) async {
    _showTranslation = show;
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
    _reciterIdController.add(reciterId);
  }

  @override
  Stream<double> getPlaybackSpeedStream() => _playbackSpeedController.stream;

  @override
  Future<double> getPlaybackSpeed() async => _playbackSpeed;

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    _playbackSpeedController.add(speed);
  }

  @override
  Stream<bool> getRepeatModeStream() => _repeatModeController.stream;

  @override
  Future<bool> getRepeatMode() async => _repeatMode;

  @override
  Future<void> setRepeatMode(bool enabled) async {
    _repeatMode = enabled;
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
    _lastAudioChapterController.add(chapterNumber);
  }

  @override
  Stream<int?> getLastAudioVerseStream() => _lastAudioVerseController.stream;

  @override
  Future<int?> getLastAudioVerse() async => _lastAudioVerse;

  @override
  Future<void> setLastAudioVerse(int? verseNumber) async {
    _lastAudioVerse = verseNumber;
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
    _themeConfigController.add(_themeConfig);
  }

  @override
  Future<void> setColorScheme(MushafColorScheme scheme) async {
    _themeConfig = ThemeConfig(
      mode: _themeConfig.mode,
      colorScheme: scheme,
      useAmoled: _themeConfig.useAmoled,
    );
    _themeConfigController.add(_themeConfig);
  }

  @override
  Future<void> setAmoledMode(bool enabled) async {
    _themeConfig = ThemeConfig(
      mode: _themeConfig.mode,
      colorScheme: _themeConfig.colorScheme,
      useAmoled: enabled,
    );
    _themeConfigController.add(_themeConfig);
  }

  @override
  Future<void> updateThemeConfig(ThemeConfig config) async {
    _themeConfig = config;
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
  }
}
