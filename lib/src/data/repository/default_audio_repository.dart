import 'dart:async';

import '../../domain/models/audio_player_state.dart';
import '../../domain/models/reciter_info.dart';
import '../../domain/models/reciter_timing.dart';
import '../../domain/repository/audio_repository.dart';
import '../audio/ayah_timing_service.dart';
import '../audio/reciter_service.dart';

/// Default implementation of AudioRepository.
class DefaultAudioRepository implements AudioRepository {
  final ReciterService _reciterService;
  final AyahTimingService _ayahTimingService;

  final StreamController<AudioPlayerState> _playerStateController =
      StreamController<AudioPlayerState>.broadcast();
  AudioPlayerState _currentState = const AudioPlayerState();
  bool _repeatEnabled = false;

  DefaultAudioRepository(this._reciterService, this._ayahTimingService);

  @override
  Future<List<ReciterInfo>> getAllReciters() async =>
      _reciterService.getAllReciters();

  @override
  Future<ReciterInfo?> getReciterById(int reciterId) async =>
      _reciterService.getReciterById(reciterId);

  @override
  Future<List<ReciterInfo>> searchReciters(
    String query, {
    String languageCode = 'en',
  }) async => _reciterService.searchReciters(query, languageCode: languageCode);

  @override
  Future<List<ReciterInfo>> getHafsReciters() async =>
      _reciterService.getHafsReciters();

  @override
  Future<ReciterInfo> getDefaultReciter() async =>
      _reciterService.getDefaultReciter();

  @override
  void saveSelectedReciter(ReciterInfo reciter) =>
      _reciterService.selectReciter(reciter);

  @override
  Stream<ReciterInfo?> getSelectedReciterStream() =>
      _reciterService.selectedReciterStream;

  @override
  Stream<AudioPlayerState> getPlayerStateStream() =>
      _playerStateController.stream;

  @override
  void loadChapter(int chapterNumber, int reciterId, {bool autoPlay = false}) {
    _currentState = _currentState.copyWith(
      currentChapter: chapterNumber,
      currentReciterId: reciterId,
      playbackState: autoPlay ? PlaybackState.loading : PlaybackState.idle,
    );
    _playerStateController.add(_currentState);
    // TODO: Integrate with actual audio player (just_audio)
  }

  @override
  void play() {
    _currentState = _currentState.copyWith(
      playbackState: PlaybackState.playing,
    );
    _playerStateController.add(_currentState);
  }

  @override
  void pause() {
    _currentState = _currentState.copyWith(playbackState: PlaybackState.paused);
    _playerStateController.add(_currentState);
  }

  @override
  void stop() {
    _currentState = _currentState.copyWith(
      playbackState: PlaybackState.stopped,
    );
    _playerStateController.add(_currentState);
  }

  @override
  void seekTo(int positionMs) {
    _currentState = _currentState.copyWith(currentPositionMs: positionMs);
    _playerStateController.add(_currentState);
  }

  @override
  void setPlaybackSpeed(double speed) {
    // TODO: Integrate with actual audio player
  }

  @override
  void setRepeatMode(bool enabled) {
    _repeatEnabled = enabled;
    _currentState = _currentState.copyWith(isRepeatEnabled: enabled);
    _playerStateController.add(_currentState);
  }

  @override
  bool isRepeatEnabled() => _repeatEnabled;

  @override
  int getCurrentPosition() => _currentState.currentPositionMs;

  @override
  int getDuration() => _currentState.durationMs;

  @override
  bool isCurrentlyPlaying() => _currentState.isPlaying;

  @override
  Future<AyahTiming?> getAyahTiming(
    int reciterId,
    int chapterNumber,
    int ayahNumber,
  ) => _ayahTimingService.getAyahTiming(reciterId, chapterNumber, ayahNumber);

  @override
  Future<int?> getCurrentVerse(
    int reciterId,
    int chapterNumber,
    int currentTimeMs,
  ) => _ayahTimingService.getCurrentVerse(
    reciterId,
    chapterNumber,
    currentTimeMs,
  );

  @override
  Future<List<AyahTiming>> getChapterTimings(
    int reciterId,
    int chapterNumber,
  ) => _ayahTimingService.getChapterTimings(reciterId, chapterNumber);

  @override
  bool hasTimingForReciter(int reciterId) =>
      _ayahTimingService.hasTimingForReciter(reciterId);

  @override
  Future<void> preloadTiming(int reciterId) =>
      _ayahTimingService.preloadTiming(reciterId);

  @override
  void release() {
    _playerStateController.close();
    _reciterService.dispose();
  }
}
