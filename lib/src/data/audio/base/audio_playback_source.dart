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

  /// Resolves audio and loads it into the shared player, then optionally seeks
  /// to [startVerseNumber] before beginning playback if [autoPlay] is true.
  Future<void> loadChapter(
    int chapterNumber,
    int reciterId, {
    bool autoPlay = false,
    int startVerseNumber = 1,
  });

  /// Returns all ayah timings for the given chapter from this source.
  Future<List<AyahTiming>> getChapterTimings(int reciterId, int chapterNumber);

  /// Returns the timing for a single ayah, or `null` if unavailable.
  Future<AyahTiming?> getAyahTiming(
    int reciterId,
    int chapterNumber,
    int ayahNumber,
  );

  /// Returns the ayah number currently playing at [currentTimeMs], or `null`.
  Future<int?> getCurrentVerse(
    int reciterId,
    int chapterNumber,
    int currentTimeMs,
  );

  /// Returns `true` if timing data is available for [reciterId].
  bool hasTimingForReciter(int reciterId);

  /// Optionally pre-fetches timing data for [reciterId] to avoid latency
  /// at playback time.
  Future<void> preloadTiming(int reciterId);
}
