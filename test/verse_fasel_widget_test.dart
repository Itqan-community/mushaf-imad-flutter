import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imad_flutter/imad_flutter.dart';
import 'package:imad_flutter/src/ui/mushaf/verse_fasel.dart';
import 'package:imad_flutter/src/data/quran/quran_data_provider.dart';

void main() {
  group('VerseFasel widget', () {
    Widget buildTestWidget(int number, {double? size}) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: size != null
                ? VerseFasel(number: number, size: size)
                : VerseFasel(number: number),
          ),
        ),
      );
    }

    Finder findVerseFaselSizedBox() {
      return find.descendant(
        of: find.byType(VerseFasel),
        matching: find.byType(SizedBox),
      ).first;
    }

    testWidgets('renders with default size', (tester) async {
      await tester.pumpWidget(buildTestWidget(1));

      final sizedBox = tester.widget<SizedBox>(findVerseFaselSizedBox());
      expect(sizedBox.width, 28);
      expect(sizedBox.height, 28);
    });

    testWidgets('renders with custom size', (tester) async {
      await tester.pumpWidget(buildTestWidget(5, size: 56));

      final sizedBox = tester.widget<SizedBox>(findVerseFaselSizedBox());
      expect(sizedBox.width, 56);
      expect(sizedBox.height, 56);
    });

    testWidgets('displays Arabic numeral for single-digit verse', (tester) async {
      await tester.pumpWidget(buildTestWidget(7));

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.data, QuranDataProvider.toArabicNumerals(7));
    });

    testWidgets('displays Arabic numeral for double-digit verse', (tester) async {
      await tester.pumpWidget(buildTestWidget(42));

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.data, QuranDataProvider.toArabicNumerals(42));
    });

    testWidgets('displays Arabic numeral for triple-digit verse', (tester) async {
      await tester.pumpWidget(buildTestWidget(286));

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.data, QuranDataProvider.toArabicNumerals(286));
    });

    testWidgets('displays Arabic numeral for verse 1', (tester) async {
      await tester.pumpWidget(buildTestWidget(1));

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.data, QuranDataProvider.toArabicNumerals(1));
    });

    testWidgets('font size scales with widget size', (tester) async {
      const smallSize = 20.0;
      const largeSize = 60.0;

      await tester.pumpWidget(buildTestWidget(1, size: smallSize));
      final smallText = tester.widget<Text>(find.byType(Text));
      final smallFontSize = smallText.style!.fontSize!;

      await tester.pumpWidget(buildTestWidget(1, size: largeSize));
      final largeText = tester.widget<Text>(find.byType(Text));
      final largeFontSize = largeText.style!.fontSize!;

      expect(smallFontSize, smallSize * 0.45);
      expect(largeFontSize, largeSize * 0.45);
      expect(largeFontSize, greaterThan(smallFontSize));
    });

    testWidgets('text uses bold weight and black color', (tester) async {
      await tester.pumpWidget(buildTestWidget(10));

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style!.fontWeight, FontWeight.bold);
      expect(text.style!.color, Colors.black);
    });

    testWidgets('text uses QuranNumbers font family', (tester) async {
      await tester.pumpWidget(buildTestWidget(10));

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style!.fontFamily, 'QuranNumbers');
    });

    testWidgets('text is centered in the widget', (tester) async {
      await tester.pumpWidget(buildTestWidget(10));

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.textAlign, TextAlign.center);

      final stack = tester.widget<Stack>(find.descendant(
        of: find.byType(VerseFasel),
        matching: find.byType(Stack),
      ));
      expect(stack.alignment, Alignment.center);
    });

    testWidgets('top padding scales with size', (tester) async {
      const size = 40.0;
      await tester.pumpWidget(buildTestWidget(1, size: size));

      final padding = tester.widget<Padding>(find.descendant(
        of: find.byType(Stack),
        matching: find.byType(Padding),
      ));
      final edgeInsets = padding.padding as EdgeInsets;
      expect(edgeInsets.top, size * 0.05);
    });

    testWidgets('renders SvgPicture for the fasel graphic', (tester) async {
      await tester.pumpWidget(buildTestWidget(1));

      final verseFaselStack = find.descendant(
        of: find.byType(VerseFasel),
        matching: find.byType(Stack),
      );
      expect(verseFaselStack, findsOneWidget);
      expect(find.byType(SvgPicture), findsOneWidget);
      final stack = tester.widget<Stack>(verseFaselStack);
      expect(stack.children.length, 2);
    });

    testWidgets('text line height is 1.0', (tester) async {
      await tester.pumpWidget(buildTestWidget(50));

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style!.height, 1.0);
    });
  });

  group('QuranDataProvider.toArabicNumerals', () {
    test('converts single digit', () {
      expect(QuranDataProvider.toArabicNumerals(5), '٥');
    });

    test('converts double digits', () {
      expect(QuranDataProvider.toArabicNumerals(42), '٤٢');
    });

    test('converts triple digits', () {
      expect(QuranDataProvider.toArabicNumerals(286), '٢٨٦');
    });

    test('converts zero', () {
      expect(QuranDataProvider.toArabicNumerals(0), '٠');
    });
  });
}
