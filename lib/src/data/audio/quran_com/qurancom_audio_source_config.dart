import 'package:imad_flutter/src/data/audio/quran_com/qurancom_api_config.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_environment.dart';

/// Caller-facing configuration for the Quran.com (Quran.Foundation) audio source.
///
/// Pass an instance of this class to `setupMushafDependencies` when using
/// [MushafAudioSource.quranCom] so the library can authenticate and stream
/// audio from the Quran.Foundation API.
///
/// ## Credentials
/// Obtain `clientId` and `clientSecret` from the Quran.Foundation developer
/// portal. **Never hard-code credentials in source code.** Instead, supply
/// them at runtime (e.g., via environment variables or a secure secrets store).
///
/// ## Example
/// ```dart
/// await setupMushafDependencies(
///   audioSource: MushafAudioSource.quranCom,
///   quranComConfig: QuranComAudioSourceConfig(
///     clientId: const String.fromEnvironment('QF_ID'),
///     clientSecret: const String.fromEnvironment('QF_SECRET'),
///   ),
///   ...
/// );
/// ```
class QuranComAudioSourceConfig {
  /// OAuth2 client ID issued by the Quran.Foundation developer portal.
  final String clientId;

  /// OAuth2 client secret issued by the Quran.Foundation developer portal.
  final String clientSecret;

  /// Which API environment to target.
  ///
  /// Defaults to [QuranComEnvironment.production] for release builds.
  /// Use [QuranComEnvironment.prelive] for development and testing.
  final QuranComEnvironment environment;

  const QuranComAudioSourceConfig({
    required this.clientId,
    required this.clientSecret,
    this.environment = QuranComEnvironment.production,
  });

  /// Derives a low-level [QuranComApiConfig] from this consumer-facing config.
  ///
  /// Used internally by the DI wiring so the rest of the library never needs
  /// to depend on this public-facing class directly.
  QuranComApiConfig toApiConfig() => QuranComApiConfig(
        clientId: clientId,
        clientSecret: clientSecret,
        environment: environment,
      );
}
