import 'dart:async';

import '../../domain/models/audio_player_state.dart';
import '../../domain/models/reciter_info.dart';
import '../../domain/models/reciter_timing.dart';
import '../../domain/repository/audio_repository.dart';
import '../audio/ayah_timing_service.dart';
import '../audio/flutter_audio_player.dart';
import '../audio/quran_com_audio_service.dart';
import '../audio/quran_com_reciter_service.dart';

/// AudioRepository implementation with Quran.com API integration.
/// This repository fetches reciters and audio URLs from Quran.com API
/// while maintaining compatibility with the existing audio playback system.
class QuranComAudioRepository implements AudioRepository {
  final QuranComReciterService _reciterService;
  final AyahTimingService _ayahTimingService;
  final FlutterAudioPlayer _audioPlayer;
  final AudioService _audioService;

  QuranComAudioRepository(
    this._reciterService,
    this._ayahTimingService,
    this._audioPlayer,
    this._audioService,
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

  @override
  void loadChapter(
    int chapterNumber,
    int reciterId, {
    bool autoPlay = false,
  }) async {
    try {
      // Get the audio URL from Quran.com API
      final audioUrl = await _audioService.getChapterAudioUrl(reciterId, chapterNumber);
      
      // Get reciter info for display
      final reciter = await _reciterService.getReciterById(reciterId);
      if (reciter != null) {
        // Create a modified reciter with the API URL
        final apiReciter = ReciterInfo(
          id: reciter.id,
          nameArabic: reciter.nameArabic,
          nameEnglish: reciter.nameEnglish,
          rewaya: reciter.rewaya,
          folderUrl: audioUrl.substring(0, audioUrl.lastIndexOf('/') + 1),
        );
        await _audioPlayer.loadChapter(
          chapterNumber,
          apiReciter,
          autoPlay: autoPlay,
        );
      }
    } on QuranComApiException catch (e) {
      // Fall back to local reciter data
      print('[QuranComAudioRepository] API error, falling back to local: $e');
      final reciter = await _reciterService.getReciterById(reciterId);
      if (reciter != null) {
        await _audioPlayer.loadChapter(
          chapterNumber,
          reciter,
          autoPlay: autoPlay,
        );
      }
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

  /// Get cache statistics for debugging.
  Map<String, dynamic> getCacheStats() {
    return {
      ..._audioService.getCacheStats(),
      'reciterService': 'QuranComReciterService',
    };
  }

  /// Clear all caches.
  void clearCache() {
    _reciterService.clearCache();
    _audioService.clearCache();
  }

  @override
  void release() {
    _audioPlayer.stop();
    _reciterService.dispose();
    _audioService.dispose();
  }
}
