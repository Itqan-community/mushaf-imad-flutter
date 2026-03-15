import 'package:flutter_test/flutter_test.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_data_source.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_reciter_provider.dart';
import 'package:imad_flutter/src/domain/models/reciter_info.dart';
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

ReciterInfo _makeReciter({
  required int id,
  required String nameEn,
  required String nameAr,
  String rewaya = 'Murattal',
}) => ReciterInfo(
  id: id,
  nameEnglish: nameEn,
  nameArabic: nameAr,
  rewaya: rewaya,
  folderUrl: '',
);

// Sample reciters used across tests
final _hafsReciter1 = _makeReciter(
  id: 7,
  nameEn: 'Mahmoud Al-Husary',
  nameAr: 'محمود خليل الحصري',
  rewaya: 'Hafs',
);

final _hafsReciter2 = _makeReciter(
  id: 9,
  nameEn: 'Mishary Rashid Al-Afasy',
  nameAr: 'مشاري راشد العفاسي',
  rewaya: 'Hafs',
);

final _warshReciter = _makeReciter(
  id: 14,
  nameEn: 'Warsh Reciter',
  nameAr: 'قارئ ورش',
  rewaya: 'Warsh',
);

final _sampleReciters = [_hafsReciter1, _hafsReciter2, _warshReciter];

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockQurancomDataSource mockDataSource;
  late MockMushafLogger mockLogger;
  late QuranComReciterProvider provider;

  setUpAll(() {
    registerFallbackValue(LogCategory.audio);
    registerFallbackValue(StackTrace.current);
  });

  setUp(() {
    mockDataSource = MockQurancomDataSource();
    mockLogger = MockMushafLogger();
    provider = QuranComReciterProvider(
      dataSource: mockDataSource,
      logger: mockLogger,
    );
  });

  group('QuranComReciterProvider', () {
    // -----------------------------------------------------------------------
    // getAllReciters
    // -----------------------------------------------------------------------

    group('getAllReciters()', () {
      test('fetches from data source on first call', () async {
        when(() => mockDataSource.fetchAllReciters())
            .thenAnswer((_) async => _sampleReciters);

        final result = await provider.getAllReciters();

        expect(result, equals(_sampleReciters));
        verify(() => mockDataSource.fetchAllReciters()).called(1);
      });

      test('returns cached list on subsequent calls without re-fetching', () async {
        when(() => mockDataSource.fetchAllReciters())
            .thenAnswer((_) async => _sampleReciters);

        await provider.getAllReciters(); // First call — hits data source
        await provider.getAllReciters(); // Second call — should use cache

        verify(() => mockDataSource.fetchAllReciters()).called(1);
      });

      test('gracefully handles data source failure and logs error', () async {
        final exception = Exception('Network unavailable');
        when(() => mockDataSource.fetchAllReciters()).thenThrow(exception);

        final result = await provider.getAllReciters();

        expect(result, isEmpty);
        verify(() => mockLogger.error(
              any(),
              error: any(named: 'error'),
              stackTrace: any(named: 'stackTrace'),
              category: LogCategory.audio,
            )).called(1);
      });
    });

    // -----------------------------------------------------------------------
    // getReciterById
    // -----------------------------------------------------------------------

    group('getReciterById()', () {
      setUp(() {
        when(() => mockDataSource.fetchAllReciters())
            .thenAnswer((_) async => _sampleReciters);
      });

      test('returns correct reciter for known ID', () async {
        final result = await provider.getReciterById(7);

        expect(result, isNotNull);
        expect(result!.id, 7);
      });

      test('returns null for unknown ID', () async {
        final result = await provider.getReciterById(9999);
        expect(result, isNull);
      });
    });

    // -----------------------------------------------------------------------
    // searchReciters
    // -----------------------------------------------------------------------

    group('searchReciters()', () {
      setUp(() {
        when(() => mockDataSource.fetchAllReciters())
            .thenAnswer((_) async => _sampleReciters);
      });

      test('finds reciter by partial English name (case-insensitive)', () async {
        final result = await provider.searchReciters('HUSARY');

        expect(result.length, 1);
        expect(result.first.id, 7);
      });

      test('finds reciter by partial Arabic name', () async {
        final result = await provider.searchReciters('مشاري');

        expect(result.length, 1);
        expect(result.first.id, 9);
      });
    });

    // -----------------------------------------------------------------------
    // getHafsReciters
    // -----------------------------------------------------------------------

    group('getHafsReciters()', () {
      setUp(() {
        when(() => mockDataSource.fetchAllReciters())
            .thenAnswer((_) async => _sampleReciters);
      });

      test('returns only Hafs reciters', () async {
        final result = await provider.getHafsReciters();

        expect(result.length, 2);
        expect(result.every((r) => r.isHafs), isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // getDefaultReciter
    // -----------------------------------------------------------------------

    group('getDefaultReciter()', () {
      test('returns first Hafs reciter when available', () async {
        when(() => mockDataSource.fetchAllReciters())
            .thenAnswer((_) async => _sampleReciters);

        final result = await provider.getDefaultReciter();

        expect(result.id, _hafsReciter1.id);
      });
    });
  });
}
