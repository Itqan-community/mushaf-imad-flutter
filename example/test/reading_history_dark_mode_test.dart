import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imad_flutter_example/main.dart';

void main() {
  Widget buildTestApp({required Brightness brightness}) {
    return MaterialApp(
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        useMaterial3: true,
        brightness: brightness,
      ),
      home: const ReadingHistoryPage(),
    );
  }

  group('ReadingHistoryPage dark mode support', () {
    testWidgets('uses theme-aware colors in light mode', (tester) async {
      await tester.pumpWidget(buildTestApp(brightness: Brightness.light));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(ReadingHistoryPage));
      final colorScheme = Theme.of(context).colorScheme;

      final icon = tester.widget<Icon>(find.byIcon(Icons.history));
      expect(icon.color, equals(colorScheme.onSurfaceVariant));

      final titleFinder = find.text('Reading History Repository');
      expect(titleFinder, findsOneWidget);
      final titleWidget = tester.widget<Text>(titleFinder);
      expect(titleWidget.style?.color, equals(colorScheme.onSurface));

      final bodyFinder = find.textContaining('Reading history will be available');
      expect(bodyFinder, findsOneWidget);
      final bodyWidget = tester.widget<Text>(bodyFinder);
      expect(bodyWidget.style?.color, equals(colorScheme.onSurfaceVariant));
    });

    testWidgets('uses theme-aware colors in dark mode', (tester) async {
      await tester.pumpWidget(buildTestApp(brightness: Brightness.dark));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(ReadingHistoryPage));
      final colorScheme = Theme.of(context).colorScheme;

      final icon = tester.widget<Icon>(find.byIcon(Icons.history));
      expect(icon.color, equals(colorScheme.onSurfaceVariant));

      final titleWidget =
          tester.widget<Text>(find.text('Reading History Repository'));
      expect(titleWidget.style?.color, equals(colorScheme.onSurface));

      final bodyWidget = tester
          .widget<Text>(find.textContaining('Reading history will be available'));
      expect(bodyWidget.style?.color, equals(colorScheme.onSurfaceVariant));
    });

    testWidgets('light and dark mode produce different color values',
        (tester) async {
      await tester.pumpWidget(buildTestApp(brightness: Brightness.light));
      await tester.pumpAndSettle();
      final lightContext = tester.element(find.byType(ReadingHistoryPage));
      final lightColors = Theme.of(lightContext).colorScheme;
      final lightOnSurface = lightColors.onSurface;

      await tester.pumpWidget(buildTestApp(brightness: Brightness.dark));
      await tester.pumpAndSettle();
      final darkContext = tester.element(find.byType(ReadingHistoryPage));
      final darkColors = Theme.of(darkContext).colorScheme;
      final darkOnSurface = darkColors.onSurface;

      expect(lightOnSurface, isNot(equals(darkOnSurface)));
    });

    testWidgets('does not use hardcoded Colors.grey', (tester) async {
      await tester.pumpWidget(buildTestApp(brightness: Brightness.dark));
      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(find.byIcon(Icons.history));
      expect(icon.color, isNot(equals(Colors.grey)));
    });
  });
}
