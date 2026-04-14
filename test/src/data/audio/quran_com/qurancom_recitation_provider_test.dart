import 'package:imad_flutter/src/domain/models/audio_source.dart';
import 'package:imad_flutter/src/domain/models/reciter.dart';
import 'package:imad_flutter/src/domain/models/riwayah.dart';

import 'package:imad_flutter/src/domain/models/recitation.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_data_source.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_recitation_provider.dart';
import 'package:imad_flutter/src/logging/mushaf_logger.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockQurancomDataSource extends Mock implements QurancomDataSource {}

class MockMushafLogger extends Mock implements MushafLogger {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Recitation _makeRecitation({
  required int id,
  required String nameEn,
  required String nameAr,
  String rewaya = 'Murattal',
}) => Recitation(
  id: id,
  reciter: Reciter(id: id, nameEnglish: nameEn, nameArabic: nameAr),
  riwayah: Riwayah(
    id: 1, // Mock riwayah id
    nameArabic: rewaya,
    nameEnglish: rewaya,
  ),
  audioSource: MushafAudioSource.quranCom,
  folderUrl: '',
);

// Sample recitations used across tests
final _hafsRecitation1 = _makeRecitation(
  id: 7,
  nameEn: 'Mahmoud Al-Husary',
  nameAr: 'محمود خليل الحصري',
  rewaya: 'Hafs',
);

final _hafsRecitation2 = _makeRecitation(
  id: 9,
  nameEn: 'Mishary Rashid Al-Afasy',
  nameAr: 'مشاري راشد العفاسي',
  rewaya: 'Hafs',
);

final _warshRecitation = _makeRecitation(
  id: 14,
  nameEn: 'Warsh Reciter',
  nameAr: 'قارئ ورش',
  rewaya: 'Warsh',
);

final _sampleRecitations = [
  _hafsRecitation1,
  _hafsRecitation2,
  _warshRecitation,
];

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockQurancomDataSource mockDataSource;
  late MockMushafLogger mockLogger;
  late QuranComRecitationProvider provider;

  setUpAll(() {
    registerFallbackValue(LogCategory.audio);
    registerFallbackValue(StackTrace.current);
  });

  setUp(() {
    mockDataSource = MockQurancomDataSource();
    mockLogger = MockMushafLogger();
    provider = QuranComRecitationProvider(
      dataSource: mockDataSource,
      logger: mockLogger,
    );
  });

  group('QuranComRecitationProvider', () {
    // -----------------------------------------------------------------------
    // getAllRecitations
    // -----------------------------------------------------------------------

    group('getAllRecitations()', () {
      test('fetches from data source on first call', () async {
        when(
          () => mockDataSource.fetchAllRecitations(),
        ).thenAnswer((_) async => _sampleRecitations);

        final result = await provider.getAllRecitations();

        expect(result, equals(_sampleRecitations));
        verify(() => mockDataSource.fetchAllRecitations()).called(1);
      });

      test(
        'returns cached list on subsequent calls without re-fetching',
        () async {
          when(
            () => mockDataSource.fetchAllRecitations(),
          ).thenAnswer((_) async => _sampleRecitations);

          await provider.getAllRecitations(); // First call — hits data source
          await provider.getAllRecitations(); // Second call — should use cache

          verify(() => mockDataSource.fetchAllRecitations()).called(1);
        },
      );

      test('gracefully handles data source failure and logs error', () async {
        final exception = Exception('Network unavailable');
        when(() => mockDataSource.fetchAllRecitations()).thenThrow(exception);

        final result = await provider.getAllRecitations();

        expect(result, isEmpty);
        verify(
          () => mockLogger.error(
            any(),
            error: any(named: 'error'),
            stackTrace: any(named: 'stackTrace'),
            category: LogCategory.audio,
          ),
        ).called(1);
      });
    });

    // -----------------------------------------------------------------------
    // getRecitationById
    // -----------------------------------------------------------------------

    group('getRecitationById()', () {
      setUp(() {
        when(
          () => mockDataSource.fetchAllRecitations(),
        ).thenAnswer((_) async => _sampleRecitations);
      });

      test('returns correct recitation for known ID', () async {
        final result = await provider.getRecitationById(7);

        expect(result, isNotNull);
        expect(result!.id, 7);
      });

      test('returns null for unknown ID', () async {
        final result = await provider.getRecitationById(9999);
        expect(result, isNull);
      });
    });

    // -----------------------------------------------------------------------
    // searchRecitations
    // -----------------------------------------------------------------------

    group('searchRecitations()', () {
      setUp(() {
        when(
          () => mockDataSource.fetchAllRecitations(),
        ).thenAnswer((_) async => _sampleRecitations);
      });

      test(
        'finds recitation by partial English name (case-insensitive)',
        () async {
          final result = await provider.searchRecitations(
            'HUSARY',
            languageCode: 'en',
          );

          expect(result.length, 1);
          expect(result.first.id, 7);
        },
      );

      test('finds recitation by partial Arabic name', () async {
        final result = await provider.searchRecitations(
          'مشاري',
          languageCode: 'ar',
        );

        expect(result.length, 1);

        expect(result.first.id, 9);
      });
    });

    // -----------------------------------------------------------------------
    // getHafsRecitations
    // -----------------------------------------------------------------------

    group('getHafsRecitations()', () {
      setUp(() {
        when(
          () => mockDataSource.fetchAllRecitations(),
        ).thenAnswer((_) async => _sampleRecitations);
      });
    });

    // -----------------------------------------------------------------------
    // getDefaultRecitation
    // -----------------------------------------------------------------------

    group('getDefaultRecitation()', () {
      test('returns first Hafs recitation when available', () async {
        when(
          () => mockDataSource.fetchAllRecitations(),
        ).thenAnswer((_) async => _sampleRecitations);

        final result = await provider.getDefaultRecitation();

        expect(result.id, _hafsRecitation1.id);
      });

      test(
        'returns first available recitation when NO Hafs recitations exist',
        () async {
          when(
            () => mockDataSource.fetchAllRecitations(),
          ).thenAnswer((_) async => [_warshRecitation]);

          final result = await provider.getDefaultRecitation();

          expect(result.id, _warshRecitation.id);
        },
      );

      test(
        'throws StateError when fetchAllRecitations returns empty list',
        () async {
          when(
            () => mockDataSource.fetchAllRecitations(),
          ).thenAnswer((_) async => []);

          expect(
            () => provider.getDefaultRecitation(),
            throwsA(isA<StateError>()),
          );
        },
      );
    });

    // -----------------------------------------------------------------------
    // clearCache
    // -----------------------------------------------------------------------

    group('clearCache()', () {
      test('forces a re-fetch from data source', () async {
        when(
          () => mockDataSource.fetchAllRecitations(),
        ).thenAnswer((_) async => _sampleRecitations);

        // Populate cache
        await provider.getAllRecitations();
        verify(() => mockDataSource.fetchAllRecitations()).called(1);

        // Clear and fetch again
        provider.clearCache();
        await provider.getAllRecitations();

        // Should have hit data source a second time
        verify(() => mockDataSource.fetchAllRecitations()).called(1);
      });
    });
  });
}
