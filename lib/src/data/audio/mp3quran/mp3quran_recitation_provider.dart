import '../../../domain/models/audio_source.dart';
import '../../../domain/models/recitation.dart';
import '../base/audio_recitation_provider.dart';
import '../recitation_data_provider.dart';

/// Provider for mp3quran.net static assets.
class Mp3QuranRecitationProvider implements AudioRecitationProvider {
  @override
  MushafAudioSource get source => MushafAudioSource.mp3quran;

  @override
  Future<List<Recitation>> getAllRecitations() async =>
      RecitationDataProvider.getAllRecitationsAsync();

  @override
  Future<Recitation?> getRecitationById(int recitationId) async =>
      RecitationDataProvider.getRecitationByIdAsync(recitationId);

  @override
  Future<List<Recitation>> searchRecitations(
    String query, {
    String languageCode = 'ar',
  }) async => RecitationDataProvider.searchRecitationsAsync(
    query,
    languageCode: languageCode,
  );

  @override
  Future<Recitation> getDefaultRecitation() async =>
      RecitationDataProvider.getDefaultRecitationAsync();
}
