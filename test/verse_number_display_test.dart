import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imad_flutter/src/data/quran/quran_data_provider.dart';
import 'package:imad_flutter/src/ui/mushaf/verse_fasel.dart';

/// Unit tests for verse number display (Arabic-Indic vs Western digits).
///
/// Covers all ayah numbers from 1 to 286 (longest chapter: Al-Baqarah).
void main() {
  // ─── toArabicNumerals correctness ────────────────────────────────────────

  group('toArabicNumerals — all ayah numbers 1..286', () {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    test('produces only Arabic-Indic digits for every number 1..286', () {
      for (int n = 1; n <= 286; n++) {
        final result = QuranDataProvider.toArabicNumerals(n);
        expect(result.isNotEmpty, isTrue,
            reason: 'toArabicNumerals($n) must not be empty');
        for (final ch in result.split('')) {
          expect(arabicDigits.contains(ch), isTrue,
              reason:
                  'toArabicNumerals($n) = "$result" contains non-Arabic-Indic char "$ch"');
        }
      }
    });

    test('digit count matches western representation for every number 1..286',
        () {
      for (int n = 1; n <= 286; n++) {
        final result = QuranDataProvider.toArabicNumerals(n);
        expect(result.length, equals(n.toString().length),
            reason:
                'toArabicNumerals($n) length ${result.length} != ${n.toString().length}');
      }
    });

    // Spot-check known values
    test('single digit: 7 → ٧', () {
      expect(QuranDataProvider.toArabicNumerals(7), equals('٧'));
    });

    test('double digit: 35 → ٣٥', () {
      expect(QuranDataProvider.toArabicNumerals(35), equals('٣٥'));
    });

    test('triple digit: 286 → ٢٨٦', () {
      expect(QuranDataProvider.toArabicNumerals(286), equals('٢٨٦'));
    });

    test('triple digit: 100 → ١٠٠', () {
      expect(QuranDataProvider.toArabicNumerals(100), equals('١٠٠'));
    });
  });

  // ─── VerseFasel widget — useArabicNumerals: false (default) ──────────────

  group('VerseFasel(useArabicNumerals: false) — Western digits via QuranNumbers font', () {
    Future<Text> pumpFasel(WidgetTester tester, int number,
        {bool useArabicNumerals = false}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerseFasel(
              number: number,
              useArabicNumerals: useArabicNumerals,
            ),
          ),
        ),
      );
      return tester.widget<Text>(find.byType(Text).first);
    }

    testWidgets('uses Western digit string for number 1', (tester) async {
      final t = await pumpFasel(tester, 1);
      expect(t.data, equals('1'));
    });

    testWidgets('uses Western digit string for number 35', (tester) async {
      final t = await pumpFasel(tester, 35);
      expect(t.data, equals('35'));
    });

    testWidgets('uses Western digit string for number 286', (tester) async {
      final t = await pumpFasel(tester, 286);
      expect(t.data, equals('286'));
    });

    testWidgets('textDirection is ltr', (tester) async {
      final t = await pumpFasel(tester, 7);
      expect(t.textDirection, equals(TextDirection.ltr));
    });

    testWidgets('fontFamily is packages/imad_flutter/QuranNumbers', (tester) async {
      final t = await pumpFasel(tester, 7);
      expect(t.style!.fontFamily, equals('packages/imad_flutter/QuranNumbers'));
    });

    // Property: all numbers 1..286 render as their Western string
    testWidgets('all numbers 1..286 render as Western digit strings',
        (tester) async {
      for (int n = 1; n <= 286; n++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VerseFasel(number: n),
            ),
          ),
        );
        final t = tester.widget<Text>(find.byType(Text).first);
        expect(t.data, equals(n.toString()),
            reason: 'VerseFasel($n) should display "${n.toString()}"');
      }
    });
  });

  // ─── VerseFasel widget — useArabicNumerals: true ─────────────────────────

  group('VerseFasel(useArabicNumerals: true) — Arabic-Indic Unicode digits', () {
    Future<Text> pumpFaselArabic(WidgetTester tester, int number) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerseFasel(number: number, useArabicNumerals: true),
          ),
        ),
      );
      return tester.widget<Text>(find.byType(Text).first);
    }

    testWidgets('number 1 renders as ١', (tester) async {
      final t = await pumpFaselArabic(tester, 1);
      expect(t.data, equals('١'));
    });

    testWidgets('number 7 renders as ٧', (tester) async {
      final t = await pumpFaselArabic(tester, 7);
      expect(t.data, equals('٧'));
    });

    testWidgets('number 35 renders as ٣٥', (tester) async {
      final t = await pumpFaselArabic(tester, 35);
      expect(t.data, equals('٣٥'));
    });

    testWidgets('number 286 renders as ٢٨٦', (tester) async {
      final t = await pumpFaselArabic(tester, 286);
      expect(t.data, equals('٢٨٦'));
    });

    testWidgets('textDirection is rtl', (tester) async {
      final t = await pumpFaselArabic(tester, 7);
      expect(t.textDirection, equals(TextDirection.rtl));
    });

    testWidgets('fontFamily is null (system font)', (tester) async {
      final t = await pumpFaselArabic(tester, 7);
      expect(t.style!.fontFamily, isNull);
    });

    // Property: all numbers 1..286 render as Arabic-Indic Unicode
    testWidgets('all numbers 1..286 render as Arabic-Indic Unicode strings',
        (tester) async {
      const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
      for (int n = 1; n <= 286; n++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VerseFasel(number: n, useArabicNumerals: true),
            ),
          ),
        );
        final t = tester.widget<Text>(find.byType(Text).first);
        final expected = QuranDataProvider.toArabicNumerals(n);
        expect(t.data, equals(expected),
            reason: 'VerseFasel($n, arabic) should display "$expected"');
        for (final ch in t.data!.split('')) {
          expect(arabicDigits.contains(ch), isTrue,
              reason: 'char "$ch" in VerseFasel($n) is not Arabic-Indic');
        }
      }
    });
  });
}
