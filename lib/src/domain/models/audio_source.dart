/// Identifies an audio source backend the library can use for recitation playback.
///
/// Pass one or more values to `setupMushafDependencies` via the `audioSources`
/// parameter. When multiple sources are enabled the library merges their reciter
/// lists and routes each playback request to the correct source automatically.
///
/// ## Values
/// - [mp3quran] – static MP3 files served from mp3quran.net (default, no
///   credentials required).
/// - [quranCom] – high-quality MP3 streams from the Quran.Foundation API
///   with verse-level timing data. Requires [QuranComAudioSourceConfig].
/// - [itqan] – audio and timing data from the Itqan CMS API.
///   Requires [ItqanAudioConfig].
///
/// ## Example -- single source
/// ```dart
/// await MushafLibrary.initialize(
///   audioSources: {MushafAudioSource.mp3quran},
/// );
/// ```
///
/// ## Example -- multiple sources
/// ```dart
/// await MushafLibrary.initialize(
///   audioSources: {MushafAudioSource.mp3quran, MushafAudioSource.quranCom},
///   quranComConfig: QuranComAudioSourceConfig(
///     clientId: 'YOUR_CLIENT_ID',
///     clientSecret: 'YOUR_CLIENT_SECRET',
///   ),
/// );
/// ```
enum MushafAudioSource {
  /// Static MP3 files from mp3quran.net bundled with pre-computed timing JSON.
  ///
  /// Requires no credentials. This is the default source.
  mp3quran,

  /// Streaming MP3 from the Quran.Foundation (Quran.com) API with
  /// verse-level timing. Requires [QuranComAudioSourceConfig] credentials.
  quranCom,

  /// Audio and verse timing from the Itqan CMS API.
  /// Requires [ItqanAudioConfig].
  itqan,
}
