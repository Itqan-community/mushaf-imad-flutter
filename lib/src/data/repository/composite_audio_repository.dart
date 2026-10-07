import 'dart:async';

import '../../domain/models/audio_player_state.dart';
import '../../domain/models/audio_source.dart';
import '../../domain/models/recitation.dart';
import '../../domain/models/reciter_timing.dart';
import '../../domain/repository/audio_repository.dart';
import '../audio/base/audio_playback_source.dart';
import '../audio/base/audio_recitation_provider.dart';
import '../audio/flutter_audio_player.dart';

import '../../mushaf_library.dart';

/// An [AudioRepository] that aggregates one or more audio source backends
/// simultaneously.
///
/// ## Recitation list
/// [getAllRecitations] returns the union of all recitations from every registered
/// [AudioRecitationProvider]. Each [Recitation] is tagged with its
/// [Recitation.audioSource] field so the routing layer knows which backend
/// to call during playback.
///
/// Default recitation: the first entry alphabetically by English name across the
/// merged list.
///
/// ## Playback routing
/// [loadChapter] looks up the recitation's [Recitation.audioSource] and delegates
/// to the matching [AudioPlaybackSource]. Timing queries follow the same routing.
///
/// ## Selected recitation
/// Selection state is held in-memory. The stream emits changes on every
/// [saveSelectedRecitation] call.
class CompositeAudioRepository implements AudioRepository {
  final List<AudioRecitationProvider> _recitationProviders;
  final Map<MushafAudioSource, AudioPlaybackSource> _playbackSources;
  final FlutterAudioPlayer _audioPlayer;

  /// Tracks which source is currently active, set on [loadChapter].
  MushafAudioSource? _activeSource;

  final StreamController<Recitation?> _selectedRecitationController =
      StreamController<Recitation?>.broadcast();

  CompositeAudioRepository({
    required List<AudioRecitationProvider> recitationProviders,
    required Map<MushafAudioSource, AudioPlaybackSource> playbackSources,
    required FlutterAudioPlayer audioPlayer,
  }) : _recitationProviders = recitationProviders,
       _playbackSources = playbackSources,
       _audioPlayer = audioPlayer;

  // ---------------------------------------------------------------------------
  // Recitation management
  // ---------------------------------------------------------------------------

  @override
  Future<List<Recitation>> getAllRecitations() async {
    final results = <Recitation>[];
    for (final provider in _recitationProviders) {
      try {
        results.addAll(await provider.getAllRecitations());
      } catch (e) {
        MushafLibrary.logger.error(
          '[CompositeAudioRepository] Error fetching recitations from ${provider.source.name}: $e',
        );
      }
    }
    // Sort alphabetically by English name.
    results.sort(
      (a, b) => a.reciter.nameEnglish.compareTo(b.reciter.nameEnglish),
    );
    return results;
  }

  @override
  Future<Recitation?> getRecitationById(int recitationId) async {
    for (final provider in _recitationProviders) {
      try {
        final recitation = await provider.getRecitationById(recitationId);
        if (recitation != null) return recitation;
      } catch (e) {
        MushafLibrary.logger.error(
          '[CompositeAudioRepository] Error finding recitation by ID from ${provider.source.name}: $e',
        );
      }
    }
    return null;
  }

  @override
  Future<List<Recitation>> searchRecitations(
    String query, {
    String languageCode = 'ar',
  }) async {
    final results = <Recitation>[];
    for (final provider in _recitationProviders) {
      try {
        results.addAll(
          await provider.searchRecitations(query, languageCode: languageCode),
        );
      } catch (e) {
        MushafLibrary.logger.error(
          '[CompositeAudioRepository] Error searching recitations in ${provider.source.name}: $e',
        );
      }
    }
    results.sort(
      (a, b) => a.reciter.nameEnglish.compareTo(b.reciter.nameEnglish),
    );
    return results;
  }

  @override
  Future<Recitation> getDefaultRecitation() async {
    final all = await getAllRecitations();
    if (all.isEmpty) {
      throw StateError(
        'CompositeAudioRepository: no recitations are available.',
      );
    }
    // Already sorted alphabetically -- return the first entry.
    return all.first;
  }

  @override
  void saveSelectedRecitation(Recitation recitation) {
    _selectedRecitationController.add(recitation);
  }

  @override
  Stream<Recitation?> getSelectedRecitationStream() =>
      _selectedRecitationController.stream;

  // ---------------------------------------------------------------------------
  // Playback
  // ---------------------------------------------------------------------------

  @override
  Future<void> loadChapter(
    int chapterNumber,
    Recitation recitation, {
    bool autoPlay = false,
    int startVerseNumber = 1,
  }) async {
    final targetSource = recitation.audioSource;

    final playbackSource = _playbackSources[targetSource];
    if (playbackSource == null) return;

    _activeSource = targetSource;
    await playbackSource.loadChapter(
      chapterNumber,
      recitation,
      autoPlay: autoPlay,
      startVerseNumber: startVerseNumber,
    );
  }

  @override
  Stream<AudioPlayerState> getPlayerStateStream() async* {
    await for (final state in _audioPlayer.domainStateStream) {
      int? verse;
      if (_activeSource != null &&
          state.currentRecitationId != null &&
          state.currentChapter != null) {
        try {
          verse = await _playbackSources[_activeSource]?.getCurrentVerse(
            state.currentRecitationId!,
            state.currentChapter!,
            state.currentPositionMs,
          );
        } catch (e) {
          MushafLibrary.logger.debug(
            '[CompositeAudioRepository] Error getting current verse: $e',
          );
        }
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
    int recitationId,
    int chapterNumber,
    int ayahNumber,
  ) async {
    final source = await _resolveSourceForRecitation(recitationId);
    return source?.getAyahTiming(recitationId, chapterNumber, ayahNumber);
  }

  @override
  Future<int?> getCurrentVerse(
    int recitationId,
    int chapterNumber,
    int currentTimeMs,
  ) async {
    final source = await _resolveSourceForRecitation(recitationId);
    return source?.getCurrentVerse(recitationId, chapterNumber, currentTimeMs);
  }

  @override
  Future<List<AyahTiming>> getChapterTimings(
    int recitationId,
    int chapterNumber,
  ) async {
    final source = await _resolveSourceForRecitation(recitationId);
    return source?.getChapterTimings(recitationId, chapterNumber) ??
        Future.value([]);
  }

  @override
  bool hasTimingForRecitation(int recitationId) {
    if (_activeSource != null) {
      return _playbackSources[_activeSource]?.hasTimingForRecitation(
            recitationId,
          ) ??
          false;
    }
    return _playbackSources.values.any(
      (s) => s.hasTimingForRecitation(recitationId),
    );
  }

  @override
  Future<void> preloadTiming(int recitationId) async {
    final source = await _resolveSourceForRecitation(recitationId);
    await source?.preloadTiming(recitationId);
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void release() {
    _audioPlayer.stop();
    _selectedRecitationController.close();
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  Future<AudioPlaybackSource?> _resolveSourceForRecitation(
    int recitationId,
  ) async {
    for (final provider in _recitationProviders) {
      final recitation = await provider.getRecitationById(recitationId);
      if (recitation != null) {
        return _playbackSources[recitation.audioSource];
      }
    }
    return null;
  }
}
