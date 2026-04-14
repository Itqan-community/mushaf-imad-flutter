import 'package:imad_flutter/src/data/audio/mushaf_audio_data_source.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_api_client.dart';
import 'package:imad_flutter/src/domain/models/audio_source.dart';
import 'package:imad_flutter/src/domain/models/recitation.dart';
import 'package:imad_flutter/src/domain/models/reciter.dart';
import 'package:imad_flutter/src/domain/models/riwayah.dart';
import 'package:imad_flutter/src/domain/models/reciter_timing.dart';

/// Implementation of [MushafAudioDataSource] that uses Quran.com API.
class QurancomDataSource implements MushafAudioDataSource {
  final QuranComApiClient _apiClient;

  /// Cache for recitation information.
  List<Recitation>? _recitationsCache;

  /// Cache for verse timings.
  final Map<String, List<AyahTiming>> _timingCache = {};

  QurancomDataSource({required QuranComApiClient apiClient})
    : _apiClient = apiClient;

  /// Fetches all available recitations from the Quran.com API.
  ///
  /// [language] The language to fetch recitations in. Defaults to 'ar'.
  ///
  /// Returns a [List<Recitation>] object containing the recitation details.
  @override
  Future<List<Recitation>> fetchAllRecitations({String? language}) async {
    if (_recitationsCache != null) return _recitationsCache!;

    // 1. Fetch from API explicitly requesting Arabic for translations
    final dtos = await _apiClient.fetchReciters(language: 'ar');
    // 2. Map DTO -> Domain Model right here in the Data Source
    _recitationsCache = dtos.map((dto) {
      final nameArabic = dto.translatedName?.name ?? dto.reciterName;
      return Recitation(
        id: dto.id,
        reciter: Reciter(
          id: dto.id,
          nameArabic: nameArabic,
          nameEnglish: dto.reciterName,
        ),
        riwayah: Riwayah(
          id: dto.id,
          nameArabic: dto.style ?? 'مجهول',
          nameEnglish: dto.style ?? 'Unknown',
        ),
        audioSource: MushafAudioSource.quranCom,
        folderUrl: '', // API source builds URLs dynamically
      );
    }).toList();
    return _recitationsCache!;
  }

  /// Fetches the audio URL for a specific chapter by recitation ID and chapter number.
  ///
  /// [recitationId] The ID of the recitation.
  /// [chapterNumber] The number of the chapter.
  ///
  /// Returns a [String] object containing the audio URL.
  @override
  Future<String> fetchChapterAudioUrl(int recitationId, int chapterNumber) async {
    final audioFile = await _apiClient.fetchChapterAudio(
      reciterId: recitationId,
      chapterNumber: chapterNumber,
      segments: true,
    );

    // Cache the timestamps for later use
    if (audioFile.timestamps != null) {
      _timingCache['$recitationId-$chapterNumber'] = audioFile.timestamps!;
    }

    return audioFile.audioUrl;
  }

  /// Fetches the verse timings for a specific chapter by recitation ID and chapter number.
  ///
  /// [recitationId] The ID of the recitation.
  /// [chapterNumber] The number of the chapter.
  ///
  /// Returns a [List<AyahTiming>] object containing the verse timings.
  @override
  Future<List<AyahTiming>?> fetchChapterTiming(
    int recitationId,
    int chapterNumber,
  ) async {
    final key = '$recitationId-$chapterNumber';

    // Check cache first
    final cached = _timingCache[key];
    if (cached != null) return cached;

    // If not, fetch from API
    await fetchChapterAudioUrl(recitationId, chapterNumber);

    return _timingCache[key];
  }
}
