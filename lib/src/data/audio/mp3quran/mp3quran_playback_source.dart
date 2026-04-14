import '../../../domain/models/audio_source.dart';
import '../../../domain/models/reciter_timing.dart';
import '../../../mushaf_library.dart';
import '../ayah_timing_service.dart';
import '../base/audio_playback_source.dart';
import '../flutter_audio_player.dart';
import '../recitation_data_provider.dart';

/// [AudioPlaybackSource] implementation for the mp3quran.net static files.
///
/// Delegates timing queries to [AyahTimingService] (which loads pre-computed
/// JSON assets) and drives playback via the shared [FlutterAudioPlayer].
class Mp3QuranPlaybackSource implements AudioPlaybackSource {
  final AyahTimingService _timingService;
  final FlutterAudioPlayer _audioPlayer;

  // Tracks what is currently loaded to avoid redundant reloads.
  int? _loadedChapter;
  int? _loadedRecitationId;

  Mp3QuranPlaybackSource({
    required AyahTimingService timingService,
    required FlutterAudioPlayer audioPlayer,
  }) : _timingService = timingService,
       _audioPlayer = audioPlayer;

  @override
  MushafAudioSource get source => MushafAudioSource.mp3quran;

  @override
  Future<void> loadChapter(
    int chapterNumber,
    int recitationId, {
    bool autoPlay = false,
    int startVerseNumber = 1,
  }) async {
    MushafLibrary.logger.debug(
      '[Mp3QuranPlaybackSource] loadChapter → chapter=$chapterNumber, '
      'recitation=$recitationId, startVerse=$startVerseNumber, autoPlay=$autoPlay',
    );

    final recitation = RecitationDataProvider.getRecitationById(recitationId);
    if (recitation == null) {
      MushafLibrary.logger.debug(
        '[Mp3QuranPlaybackSource] recitation NOT FOUND for id=$recitationId',
      );
      return;
    }

    final needsLoad =
        _loadedChapter != chapterNumber || _loadedRecitationId != recitationId;

    if (needsLoad) {
      await _audioPlayer.loadChapter(
        chapterNumber,
        recitation,
        autoPlay: false,
        audioUrl: recitation.getAudioUrl(chapterNumber),
      );
      _loadedChapter = chapterNumber;
      _loadedRecitationId = recitationId;
      MushafLibrary.logger.debug(
        '[Mp3QuranPlaybackSource] audio loaded for chapter=$chapterNumber',
      );
    } else {
      MushafLibrary.logger.debug(
        '[Mp3QuranPlaybackSource] chapter already loaded, skipping reload',
      );
    }

    if (startVerseNumber > 1) {
      final timing = await _timingService.getAyahTiming(
        recitationId,
        chapterNumber,
        startVerseNumber,
      );
      if (timing != null) {
        MushafLibrary.logger.debug(
          '[Mp3QuranPlaybackSource] seeking to verse=$startVerseNumber '
          'at ${timing.startTime}ms',
        );
        await _audioPlayer.seek(Duration(milliseconds: timing.startTime));
      } else {
        MushafLibrary.logger.debug(
          '[Mp3QuranPlaybackSource] no timing for verse=$startVerseNumber, '
          'seeking to start',
        );
        await _audioPlayer.seek(Duration.zero);
      }
    } else {
      await _audioPlayer.seek(Duration.zero);
    }

    if (autoPlay) {
      await _audioPlayer.play();
    }
  }

  @override
  Future<List<AyahTiming>> getChapterTimings(
    int recitationId,
    int chapterNumber,
  ) => _timingService.getChapterTimings(recitationId, chapterNumber);

  @override
  Future<AyahTiming?> getAyahTiming(
    int recitationId,
    int chapterNumber,
    int ayahNumber,
  ) => _timingService.getAyahTiming(recitationId, chapterNumber, ayahNumber);

  @override
  Future<int?> getCurrentVerse(
    int recitationId,
    int chapterNumber,
    int currentTimeMs,
  ) => _timingService.getCurrentVerse(
    recitationId,
    chapterNumber,
    currentTimeMs,
  );

  @override
  bool hasTimingForRecitation(int recitationId) =>
      _timingService.hasTimingForRecitation(recitationId);

  @override
  Future<void> preloadTiming(int recitationId) =>
      _timingService.preloadTiming(recitationId);
}
