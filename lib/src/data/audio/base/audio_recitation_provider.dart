import '../../../domain/models/audio_source.dart';
import '../../../domain/models/recitation.dart';

/// Base interface for fetching recitations from a specific backend source.
abstract class AudioRecitationProvider {
  /// The source type this provider handles.
  MushafAudioSource get source;

  /// Returns all available recitations from this source.
  Future<List<Recitation>> getAllRecitations();

  /// Gets a specific recitation by its ID from this source.
  Future<Recitation?> getRecitationById(int recitationId);

  /// Searches recitations by name.
  Future<List<Recitation>> searchRecitations(
    String query, {
    String languageCode = 'ar',
  });

  /// Returns a sensible default recitation for this source.
  Future<Recitation> getDefaultRecitation();
}
