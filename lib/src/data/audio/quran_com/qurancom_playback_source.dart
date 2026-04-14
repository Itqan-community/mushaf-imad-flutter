import '../../../domain/models/audio_source.dart';
import '../../../domain/models/reciter_timing.dart';
import '../../../logging/mushaf_logger.dart';
import '../ayah_timing_service.dart';
import '../base/audio_playback_source.dart';
import '../flutter_audio_player.dart';
import 'qurancom_data_source.dart';
import 'qurancom_recitation_provider.dart';

/// [AudioPlaybackSource] implementation for the Quran.com (Quran.Foundation)
/// streaming API.
///
/// Fetches chapter audio URLs and verse-level timing segments from
/// [QurancomDataSource], then drives playback via the shared [FlutterAudioPlayer].
class QuranComPlaybackSource implements AudioPlaybackSource {
  final QuranComRecitationProvider _recitationProvider;
  final AyahTimingService _timingService;
  final QurancomDataSource _dataSource;
  final FlutterAudioPlayer _audioPlayer;
  final MushafLogger? _logger;

  // Tracks what is currently loaded to avoid redundant reloads.
  int? _loadedChapter;
  int? _loadedReciterId;

  QuranComPlaybackSource({
    required QuranComRecitationProvider recitationProvider,
    required AyahTimingService timingService,
    required QurancomDataSource dataSource,
    required FlutterAudioPlayer audioPlayer,
    MushafLogger? logger,
  }) : _recitationProvider = recitationProvider,
       _timingService = timingService,
       _dataSource = dataSource,
       _audioPlayer = audioPlayer,
       _logger = logger;

  @override
  MushafAudioSource get source => MushafAudioSource.quranCom;

  @override
  Future<void> loadChapter(
    int chapterNumber,
    int recitationId, {
    bool autoPlay = false,
    int startVerseNumber = 1,
  }) async {
    final recitation = await _recitationProvider.getRecitationById(
      recitationId,
    );
    if (recitation == null) return;

    try {
      final needsLoad =
          _loadedChapter != chapterNumber || _loadedReciterId != recitationId;

      if (needsLoad) {
        final audioUrl = await _dataSource.fetchChapterAudioUrl(
          recitationId,
          chapterNumber,
        );
        await _audioPlayer.loadChapter(
          chapterNumber,
          recitation,
          autoPlay: autoPlay,
          audioUrl: audioUrl,
        );
        _loadedChapter = chapterNumber;
        _loadedReciterId = recitationId;
      }

      if (startVerseNumber > 1) {
        final timing = await _timingService.getAyahTiming(
          recitationId,
          chapterNumber,
          startVerseNumber,
        );
        if (timing != null) {
          _logger?.debug(
            'Seeking to verse=$startVerseNumber at ${timing.startTime}ms',
            category: LogCategory.audio,
          );
          await _audioPlayer.seek(Duration(milliseconds: timing.startTime));
        } else {
          await _audioPlayer.seek(Duration.zero);
        }
      } else {
        await _audioPlayer.seek(Duration.zero);
      }

      if (autoPlay) {
        await _audioPlayer.play();
      }
    } catch (e, s) {
      _logger?.error(
        'Failed to load Quran.com chapter audio',
        error: e,
        stackTrace: s,
        category: LogCategory.audio,
      );
    }
  }

  @override
  Future<List<AyahTiming>> getChapterTimings(
    int recitationId,
    int chapterNumber,
  ) async {
    final timings = await _dataSource.fetchChapterTiming(
      recitationId,
      chapterNumber,
    );
    return timings ?? const [];
  }

  @override
  Future<AyahTiming?> getAyahTiming(
    int recitationId,
    int chapterNumber,
    int ayahNumber,
  ) async {
    final timings = await getChapterTimings(recitationId, chapterNumber);
    if (timings.isEmpty) return null;

    return timings.where((t) => t.ayah == ayahNumber).firstOrNull;
  }

  @override
  Future<int?> getCurrentVerse(
    int recitationId,
    int chapterNumber,
    int currentTimeMs,
  ) async {
    final timings = await getChapterTimings(recitationId, chapterNumber);
    if (timings.isEmpty) return null;

    AyahTiming? currentAyah;
    for (final timing in timings) {
      if (currentTimeMs >= timing.startTime) {
        currentAyah = timing;
      } else {
        break;
      }
    }

    if (currentAyah == null) return null;

    return currentAyah.ayah;
  }

  @override
  bool hasTimingForRecitation(int recitationId) => true;

  @override
  Future<void> preloadTiming(int recitationId) async {
    // Timing is fetched alongside the audio URL in loadChapter,
    // so explicit preloading isn't strictly necessary for Quran.com,
    // but we could call _dataSource.fetchChapterTiming if we wanted to
    // be completely proactive. For now, it's a no-op as the design fetches
    // it on-demand fast enough given the API response.
  }
}
