import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_api_client.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_data_source.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_reciter.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_chapter_audio.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_verse_timing.dart';

class MockQuranComApiClient extends Mock implements QuranComApiClient {}

void main() {
  late QurancomDataSource dataSource;
  late MockQuranComApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockQuranComApiClient();
    dataSource = QurancomDataSource(apiClient: mockApiClient);
  });

  group('QurancomDataSource', () {
    test('fetchAllReciters should fetch and map reciters with caching', () async {
      final mockReciters = [
        QuranComReciter(
          id: 1,
          reciterName: 'Reciter 1',
          style: 'Murattal',
          translatedName: QuranComTranslatedName(name: 'القارئ 1', languageName: 'arabic'),
        ),
      ];

      when(() => mockApiClient.fetchReciters(language: 'ar'))
          .thenAnswer((_) async => mockReciters);

      // First call - should trigger API
      final result1 = await dataSource.fetchAllReciters();
      
      expect(result1.length, 1);
      expect(result1.first.id, 1);
      expect(result1.first.nameEnglish, 'Reciter 1');
      expect(result1.first.nameArabic, 'القارئ 1');
      expect(result1.first.rewaya, 'Murattal');
      expect(result1.first.folderUrl, '');

      // Second call - should be cached
      final result2 = await dataSource.fetchAllReciters();
      expect(result2, result1);
      verify(() => mockApiClient.fetchReciters(language: 'ar')).called(1);
    });

    test('fetchChapterAudioUrl should fetch audio and eager-cache timings', () async {
      final mockAudioFile = QuranComAudioFile(
        id: 1,
        chapterId: 1,
        fileSize: 100,
        format: 'mp3',
        audioUrl: 'https://example.com/audio.mp3',
        timestamps: [
          QuranComVerseTiming(
            verseKey: '1:1',
            timestampFrom: 0,
            timestampTo: 1000,
            duration: 1000,
          ),
        ],
      );

      when(() => mockApiClient.fetchChapterAudio(
            reciterId: 1,
            chapterNumber: 1,
            segments: true,
          )).thenAnswer((_) async => mockAudioFile);

      // Fetch URL
      final url = await dataSource.fetchChapterAudioUrl(1, 1);

      expect(url, 'https://example.com/audio.mp3');
      
      // Verify that calling fetchChapterTiming immediately returns from cache
      final timings = await dataSource.fetchChapterTiming(1, 1);
      expect(timings?.length, 1);
      expect(timings?.first.verseKey, '1:1');
      
      // Verify API was ONLY called once total for both operations
      verify(() => mockApiClient.fetchChapterAudio(
            reciterId: 1,
            chapterNumber: 1,
            segments: true,
          )).called(1);
    });

    test('fetchChapterTiming should fetch via fetchChapterAudioUrl if cache miss', () async {
       final mockAudioFile = QuranComAudioFile(
        id: 1,
        chapterId: 1,
        fileSize: 100,
        format: 'mp3',
        audioUrl: 'https://example.com/audio.mp3',
        timestamps: [
          QuranComVerseTiming(
            verseKey: '1:1',
            timestampFrom: 0,
            timestampTo: 1000,
            duration: 1000,
          ),
        ],
      );

      when(() => mockApiClient.fetchChapterAudio(
            reciterId: 1,
            chapterNumber: 1,
            segments: true,
          )).thenAnswer((_) async => mockAudioFile);

      // Call timing directly (cache miss)
      final timings = await dataSource.fetchChapterTiming(1, 1);
      
      expect(timings?.length, 1);
      expect(timings?.first.verseKey, '1:1');
      
      // Verify it delegated correctly to API via fetchChapterAudioUrl
      verify(() => mockApiClient.fetchChapterAudio(
        reciterId: 1, 
        chapterNumber: 1, 
        segments: true,
      )).called(1);
    });

    test('fetchChapterTiming should handle null timestamps from API', () async {
       final mockAudioFile = QuranComAudioFile(
        id: 1,
        chapterId: 1,
        fileSize: 100,
        format: 'mp3',
        audioUrl: 'https://example.com/audio.mp3',
        timestamps: null,
      );

      when(() => mockApiClient.fetchChapterAudio(
            reciterId: 1,
            chapterNumber: 1,
            segments: true,
          )).thenAnswer((_) async => mockAudioFile);

      final timings = await dataSource.fetchChapterTiming(1, 1);
      
      expect(timings, isNull);
    });
  });
}
