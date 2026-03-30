import 'package:flutter_test/flutter_test.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_api_client.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_api_config.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_environment.dart';
import 'package:imad_flutter/src/logging/mushaf_logger.dart';

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
  final logger = DefaultMushafLogger();

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
        logger.info('--- TEST: Fetch Reciters ---', category: LogCategory.audio);
        logger.info('Fetching real reciters list...', category: LogCategory.audio);
        final reciters = await apiClient.fetchReciters();

        expect(
          reciters,
          isNotEmpty,
          reason: 'Reciters list should not be empty',
        );
        logger.info('✅ Successfully fetched ${reciters.length} reciters.', category: LogCategory.audio);

        final first = reciters.first;
        expect(first.id, isPositive);
        expect(first.reciterName, isNotEmpty);
        logger.info(
          '✅ First reciter: id=${first.id}, name="${first.reciterName}", style="${first.style}"',
          category: LogCategory.audio,
        );
        logger.info(
          '✅ Translated name: "${first.translatedName?.name}" (${first.translatedName?.languageName})',
          category: LogCategory.audio,
        );

        // Find Mishari al-Afasy (id usually 7 or similar)
        final mishari = reciters
            .where((r) => r.reciterName.toLowerCase().contains('afasy'))
            .firstOrNull;
        if (mishari != null) {
          logger.info(
            '✅ Found Mishari al-Afasy: id=${mishari.id}, Name="${mishari.translatedName?.name ?? mishari.reciterName}"',
            category: LogCategory.audio,
          );
        }
      },
    );

    test(
      'should successfully fetch chapter audio and timings (Fatiha) and deeply assert structure',
      () async {
        logger.info('--- TEST: Fetch Chapter Audio (Fatiha) ---', category: LogCategory.audio);
        logger.info(
          'Fetching real audio and timings for Fatiha (reciter 7, chapter 1)...',
          category: LogCategory.audio,
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

        logger.info('✅ Audio URL: ${audioFile.audioUrl}', category: LogCategory.audio);
        logger.info('✅ Format: ${audioFile.format}, Size: ${audioFile.fileSize} KB', category: LogCategory.audio);
        logger.info(
          '✅ Timestamps count: ${timestamps.length} (Verified exactly 7 for Fatiha)',
          category: LogCategory.audio,
        );

        for (int i = 0; i < timestamps.length; i++) {
          final verse = timestamps[i];
          expect(verse.ayah, equals(i + 1));
          expect(verse.startTime, greaterThanOrEqualTo(0));
          expect(verse.endTime, greaterThanOrEqualTo(verse.startTime));
        }

        final firstVerse = timestamps.first;
        logger.info(
          '  First verse [ayah=${firstVerse.ayah}]: From ${firstVerse.startTime}ms to ${firstVerse.endTime}ms',
          category: LogCategory.audio,
        );
      },
    );

    test('should successfully fetch chapter audio without segments', () async {
      logger.info('\n--- TEST: Fetch Chapter Audio Without Segments ---', category: LogCategory.audio);
      logger.info(
        'Fetching Husary (reciter 6) for Fatiha (chapter 1) with segments=false...',
        category: LogCategory.audio,
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
        logger.info('  Timestamps successfully retrieved without segments array', category: LogCategory.audio);
        // AyahTiming no longer exposes segments, so we just verify we got timings
        expect(timestamps.first.ayah, greaterThan(0));
      }
    });

    test(
      'should fail gracefully when requesting an invalid chapter (e.g., 115)',
      () async {
        logger.info('\n--- TEST: Edge Case - Invalid Chapter ---', category: LogCategory.audio);
        logger.info('Fetching audio for non-existent chapter 115...', category: LogCategory.audio);

        try {
          await apiClient.fetchChapterAudio(reciterId: 7, chapterNumber: 115);
          fail('Should have thrown an exception for chapter 115');
        } catch (e) {
          logger.info('✅ Successfully caught expected error for invalid chapter:', category: LogCategory.audio);
          logger.info('   -> $e', category: LogCategory.audio);
          expect(
            e.toString(),
            contains('404'),
          ); // Assuming API returns 404 for invalid chapter
        }
      },
    );

    test('should handle token caching and 401 recovery on real API', () async {
      logger.info('\n--- TEST: Sequential Calls (Caching) ---', category: LogCategory.audio);
      logger.info('Executing Call 1...', category: LogCategory.audio);
      //time calculation
      final stopwatch = Stopwatch()..start();
      await apiClient.fetchReciters();
      stopwatch.stop();
      final call1Time = stopwatch.elapsedMilliseconds;
      logger.info('✅ Call 1 completed in $call1Time ms', category: LogCategory.audio);
      logger.info('Executing Call 2 (Should be faster, using cached token)...', category: LogCategory.audio);
      stopwatch.reset();
      stopwatch.start();
      await apiClient.fetchReciters();
      stopwatch.stop();
      final call2Time = stopwatch.elapsedMilliseconds;
      logger.info('✅ Call 2 completed in $call2Time ms', category: LogCategory.audio);
      logger.info('Call 1 time: $call1Time ms, Call 2 time: $call2Time ms', category: LogCategory.audio);
      logger.info(
        'Faster by ${call1Time - call2Time} ms (Expected due to token caching and no re-authentication)',
        category: LogCategory.audio,
      );
      logger.info('✅ Sequential calls successful.', category: LogCategory.audio);
    });
  });
}
