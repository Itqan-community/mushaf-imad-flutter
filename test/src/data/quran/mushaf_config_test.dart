import 'package:flutter/widgets.dart' show AssetImage;
import 'package:flutter_test/flutter_test.dart';
import 'package:imad_flutter/src/data/quran/mushaf_asset_provider.dart';
import 'package:imad_flutter/src/data/quran/quran_data_provider.dart';
import 'package:imad_flutter/src/data/quran/verse_data_provider.dart'
    show VerseMarkerData, VerseHighlightData;
import 'package:imad_flutter/src/domain/models/mushaf_config.dart';
import 'package:imad_flutter/src/domain/models/mushaf_type.dart';
import 'package:imad_flutter/src/domain/models/verse_highlight.dart';
import 'package:imad_flutter/src/domain/models/verse_marker.dart';

import 'test_helpers.dart';

void main() {
  // ---------------------------------------------------------------------------
  // FlutterAssetProvider
  // ---------------------------------------------------------------------------
  group('FlutterAssetProvider', () {
    test('produces an AssetImage for the package', () {
      const provider = FlutterAssetProvider(
        package: 'imad_flutter',
        assetDirectory: 'quran-images',
      );

      final image = provider.resolveLineImage(1, 1);
      expect(image, isA<AssetImage>());
      expect(provider.description, contains('FlutterAssetProvider'));
    });

    test('resolves correct asset path', () {
      const provider = FlutterAssetProvider(
        package: 'imad_flutter',
        assetDirectory: 'quran-images',
      );

      final image = provider.resolveLineImage(604, 15) as AssetImage;
      expect(image.assetName, 'assets/quran-images/604/15.png');
      expect(image.package, 'imad_flutter');
    });
  });

  // ---------------------------------------------------------------------------
  // MushafConfig
  // ---------------------------------------------------------------------------
  group('MushafConfig', () {
    test('lineImageProvider delegates to assetProvider', () {
      const provider = FlutterAssetProvider(
        package: 'imad_flutter',
        assetDirectory: 'quran-images',
      );
      const config = MushafConfig(
        type: MushafType.hafs1441,
        assetProvider: provider,
        totalPages: 604,
        markerField: 'marker1441',
        highlightsField: 'highlights1441',
      );

      final image = config.lineImageProvider(1, 1) as AssetImage;
      expect(image.assetName, 'assets/quran-images/1/1.png');
    });
  });

  // ---------------------------------------------------------------------------
  // MushafConfigRegistry
  // ---------------------------------------------------------------------------
  group('MushafConfigRegistry', () {
    test('defaultType is hafs1441', () {
      expect(MushafConfigRegistry.defaultType, MushafType.hafs1441);
    });

    test('defaultConfig uses bundled FlutterAssetProvider', () {
      final config = MushafConfigRegistry.defaultConfig;

      expect(config.type, MushafType.hafs1441);
      expect(config.totalPages, 604);
      expect(config.markerField, 'marker1441');
      expect(config.highlightsField, 'highlights1441');

      final image = config.lineImageProvider(1, 1);
      expect(image, isA<AssetImage>());
    });

    test('configFor returns correct config for hafs1441', () {
      final config = MushafConfigRegistry.configFor(MushafType.hafs1441);
      expect(config.type, MushafType.hafs1441);
      expect(config.totalPages, 604);
    });

    test('hafs1405 unavailable before registerAssetProvider', () {
      expect(MushafConfigRegistry.isAvailable(MushafType.hafs1405), isFalse);
      expect(
        () => MushafConfigRegistry.configFor(MushafType.hafs1405),
        throwsStateError,
      );
    });

    test('registerAssetProvider for 1405 makes it available', () {
      const provider = FlutterAssetProvider(
        package: 'test',
        assetDirectory: 'quran-images',
      );
      register1405(provider);

      expect(MushafConfigRegistry.isAvailable(MushafType.hafs1405), isTrue);
      final config = MushafConfigRegistry.configFor(MushafType.hafs1405);
      expect(config.type, MushafType.hafs1405);
      expect(config.totalPages, 604);
      expect(config.markerField, 'marker1405');
      expect(config.highlightsField, 'highlights1405');
    });

    test('hafs1441 provider cannot be overridden', () {
      const provider = FlutterAssetProvider(
        package: 'test',
        assetDirectory: 'quran-images',
      );
      expect(
        () => MushafConfigRegistry.registerAssetProvider(
          MushafType.hafs1441,
          provider,
        ),
        throwsAssertionError,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // QuranDataProvider — backward compatibility
  // ---------------------------------------------------------------------------
  group('QuranDataProvider — backward compatibility', () {
    test('getLineImagePath returns unchanged hafs1441 path', () {
      expect(
        QuranDataProvider.getLineImagePath(1, 1),
        'assets/quran-images/1/1.png',
      );
      expect(
        QuranDataProvider.getLineImagePath(604, 15),
        'assets/quran-images/604/15.png',
      );
    });

    test('getLineImageProvider defaults to hafs1441 AssetImage', () {
      expect(QuranDataProvider.getLineImageProvider(1, 1), isA<AssetImage>());
    });

    test('getLineImageProvider resolves 1405 when registered', () {
      register1405(
        const FlutterAssetProvider(
          package: 'test',
          assetDirectory: 'quran-images-1405',
        ),
      );

      final provider = QuranDataProvider.getLineImageProvider(
        1,
        1,
        mushafType: MushafType.hafs1405,
      );
      expect(provider, isA<AssetImage>());
    });

    test('totalPages is 604 (unchanged)', () {
      expect(QuranDataProvider.totalPages, 604);
    });

    test('pagesFor returns 604 for both variants', () {
      register1405(
        const FlutterAssetProvider(
          package: 'test',
          assetDirectory: 'quran-images-1405',
        ),
      );

      expect(QuranDataProvider.pagesFor(MushafType.hafs1441), 604);
      expect(QuranDataProvider.pagesFor(MushafType.hafs1405), 604);
    });
  });

  // ---------------------------------------------------------------------------
  // PageVerseData — mushaf-aware accessors
  // ---------------------------------------------------------------------------
  group('PageVerseData — mushaf-aware accessors', () {
    test('getMarker returns marker1441 for hafs1441', () {
      final verse = buildPageVerseData(
        marker1441: const VerseMarkerData(
          line: 3,
          centerX: 0.5,
          centerY: 0.8,
          numberCodePoint: '1',
        ),
      );

      final marker = verse.getMarker(MushafType.hafs1441);
      expect(marker, isNotNull);
      expect(marker!.line, 3);
    });

    test('getMarker returns marker1405 for hafs1405', () {
      final verse = buildPageVerseData(
        marker1405: const VerseMarkerData(
          line: 5,
          centerX: 0.7,
          centerY: 0.3,
          numberCodePoint: '2',
        ),
      );

      final marker = verse.getMarker(MushafType.hafs1405);
      expect(marker, isNotNull);
      expect(marker!.line, 5);
    });

    test('getMarker returns null when no marker for that Mushaf', () {
      final verse = buildPageVerseData(
        marker1441: const VerseMarkerData(
          line: 1,
          centerX: 0.0,
          centerY: 0.0,
          numberCodePoint: '1',
        ),
      );
      expect(verse.getMarker(MushafType.hafs1405), isNull);
    });

    test('getHighlights returns correct highlights per Mushaf', () {
      final verse = buildPageVerseData(
        highlights1441: const [
          VerseHighlightData(line: 1, left: 0.1, right: 0.5),
        ],
        highlights1405: const [
          VerseHighlightData(line: 2, left: 0.2, right: 0.8),
        ],
      );

      final h1441 = verse.getHighlights(MushafType.hafs1441);
      expect(h1441.length, 1);
      expect(h1441[0].line, 1);

      final h1405 = verse.getHighlights(MushafType.hafs1405);
      expect(h1405.length, 1);
      expect(h1405[0].line, 2);
    });

    test('occupiesLine defaults to hafs1441 when no type given', () {
      final verse = buildPageVerseData(
        highlights1441: const [
          VerseHighlightData(line: 1, left: 0.0, right: 1.0),
          VerseHighlightData(line: 3, left: 0.0, right: 1.0),
        ],
      );

      expect(verse.occupiesLine(1), isTrue);
      expect(verse.occupiesLine(3), isTrue);
      expect(verse.occupiesLine(5), isFalse);
    });

    test('occupiesLine with 1405 uses 1405 highlights', () {
      final verse = buildPageVerseData(
        highlights1405: const [
          VerseHighlightData(line: 7, left: 0.0, right: 1.0),
        ],
      );

      expect(verse.occupiesLine(7, mushafType: MushafType.hafs1405), isTrue);
      expect(verse.occupiesLine(1, mushafType: MushafType.hafs1405), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Verse — mushaf-aware accessors
  // ---------------------------------------------------------------------------
  group('Verse — mushaf-aware accessors', () {
    test('getMarker delegates by MushafType', () {
      final verse = buildVerse(
        marker1441: const VerseMarker(
          numberCodePoint: '1',
          line: 1,
          centerX: 0.5,
          centerY: 0.5,
        ),
        marker1405: const VerseMarker(
          numberCodePoint: '2',
          line: 8,
          centerX: 0.6,
          centerY: 0.4,
        ),
      );

      expect(verse.getMarker(MushafType.hafs1441)?.line, 1);
      expect(verse.getMarker(MushafType.hafs1405)?.line, 8);
    });

    test('getHighlights delegates by MushafType', () {
      final verse = buildVerse(
        highlights1441: const [VerseHighlight(line: 1, left: 0.0, right: 1.0)],
        highlights1405: const [VerseHighlight(line: 10, left: 0.0, right: 1.0)],
      );

      final h1441 = verse.getHighlights(MushafType.hafs1441);
      expect(h1441[0].line, 1);

      final h1405 = verse.getHighlights(MushafType.hafs1405);
      expect(h1405[0].line, 10);
    });
  });
}

/// Helper so tests don't trip over the 1405 StateError.
void register1405(MushafAssetProvider provider) {
  MushafConfigRegistry.registerAssetProvider(MushafType.hafs1405, provider);
}
