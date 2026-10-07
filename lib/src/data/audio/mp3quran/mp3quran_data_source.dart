import '../../../domain/models/recitation.dart';
import '../../../domain/models/reciter_timing.dart';
import '../mushaf_audio_data_source.dart';
import '../recitation_data_provider.dart';
import 'mp3quran_api_client.dart';

/// Data source implementation for MP3Quran
class Mp3QuranDataSource implements MushafAudioDataSource {
  final Mp3QuranApiClient _apiClient;

  Mp3QuranDataSource({Mp3QuranApiClient? apiClient})
    : _apiClient = apiClient ?? Mp3QuranApiClient();

  @override
  Future<List<Recitation>> fetchAllRecitations() async {
    return _apiClient.fetchRecitations();
  }

  @override
  Future<String> fetchChapterAudioUrl(
    int recitationId,
    int chapterNumber,
  ) async {
    final recitation = await RecitationDataProvider.getRecitationByIdAsync(
      recitationId,
    );
    if (recitation != null) {
      return recitation.getAudioUrl(chapterNumber);
    }
    return '';
  }

  @override
  Future<List<AyahTiming>?> fetchChapterTiming(
    int recitationId,
    int chapterNumber,
  ) async {
    try {
      return await _apiClient.fetchChapterTiming(
        reciterId: recitationId,
        chapterNumber: chapterNumber,
      );
    } catch (e) {
      return null;
    }
  }
}
