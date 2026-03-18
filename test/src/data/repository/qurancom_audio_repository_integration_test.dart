import 'package:flutter_test/flutter_test.dart';
import 'package:imad_flutter/src/data/audio/ayah_timing_service.dart';
import 'package:imad_flutter/src/data/audio/flutter_audio_player.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_api_client.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_api_config.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_data_source.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_environment.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_reciter_provider.dart';
import 'package:imad_flutter/src/data/repository/qurancom_audio_repository.dart';
import 'package:imad_flutter/src/domain/models/reciter_info.dart';
import 'package:imad_flutter/src/logging/mushaf_logger.dart';
import 'package:mocktail/mocktail.dart';

/// Manual Integration Test for QuranComAudioRepository.
///
/// Run this test using:
/// flutter test test/src/data/repository/qurancom_audio_repository_integration_test.dart \
///   --dart-define=QF_ID=YOUR_CLIENT_ID \
///   --dart-define=QF_SECRET=YOUR_CLIENT_SECRET
class MockFlutterAudioPlayer extends Mock implements FlutterAudioPlayer {}

class _FakeReciter extends Fake implements ReciterInfo {}

void main() {
  const clientId = String.fromEnvironment('QF_ID');
  const clientSecret = String.fromEnvironment('QF_SECRET');
  final logger = DefaultMushafLogger();

  setUpAll(() {
    registerFallbackValue(_FakeReciter());
  });

  group('QuranComAudioRepository Integration', () {
    if (clientId.isEmpty || clientSecret.isEmpty) {
      test(
        'Skipping integration test (Credentials missing)',
        () {},
        skip: 'QF_ID or QF_SECRET not provided via --dart-define',
      );
      return;
    }

    // Common setup using prelive
    final config = QuranComApiConfig(
      clientId: clientId,
      clientSecret: clientSecret,
      environment: QuranComEnvironment.prelive,
    );

    final apiClient = QuranComApiClient(config: config);
    final dataSource = QurancomDataSource(apiClient: apiClient);
    final provider = QuranComReciterProvider(dataSource: dataSource, logger: logger);
    final timingService = AyahTimingService(dataSource: dataSource);
    final mockPlayer = MockFlutterAudioPlayer();

    final repository = QuranComAudioRepository(
      reciterProvider: provider,
      timingService: timingService,
      dataSource: dataSource,
      audioPlayer: mockPlayer,
      logger: logger,
    );

    tearDownAll(() {
      apiClient.dispose();
    });

    test('loadChapter fetches real URL from API and passes it to player', () async {
      logger.info('--- TEST: loadChapter (Hafs) ---', category: LogCategory.audio);
      logger.info('Fetching real audio URL for chapter 1...', category: LogCategory.audio);

      // Arrange: Stub player
      when(() => mockPlayer.loadChapter(
        any(),
        any(),
        autoPlay: any(named: 'autoPlay'),
        audioUrl: any(named: 'audioUrl'),
      )).thenAnswer((_) async {});

      // Act: Get a valid reciter
      final reciters = await provider.getAllReciters();
      final reciter = reciters.firstWhere((r) => r.isHafs);
      logger.info('Using reciter: ${reciter.nameEnglish} (ID: ${reciter.id})', category: LogCategory.audio);

      repository.loadChapter(1, reciter.id);
      await untilCalled(() => mockPlayer.loadChapter(
        any(),
        any(),
        autoPlay: any(named: 'autoPlay'),
        audioUrl: any(named: 'audioUrl'),
      ));

      // Assert: Verify that a non-empty, real URL was passed to the player
      final capturedUrl = verify(() => mockPlayer.loadChapter(
        1,
        any(),
        autoPlay: false,
        audioUrl: captureAny(named: 'audioUrl'),
      )).captured.first as String;

      expect(capturedUrl, isNotEmpty);
      expect(capturedUrl.startsWith('http'), isTrue);
      logger.info('✅ Successfully retrieved real URL: $capturedUrl', category: LogCategory.audio);
    });

    test('getChapterTimings fetches real timings from API', () async {
      logger.info('--- TEST: getChapterTimings (Fatiha) ---', category: LogCategory.audio);
      
      final reciters = await provider.getAllReciters();
      final reciter = reciters.firstWhere((r) => r.isHafs); 

      logger.info('Fetching timings for ${reciter.nameEnglish}, Chapter 1...', category: LogCategory.audio);
      final timings = await repository.getChapterTimings(reciter.id, 1);
      
      expect(timings, isNotEmpty);
      expect(timings.length, equals(7), reason: 'Fatiha should have 7 verses');
      expect(timings.first.ayah, 1);
      expect(timings.first.startTime, 0);
      
      logger.info('✅ Successfully fetched ${timings.length} verse timings.', category: LogCategory.audio);
      logger.info('✅ First verse ends at: ${timings.first.endTime}ms', category: LogCategory.audio);
    });

    test('preloadTiming works without error', () async {
      logger.info('--- TEST: preloadTiming ---', category: LogCategory.audio);
      final reciters = await provider.getAllReciters();
      final reciter = reciters.first;

      await expectLater(repository.preloadTiming(reciter.id), completes);
      logger.info('✅ preloadTiming completed for reciter ${reciter.id}', category: LogCategory.audio);
    });

    test('loadChapter handles invalid data gracefully', () async {
      logger.info('--- TEST: loadChapter Error (Invalid Chapter) ---', category: LogCategory.audio);
      
      final reciters = await provider.getAllReciters();
      final reciter = reciters.first;

      // Chapter 115 doesn't exist. Should not throw but log error.
      repository.loadChapter(115, reciter.id);
      // Wait for the async error to be caught and logged
      await Future.delayed(const Duration(seconds: 1));
      
      logger.info('✅ loadChapter (Invalid) completed gracefully.', category: LogCategory.audio);
    });
  });
}
