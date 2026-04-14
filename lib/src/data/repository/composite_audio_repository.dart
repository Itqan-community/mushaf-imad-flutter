import 'dart:async';

import '../../domain/models/audio_player_state.dart';
import '../../domain/models/audio_source.dart';
import '../../domain/models/reciter_info.dart';
import '../../domain/models/reciter_timing.dart';
import '../../domain/repository/audio_repository.dart';
import '../audio/base/audio_playback_source.dart';
import '../audio/base/audio_reciter_provider.dart';
import '../audio/flutter_audio_player.dart';

/// An [AudioRepository] that aggregates one or more audio source backends
/// simultaneously.
///
/// ## Reciter list
/// [getAllReciters] returns the union of all reciters from every registered
/// [AudioReciterProvider]. Each [ReciterInfo] is tagged with its
/// [ReciterInfo.audioSource] field so the routing layer knows which backend
/// to call during playback. When the same reciter appears in multiple sources
/// both entries are included and can be distinguished by their source tag.
///
/// Default reciter: the first entry alphabetically by English name across the
/// merged list.
///
/// ## Playback routing
/// [loadChapter] looks up the reciter's [ReciterInfo.audioSource] and delegates
/// to the matching [AudioPlaybackSource]. Timing queries follow the same routing.
///
/// ## Selected reciter
/// Selection state is held in-memory. The stream emits changes on every
/// [saveSelectedReciter] call.
class CompositeAudioRepository implements AudioRepository {
  final List<AudioReciterProvider> _reciterProviders;
  final Map<MushafAudioSource, AudioPlaybackSource> _playbackSources;
  final FlutterAudioPlayer _audioPlayer;

  /// Tracks which source is currently active, set on [loadChapter].
  MushafAudioSource? _activeSource;

  final StreamController<ReciterInfo?> _selectedReciterController =
      StreamController<ReciterInfo?>.broadcast();

  CompositeAudioRepository({
    required List<AudioReciterProvider> reciterProviders,
    required Map<MushafAudioSource, AudioPlaybackSource> playbackSources,
    required FlutterAudioPlayer audioPlayer,
  }) : _reciterProviders = reciterProviders,
       _playbackSources = playbackSources,
       _audioPlayer = audioPlayer;

  // ---------------------------------------------------------------------------
  // Reciter management
  // ---------------------------------------------------------------------------

  @override
  Future<List<ReciterInfo>> getAllReciters() async {
    final results = <ReciterInfo>[];
    for (final provider in _reciterProviders) {
      results.addAll(await provider.getAllReciters());
    }
    // Sort alphabetically by English name.
    results.sort(
      (a, b) => a.nameEnglish.compareTo(b.nameEnglish),
    );
    return results;
  }

  @override
  Future<ReciterInfo?> getReciterById(int reciterId) async {
    // The caller must use the full list to distinguish same-id reciters from
    // different sources. This method returns the first match found.
    for (final provider in _reciterProviders) {
      final reciter = await provider.getReciterById(reciterId);
      if (reciter != null) return reciter;
    }
    return null;
  }

  @override
  Future<List<ReciterInfo>> searchReciters(
    String query, {
    String languageCode = 'en',
  }) async {
    final results = <ReciterInfo>[];
    for (final provider in _reciterProviders) {
      results.addAll(
        await provider.searchReciters(query, languageCode: languageCode),
      );
    }
    results.sort((a, b) => a.nameEnglish.compareTo(b.nameEnglish));
    return results;
  }

  @override
  Future<List<ReciterInfo>> getHafsReciters() async {
    final results = <ReciterInfo>[];
    for (final provider in _reciterProviders) {
      results.addAll(await provider.getHafsReciters());
    }
    results.sort((a, b) => a.nameEnglish.compareTo(b.nameEnglish));
    return results;
  }

