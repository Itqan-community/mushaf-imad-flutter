import '../models/audio_player_state.dart';
import '../models/reciter_info.dart';
import '../models/reciter_timing.dart';

/// Repository for Quran audio playback and reciter management.
/// Public API - exposed to library consumers.
abstract class AudioRepository {
  /// Get all available reciters.
  Future<List<ReciterInfo>> getAllReciters();

  /// Get reciter by ID.
  Future<ReciterInfo?> getReciterById(int reciterId);

  /// Search reciters by name.
  Future<List<ReciterInfo>> searchReciters(
    String query, {
    String languageCode = 'en',
  });

  /// Get all Hafs reciters.
  Future<List<ReciterInfo>> getHafsReciters();

  /// Get default reciter.
  Future<ReciterInfo> getDefaultReciter();

  /// Select a reciter and save the preference.
  void saveSelectedReciter(ReciterInfo reciter);

  /// Observe the selected reciter.
  Stream<ReciterInfo?> getSelectedReciterStream();

  /// Observe audio player state.
  Stream<AudioPlayerState> getPlayerStateStream();

  /// Load and optionally play a chapter.
  void loadChapter(int chapterNumber, int reciterId, {bool autoPlay = false});

  /// Start or resume playback.
  void play();

  /// Pause playback.
  void pause();

  /// Stop playback.
  void stop();

  /// Seek to specific position in milliseconds.
  void seekTo(int positionMs);

  /// Set playback speed (0.5 = half speed, 1.0 = normal, 2.0 = double speed).
  void setPlaybackSpeed(double speed);

  /// Set repeat mode.
  void setRepeatMode(bool enabled);

  /// Get current repeat mode.
  bool isRepeatEnabled();

  /// Get current playback position in milliseconds.
  int getCurrentPosition();

  /// Get total duration in milliseconds.
  int getDuration();

  /// Check if player is currently playing.
  bool isCurrentlyPlaying();

  /// Get timing for a specific ayah.
  Future<AyahTiming?> getAyahTiming(
    int reciterId,
    int chapterNumber,
    int ayahNumber,
  );

  /// Get the current verse being recited based on playback position.
  Future<int?> getCurrentVerse(
    int reciterId,
    int chapterNumber,
    int currentTimeMs,
  );

  /// Get all timing data for a chapter.
  Future<List<AyahTiming>> getChapterTimings(int reciterId, int chapterNumber);

  /// Check if timing data is available for a reciter.
  bool hasTimingForReciter(int reciterId);

  /// Preload timing data for better performance.
  Future<void> preloadTiming(int reciterId);

  /// Release player resources.
  void release();
}
