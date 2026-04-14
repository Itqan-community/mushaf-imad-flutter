import '../../../domain/models/audio_source.dart';
import '../../../domain/models/reciter_info.dart';
import '../../../domain/models/reciter_timing.dart';
import '../../../logging/mushaf_logger.dart';
import '../ayah_timing_service.dart';
import '../base/audio_playback_source.dart';
import '../flutter_audio_player.dart';
import 'qurancom_data_source.dart';
import 'qurancom_reciter_provider.dart';

/// [AudioPlaybackSource] implementation for the Quran.com (Quran.Foundation)
/// streaming API.
///
/// Fetches chapter audio URLs and verse-level timing segments from
/// [QurancomDataSource], then drives playback via the shared [FlutterAudioPlayer].
class QuranComPlaybackSource implements AudioPlaybackSource {
  final QuranComReciterProvider _reciterProvider;
  final AyahTimingService _timingService;
  final QurancomDataSource _dataSource;
  final FlutterAudioPlayer _audioPlayer;
  final MushafLogger? _logger;

  // Tracks what is currently loaded to avoid redundant reloads.
  int? _loadedChapter;
  int? _loadedReciterId;

  QuranComPlaybackSource({
    required QuranComReciterProvider reciterProvider,
    required AyahTimingService timingService,
    required QurancomDataSource dataSource,
    required FlutterAudioPlayer audioPlayer,
    MushafLogger? logger,
  }) : _reciterProvider = reciterProvider,
       _timingService = timingService,
       _dataSource = dataSource,
       _audioPlayer = audioPlayer,
       _logger = logger;

  @override
  MushafAudioSource get source => MushafAudioSource.quranCom;

  @override
  Future<void> loadChapter(
    int chapterNumber,
    int reciterId, {
    bool autoPlay = false,
    int startVerseNumber = 1,
  }) async {
    final ReciterInfo? reciter =
        await _reciterProvider.getReciterById(reciterId);
    if (reciter == null) return;

    try {
      final needsLoad =
          _loadedChapter != chapterNumber || _loadedReciterId != reciterId;

      if (needsLoad) {
        final audioUrl = await _dataSource.fetchChapterAudioUrl(
          reciterId,
          chapterNumber,
        );
        await _audioPlayer.loadChapter(
          chapterNumber,
          reciter,
          autoPlay: false,
          audioUrl: audioUrl,
        );
        _loadedChapter = chapterNumber;
        _loadedReciterId = reciterId;
      }

      if (startVerseNumber > 1) {
        final timing = await _timingService.getAyahTiming(
          reciterId,
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
    int reciterId,
    int chapterNumber,
  ) => _timingService.getChapterTimings(reciterId, chapterNumber);

  @override
  Future<AyahTiming?> getAyahTiming(
    int reciterId,
    int chapterNumber,
    int ayahNumber,
  ) => _timingService.getAyahTiming(reciterId, chapterNumber, ayahNumber);

  @override
  Future<int?> getCurrentVerse(
    int reciterId,
    int chapterNumber,
    int currentTimeMs,
  ) => _timingService.getCurrentVerse(reciterId, chapterNumber, currentTimeMs);

  @override
  bool hasTimingForReciter(int reciterId) =>
      _timingService.hasTimingForReciter(reciterId);

  @override
  Future<void> preloadTiming(int reciterId) =>
      _timingService.preloadTiming(reciterId);
}
