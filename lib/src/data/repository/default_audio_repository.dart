import 'dart:async';

import '../audio/ayah_timing_service.dart';
import '../audio/recitation_service.dart';
import 'package:imad_flutter/imad_flutter.dart';

/// Default implementation of AudioRepository.
class DefaultAudioRepository implements AudioRepository {
  final RecitationService _recitationService;
  final AyahTimingService _ayahTimingService;
  final FlutterAudioPlayer _audioPlayer;

  DefaultAudioRepository(
    this._recitationService,
    this._ayahTimingService,
    this._audioPlayer,
  );

  @override
  Future<List<Recitation>> getAllRecitations() async =>
      _recitationService.getAllRecitations();

  @override
  Future<Recitation?> getRecitationById(int recitationId) async =>
      _recitationService.getRecitationById(recitationId);

  @override
  Future<List<Recitation>> searchRecitations(
    String query, {
    String languageCode = 'ar',
  }) async => _recitationService.searchRecitations(query, languageCode: languageCode);

  @override
  Future<Recitation> getDefaultRecitation() async =>
      _recitationService.getDefaultRecitation();

  @override
  void saveSelectedRecitation(Recitation recitation) =>
      _recitationService.selectRecitation(recitation);

  @override
  Stream<Recitation?> getSelectedRecitationStream() =>
      _recitationService.selectedRecitationStream;

  @override
  Stream<AudioPlayerState> getPlayerStateStream() async* {
    await for (final state in _audioPlayer.domainStateStream) {
      int? verse;
      if (state.currentRecitationId != null && state.currentChapter != null) {
        verse = await _ayahTimingService.getCurrentVerse(
          state.currentRecitationId!,
          state.currentChapter!,
          state.currentPositionMs,
        );
      }
      yield state.copyWith(currentVerse: verse);
    }
  }

  // Tracks what is currently loaded to avoid race conditions from double loads
  int? _loadedChapter;
  int? _loadedRecitationId;

  @override
  Future<void> loadChapter(
    int chapterNumber,
    int recitationId, {
    bool autoPlay = false,
    int startVerseNumber = 1,
  }) async {
    MushafLibrary.logger.debug(
      '[DefaultAudioRepository] loadChapter → chapter=$chapterNumber, recitation=$recitationId, startVerse=$startVerseNumber, autoPlay=$autoPlay',
    );

    final recitation = _recitationService.getRecitationById(recitationId);
    if (recitation == null) {
      MushafLibrary.logger.debug(
        '[DefaultAudioRepository] loadChapter → recitation NOT FOUND for id=$recitationId',
      );
      return;
    }

    // Only reload audio if chapter or recitation changed.
    final needsLoad =
        _loadedChapter != chapterNumber || _loadedRecitationId != recitationId;

    if (needsLoad) {
      await _audioPlayer.loadChapter(chapterNumber, recitation, autoPlay: false);
      _loadedChapter = chapterNumber;
      _loadedRecitationId = recitationId;
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
        recitationId,
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
    int recitationId,
    int chapterNumber,
    int ayahNumber,
  ) => _ayahTimingService.getAyahTiming(recitationId, chapterNumber, ayahNumber);

  @override
  Future<int?> getCurrentVerse(
    int recitationId,
    int chapterNumber,
    int currentTimeMs,
  ) => _ayahTimingService.getCurrentVerse(
    recitationId,
    chapterNumber,
    currentTimeMs,
  );

  @override
  Future<List<AyahTiming>> getChapterTimings(
    int recitationId,
    int chapterNumber,
  ) => _ayahTimingService.getChapterTimings(recitationId, chapterNumber);

  @override
  bool hasTimingForRecitation(int recitationId) =>
      _ayahTimingService.hasTimingForRecitation(recitationId);

  @override
  Future<void> preloadTiming(int recitationId) =>
      _ayahTimingService.preloadTiming(recitationId);

  @override
  void release() {
    _audioPlayer.stop();
    _recitationService.dispose();
  }
}
