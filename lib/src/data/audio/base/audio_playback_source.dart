import '../../../domain/models/audio_source.dart';
import '../../../domain/models/reciter_timing.dart';

/// Common interface for any class that performs audio-data fetching and
/// verse-timing queries for a specific backend source.
///
/// The [CompositeAudioRepository] holds one [AudioPlaybackSource] per enabled
/// [MushafAudioSource] and dispatches `loadChapter` and timing calls to
/// whichever source owns the currently selected reciter.
///
/// Implementations:
/// - `Mp3QuranPlaybackSource` ([MushafAudioSource.mp3quran])
/// - `QuranComPlaybackSource` ([MushafAudioSource.quranCom])
/// - `ItqanPlaybackSource`    ([MushafAudioSource.itqan])
abstract class AudioPlaybackSource {
  /// The source this playback provider handles.
  MushafAudioSource get source;

  /// Loads (and optionally begins auto-playing) the specified chapter.
  ///
  /// [chapterNumber] 1-114
  /// [recitationId] The internal ID of the recitation in this specific source backend.
  /// [autoPlay] Immediately start playback after loading.
  /// [startVerseNumber] Seek to this verse upon loading.
  Future<void> loadChapter(
    int chapterNumber,
    int recitationId, {
    bool autoPlay = false,
    int startVerseNumber = 1,
  });

  /// Returns all ayah timings for the given chapter from this source.
  Future<List<AyahTiming>> getChapterTimings(int recitationId, int chapterNumber);

  /// Returns the timing for a single ayah, or `null` if unavailable.
  Future<AyahTiming?> getAyahTiming(
    int recitationId,
    int chapterNumber,
    int ayahNumber,
  );

  /// Returns the ayah number currently playing at [currentTimeMs], or `null`.
  Future<int?> getCurrentVerse(
    int recitationId,
    int chapterNumber,
    int currentTimeMs,
  );

  /// Returns `true` if timing data is available for [recitationId].
  bool hasTimingForRecitation(int recitationId);

  /// Optionally pre-fetches timing data for [recitationId] to avoid latency
  /// at playback time.
  Future<void> preloadTiming(int recitationId);
}
