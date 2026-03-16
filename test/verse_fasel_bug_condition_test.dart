import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imad_flutter/src/ui/mushaf/verse_fasel.dart';

/// Bug Condition Exploration Test
///
/// **Validates: Requirements 1.1, 1.2, 1.3**
///
/// This test is EXPECTED TO FAIL on unfixed code.
/// Failure confirms the three bugs exist in VerseFasel.build():
///   1. TextStyle missing `package: 'imad_flutter'` — detectable via fontFamily prefix
///   2. toArabicNumerals() produces Arabic-Indic Unicode instead of Western digits
///   3. Text widget missing `textDirection: TextDirection.ltr`
///
/// Note: When `package: 'imad_flutter'` is set in TextStyle, Flutter internally
/// prefixes fontFamily as 'packages/imad_flutter/QuranNumbers'. Without it,
/// fontFamily stays as 'QuranNumbers'. This is the observable side-effect we test.
void main() {
  group('VerseFasel bug condition exploration', () {
    Future<Text> pumpAndFindText(WidgetTester tester, int number) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: VerseFasel(number: number),
              ),
            ),
          ),
        ),
      );
      final textWidget = tester.widget<Text>(find.byType(Text).first);
      return textWidget;
    }

    testWidgets(
      'VerseFasel(number: 35) text should be "35" not "٣٥"',
      (tester) async {
        final textWidget = await pumpAndFindText(tester, 35);
        // FAILS on unfixed code: toArabicNumerals(35) returns '٣٥'
        expect(
          textWidget.data,
          equals('35'),
          reason:
              'Counterexample: VerseFasel(number: 35) → text is "${textWidget.data}" instead of "35"',
        );
      },
    );

    testWidgets(
      'VerseFasel(number: 1) fontFamily should be "packages/imad_flutter/QuranNumbers"',
      (tester) async {
        final textWidget = await pumpAndFindText(tester, 1);
        // FAILS on unfixed code: fontFamily is 'QuranNumbers' (no package prefix)
        // When package: 'imad_flutter' is set, Flutter prefixes fontFamily as
        // 'packages/imad_flutter/QuranNumbers'. Without it, it stays 'QuranNumbers'.
        expect(
          textWidget.style!.fontFamily,
          equals('packages/imad_flutter/QuranNumbers'),
          reason:
              'Counterexample: fontFamily is "${textWidget.style!.fontFamily}" instead of "packages/imad_flutter/QuranNumbers" — missing package: \'imad_flutter\' in TextStyle',
        );
      },
    );

    testWidgets(
      'VerseFasel(number: 286) textDirection should be TextDirection.ltr',
      (tester) async {
        final textWidget = await pumpAndFindText(tester, 286);
        // FAILS on unfixed code: textDirection is null (not specified)
        expect(
          textWidget.textDirection,
          equals(TextDirection.ltr),
          reason:
              'Counterexample: textDirection is "${textWidget.textDirection}" instead of TextDirection.ltr',
        );
      },
    );

    testWidgets(
      'VerseFasel(number: 7) single digit — all three properties correct',
      (tester) async {
        final textWidget = await pumpAndFindText(tester, 7);
        expect(
          textWidget.data,
          equals('7'),
          reason:
              'Counterexample: VerseFasel(number: 7) → text is "${textWidget.data}" instead of "7"',
        );
        expect(
          textWidget.style!.fontFamily,
          equals('packages/imad_flutter/QuranNumbers'),
          reason:
              'Counterexample: fontFamily is "${textWidget.style!.fontFamily}" instead of "packages/imad_flutter/QuranNumbers"',
        );
        expect(
          textWidget.textDirection,
          equals(TextDirection.ltr),
          reason:
              'Counterexample: textDirection is "${textWidget.textDirection}" instead of TextDirection.ltr',
        );
      },
    );
  });
}
