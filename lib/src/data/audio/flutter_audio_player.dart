import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../domain/models/audio_player_state.dart' as domain;
import '../../domain/models/reciter_info.dart';

class FlutterAudioPlayer extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  int? _currentChapter;
  int? _currentReciterId;

  // يمكن مستقبلاً نقل هذا الرابط لملف إعدادات (Config) كما اقترح البوت
  static const String _webProxyUrl = 'https://corsproxy.io/?';

  final _domainStateController =
      StreamController<domain.AudioPlayerState>.broadcast();

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
    _player.playbackEventStream.listen((event) {
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

  /// تحميل السورة مع دعم البدء من آية محددة
  Future<void> loadChapter(
    int chapterNumber,
    ReciterInfo reciter, {
    bool autoPlay = false,
    int? startAyahNumber,
  }) async {
    _currentChapter = chapterNumber;
    _currentReciterId = reciter.id;

    AudioSource source;

    // ✅ إضافة الحماية (Validation) التي طلبها البوت
    if (startAyahNumber != null && startAyahNumber > 1) {
      final verseCount = reciter.getChapterVerseCount(chapterNumber);
      
      // إذا كان رقم الآية أكبر من عدد آيات السورة، ابدأ من السورة كاملة
      if (startAyahNumber > verseCount) {
        final url = reciter.getAudioUrl(chapterNumber);
        source = AudioSource.uri(Uri.parse(_resolveFinalUrl(url)));
      } else {
        final children = <AudioSource>[];
        for (int ayah = startAyahNumber; ayah <= verseCount; ayah++) {
          final url = reciter.getAyahUrl(
            chapterNumber: chapterNumber,
            ayahNumber: ayah,
          );
          children.add(AudioSource.uri(Uri.parse(_resolveFinalUrl(url))));
        }
        source = ConcatenatingAudioSource(children: children);
      }
    } else {
      final url = reciter.getAudioUrl(chapterNumber);
      source = AudioSource.uri(Uri.parse(_resolveFinalUrl(url)));
    }

    try {
      await _player.setAudioSource(source);
      if (autoPlay) {
        await play();
      }
    } catch (e) {
      _broadcastDomainState(error: e.toString());
    }
  }

  /// ✅ إضافة الدالة المفقودة التي سببت الخطأ الحرج في الـ Repository
  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  void setRepeatModeBool(bool enabled) {
    _player.setLoopMode(enabled ? LoopMode.all : LoopMode.off);
  }

  bool isRepeatMode() => _player.loopMode != LoopMode.off;

  @override
  Future<void> play() => _player.play();

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
