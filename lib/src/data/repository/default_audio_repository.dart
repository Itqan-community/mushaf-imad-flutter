import 'dart:async';

import '../audio/ayah_timing_service.dart';
import '../audio/flutter_audio_player.dart';
import '../audio/reciter_service.dart';
import 'package:imad_flutter/imad_flutter.dart';

/// Default implementation of AudioRepository.
class DefaultAudioRepository implements AudioRepository {
  final ReciterService _reciterService;
  final AyahTimingService _ayahTimingService;
  final FlutterAudioPlayer _audioPlayer;

  DefaultAudioRepository(
    this._reciterService,
    this._ayahTimingService,
    this._audioPlayer,
  );

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

  // Tracks what is currently loaded to avoid race conditions from double loads
  int? _loadedChapter;
  int? _loadedReciterId;

  @override
  Future<void> loadChapter(
    int chapterNumber,
    int reciterId, {
    bool autoPlay = false,
    int startVerseNumber = 1,
  }) async {
    MushafLibrary.logger.debug(
      '[DefaultAudioRepository] loadChapter → chapter=$chapterNumber, reciter=$reciterId, startVerse=$startVerseNumber, autoPlay=$autoPlay',
    );

    final reciter = _reciterService.getReciterById(reciterId);
    if (reciter == null) {
      MushafLibrary.logger.debug(
        '[DefaultAudioRepository] loadChapter → reciter NOT FOUND for id=$reciterId',
      );
      return;
    }

    // Only reload audio if chapter or reciter changed.
    // This prevents the race where _initViewModel (verse=1) and
    // didUpdateWidget (verse=10) both call loadChapter — the first reload
    // completing after the second seek would reset position to 0.
    final needsLoad =
        _loadedChapter != chapterNumber || _loadedReciterId != reciterId;

    if (needsLoad) {
      await _audioPlayer.loadChapter(chapterNumber, reciter, autoPlay: false);
      _loadedChapter = chapterNumber;
      _loadedReciterId = reciterId;
      MushafLibrary.logger.debug(
        '[DefaultAudioRepository] loadChapter → audio loaded for chapter=$chapterNumber',
      );
    } else {
      MushafLibrary.logger.debug(
        '[DefaultAudioRepository] loadChapter → chapter already loaded, skipping reload',
      );
    }

    // Always seek — even for verse 1 (seek to zero) so position is deterministic
    if (startVerseNumber > 1) {
      final timing = await _ayahTimingService.getAyahTiming(
        reciterId,
        chapterNumber,
        startVerseNumber,
      );

      if (timing != null) {
        MushafLibrary.logger.debug(
          '[DefaultAudioRepository] loadChapter → seeking to verse=$startVerseNumber at ${timing.startTime}ms',
        );
        await _audioPlayer.seek(Duration(milliseconds: timing.startTime));
      } else {
        MushafLibrary.logger.debug(
          '[DefaultAudioRepository] loadChapter → ⚠️ NO timing found for verse=$startVerseNumber — seeking to start',
        );
        await _audioPlayer.seek(Duration.zero);
      }
    } else {
      MushafLibrary.logger.debug(
        '[DefaultAudioRepository] loadChapter → startVerse=1, seeking to beginning',
      );
      await _audioPlayer.seek(Duration.zero);
    }

    // Start playback if required
    if (autoPlay) {
      await _audioPlayer.play();
      MushafLibrary.logger.debug(
        '[DefaultAudioRepository] loadChapter → playback started',
      );
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
    _audioPlayer.stop();
    _reciterService.dispose();
  }
}
