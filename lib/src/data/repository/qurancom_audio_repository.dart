import 'dart:async';

import 'package:imad_flutter/src/data/audio/ayah_timing_service.dart';
import 'package:imad_flutter/src/data/audio/flutter_audio_player.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_data_source.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_reciter_provider.dart';
import 'package:imad_flutter/src/domain/models/audio_player_state.dart';
import 'package:imad_flutter/src/domain/models/reciter_info.dart';
import 'package:imad_flutter/src/domain/models/reciter_timing.dart';
import 'package:imad_flutter/src/domain/repository/audio_repository.dart';
import 'package:imad_flutter/src/logging/mushaf_logger.dart';

/// [AudioRepository] implementation backed by the Quran.com API.
///
/// Delegates:
/// - Reciter queries  → [QuranComReciterProvider]
/// - Timing queries   → [AyahTimingService] (with Quran.com API fallback)
/// - Audio URL fetch  → [QurancomDataSource]
/// - Playback control → [FlutterAudioPlayer]
class QuranComAudioRepository implements AudioRepository {
  final QuranComReciterProvider _reciterProvider;
  final AyahTimingService _timingService;
  final QurancomDataSource _dataSource;
  final FlutterAudioPlayer _audioPlayer;
  final MushafLogger? _logger;

  QuranComAudioRepository({
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

  // ---------------------------------------------------------------------------
  // Reciter Management
  // ---------------------------------------------------------------------------

  @override
  Future<List<ReciterInfo>> getAllReciters() =>
      _reciterProvider.getAllReciters();

  @override
  Future<ReciterInfo?> getReciterById(int reciterId) =>
      _reciterProvider.getReciterById(reciterId);

  @override
  Future<List<ReciterInfo>> searchReciters(
    String query, {
    String languageCode = 'en',
  }) => _reciterProvider.searchReciters(query, languageCode: languageCode);


  @override
  Future<ReciterInfo> getDefaultReciter() =>
      _reciterProvider.getDefaultReciter();

  @override
  void saveSelectedReciter(ReciterInfo reciter) {
    // No persistent selection in this implementation — state is held by the UI.
    // TODO(phase5): Wire to a preferences service if needed.
  }

  @override
  Stream<ReciterInfo?> getSelectedReciterStream() => const Stream.empty();

  // ---------------------------------------------------------------------------
  // Playback
  // ---------------------------------------------------------------------------

  // Tracks what is currently loaded to avoid reloading the same chapter
  int? _loadedChapter;
  int? _loadedReciterId;

  @override
  Future<void> loadChapter(
    int chapterNumber,
    int reciterId, {
    bool autoPlay = false,
    int startVerseNumber = 1,
  }) async {
    final reciter = await _reciterProvider.getReciterById(reciterId);
    if (reciter == null) return;

    try {
      // Only reload audio if chapter or reciter changed
      final needsLoad =
          _loadedChapter != chapterNumber || _loadedReciterId != reciterId;

      if (needsLoad) {
        final audioUrl = await _dataSource.fetchChapterAudioUrl(
          reciterId,
          chapterNumber,
        );
        // Load without autoPlay so we can seek first
        await _audioPlayer.loadChapter(
          chapterNumber,
          reciter,
          autoPlay: false,
          audioUrl: audioUrl,
        );
        _loadedChapter = chapterNumber;
        _loadedReciterId = reciterId;
      }

      // Seek to the requested verse's start time
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

      // Start playback if requested
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
  Stream<AudioPlayerState> getPlayerStateStream() async* {
    await for (final state in _audioPlayer.domainStateStream) {
      int? verse;
      if (state.currentReciterId != null && state.currentChapter != null) {
        verse = await _timingService.getCurrentVerse(
          state.currentReciterId!,
          state.currentChapter!,
          state.currentPositionMs,
        );
      }
      yield state.copyWith(currentVerse: verse);
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

  // ---------------------------------------------------------------------------
  // Timing
  // ---------------------------------------------------------------------------

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
  Future<List<AyahTiming>> getChapterTimings(
    int reciterId,
    int chapterNumber,
  ) => _timingService.getChapterTimings(reciterId, chapterNumber);

  @override
  bool hasTimingForReciter(int reciterId) =>
      _timingService.hasTimingForReciter(reciterId);

  @override
  Future<void> preloadTiming(int reciterId) =>
      _timingService.preloadTiming(reciterId);

  // ---------------------------------------------------------------------------
  // Sync getters (rely on stream — return 0/false while idle)
  // ---------------------------------------------------------------------------

  @override
  int getCurrentPosition() => 0;

  @override
  int getDuration() => 0;

  @override
  bool isCurrentlyPlaying() => false;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void release() {
    _audioPlayer.stop();
    _reciterProvider.clearCache();
  }
}
