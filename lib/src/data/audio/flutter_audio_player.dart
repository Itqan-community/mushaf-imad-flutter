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

  /// Web proxy for CORS (used only on web)
  static const String _webProxyUrl = 'https://corsproxy.io/?';

  final _domainStateController =
      StreamController<domain.AudioPlayerState>.broadcast();

  Stream<domain.AudioPlayerState> get domainStateStream =>
      _domainStateController.stream;

  FlutterAudioPlayer() {
    _initStreams();
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _player.dispose();
    await _domainStateController.close();
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

  String _resolveFinalUrl(String url) {
    return kIsWeb ? '$_webProxyUrl${Uri.encodeComponent(url)}' : url;
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
    _domainStateController.add(
      domain.AudioPlayerState(
        playbackState:
            error != null ? domain.PlaybackState.error : _getDomainPlaybackState(),
        currentPositionMs: _player.position.inMilliseconds,
        durationMs: _player.duration?.inMilliseconds ?? 0,
        currentChapter: _currentChapter,
        currentReciterId: _currentReciterId,
        isBuffering:
            _player.processingState == ProcessingState.buffering ||
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

    final title = 'Surah ${chapterNumber.toString().padLeft(3, "0")}';
    debugPrint('[FlutterAudioPlayer] Loading chapter: $title');

    try {
      AudioSource source;

      if (startAyahNumber != null && startAyahNumber > 1) {
        final verseCount = reciter.getChapterVerseCount(chapterNumber);

        if (startAyahNumber > verseCount) {
          final chapterUrl = reciter.getAudioUrl(chapterNumber);
          source = AudioSource.uri(Uri.parse(_resolveFinalUrl(chapterUrl)));
        } else {
          final children = <AudioSource>[];
          for (int ayah = startAyahNumber; ayah <= verseCount; ayah++) {
            final ayahUrl = reciter.getAyahUrl(
              chapterNumber: chapterNumber,
              ayahNumber: ayah,
            );
            children.add(
              AudioSource.uri(Uri.parse(_resolveFinalUrl(ayahUrl))),
            );
          }
          source = ConcatenatingAudioSource(children: children);
        }
      } else {
        final chapterUrl = reciter.getAudioUrl(chapterNumber);
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
      _broadcastDomainState(error: e.toString());
    }
  }

  Future<void> loadChapterByReciterId(
    int chapterNumber,
    int reciterId, {
    bool autoPlay = false,
  }) async {
    final reciter = ReciterInfo.byId(reciterId);
    return loadChapter(
      chapterNumber,
      reciter,
      autoPlay: autoPlay,
    );
  }

  @override
  Future<void> play() async {
    debugPrint('[FlutterAudioPlayer] Play requested.');
    try {
      await _player.play();
    } catch (e, stack) {
      debugPrint('[FlutterAudioPlayer] ERROR during play(): $e');
      debugPrintStack(stackTrace: stack);
      _broadcastDomainState(error: e.toString());
    }
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    late final LoopMode loopMode;
    switch (repeatMode) {
      case AudioServiceRepeatMode.one:
        loopMode = LoopMode.one;
        break;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        loopMode = LoopMode.all;
        break;
      case AudioServiceRepeatMode.none:
      default:
        loopMode = LoopMode.off;
        break;
    }
    await _player.setLoopMode(loopMode);
  }
}
