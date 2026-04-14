import '../models/audio_player_state.dart';
import '../models/recitation.dart';
import '../models/reciter_timing.dart';

/// Repository for Quran audio playback and recitation management.
/// Public API - exposed to library consumers.
abstract class AudioRepository {
  /// Get all available recitations across combined sources.
  Future<List<Recitation>> getAllRecitations();

  /// Get recitation by combined ID.
  Future<Recitation?> getRecitationById(int recitationId);

  /// Search recitations by name.
  Future<List<Recitation>> searchRecitations(
    String query, {
    String languageCode = 'ar',
  });

  /// Get default recitation.
  Future<Recitation> getDefaultRecitation();

  /// Select a recitation and save the preference.
  void saveSelectedRecitation(Recitation recitation);

  /// Observe the selected recitation.
  Stream<Recitation?> getSelectedRecitationStream();

  /// Observe audio player state.
  Stream<AudioPlayerState> getPlayerStateStream();

  /// Load and optionally play a chapter.
  Future<void> loadChapter(
    int chapterNumber,
    int recitationId, {
    bool autoPlay = false,
    int startVerseNumber = 1,
  });

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
    int recitationId,
    int chapterNumber,
    int ayahNumber,
  );

  /// Get the current verse being recited based on playback position.
  Future<int?> getCurrentVerse(
    int recitationId,
    int chapterNumber,
    int currentTimeMs,
  );

  /// Get all timing data for a chapter.
  Future<List<AyahTiming>> getChapterTimings(int recitationId, int chapterNumber);

  /// Check if timing data is available for a recitation.
  bool hasTimingForRecitation(int recitationId);

  /// Preload timing data for better performance.
  Future<void> preloadTiming(int recitationId);

  /// Release player resources.
  void release();
}