  @override
  Future<ReciterInfo> getDefaultReciter() async {
    final all = await getAllReciters();
    if (all.isEmpty) {
      throw StateError('CompositeAudioRepository: no reciters are available.');
    }
    // Already sorted alphabetically -- return the first entry.
    return all.first;
  }

  @override
  void saveSelectedReciter(ReciterInfo reciter) {
    _selectedReciterController.add(reciter);
  }

  @override
  Stream<ReciterInfo?> getSelectedReciterStream() =>
      _selectedReciterController.stream;

  // ---------------------------------------------------------------------------
  // Playback
  // ---------------------------------------------------------------------------

  @override
  Future<void> loadChapter(
    int chapterNumber,
    int reciterId, {
    bool autoPlay = false,
    int startVerseNumber = 1,
  }) async {
    // Determine which source owns the reciter.
    // We look for a provider that knows this reciterId; if multiple sources
    // have it the one that was registered first wins (callers should pass
    // the full ReciterInfo with its audioSource tag when possible).
    MushafAudioSource? targetSource;
    for (final provider in _reciterProviders) {
      final reciter = await provider.getReciterById(reciterId);
      if (reciter != null) {
        targetSource = reciter.audioSource;
        break;
      }
    }

    if (targetSource == null) return;

    final playbackSource = _playbackSources[targetSource];
    if (playbackSource == null) return;

    _activeSource = targetSource;
    await playbackSource.loadChapter(
      chapterNumber,
      reciterId,
      autoPlay: autoPlay,
      startVerseNumber: startVerseNumber,
    );
  }

  @override
  Stream<AudioPlayerState> getPlayerStateStream() async* {
    await for (final state in _audioPlayer.domainStateStream) {
      int? verse;
      if (_activeSource != null &&
          state.currentReciterId != null &&
          state.currentChapter != null) {
        verse = await _playbackSources[_activeSource]?.getCurrentVerse(
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

  @override
  int getCurrentPosition() => 0;

  @override
  int getDuration() => 0;

  @override
  bool isCurrentlyPlaying() => false;

  // ---------------------------------------------------------------------------
  // Timing (routed to active source)
  // ---------------------------------------------------------------------------

  @override
  Future<AyahTiming?> getAyahTiming(
    int reciterId,
    int chapterNumber,
    int ayahNumber,
  ) async {
    final source = await _resolveSourceForReciter(reciterId);
    return source?.getAyahTiming(reciterId, chapterNumber, ayahNumber);
  }

  @override
  Future<int?> getCurrentVerse(
    int reciterId,
    int chapterNumber,
    int currentTimeMs,
  ) async {
    final source = await _resolveSourceForReciter(reciterId);
    return source?.getCurrentVerse(reciterId, chapterNumber, currentTimeMs);
  }

  @override
  Future<List<AyahTiming>> getChapterTimings(
    int reciterId,
    int chapterNumber,
  ) async {
    final source = await _resolveSourceForReciter(reciterId);
    return source?.getChapterTimings(reciterId, chapterNumber) ??
        Future.value([]);
  }

  @override
  bool hasTimingForReciter(int reciterId) {
    // Check the active source first; fall back to scanning all sources.
    if (_activeSource != null) {
      return _playbackSources[_activeSource]?.hasTimingForReciter(reciterId) ??
          false;
    }
    return _playbackSources.values.any(
      (s) => s.hasTimingForReciter(reciterId),
    );
  }

  @override
  Future<void> preloadTiming(int reciterId) async {
    final source = await _resolveSourceForReciter(reciterId);
    await source?.preloadTiming(reciterId);
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void release() {
    _audioPlayer.stop();
    _selectedReciterController.close();
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  Future<AudioPlaybackSource?> _resolveSourceForReciter(int reciterId) async {
    for (final provider in _reciterProviders) {
      final reciter = await provider.getReciterById(reciterId);
      if (reciter != null) {
        return _playbackSources[reciter.audioSource];
      }
    }
    return null;
  }
}
