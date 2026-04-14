import '../../../domain/models/audio_source.dart';
import '../../../domain/models/reciter_info.dart';
import '../base/audio_reciter_provider.dart';
import '../reciter_data_provider.dart';

/// [AudioReciterProvider] implementation backed by the hardcoded mp3quran.net
/// reciter list in [ReciterDataProvider].
///
/// All returned [ReciterInfo] objects are tagged with [MushafAudioSource.mp3quran].
class Mp3QuranReciterProvider implements AudioReciterProvider {
  const Mp3QuranReciterProvider();

  @override
  MushafAudioSource get source => MushafAudioSource.mp3quran;

  @override
  Future<List<ReciterInfo>> getAllReciters() async =>
      ReciterDataProvider.allReciters;

  @override
  Future<ReciterInfo?> getReciterById(int reciterId) async =>
      ReciterDataProvider.getReciterById(reciterId);

  @override
  Future<List<ReciterInfo>> searchReciters(
    String query, {
    String languageCode = 'en',
  }) async =>
      ReciterDataProvider.searchReciters(query, languageCode: languageCode);

  @override
  Future<List<ReciterInfo>> getHafsReciters() async =>
      ReciterDataProvider.getHafsReciters();

  @override
  Future<ReciterInfo> getDefaultReciter() async =>
      ReciterDataProvider.getDefaultReciter();
}
