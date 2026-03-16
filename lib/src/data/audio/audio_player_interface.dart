import 'dart:async';
import '../../domain/models/audio_player_state.dart';
import '../../domain/models/reciter_info.dart';

/// Abstraction over the audio player, enabling testability.
abstract class AudioPlayerInterface {
  Stream<AudioPlayerState> get domainStateStream;

  Future<void> loadChapter(
    int chapterNumber,
    ReciterInfo reciter, {
    bool autoPlay = false,
  });

  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setSpeed(double speed);
  Future<void> setRepeatModeBool(bool enabled);
  bool isRepeatMode();
}
