import '../../../domain/models/audio_source.dart';
import '../../../domain/models/reciter_info.dart';

/// Common interface for any class that can supply a list of Quran reciters
/// from a specific audio backend.
///
/// Each concrete implementation corresponds to one [MushafAudioSource] and is
/// responsible for tagging every returned [ReciterInfo] with the correct
/// [ReciterInfo.audioSource] value so the composite layer can route playback
/// requests correctly.
///
/// Implementations:
/// - `Mp3QuranReciterProvider` ([MushafAudioSource.mp3quran])
/// - `QuranComReciterProvider`  ([MushafAudioSource.quranCom])
/// - `ItqanReciterProvider`    ([MushafAudioSource.itqan])
abstract class AudioReciterProvider {
  /// The source this provider supplies reciters for.
  MushafAudioSource get source;

  /// Returns all reciters available from this source.
  Future<List<ReciterInfo>> getAllReciters();

  /// Returns the reciter matching [reciterId], or `null` if not found.
  Future<ReciterInfo?> getReciterById(int reciterId);

  /// Searches reciters by partial name match.
  ///
  /// [languageCode] can be `'ar'` or `'en'`.
  Future<List<ReciterInfo>> searchReciters(
    String query, {
    String languageCode = 'en',
  });

  /// Returns all reciters that use the Hafs recitation style.
  Future<List<ReciterInfo>> getHafsReciters();

  /// Returns a sensible default reciter for this source.
  Future<ReciterInfo> getDefaultReciter();
}
