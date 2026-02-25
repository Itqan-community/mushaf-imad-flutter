import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../../domain/models/audio_player_state.dart' as domain;
import '../../domain/models/reciter_info.dart';

/// App-specific AudioHandler that connects just_audio to audio_service
class FlutterAudioPlayer extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  int? _currentChapter;
  int? _currentReciterId;

  /// Expose the underlying just_audio player state as our domain state
  final _domainStateController =
      StreamController<domain.AudioPlayerState>.broadcast();
  Stream<domain.AudioPlayerState> get domainStateStream =>
      _domainStateController.stream;

  FlutterAudioPlayer() {
    _initStreams();
  }

  void _initStreams() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            if (playing) MediaControl.pause else MediaControl.play,
            MediaControl.stop,
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 3],
          processingState: _getProcessingState(),
          playing: playing,
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
          queueIndex: event.currentIndex,
        ),
      );

      _broadcastDomainState();
    });

    _player.positionStream.listen((_) => _broadcastDomainState());
  }

  /// ✅ Helper to resolve final URL for Web compatibility (CORS Proxy)
  String _resolveFinalUrl(String url) {
    return kIsWeb ? 'https://corsproxy.io/?${Uri.encodeComponent(url)}' : url;
  }

  AudioProcessingState _getProcessingState() {
    switch (_player.processingState) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  domain.PlaybackState _getDomainPlaybackState() {
    switch (_player.processingState) {
      case ProcessingState.idle:
        return domain.PlaybackState.idle;
      case ProcessingState.loading:
      case ProcessingState.buffering:
        return domain.PlaybackState.loading;
      case ProcessingState.ready:
        return _player.playing
            ? domain.PlaybackState.playing
            : domain.PlaybackState.paused;
      case ProcessingState.completed:
        return domain.PlaybackState.stopped;
    }
  }

  void _broadcastDomainState() {
    _domainStateController.add(
      domain.AudioPlayerState(
        playbackState: _getDomainPlaybackState(),
        currentPositionMs: _player.position.inMilliseconds,
        durationMs: _player.duration?.inMilliseconds ?? 0,
        currentChapter: _currentChapter,
        currentReciterId: _currentReciterId,
        isBuffering:
            _player.processingState == ProcessingState.buffering ||
            _player.processingState == ProcessingState.loading,
        isRepeatEnabled: _player.loopMode != LoopMode.off,
        errorMessage: null,
      ),
    );
  }

  Future<void> loadChapter(
    int chapterNumber,
    ReciterInfo reciter, {
    bool autoPlay = false,
    int? startAyahNumber,
  }) async {
    _currentChapter = chapterNumber;
    _currentReciterId = reciter.id;

    final title = 'Surah ${chapterNumber.toString().padLeft(3, "0")}';
    debugPrint('[FlutterAudioPlayer] Loading chapter: $title');

    try {
      AudioSource source;

      if (startAyahNumber != null && startAyahNumber > 1) {
        // ⚠️ Note: ReciterInfo must implement getChapterVerseCount and getAyahUrl
        final verseCount = reciter.getChapterVerseCount(chapterNumber);
        final children = <AudioSource>[];

        for (int ayah = startAyahNumber; ayah <= verseCount; ayah++) {
          final ayahUrl = reciter.getAyahUrl(
            chapterNumber: chapterNumber,
            ayahNumber: ayah,
          );
          
          // ✅ Using helper to avoid duplication
          children.add(AudioSource.uri(Uri.parse(_resolveFinalUrl(ayahUrl))));
        }

        source = ConcatenatingAudioSource(children: children);
      } else {
        final chapterUrl = reciter.getAudioUrl(chapterNumber);
        
        // ✅ Using helper to avoid duplication
        source = AudioSource.uri(Uri.parse(_resolveFinalUrl(chapterUrl)));
      }

      mediaItem.add(
        MediaItem(
          id: 'chapter-$chapterNumber',
          album: reciter.getDisplayName(),
          title: title,
        ),
      );

      await _player.setAudioSource(source);

      if (autoPlay) {
        await play();
      }
    } catch (e, stack) {
      debugPrint('[FlutterAudioPlayer] ERROR loading audio source: $e');
      debugPrintStack(stackTrace: stack);
      _domainStateController.add(
        domain.AudioPlayerState(
          playbackState: domain.PlaybackState.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  @override
  Future<void> play() async {
    debugPrint('[FlutterAudioPlayer] Play requested.');
    try {
      await _player.play();
    } catch (e, stack) {
      debugPrint('[FlutterAudioPlayer] ERROR during play(): $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  @override
  Future<void> pause() async {
    debugPrint('[FlutterAudioPlayer] Pause requested.');
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    debugPrint('[FlutterAudioPlayer] Stop requested.');
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    // ✅ Improved mapping: .all should loop the whole playlist, not just one ayah
    late final LoopMode loopMode;
    switch (repeatMode) {
      case AudioServiceRepeatMode.one:
        loopMode = LoopMode.one;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        loopMode = LoopMode.all;
      case AudioServiceRepeatMode.none:
      default:
        loopMode = LoopMode.off;
    }
    await _player.setLoopMode(loopMode);
  }

  Future<void> setRepeatModeBool(bool enabled) => setRepeatMode(
        enabled ? AudioServiceRepeatMode.all : AudioServiceRepeatMode.none,
      );

  bool isRepeatMode() => _player.loopMode != LoopMode.off;
}
