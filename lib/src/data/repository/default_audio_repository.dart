import 'dart:async';

import '../../domain/error/failure.dart';
import '../../domain/models/audio_player_state.dart';
import '../../domain/models/reciter_info.dart';
import '../../domain/models/reciter_timing.dart';
import '../../domain/models/result.dart';
import '../../domain/repository/audio_repository.dart';
import '../audio/ayah_timing_service.dart';
import '../audio/flutter_audio_player.dart';
import '../audio/reciter_service.dart';

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
  Future<Result<List<ReciterInfo>>> getAllReciters() async => Result.runCatching(
        () => _reciterService.getAllReciters(),
        failureMapper: (e) => DatabaseFailure('Failed to fetch reciters', e),
      );

  @override
  Future<Result<ReciterInfo?>> getReciterById(int reciterId) async =>
      Result.runCatching(
        () => _reciterService.getReciterById(reciterId),
        failureMapper: (e) => DatabaseFailure('Failed to fetch reciter $reciterId', e),
      );

  @override
  Future<Result<List<ReciterInfo>>> searchReciters(
    String query, {
    String languageCode = 'en',
  }) async =>
      Result.runCatching(
        () => _reciterService.searchReciters(query, languageCode: languageCode),
        failureMapper: (e) => DatabaseFailure('Search failed for query: $query', e),
      );

  @override
  Future<Result<List<ReciterInfo>>> getHafsReciters() async =>
      Result.runCatching(
        () => _reciterService.getHafsReciters(),
        failureMapper: (e) => DatabaseFailure('Failed to fetch Hafs reciters', e),
      );

  @override
  Future<Result<ReciterInfo>> getDefaultReciter() async => Result.runCatching(
        () => _reciterService.getDefaultReciter(),
        failureMapper: (e) => DatabaseFailure('Failed to fetch default reciter', e),
      );

  @override
  Future<Result<void>> saveSelectedReciter(ReciterInfo reciter) async =>
      Result.runCatching(
        () async => _reciterService.selectReciter(reciter),
        failureMapper: (e) => PreferenceFailure('Failed to save selected reciter', e),
      );

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
  Future<Result<void>> loadChapter(
    int chapterNumber,
    int reciterId, {
    bool autoPlay = false,
  }) async {
    return Result.runCatching(
      () async {
        final reciter = await _reciterService.getReciterById(reciterId);
        if (reciter == null) {
          throw ValidationFailure('Reciter $reciterId not found');
        }
        await _audioPlayer.loadChapter(
          chapterNumber,
          reciter,
          autoPlay: autoPlay,
        );
      },
      failureMapper: (e) => e is Failure ? e : NetworkFailure('Failed to load chapter audio', e),
    );
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
  Future<Result<AyahTiming?>> getAyahTiming(
    int reciterId,
    int chapterNumber,
    int ayahNumber,
  ) =>
      Result.runCatching(
        () => _ayahTimingService.getAyahTiming(reciterId, chapterNumber, ayahNumber),
        failureMapper: (e) =>
            DatabaseFailure('Failed to fetch ayah timing for $reciterId', e),
      );

  @override
  Future<Result<int?>> getCurrentVerse(
    int reciterId,
    int chapterNumber,
    int currentTimeMs,
  ) =>
      Result.runCatching(
        () => _ayahTimingService.getCurrentVerse(
            reciterId, chapterNumber, currentTimeMs),
        failureMapper: (e) =>
            DatabaseFailure('Failed to determine current verse', e),
      );

  @override
  Future<Result<List<AyahTiming>>> getChapterTimings(
    int reciterId,
    int chapterNumber,
  ) =>
      Result.runCatching(
        () => _ayahTimingService.getChapterTimings(reciterId, chapterNumber),
        failureMapper: (e) =>
            DatabaseFailure('Failed to fetch chapter timings for $reciterId', e),
      );

  @override
  bool hasTimingForReciter(int reciterId) =>
      _ayahTimingService.hasTimingForReciter(reciterId);

  @override
  Future<Result<void>> preloadTiming(int reciterId) => Result.runCatching(
        () => _ayahTimingService.preloadTiming(reciterId),
        failureMapper: (e) => DatabaseFailure('Failed to preload timing data', e),
      );

  @override
  void release() {
    _audioPlayer.stop();
    _reciterService.dispose();
  }
}

