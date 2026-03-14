import 'package:flutter_test/flutter_test.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_api_client.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_api_config.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_data_source.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_environment.dart';

/// Integration Test for QurancomDataSource.
///
/// Run this test using:
/// flutter test test/src/data/audio/quran_com/qurancom_data_source_integration_test.dart \
///   --dart-define=QF_ID=YOUR_CLIENT_ID \
///   --dart-define=QF_SECRET=YOUR_CLIENT_SECRET
void main() {
  const clientId = String.fromEnvironment('QF_ID');
  const clientSecret = String.fromEnvironment('QF_SECRET');

  group('QurancomDataSource Integration Test', () {
    if (clientId.isEmpty || clientSecret.isEmpty) {
      test(
        'Skipping integration test (Credentials missing)',
        () {},
        skip: 'QF_ID or QF_SECRET not provided via --dart-define',
      );
      return;
    }

    late QuranComApiClient apiClient;
    late QurancomDataSource dataSource;

    setUp(() {
      final config = QuranComApiConfig(
        clientId: clientId,
        clientSecret: clientSecret,
        environment: QuranComEnvironment.prelive,
      );
      apiClient = QuranComApiClient(config: config);
      dataSource = QurancomDataSource(apiClient: apiClient);
    });

    tearDown(() {
      apiClient.dispose();
    });

    test('should fetch real reciters and map to ReciterInfo with Arabic names', () async {
      print('\n--- TEST: Integration Fetch Reciters ---');
      final reciters = await dataSource.fetchAllReciters();
      
      expect(reciters, isNotEmpty);
      final first = reciters.first;
      
      // Basic field checks
      expect(first.id, isPositive);
      expect(first.nameArabic, isNotEmpty);
      expect(first.nameEnglish, isNotEmpty);
      expect(first.rewaya, isNotEmpty);
      
      print('✅ Successfully fetched ${reciters.length} reciters.');
      print('✅ Mapped Example: English="${first.nameEnglish}", Arabic="${first.nameArabic}", Style="${first.rewaya}"');
    });

    test('should fetch and cache timings for a real chapter', () async {
      print('\n--- TEST: Integration Audio & Timing Cache ---');
      // Test with Fatiha (chapter 1) and Mishari (id 7)
      final url = await dataSource.fetchChapterAudioUrl(7, 1);
      expect(url, contains('.mp3'));
      print('✅ Audio URL: $url');

      // Subsequent timing fetch should be instant/cached
      final stopwatch = Stopwatch()..start();
      final timings = await dataSource.fetchChapterTiming(7, 1);
      stopwatch.stop();
      
      expect(timings, isNotNull);
      expect(timings!.length, equals(7));
      print('✅ Timestamps count: ${timings.length}');
      print('✅ Timing fetch duration (cached): ${stopwatch.elapsedMilliseconds}ms');
      
      // In integration tests, 50ms is a safe "cached" threshold to account for CPU variation
      expect(stopwatch.elapsedMilliseconds, lessThan(50), reason: 'Timing should be returned from cache');
    });
  });
}
