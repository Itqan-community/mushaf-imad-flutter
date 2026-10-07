import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:imad_flutter/src/data/audio/ayah_timing_service.dart';
import 'package:imad_flutter/src/data/audio/mushaf_audio_data_source.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_api_client.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_api_config.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_data_source.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_environment.dart';
import 'package:imad_flutter/src/logging/mushaf_logger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Allow real network calls to pass through instead of Flutter blocking them with a 400 response
  HttpOverrides.global = null;

  // Load credentials from environment variables for testing
  const clientId = String.fromEnvironment('QF_ID');
  const clientSecret = String.fromEnvironment('QF_SECRET');

  group('AyahTimingService Integration Test (Live API)', () {
    if (clientId.isEmpty || clientSecret.isEmpty) {
      test(
        'Skipping integration test (Credentials missing)',
        () {},
        skip: 'QF_ID or QF_SECRET not provided via --dart-define',
      );
      return;
    }

    late AyahTimingService timingService;
    late MushafAudioDataSource dataSource;
    late QuranComApiClient apiClient;
    final logger = DefaultMushafLogger();

    setUpAll(() {
      final config = QuranComApiConfig(
        clientId: clientId,
        clientSecret: clientSecret,
        environment: QuranComEnvironment.prelive,
      );

      apiClient = QuranComApiClient(config: config);
      dataSource = QurancomDataSource(apiClient: apiClient);
      timingService = AyahTimingService(dataSource: dataSource);
    });

    tearDownAll(() {
      apiClient.dispose();
    });

    test(
      'should fetch timings dynamically and cache them when asset is missing',
      () async {
        logger.info(
          '--- TEST: Fetch Timings Dynamically & Cache ---',
          category: LogCategory.timing,
        );
        // Act
        // Reciter 7 (Mishary), Chapter 1 (Al-Fatihah)
        final timings = await timingService.getChapterTimings(7, 1);
        logger.info(
          '✅ Successfully fetched ${timings.length} ayahs from API fallback.',
          category: LogCategory.timing,
        );

        // Assert
        expect(
          timings,
          isNotEmpty,
          reason: 'Live API should return Chapter 1 timings',
        );
        // Fatihah has 7 ayahs
        expect(
          timings.length,
          7,
          reason: 'Fatihah should have exactly 7 ayahs timed',
        );

        // Verify some mapped properties
        expect(timings.first.ayah, 1);
        expect(timings.first.startTime, greaterThanOrEqualTo(0));
        expect(timings.first.endTime, greaterThan(timings.first.startTime));

        // Act 2: Should hit memory cache
        final sw = Stopwatch()..start();
        final timings2 = await timingService.getChapterTimings(7, 1);
        sw.stop();

        expect(timings2.length, 7);
        expect(
          sw.elapsedMilliseconds,
          lessThan(
            500,
          ), // generous threshold to avoid flakiness on slow devices
          reason: 'Dynamic cache should be instantaneous',
        );
        logger.info(
          '✅ Second fetch from dynamic cache took ${sw.elapsedMilliseconds}ms.',
          category: LogCategory.timing,
        );
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test('should retrieve specific ayah timing after caching chapter', () async {
      logger.info(
        '--- TEST: Retrieve Specific Ayah Timing ---',
        category: LogCategory.timing,
      );
      // Act
      // Make sure it's cached
      await timingService.getChapterTimings(7, 2);

      // Request a specific verse, e.g., Ayah 255 (Ayat Al-Kursi)
      final timing = await timingService.getAyahTiming(7, 2, 255);

      logger.info(
        '✅ Retrieved individual Ayah Timing: Ayah ${timing?.ayah}, Start: ${timing?.startTime}ms, End: ${timing?.endTime}ms',
        category: LogCategory.timing,
      );

      // Assert
      expect(timing, isNotNull);
      expect(timing!.ayah, 255);
      expect(timing.startTime, greaterThan(0));
    });

    test('should get current verse from timestamps', () async {
      // Ensure Chapter 1 timings are loaded
      await timingService.getChapterTimings(7, 1);

      // Look up timing for Ayah 2
      final ayah2Timing = await timingService.getAyahTiming(7, 1, 2);
      expect(ayah2Timing, isNotNull);

      // Midpoint of Ayah 2
      final midpointMs =
          ayah2Timing!.startTime +
          ((ayah2Timing.endTime - ayah2Timing.startTime) ~/ 2);

      // Test the getCurrentVerse method
      final currentAyah = await timingService.getCurrentVerse(7, 1, midpointMs);
      logger.info(
        '--- TEST: Get Current Verse from Timestamps ---',
        category: LogCategory.timing,
      );
      logger.info(
        '✅ Found verse number: $currentAyah for time: ${midpointMs}ms',
        category: LogCategory.timing,
      );

      expect(currentAyah, 2);
    });

    test(
      'should return empty list gracefully when API fails (e.g., invalid reciter id)',
      () async {
        logger.info(
          '--- TEST: Handle API Error Gracefully ---',
          category: LogCategory.timing,
        );
        // Act
        // Try fetching for an absurdly high reciter ID
        final timings = await timingService.getChapterTimings(99999, 1);

        logger.info(
          '✅ API Fallback returned empty list for invalid reciter, avoiding crash.',
          category: LogCategory.timing,
        );

        // Assert
        expect(timings, isEmpty);
      },
    );

  });
}
