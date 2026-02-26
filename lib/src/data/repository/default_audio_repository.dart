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
  Future<List<ReciterInfo>> searchReciters(
    String query, {
    String languageCode = 'en',
  }) async =>
      _reciterService.searchReciters(
        query,
        languageCode: languageCode,
      );

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
    int? startAyahNumber, // ✅ تم إضافة المعامل هنا
  }) async {
    final reciter = await _reciterService.getReciterById(reciterId);
    if (reciter == null) return;

    // ✅ تمرير startAyahNumber إلى المشغل الفعلي
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
  void setRepeatMode(bool enabled) =>
      _audioPlayer.setRepeatModeBool(enabled);

  @override
  bool isRepeatEnabled() =>
      _audioPlayer.isRepeatMode();

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
  ) =>
      _ayahTimingService.getAyahTiming(
        reciterId,
        chapterNumber,
        ayahNumber,
      );

  @override
  Future<int?> getCurrentVerse(
    int reciterId,
    int chapterNumber,
    int currentTimeMs,
  ) =>
      _ayahTimingService.getCurrentVerse(
        reciterId,
        chapterNumber,
        currentTimeMs,
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

  @override
  void release() {
    _audioPlayer.stop();
    _reciterService.dispose();
  }
}
