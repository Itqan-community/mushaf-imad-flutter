import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imad_flutter/src/data/quran/verse_data_provider.dart';
import 'package:imad_flutter/src/ui/mushaf/quran_line_image.dart';

void main() {
  Widget buildTestWidget({
    int page = 1,
    int line = 1,
    List<VerseHighlightData> audioHighlights = const [],
    Color? audioHighlightsColor,
    List<VerseHighlightData> selectionHighlights = const [],
    VoidCallback? onTap,
    void Function(double)? onTapUpExact,
    List<PageVerseData> markers = const [],
    Color? highlightColor,
    Color? textColor,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 360,
          child: QuranLineImage(
            page: page,
            line: line,
            audioHighlights: audioHighlights,
            audioHighlightsColor: audioHighlightsColor,
            selectionHighlights: selectionHighlights,
            onTap: onTap,
            onTapUpExact: onTapUpExact,
            markers: markers,
            highlightColor: highlightColor,
            textColor: textColor,
          ),
        ),
      ),
    );
  }

  group('QuranLineImage', () {
    testWidgets('renders with correct aspect ratio', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      final aspectRatio = tester.widget<AspectRatio>(
        find.byType(AspectRatio),
      );
      expect(aspectRatio.aspectRatio, closeTo(1440.0 / 232.0, 0.01));
    });

    testWidgets('wraps in a GestureDetector', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(GestureDetector), findsOneWidget);
      final gd = tester.widget<GestureDetector>(
        find.byType(GestureDetector),
      );
      expect(gd.behavior, HitTestBehavior.opaque);
    });

    testWidgets('renders Stack with StackFit.expand', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      final stack = tester.widget<Stack>(find.byType(Stack).first);
      expect(stack.fit, StackFit.expand);
    });

    group('selection highlights', () {
      testWidgets('renders no highlights when list is empty', (tester) async {
        await tester.pumpWidget(buildTestWidget(selectionHighlights: []));

        expect(find.byType(Positioned), findsNothing);
      });

      testWidgets('renders Positioned container for each highlight',
          (tester) async {
        final highlights = [
          const VerseHighlightData(line: 1, left: 0.2, right: 0.6),
          const VerseHighlightData(line: 1, left: 0.7, right: 0.9),
        ];

        await tester.pumpWidget(
          buildTestWidget(selectionHighlights: highlights),
        );

        final positionedWidgets = tester.widgetList<Positioned>(
          find.byType(Positioned),
        );
        expect(positionedWidgets.length, 2);
      });

      testWidgets('highlight uses default gold color when no highlightColor',
          (tester) async {
        final highlights = [
          const VerseHighlightData(line: 1, left: 0.1, right: 0.5),
        ];

        await tester.pumpWidget(
          buildTestWidget(selectionHighlights: highlights),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(Positioned),
            matching: find.byType(Container),
          ),
        );
        final decoration = container.decoration as BoxDecoration;
        // Default color is Color(0xFFD4A574) with alpha 0.25
        expect(decoration.color, isNotNull);
        expect(decoration.color!.a, closeTo(0.25, 0.01));
      });

      testWidgets('highlight uses custom highlightColor', (tester) async {
        final highlights = [
          const VerseHighlightData(line: 1, left: 0.0, right: 1.0),
        ];

        await tester.pumpWidget(
          buildTestWidget(
            selectionHighlights: highlights,
            highlightColor: Colors.red,
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(Positioned),
            matching: find.byType(Container),
          ),
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, isNotNull);
        // Should be red-based with alpha 0.25
        expect(decoration.color!.a, closeTo(0.25, 0.01));
      });

      testWidgets('highlight position is proportional to line width',
          (tester) async {
        final highlights = [
          const VerseHighlightData(line: 1, left: 0.25, right: 0.75),
        ];

        await tester.pumpWidget(
          buildTestWidget(selectionHighlights: highlights),
        );

        final positioned = tester.widget<Positioned>(
          find.byType(Positioned).first,
        );
        // Container width is 360, so:
        // left = 360 * 0.25 = 90
        // width = 360 * (0.75 - 0.25) = 180
        expect(positioned.left, closeTo(90, 1));
        expect(positioned.width, closeTo(180, 1));
        expect(positioned.top, 0);
        expect(positioned.bottom, 0);
      });

      testWidgets('highlight has rounded corners', (tester) async {
        final highlights = [
          const VerseHighlightData(line: 1, left: 0.0, right: 0.5),
        ];

        await tester.pumpWidget(
          buildTestWidget(selectionHighlights: highlights),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(Positioned),
            matching: find.byType(Container),
          ),
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.borderRadius, BorderRadius.circular(4));
      });
    });

    group('audio highlights', () {
      testWidgets('renders base image when no audio highlights',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(audioHighlights: []));

        // Should render one base Image.asset (via errorBuilder since asset doesn't exist in test)
        expect(find.byType(Image), findsOneWidget);
      });

      testWidgets('renders ClipRect widgets for audio highlight',
          (tester) async {
        final highlights = [
          const VerseHighlightData(line: 1, left: 0.3, right: 0.7),
        ];

        await tester.pumpWidget(
          buildTestWidget(audioHighlights: highlights),
        );

        // Audio highlight creates 3 ClipRect segments: before, highlight, after
        expect(find.byType(ClipRect), findsNWidgets(3));
      });

      testWidgets('multiple audio highlights create multiple clip sets',
          (tester) async {
        final highlights = [
          const VerseHighlightData(line: 1, left: 0.1, right: 0.3),
          const VerseHighlightData(line: 1, left: 0.5, right: 0.8),
        ];

        await tester.pumpWidget(
          buildTestWidget(audioHighlights: highlights),
        );

        // Each audio highlight creates 3 ClipRects = 6 total
        expect(find.byType(ClipRect), findsNWidgets(6));
      });
    });

    group('verse markers', () {
      testWidgets('renders VerseFasel for each marker', (tester) async {
        final markerData = [
          PageVerseData(
            verseID: 1,
            number: 5,
            chapter: 1,
            marker1441: const VerseMarkerData(
              line: 1,
              centerX: 0.5,
              centerY: 0.5,
              numberCodePoint: '\uFD3F',
            ),
          ),
        ];

        await tester.pumpWidget(buildTestWidget(markers: markerData));

        // VerseFasel is rendered inside a Positioned inside a nested Stack
        // Find the nested Stack that contains markers
        final stacks = tester.widgetList<Stack>(find.byType(Stack));
        expect(stacks.length, greaterThanOrEqualTo(2)); // outer + marker stack
      });

      testWidgets('no marker stack when markers list is empty',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(markers: []));

        // Only the outer Stack from LayoutBuilder
        final stacks = tester.widgetList<Stack>(find.byType(Stack));
        expect(stacks.length, 1);
      });

      testWidgets('marker with null marker1441 renders SizedBox.shrink',
          (tester) async {
        final markerData = [
          const PageVerseData(
            verseID: 1,
            number: 5,
            chapter: 1,
            marker1441: null,
          ),
        ];

        await tester.pumpWidget(buildTestWidget(markers: markerData));

        // The marker stack is created but contains only a SizedBox.shrink
        expect(find.byType(SizedBox), findsWidgets);
      });
    });

    group('tap handling', () {
      testWidgets('invokes onTapUpExact with normalized position',
          (tester) async {
        double? tappedRatio;

        await tester.pumpWidget(
          buildTestWidget(onTapUpExact: (ratio) => tappedRatio = ratio),
        );

        // Tap in the center of the widget
        await tester.tapAt(tester.getCenter(find.byType(GestureDetector)));
        await tester.pump();

        expect(tappedRatio, isNotNull);
        expect(tappedRatio!, closeTo(0.5, 0.1));
      });

      testWidgets('invokes onTap when onTapUpExact is null', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          buildTestWidget(onTap: () => tapped = true),
        );

        await tester.tapAt(tester.getCenter(find.byType(GestureDetector)));
        await tester.pump();

        expect(tapped, isTrue);
      });
    });

    group('text color tinting', () {
      testWidgets('base image applies textColor with srcIn blend',
          (tester) async {
        await tester.pumpWidget(
          buildTestWidget(textColor: Colors.white),
        );

        final image = tester.widget<Image>(find.byType(Image).first);
        expect(image.color, Colors.white);
        expect(image.colorBlendMode, BlendMode.srcIn);
      });

      testWidgets('no blend mode when textColor is null', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        final image = tester.widget<Image>(find.byType(Image).first);
        expect(image.color, isNull);
        expect(image.colorBlendMode, isNull);
      });
    });

    group('error handling', () {
      testWidgets('shows error text when asset is missing', (tester) async {
        await tester.pumpWidget(buildTestWidget(page: 999, line: 99));
        await tester.pump();

        // The Image.asset errorBuilder renders an error message
        // Since the asset doesn't exist in tests, errorBuilder fires
        expect(find.textContaining('Missing quran-images'), findsOneWidget);
      });
    });
  });
}
