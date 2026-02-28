import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../domain/models/audio_player_state.dart' as domain;
import '../../domain/models/reciter_info.dart';

class FlutterAudioPlayer extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final _domainStateController =
      StreamController<domain.AudioPlayerState>.broadcast();

  int? _currentChapter;
  int? _currentReciterId;

  static const String _defaultProxy = 'https://corsproxy.io/?';

  Stream<domain.AudioPlayerState> get domainStateStream =>
      _domainStateController.stream;

  int? get currentReciterId => _currentReciterId;

  FlutterAudioPlayer() {
    _initStreams();
  }

  Future<void> dispose() async {
    await _player.dispose();
    await _domainStateController.close();
  }

  void _initStreams() {
    _player.playbackEventStream.listen(
      (_) {
        final playing = _player.playing;

        playbackState.add(
          playbackState.value.copyWith(
            controls: [
              MediaControl.skipToPrevious,
              if (playing) MediaControl.pause else MediaControl.play,
              MediaControl.stop,
              MediaControl.skipToNext,
            ],
            processingState: _getProcessingState(),
            playing: playing,
            updatePosition: _player.position,
            bufferedPosition: _player.bufferedPosition,
            speed: _player.speed,
          ),
        );

        _broadcastDomainState();
      },
      onError: (Object e, StackTrace _) {
        _broadcastDomainState(error: e.toString());
      },
    );

    _player.positionStream.listen((_) => _broadcastDomainState());
  }

  String _resolveFinalUrl(String url) {
    if (!kIsWeb) return url;
    return '$_defaultProxy${Uri.encodeComponent(url)}';
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

  void _broadcastDomainState({String? error}) {
    if (_domainStateController.isClosed) return;

    _domainStateController.add(
      domain.AudioPlayerState(
        playbackState: error != null
            ? domain.PlaybackState.error
            : _getDomainPlaybackState(),
        currentPositionMs: _player.position.inMilliseconds,
        durationMs: _player.duration?.inMilliseconds ?? 0,
        currentChapter: _currentChapter,
        currentReciterId: _currentReciterId,
        isBuffering: _player.processingState == ProcessingState.buffering ||
            _player.processingState == ProcessingState.loading,
        isRepeatEnabled: _player.loopMode != LoopMode.off,
        errorMessage: error,
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

    final verseCount = reciter.getChapterVerseCount(chapterNumber);

    final List<AudioSource> children = List.generate(
      verseCount,
      (index) {
        final ayahNumber = index + 1;
        final url = reciter.getAyahUrl(
          chapterNumber: chapterNumber,
          ayahNumber: ayahNumber,
        );
        return AudioSource.uri(Uri.parse(_resolveFinalUrl(url)));
      },
    );

    final int initialIndex = (startAyahNumber != null &&
            startAyahNumber >= 1 &&
            startAyahNumber <= verseCount)
        ? startAyahNumber - 1
        : 0;

    final source = ConcatenatingAudioSource(
      children: children,
      initialIndex: initialIndex,
    );

    try {
      await _player.setAudioSource(source);
      if (autoPlay) {
        await _player.play();
      }
    } catch (e) {
      _broadcastDomainState(error: e.toString());
    }
  }

  Future<void> loadChapterByReciterId(
    int chapterNumber,
    int reciterId, {
    bool autoPlay = false,
    int? startAyahNumber,
  }) async {
    final reciter = ReciterInfo.byId(reciterId);
    return loadChapter(
      chapterNumber,
      reciter,
      autoPlay: autoPlay,
      startAyahNumber: startAyahNumber,
    );
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.all:
        await _player.setLoopMode(LoopMode.all);
        break;
    }
  }

  @override
  Future<void> play() async {
    try {
      await _player.play();
    } catch (e) {
      _broadcastDomainState(error: e.toString());
    }
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);
}
