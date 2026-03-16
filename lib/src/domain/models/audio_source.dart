/// Selects the audio source backend the library uses for recitation playback.
///
/// Pass this value to `setupMushafDependencies` (or the equivalent init call)
/// so the DI container wires the correct [AudioRepository] implementation.
///
/// ## Values
/// - [local] – bundled MP3 assets shipped with the app (original behaviour).
/// - [quranCom] – high-quality MP3 streams from the Quran.Foundation API
///   with verse-level timing data. Requires [QuranComApiConfig] credentials.
///
/// ## Example
/// ```dart
/// await setupMushafDependencies(
///   audioSource: MushafAudioSource.quranCom,
///   quranComConfig: QuranComApiConfig(
///     clientId: 'YOUR_CLIENT_ID',
///     clientSecret: 'YOUR_CLIENT_SECRET',
///   ),
///   ...
/// );
/// ```
enum MushafAudioSource {
  /// Use bundled local MP3/timing assets (default, no network required).
  local,

  /// Use the Quran.Foundation (Quran.com) streaming API.
  ///
  /// Requires a valid [QuranComApiConfig] to be supplied at initialization.
  quranCom,
}
