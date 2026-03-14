import 'package:flutter_test/flutter_test.dart';
import 'package:imad_flutter/src/data/audio/ayah_timing_service.dart';
import 'package:imad_flutter/src/data/audio/mushaf_audio_data_source.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_verse_timing.dart';
import 'package:mocktail/mocktail.dart';

class MockMushafAudioDataSource extends Mock implements MushafAudioDataSource {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AyahTimingService timingService;
  late MockMushafAudioDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockMushafAudioDataSource();
    timingService = AyahTimingService(dataSource: mockDataSource);
  });

  group('AyahTimingService', () {
    test('getChapterTimings returns empty list if both asset and API fail', () async {
      // Arrange
      const reciterId = 999;
      const chapterNumber = 1;
      when(() => mockDataSource.fetchChapterTiming(reciterId, chapterNumber))
          .thenAnswer((_) async => null);

      // Act
      final timings = await timingService.getChapterTimings(reciterId, chapterNumber);

      // Assert
      expect(timings, isEmpty);
      verify(() => mockDataSource.fetchChapterTiming(reciterId, chapterNumber)).called(1);
    });

    test('getChapterTimings falls back to API and caches result dynamically when asset is missing', () async {
      // Arrange
      const reciterId = 888;
      const chapterNumber = 2;
      final mockApiResult = [
        QuranComVerseTiming(verseKey: '2:1', timestampFrom: 0, timestampTo: 5000, duration: 5000),
        QuranComVerseTiming(verseKey: '2:2', timestampFrom: 5000, timestampTo: 10000, duration: 5000),
      ];

      when(() => mockDataSource.fetchChapterTiming(reciterId, chapterNumber))
          .thenAnswer((_) async => mockApiResult);

      // Act - First Call (should hit API)
      final timings1 = await timingService.getChapterTimings(reciterId, chapterNumber);

      // Assert - First Call
      expect(timings1.length, 2);
      expect(timings1.first.ayah, 1);
      expect(timings1.first.startTime, 0);
      expect(timings1.first.endTime, 5000);
      verify(() => mockDataSource.fetchChapterTiming(reciterId, chapterNumber)).called(1);

      // Act - Second Call (should hit dynamic cache)
      final timings2 = await timingService.getChapterTimings(reciterId, chapterNumber);

      // Assert - Second Call
      expect(timings2.length, 2);
      // Verify API was NOT called again
      verifyNever(() => mockDataSource.fetchChapterTiming(reciterId, chapterNumber));
    });

    test('getAyahTiming returns null when fetching timing fails', () async {
      // Arrange
      when(() => mockDataSource.fetchChapterTiming(any(), any()))
          .thenAnswer((_) async => null);

      // Act
      final timing = await timingService.getAyahTiming(999, 1, 1);

      // Assert
      expect(timing, isNull);
    });

    test('getAyahTiming returns specific verse from dynamically cached timings', () async {
      // Arrange
      const reciterId = 777;
      const chapterNumber = 114;
      final mockApiResult = [
        QuranComVerseTiming(verseKey: '114:1', timestampFrom: 0, timestampTo: 2000, duration: 2000),
        QuranComVerseTiming(verseKey: '114:2', timestampFrom: 2000, timestampTo: 4000, duration: 2000),
      ];
      when(() => mockDataSource.fetchChapterTiming(reciterId, chapterNumber))
          .thenAnswer((_) async => mockApiResult);

      // Act
      final timing = await timingService.getAyahTiming(reciterId, chapterNumber, 2);

      // Assert
      expect(timing, isNotNull);
      expect(timing!.ayah, 2);
      expect(timing.startTime, 2000);
      expect(timing.endTime, 4000);
    });

    test('getCurrentVerse returns correct verse based on playback time', () async {
      // Arrange
      const reciterId = 666;
      const chapterNumber = 1;
      final mockApiResult = [
        QuranComVerseTiming(verseKey: '1:1', timestampFrom: 0, timestampTo: 5000, duration: 5000), // ms 0 -> 5000
        QuranComVerseTiming(verseKey: '1:2', timestampFrom: 5000, timestampTo: 10000, duration: 5000), // ms 5000 -> 10000
      ];
      when(() => mockDataSource.fetchChapterTiming(reciterId, chapterNumber))
          .thenAnswer((_) async => mockApiResult);

      // Act
      final verseNull = await timingService.getCurrentVerse(reciterId, chapterNumber, -50);
      final verse1 = await timingService.getCurrentVerse(reciterId, chapterNumber, 2500);
      final verse2 = await timingService.getCurrentVerse(reciterId, chapterNumber, 5000);
      final verseEnd = await timingService.getCurrentVerse(reciterId, chapterNumber, 15000);

      // Assert
      expect(verseNull, isNull);
      expect(verse1, 1);
      expect(verse2, 2);
      expect(verseEnd, isNull);
    });

    test('getChapterTimings reads from local assets if available and does NOT call API', () async {
      // Arrange - Reciter 1 has local assets in the project (from legacy bulk timing files).
      const reciterId = 1; 
      const chapterNumber = 1;

      // Act
      final timings = await timingService.getChapterTimings(reciterId, chapterNumber);

      // Assert
      expect(timings, isNotEmpty, reason: 'Should load from local assets');
      verifyNever(() => mockDataSource.fetchChapterTiming(any(), any()));
    });

    test('getChapterTimings handles dataSource throwing an exception gracefully', () async {
      // Arrange
      const reciterId = 555;
      const chapterNumber = 1;
      when(() => mockDataSource.fetchChapterTiming(reciterId, chapterNumber))
          .thenThrow(Exception('API Error 400'));

      // Act
      final timings = await timingService.getChapterTimings(reciterId, chapterNumber);

      // Assert
      expect(timings, isEmpty, reason: 'Should catch exception and return empty list');
      verify(() => mockDataSource.fetchChapterTiming(reciterId, chapterNumber)).called(1);
    });

    test('getChapterTimings returns empty list if no asset exists and no dataSource is provided', () async {
      // Arrange
      final serviceNoApi = AyahTimingService(dataSource: null); 

      // Act
      final timings = await serviceNoApi.getChapterTimings(999, 1);

      // Assert
      expect(timings, isEmpty);
    });

    test('getAyahTiming returns null for non-existent verse', () async {
      // Arrange
      const reciterId = 444;
      const chapterNumber = 114;
      final mockApiResult = [
        QuranComVerseTiming(verseKey: '114:1', timestampFrom: 0, timestampTo: 2000, duration: 2000),
      ];
      when(() => mockDataSource.fetchChapterTiming(reciterId, chapterNumber))
          .thenAnswer((_) async => mockApiResult);

      // Act
      final timing = await timingService.getAyahTiming(reciterId, chapterNumber, 99); // Verse 99 does not exist

      // Assert
      expect(timing, isNull);
    });
  });
}
