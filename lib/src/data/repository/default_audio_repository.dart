import 'dart:async';
import '../../domain/models/audio_player_state.dart';
import '../../domain/models/reciter_info.dart';
import '../../domain/models/reciter_timing.dart';
import '../../domain/repository/audio_repository.dart';
import '../audio/ayah_timing_service.dart';
import '../audio/flutter_audio_player.dart';
import '../audio/reciter_service.dart';

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
  Stream<AudioPlayerState> getPlayerStateStream() async* {
    await for (final state in _audioPlayer.domainStateStream) {
      int? verse;
      if (state.currentReciterId != null &&
          state.currentChapter != null &&
          state.currentPositionMs >= 0) {
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
    int? startAyahNumber,
  }) async {
    final reciter =
        await _reciterService.getReciterById(reciterId);
    if (reciter == null) return;

    await _audioPlayer.loadChapter(
      chapterNumber,
      reciter,
      autoPlay: autoPlay,
      startAyahNumber: startAyahNumber,
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
  void setPlaybackSpeed(double speed) =>
      _audioPlayer.setSpeed(speed);

  @override
  Future<void> dispose() async {
    await _audioPlayer.dispose();
    _reciterService.dispose();
  }

  @override
  void release() {
    dispose();
  }

  @override
  Future<AyahTiming?> getAyahTiming(
    int reciterId,
    int chapterNumber,
    int ayahNumber,
  ) =>
      _ayahTimingService.getAyahTiming(
        reciterId,
        chapterNumber,
        ayahNumber,
      );

  @override
  Future<List<AyahTiming>> getChapterTimings(
    int reciterId,
    int chapterNumber,
  ) =>
      _ayahTimingService.getChapterTimings(
        reciterId,
        chapterNumber,
      );

  @override
  bool hasTimingForReciter(int reciterId) =>
      _ayahTimingService.hasTimingForReciter(reciterId);

  @override
  Future<void> preloadTiming(int reciterId) =>
      _ayahTimingService.preloadTiming(reciterId);
}
