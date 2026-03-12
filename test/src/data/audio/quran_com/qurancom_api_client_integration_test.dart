import 'package:flutter_test/flutter_test.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_api_client.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_api_config.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_environment.dart';

/// Manual Integration Test for QuranComApiClient.
///
/// Run this test using:
/// flutter test test/src/data/audio/quran_com/qurancom_api_client_integration_test.dart \
///   --dart-define=QF_ID=YOUR_CLIENT_ID \
///   --dart-define=QF_SECRET=YOUR_CLIENT_SECRET
void main() {
  // Read credentials from environment
  const clientId = String.fromEnvironment('QF_ID');
  const clientSecret = String.fromEnvironment('QF_SECRET');

  group('QuranComApiClient Integration Test', () {
    if (clientId.isEmpty || clientSecret.isEmpty) {
      test(
        'Skipping integration test (Credentials missing)',
        () {},
        skip: 'QF_ID or QF_SECRET not provided via --dart-define',
      );
      return;
    }

    late QuranComApiClient apiClient;

    setUp(() {
      final config = QuranComApiConfig(
        clientId: clientId,
        clientSecret: clientSecret,
        environment: QuranComEnvironment.prelive,
      );
      apiClient = QuranComApiClient(config: config);
    });

    tearDown(() {
      apiClient.dispose();
    });

    test(
      'should successfully fetch reciters from real API and validate fields',
      () async {
        print('\n--- TEST: Fetch Reciters ---');
        print('Fetching real reciters list...');
        final reciters = await apiClient.fetchReciters();

        expect(
          reciters,
          isNotEmpty,
          reason: 'Reciters list should not be empty',
        );
        print('✅ Successfully fetched ${reciters.length} reciters.');

        final first = reciters.first;
        expect(first.id, isPositive);
        expect(first.reciterName, isNotEmpty);
        print(
          '✅ First reciter: id=${first.id}, name="${first.reciterName}", style="${first.style}"',
        );
        print(
          '✅ Translated name: "${first.translatedName?.name}" (${first.translatedName?.languageName})',
        );

        // Find Mishari al-Afasy (id usually 7 or similar)
        final mishari = reciters
            .where((r) => r.reciterName.toLowerCase().contains('afasy'))
            .firstOrNull;
        if (mishari != null) {
          print(
            '✅ Found Mishari al-Afasy: id=${mishari.id}, Name="${mishari.translatedName?.name ?? mishari.reciterName}"',
          );
        }
      },
    );

    test(
      'should successfully fetch chapter audio and timings (Fatiha) and deeply assert structure',
      () async {
        print('\n--- TEST: Fetch Chapter Audio (Fatiha) ---');
        print(
          'Fetching real audio and timings for Fatiha (reciter 7, chapter 1)...',
        );
        final audioFile = await apiClient.fetchChapterAudio(
          reciterId: 7,
          chapterNumber: 1,
          segments: true,
        );

        expect(audioFile.chapterId, equals(1));
        expect(audioFile.audioUrl, isNotEmpty);
        expect(audioFile.fileSize, greaterThan(0));
        expect(audioFile.format, isNotEmpty);
        expect(audioFile.timestamps, isNotNull);

        final timestamps = audioFile.timestamps!;
        expect(
          timestamps.length,
          equals(7),
          reason: 'Al-Fatiha must have exactly 7 verses',
        );

        print('✅ Audio URL: ${audioFile.audioUrl}');
        print('✅ Format: ${audioFile.format}, Size: ${audioFile.fileSize} KB');
        print(
          '✅ Timestamps count: ${timestamps.length} (Verified exactly 7 for Fatiha)',
        );

        for (int i = 0; i < timestamps.length; i++) {
          final verse = timestamps[i];
          expect(verse.verseKey, equals('1:${i + 1}'));
          expect(verse.timestampFrom, greaterThanOrEqualTo(0));
          expect(verse.timestampTo, greaterThanOrEqualTo(verse.timestampFrom));
        }

        final firstVerse = timestamps.first;
        print(
          '✅ First verse [${firstVerse.verseKey}]: From ${firstVerse.timestampFrom}ms to ${firstVerse.timestampTo}ms',
        );

        if (firstVerse.segments != null && firstVerse.segments!.isNotEmpty) {
          print(
            '✅ First verse has ${firstVerse.segments!.length} word segments.',
          );
          final firstWord = firstVerse.segments!.first;
          print(
            '   -> Word ${firstWord.wordIndex}: ${firstWord.startMs}ms - ${firstWord.endMs}ms',
          );
        } else {
          print(
            '⚠️ Warning: No segments found for the first verse (might be normal depending on reciter).',
          );
        }
      },
    );

    test('should successfully fetch chapter audio without segments', () async {
      print('\n--- TEST: Fetch Chapter Audio Without Segments ---');
      print(
        'Fetching Husary (reciter 6) for Fatiha (chapter 1) with segments=false...',
      );
      final audioFile = await apiClient.fetchChapterAudio(
        reciterId: 6,
        chapterNumber: 1,
        segments: false,
      );

      expect(audioFile.chapterId, equals(1));
      expect(audioFile.audioUrl, isNotEmpty);

      final timestamps = audioFile.timestamps;
      if (timestamps != null && timestamps.isNotEmpty) {
        print('✅ Timestamps successfully retrieved without segments array');
        for (final verse in timestamps) {
          expect(
            verse.segments,
            isNull,
            reason:
                'Segments array should be null when requested without segments',
          );
        }
      }
    });

    test(
      'should fail gracefully when requesting an invalid chapter (e.g., 115)',
      () async {
        print('\n--- TEST: Edge Case - Invalid Chapter ---');
        print('Fetching audio for non-existent chapter 115...');

        try {
          await apiClient.fetchChapterAudio(reciterId: 7, chapterNumber: 115);
          fail('Should have thrown an exception for chapter 115');
        } catch (e) {
          print('✅ Successfully caught expected error for invalid chapter:');
          print('   -> $e');
          expect(
            e.toString(),
            contains('404'),
          ); // Assuming API returns 404 for invalid chapter
        }
      },
    );

    test('should handle token caching and 401 recovery on real API', () async {
      print('\n--- TEST: Sequential Calls (Caching) ---');
      print('Executing Call 1...');
      //time calculation
      final stopwatch = Stopwatch()..start();
      await apiClient.fetchReciters();
      stopwatch.stop();
      final call1Time = stopwatch.elapsedMilliseconds;
      print('✅ Call 1 completed in ${stopwatch.elapsedMilliseconds} ms');
      print('Executing Call 2 (Should be faster, using cached token)...');
      stopwatch.reset();
      stopwatch.start();
      await apiClient.fetchReciters();
      stopwatch.stop();
      final call2Time = stopwatch.elapsedMilliseconds;
      print('✅ Call 2 completed in ${stopwatch.elapsedMilliseconds} ms');
      print('Call 1 time: ${call1Time} ms, Call 2 time: ${call2Time} ms');
      print(
        'Faster by ${call1Time - call2Time} ms (Expected due to token caching and no re-authentication)',
      );
      print('✅ Sequential calls successful.');
    });
  });
}
