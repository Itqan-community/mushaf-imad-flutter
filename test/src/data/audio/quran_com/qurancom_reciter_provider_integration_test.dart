import 'package:flutter_test/flutter_test.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_api_client.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_api_config.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_data_source.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_environment.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_reciter_provider.dart';
import 'package:imad_flutter/src/logging/mushaf_logger.dart';

/// Manual Integration Test for QuranComReciterProvider.
///
/// Run this test using:
/// flutter test test/src/data/audio/quran_com/qurancom_reciter_provider_integration_test.dart \
///   --dart-define=QF_ID=YOUR_CLIENT_ID \
///   --dart-define=QF_SECRET=YOUR_CLIENT_SECRET
void main() {
  const clientId = String.fromEnvironment('QF_ID');
  const clientSecret = String.fromEnvironment('QF_SECRET');
  final logger = DefaultMushafLogger();

  group('QuranComReciterProvider Integration', () {
    if (clientId.isEmpty || clientSecret.isEmpty) {
      test(
        'Skipping integration test (Credentials missing)',
        () {},
        skip: 'QF_ID or QF_SECRET not provided via --dart-define',
      );
      return;
    }

    // Use prelive environment for testing
    final config = QuranComApiConfig(
      clientId: clientId,
      clientSecret: clientSecret,
      environment: QuranComEnvironment.prelive,
    );

    final apiClient = QuranComApiClient(config: config);
    final dataSource = QurancomDataSource(apiClient: apiClient);
    // Inject logger here
    final provider = QuranComReciterProvider(
      dataSource: dataSource,
      logger: logger,
    );

    tearDownAll(() {
      apiClient.dispose();
    });

    test(
      'fetchAllReciters returns a real list from Quran.foundation',
      () async {
        logger.info(
          '--- TEST: fetchAllReciters ---',
          category: LogCategory.audio,
        );
        logger.info(
          'Fetching real reciters list from Quran.com API...',
          category: LogCategory.audio,
        );
        final reciters = await provider.getAllReciters();

        expect(reciters, isNotEmpty);

        // Check for a famous reciter (e.g., Al-Husary)
        final husary = reciters.any((r) => r.nameEnglish.contains('Husary'));
        expect(
          husary,
          isTrue,
          reason: 'Expected to find Mahmoud Al-Husary in the real list',
        );

        logger.info(
          '✅ Successfully fetched ${reciters.length} reciters.',
          category: LogCategory.audio,
        );
      },
    );

    test('getReciterById works with real data', () async {
      logger.info('--- TEST: getReciterById ---', category: LogCategory.audio);
      final reciters = await provider.getAllReciters();
      final first = reciters.first;

      final found = await provider.getReciterById(first.id);
      expect(found, isNotNull);
      expect(found?.id, first.id);
      logger.info(
        '✅ Successfully found reciter by ID: ${found?.nameEnglish}',
        category: LogCategory.audio,
      );
    });

    test('searchReciters works with real data', () async {
      logger.info(
        '--- TEST: searchReciters (Mishari) ---',
        category: LogCategory.audio,
      );
      final results = await provider.searchReciters('Mishari');

      expect(results, isNotEmpty);
      expect(results.any((r) => r.nameEnglish.contains('Mishari')), isTrue);
      logger.info(
        '✅ Found ${results.length} results matching "Mishari".',
        category: LogCategory.audio,
      );
    });

    test('getDefaultReciter returns a real reciter', () async {
      logger.info(
        '--- TEST: getDefaultReciter ---',
        category: LogCategory.audio,
      );
      final reciter = await provider.getDefaultReciter();
      expect(reciter, isNotNull);
      logger.info(
        '✅ Default reciter is: ${reciter.nameEnglish}',
        category: LogCategory.audio,
      );
    });
  });
}
