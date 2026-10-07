import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imad_flutter/imad_flutter.dart';
import 'package:imad_flutter/src/data/repository/default_preferences_repository.dart';

void main() {
  group('LineCompactness model tests', () {
    test('preset values have expected spacing factors and overlap', () {
      expect(LineCompactness.ultraCompact.spacingFactor, equals(0.55));
      expect(LineCompactness.ultraCompact.overlap, closeTo(0.45, 0.001));
      expect(LineCompactness.ultraCompact.isExpanded, isFalse);

      expect(LineCompactness.tight.spacingFactor, equals(0.65));
      expect(LineCompactness.tight.overlap, closeTo(0.35, 0.001));
      expect(LineCompactness.tight.isExpanded, isFalse);

      expect(LineCompactness.compact.spacingFactor, equals(0.75));
      expect(LineCompactness.compact.overlap, closeTo(0.25, 0.001));
      expect(LineCompactness.compact.isExpanded, isFalse);

      expect(LineCompactness.normal.spacingFactor, equals(0.85));
      expect(LineCompactness.normal.overlap, closeTo(0.15, 0.001));
      expect(LineCompactness.normal.isExpanded, isFalse);

      expect(LineCompactness.loose.spacingFactor, equals(1.0));
      expect(LineCompactness.loose.overlap, equals(0.0));
      expect(LineCompactness.loose.isExpanded, isFalse);

      expect(LineCompactness.expanded.spacingFactor, isNull);
      expect(LineCompactness.expanded.overlap, equals(0.0));
      expect(LineCompactness.expanded.isExpanded, isTrue);
    });

    test('overlap and scale constructors configure factor correctly', () {
      const withOverlap = LineCompactness.withOverlap(0.40);
      expect(withOverlap.spacingFactor, closeTo(0.60, 0.001));
      expect(withOverlap.overlap, closeTo(0.40, 0.001));

      final fromScaleZero = LineCompactness.fromScale(0.0);
      expect(fromScaleZero.spacingFactor, equals(1.0));

      final fromScaleOne = LineCompactness.fromScale(1.0);
      expect(fromScaleOne.spacingFactor, closeTo(0.70, 0.001));

      final fromScaleHigh = LineCompactness.fromScale(1.5);
      expect(fromScaleHigh.spacingFactor, closeTo(0.55, 0.001));
    });

    test('custom spacing factor works correctly', () {
      const custom = LineCompactness.custom(0.42);
      expect(custom.spacingFactor, equals(0.42));
      expect(custom.overlap, closeTo(0.58, 0.001));
      expect(custom.isExpanded, isFalse);
      expect(custom.name, equals('custom'));

      const fromConstructor = LineCompactness(0.92);
      expect(fromConstructor.spacingFactor, equals(0.92));
      expect(fromConstructor.isExpanded, isFalse);
    });

    test('name and fromName work correctly with strings and numbers', () {
      expect(LineCompactness.ultraCompact.name, equals('ultraCompact'));
      expect(LineCompactness.tight.name, equals('tight'));
      expect(LineCompactness.compact.name, equals('compact'));
      expect(LineCompactness.normal.name, equals('normal'));
      expect(LineCompactness.loose.name, equals('loose'));
      expect(LineCompactness.expanded.name, equals('expanded'));

      expect(
        LineCompactness.fromName('ultracompact'),
        equals(LineCompactness.ultraCompact),
      );
      expect(
        LineCompactness.fromName('ultra_compact'),
        equals(LineCompactness.ultraCompact),
      );
      expect(LineCompactness.fromName('tight'), equals(LineCompactness.tight));
      expect(
        LineCompactness.fromName('compact'),
        equals(LineCompactness.compact),
      );
      expect(
        LineCompactness.fromName('normal'),
        equals(LineCompactness.normal),
      );
      expect(LineCompactness.fromName('loose'), equals(LineCompactness.loose));
      expect(
        LineCompactness.fromName('expanded'),
        equals(LineCompactness.expanded),
      );
      expect(
        LineCompactness.fromName('unknown'),
        equals(LineCompactness.normal),
      );

      // Parsing numerical scale and percentages
      expect(LineCompactness.fromName('0.60').spacingFactor, equals(0.60));
      expect(LineCompactness.fromName('65%').spacingFactor, equals(0.65));
      expect(LineCompactness.fromName('45').spacingFactor, equals(0.45));
    });

    test('displayName formats preset and custom values', () {
      expect(
        LineCompactness.ultraCompact.displayName,
        equals('Ultra Compact (55%)'),
      );
      expect(LineCompactness.tight.displayName, equals('Tight (65%)'));
      expect(LineCompactness.compact.displayName, equals('Compact (75%)'));
      expect(LineCompactness.normal.displayName, equals('Normal (85%)'));
      expect(LineCompactness.loose.displayName, equals('Loose (100%)'));
      expect(LineCompactness.expanded.displayName, equals('Expanded'));
      expect(const LineCompactness(0.40).displayName, equals('Custom (40%)'));
    });

    test('equality and hashCode work as expected', () {
      expect(const LineCompactness(0.75), equals(LineCompactness.compact));
      expect(
        const LineCompactness(0.75).hashCode,
        equals(LineCompactness.compact.hashCode),
      );
      expect(LineCompactness.compact, isNot(equals(LineCompactness.normal)));
      expect(LineCompactness.expanded, isNot(equals(LineCompactness.normal)));
    });

    test('toString formats meaningfully', () {
      expect(LineCompactness.compact.toString(), contains('0.75'));
      expect(LineCompactness.compact.toString(), contains('25%'));
      expect(
        LineCompactness.expanded.toString(),
        equals('LineCompactness.expanded'),
      );
    });

    test('values list contains all presets', () {
      expect(
        LineCompactness.values,
        containsAll([
          LineCompactness.ultraCompact,
          LineCompactness.tight,
          LineCompactness.compact,
          LineCompactness.normal,
          LineCompactness.loose,
          LineCompactness.expanded,
        ]),
      );
    });
  });

  group('PreferencesRepository LineCompactness tests', () {
    test(
      'DefaultPreferencesRepository stores and streams line compactness',
      () async {
        final repo = DefaultPreferencesRepository();

        expect(await repo.getLineCompactness(), equals(LineCompactness.normal));

        final emitted = <LineCompactness>[];
        final sub = repo.getLineCompactnessStream().listen(emitted.add);

        await repo.setLineCompactness(LineCompactness.tight);
        expect(await repo.getLineCompactness(), equals(LineCompactness.tight));

        await repo.setLineCompactness(LineCompactness.expanded);
        expect(
          await repo.getLineCompactness(),
          equals(LineCompactness.expanded),
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(
          emitted,
          equals([LineCompactness.tight, LineCompactness.expanded]),
        );

        await sub.cancel();
      },
    );
  });

  group('MushafThemeNotifier LineCompactness tests', () {
    test(
      'MushafThemeNotifier initializes and notifies on compactness change',
      () {
        final notifier = MushafThemeNotifier(
          initialCompactness: LineCompactness.normal,
        );

        expect(notifier.lineCompactness, equals(LineCompactness.normal));

        var notified = 0;
        notifier.addListener(() => notified++);

        notifier.setCompactness(LineCompactness.compact);
        expect(notifier.lineCompactness, equals(LineCompactness.compact));
        expect(notified, equals(1));

        // Setting same value does not notify
        notifier.setCompactness(LineCompactness.compact);
        expect(notified, equals(1));
      },
    );
  });

  group('QuranPageWidget Layout Tests with LineCompactness', () {
    testWidgets('renders QuranPageWidget with default LineCompactness.normal', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: QuranPageWidget(pageNumber: 1))),
      );

      expect(find.byType(QuranPageWidget), findsOneWidget);
      expect(find.byType(QuranLineImage), findsNWidgets(15));
    });

    testWidgets('renders QuranPageWidget with LineCompactness.compact', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuranPageWidget(
              pageNumber: 1,
              lineCompactness: LineCompactness.compact,
            ),
          ),
        ),
      );

      expect(find.byType(QuranPageWidget), findsOneWidget);
      expect(find.byType(QuranLineImage), findsNWidgets(15));
      expect(find.byType(Positioned), findsWidgets);
    });

    testWidgets('renders QuranPageWidget with LineCompactness.ultraCompact', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuranPageWidget(
              pageNumber: 1,
              lineCompactness: LineCompactness.ultraCompact,
            ),
          ),
        ),
      );

      expect(find.byType(QuranPageWidget), findsOneWidget);
      expect(find.byType(QuranLineImage), findsNWidgets(15));
    });

    testWidgets(
      'renders QuranPageWidget with numerical LineCompactness factor',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: QuranPageWidget(
                pageNumber: 1,
                lineCompactness: LineCompactness(0.60),
              ),
            ),
          ),
        );

        expect(find.byType(QuranPageWidget), findsOneWidget);
        expect(find.byType(QuranLineImage), findsNWidgets(15));
      },
    );

    testWidgets('renders QuranPageWidget with LineCompactness.withOverlap', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuranPageWidget(
              pageNumber: 1,
              lineCompactness: LineCompactness.withOverlap(0.40),
            ),
          ),
        ),
      );

      expect(find.byType(QuranPageWidget), findsOneWidget);
      expect(find.byType(QuranLineImage), findsNWidgets(15));
    });

    testWidgets('renders QuranPageWidget with LineCompactness.fromScale', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuranPageWidget(
              pageNumber: 1,
              lineCompactness: LineCompactness.fromScale(1.5),
            ),
          ),
        ),
      );

      expect(find.byType(QuranPageWidget), findsOneWidget);
      expect(find.byType(QuranLineImage), findsNWidgets(15));
    });

    testWidgets(
      'renders QuranPageWidget with LineCompactness.expanded (legacy)',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: QuranPageWidget(
                pageNumber: 1,
                lineCompactness: LineCompactness.expanded,
              ),
            ),
          ),
        );

        expect(find.byType(QuranPageWidget), findsOneWidget);
        expect(find.byType(QuranLineImage), findsNWidgets(15));
      },
    );

    testWidgets(
      'renders QuranPageWidget with custom lineCompactness and pagePadding',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: QuranPageWidget(
                pageNumber: 1,
                lineCompactness: LineCompactness.custom(0.75),
                pagePadding: EdgeInsets.all(12),
              ),
            ),
          ),
        );

        expect(find.byType(QuranPageWidget), findsOneWidget);
        expect(find.byType(QuranLineImage), findsNWidgets(15));
      },
    );

    testWidgets('tapping on overlapping QuranPageWidget dispatches verse tap', (
      tester,
    ) async {
      VerseDataProvider.instance.setPageDataForTesting({
        1: [
          const PageVerseData(
            verseID: 1,
            number: 1,
            chapter: 1,
            highlights1441: [
              VerseHighlightData(line: 5, left: 0.0, right: 1.0),
            ],
          ),
        ],
      });
      PageVerseData? tappedVerse;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuranPageWidget(
              pageNumber: 1,
              lineCompactness: const LineCompactness(0.55),
              onVerseTap: (verse) {
                tappedVerse = verse;
              },
            ),
          ),
        ),
      );

      final lineImages = find.byType(QuranLineImage);
      expect(lineImages, findsNWidgets(15));

      // Tap on line 5 where the verse is placed
      await tester.tap(lineImages.at(4));
      await tester.pump();

      expect(tappedVerse, isNotNull);
      expect(tappedVerse?.chapter, equals(1));
      expect(tappedVerse?.number, equals(1));
    });

    testWidgets('MushafThemeScope propagates compactness to MushafPageView', (
      tester,
    ) async {
      final notifier = MushafThemeNotifier(
        initialCompactness: LineCompactness.compact,
      );

      await tester.pumpWidget(
        MushafThemeScope(
          notifier: notifier,
          child: const MaterialApp(
            home: Scaffold(body: QuranPageWidget(pageNumber: 1)),
          ),
        ),
      );

      expect(find.byType(QuranPageWidget), findsOneWidget);
    });
  });
}
