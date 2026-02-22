/// Playback states for audio player.
enum PlaybackState { idle, loading, playing, paused, stopped, error }

/// Audio player state containing playback information.
class AudioPlayerState {
  final PlaybackState playbackState;
  final int currentPositionMs;
  final int durationMs;
  final int? currentChapter;
  final int? currentVerse;
  final int? currentReciterId;
  final bool isBuffering;
  final bool isRepeatEnabled;
  final String? errorMessage;

  const AudioPlayerState({
    this.playbackState = PlaybackState.idle,
    this.currentPositionMs = 0,
    this.durationMs = 0,
    this.currentChapter,
    this.currentVerse,
    this.currentReciterId,
    this.isBuffering = false,
    this.isRepeatEnabled = false,
    this.errorMessage,
  });

  double get progressPercentage {
    if (durationMs > 0) {
      return (currentPositionMs / durationMs) * 100.0;
    }
    return 0.0;
  }

  int get remainingTimeMs =>
      (durationMs - currentPositionMs).clamp(0, durationMs);

  bool get isPlaying => playbackState == PlaybackState.playing;

  AudioPlayerState copyWith({
    PlaybackState? playbackState,
    int? currentPositionMs,
    int? durationMs,
    int? currentChapter,
    int? currentVerse,
    int? currentReciterId,
    bool? isBuffering,
    bool? isRepeatEnabled,
    String? errorMessage,
  }) {
    return AudioPlayerState(
      playbackState: playbackState ?? this.playbackState,
      currentPositionMs: currentPositionMs ?? this.currentPositionMs,
      durationMs: durationMs ?? this.durationMs,
      currentChapter: currentChapter ?? this.currentChapter,
      currentVerse: currentVerse ?? this.currentVerse,
      currentReciterId: currentReciterId ?? this.currentReciterId,
      isBuffering: isBuffering ?? this.isBuffering,
      isRepeatEnabled: isRepeatEnabled ?? this.isRepeatEnabled,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
