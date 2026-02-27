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
    // Listen to just_audio state changes and broadcast to audio_service and domain
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
        errorMessage: null, // Hook up to stream errors if needed
      ),
    );
  }

  /// Custom extension to load a specific chapter from a reciter
  Future<void> loadChapter(
    int chapterNumber,
    ReciterInfo reciter, {
    String? audioUrl,
    bool autoPlay = false,
  }) async {
    _currentChapter = chapterNumber;
    _currentReciterId = reciter.id;

    // Use CORS proxy for web to bypass restrictive mp3quran headers
    final resolvedAudioUrl = audioUrl ?? reciter.getAudioUrl(chapterNumber);
    final url = kIsWeb
        ? 'https://corsproxy.io/?${Uri.encodeComponent(resolvedAudioUrl)}'
        : resolvedAudioUrl;

    final title = 'Surah ${chapterNumber.toString().padLeft(3, "0")}';
    print('[FlutterAudioPlayer] Loading chapter: $title from URL: $url');

    mediaItem.add(
      MediaItem(id: url, album: reciter.getDisplayName(), title: title),
    );

    try {
      print('[FlutterAudioPlayer] Calling setAudioSource...');
      await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
      print(
        '[FlutterAudioPlayer] setAudioSource completed successfully. autoPlay=$autoPlay',
      );
      if (autoPlay) {
        play();
      }
    } catch (e, stack) {
      print('[FlutterAudioPlayer] ERROR loading audio source: $e');
      print(stack);
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
    print(
      '[FlutterAudioPlayer] Play requested. Current state: ${_player.processingState}, playing: ${_player.playing}',
    );
    try {
      await _player.play();
      print('[FlutterAudioPlayer] Play completed.');
    } catch (e, stack) {
      print('[FlutterAudioPlayer] ERROR during play(): $e');
      print(stack);
    }
  }

  @override
  Future<void> pause() async {
    print('[FlutterAudioPlayer] Pause requested.');
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    print('[FlutterAudioPlayer] Stop requested.');
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    final loopMode =
        repeatMode == AudioServiceRepeatMode.all ||
            repeatMode == AudioServiceRepeatMode.one
        ? LoopMode.one
        : LoopMode.off;
    await _player.setLoopMode(loopMode);
  }

  Future<void> setRepeatModeBool(bool enabled) => setRepeatMode(
    enabled ? AudioServiceRepeatMode.one : AudioServiceRepeatMode.none,
  );

  bool isRepeatMode() => _player.loopMode != LoopMode.off;
}
