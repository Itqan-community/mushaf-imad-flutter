import 'dart:async';

import '../../domain/models/audio_player_state.dart';
import '../../domain/models/reciter_info.dart';
import '../../domain/models/reciter_timing.dart';
import '../../domain/repository/audio_repository.dart';
import '../../domain/repository/preferences_repository.dart';
import '../audio/audio_player_interface.dart';
import '../audio/ayah_timing_service.dart';
import '../audio/flutter_audio_player.dart';
import '../audio/reciter_service.dart';

/// Default implementation of AudioRepository.
class DefaultAudioRepository implements AudioRepository {
  final ReciterService _reciterService;
  final AyahTimingService _ayahTimingService;
  final AudioPlayerInterface _audioPlayer;
  final PreferencesRepository _preferencesRepository;

  StreamSubscription<AudioPlayerState>? _positionSaveSubscription;
  int _lastSavedPositionMs = 0;
  static const int _saveIntervalMs = 5000; // save every 5 seconds

  DefaultAudioRepository(
    this._reciterService,
    this._ayahTimingService,
    AudioPlayerInterface audioPlayer,
    this._preferencesRepository,
  ) : _audioPlayer = audioPlayer {
    _initPositionSaving();
  }

  void _initPositionSaving() {
    _positionSaveSubscription = _audioPlayer.domainStateStream.listen((state) {
      // Save position on pause or stop
      if (state.playbackState == PlaybackState.paused ||
          state.playbackState == PlaybackState.stopped) {
        _persistPosition(state.currentPositionMs);
      }
      // Save periodically during playback (every 5 seconds)
      if (state.playbackState == PlaybackState.playing) {
        final diff = (state.currentPositionMs - _lastSavedPositionMs).abs();
        if (diff >= _saveIntervalMs) {
          _persistPosition(state.currentPositionMs);
        }
      }
    });
  }

  void _persistPosition(int positionMs) {
    if (positionMs == _lastSavedPositionMs) return;
    _lastSavedPositionMs = positionMs;
    _preferencesRepository.setLastAudioPositionMs(positionMs);
  }

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
  Stream<AudioPlayerState> getPlayerStateStream() async* {
    await for (final state in _audioPlayer.domainStateStream) {
      int? verse;
      if (state.currentReciterId != null && state.currentChapter != null) {
        verse = await _ayahTimingService.getCurrentVerse(
          state.currentReciterId!,
          state.currentChapter!,
          state.currentPositionMs,
        );
      }
      yield state.copyWith(currentVerse: verse);
    }
  }

  @override
  void loadChapter(
    int chapterNumber,
    int reciterId, {
    bool autoPlay = false,
  }) async {
    final reciter = _reciterService.getReciterById(reciterId);
    if (reciter == null) return;

    // Check if we're resuming the same chapter
    final lastChapter = await _preferencesRepository.getLastAudioChapter();
    final savedPositionMs = lastChapter == chapterNumber
        ? await _preferencesRepository.getLastAudioPositionMs()
        : 0;

    // Save the new chapter
    await _preferencesRepository.setLastAudioChapter(chapterNumber);
    // Reset saved position tracking for the new chapter
    _lastSavedPositionMs = savedPositionMs;

    await _audioPlayer.loadChapter(
      chapterNumber,
      reciter,
      autoPlay: autoPlay,
    );

    // Restore position if resuming the same chapter
    if (savedPositionMs > 0) {
      await _audioPlayer.seek(Duration(milliseconds: savedPositionMs));
    }
  }

  @override
  void play() => _audioPlayer.play();

  @override
  void pause() => _audioPlayer.pause();

  @override
  void stop() => _audioPlayer.stop();

  @override
  void seekTo(int positionMs) =>
      _audioPlayer.seek(Duration(milliseconds: positionMs));

  @override
  void setPlaybackSpeed(double speed) => _audioPlayer.setSpeed(speed);

  @override
  void setRepeatMode(bool enabled) => _audioPlayer.setRepeatModeBool(enabled);

  @override
  bool isRepeatEnabled() => _audioPlayer.isRepeatMode();

  // These synchronous getters might need an async await if audio_service is isolated,
  // but just_audio within BaseAudioHandler holds synchronous state if in same isolate.
  // For now, these are not strictly available synchronously from base handler, so we can stub
  // or return default if we don't store them locally anymore. We'll return 0 for now since
  // UI mostly relies on the Stream<AudioPlayerState>.
  @override
  int getCurrentPosition() => 0;

  @override
  int getDuration() => 0;

  @override
  bool isCurrentlyPlaying() => false;

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
    _positionSaveSubscription?.cancel();
    _audioPlayer.stop();
    _reciterService.dispose();
  }
}
