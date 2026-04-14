import 'package:imad_flutter/src/data/audio/mushaf_audio_data_source.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_api_client.dart';
import 'package:imad_flutter/src/domain/models/reciter_info.dart';
import 'package:imad_flutter/src/domain/models/reciter_timing.dart';

/// Implementation of [MushafAudioDataSource] that uses Quran.com API.
class QurancomDataSource implements MushafAudioDataSource {
  final QuranComApiClient _apiClient;

  /// Cache for reciter information.
  List<ReciterInfo>? _recitersCache;

  /// Cache for verse timings.
  final Map<String, List<AyahTiming>> _timingCache = {};

  QurancomDataSource({required QuranComApiClient apiClient})
    : _apiClient = apiClient;

  /// Fetches all available reciters from the Quran.com API.
  ///
  /// [language] The language to fetch reciters in. Defaults to 'ar'.
  ///
  /// Returns a [List<ReciterInfo>] object containing the reciter details.
  @override
  Future<List<ReciterInfo>> fetchAllReciters({String? language}) async {
    if (_recitersCache != null) return _recitersCache!;

    // 1. Fetch from API explicitly requesting Arabic for translations
    final dtos = await _apiClient.fetchReciters(language: 'ar');
    // 2. Map DTO -> Domain Model right here in the Data Source
    _recitersCache = dtos.map((dto) {
      return ReciterInfo(
        id: dto.id,
        nameEnglish: dto.reciterName,
        nameArabic:
            dto.translatedName?.name ?? dto.reciterName, // From 'ar' request
        folderUrl: '', // API source builds URLs dynamically
      );
    }).toList();
    return _recitersCache!;
  }

  /// Fetches the audio URL for a specific chapter by reciter ID and chapter number.
  ///
  /// [reciterId] The ID of the reciter.
  /// [chapterNumber] The number of the chapter.
  ///
  /// Returns a [String] object containing the audio URL.
  @override
  Future<String> fetchChapterAudioUrl(int reciterId, int chapterNumber) async {
    final audioFile = await _apiClient.fetchChapterAudio(
      reciterId: reciterId,
      chapterNumber: chapterNumber,
      segments: true,
    );

    // Cache the timestamps for later use
    if (audioFile.timestamps != null) {
      _timingCache['$reciterId-$chapterNumber'] = audioFile.timestamps!;
    }

    return audioFile.audioUrl;
  }

  /// Fetches the verse timings for a specific chapter by reciter ID and chapter number.
  ///
  /// [reciterId] The ID of the reciter.
  /// [chapterNumber] The number of the chapter.
  ///
  /// Returns a [List<AyahTiming>] object containing the verse timings.
  @override
  Future<List<AyahTiming>?> fetchChapterTiming(
    int reciterId,
    int chapterNumber,
  ) async {
    final key = '$reciterId-$chapterNumber';

    // Check cache first
    final cached = _timingCache[key];
    if (cached != null) return cached;

    // If not, fetch from API
    await fetchChapterAudioUrl(reciterId, chapterNumber);

    return _timingCache[key];
  }
}
