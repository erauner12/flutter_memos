import 'package:flutter/gestures.dart'; // Import for kPressTimeout
import 'package:flutter/material.dart';
import 'package:flutter_memos/models/memo.dart'; // Import Memo model
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Helper to wrap widget for testing with MaterialApp and Scaffold
Widget buildTestableWidget(Widget child) {
  return ProviderScope( // Include ProviderScope if MemoCard uses Riverpod internally
    child: MaterialApp(
      // Define both light and dark themes to test against
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        cardColor: Colors.white, // Default light theme card color
        // Define other relevant theme properties if needed
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
          outline: Colors.grey.shade600, // Example outline color
        ),
        cardColor: const Color(0xFF2C2C2C), // Example dark theme card color
        // Define other relevant theme properties if needed
      ),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  // Create a dummy memo object to pass to MemoCard
  final testMemo = Memo(
    id: 'test-id-123',
    content: 'This is the test memo content.',
    updateTime: DateTime.now().toIso8601String(),
    // Add other required fields if MemoCard uses them
  );

  group('MemoCard Visual Selection State', () {
    testWidgets('renders with default style when not selected (Light Theme)', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(buildTestableWidget(
        // Explicitly set light theme for this test
        Theme(
          data: ThemeData.light(),
          child: MemoCard(
            // Pass the Memo object using the named parameter 'memo'
            id: testMemo.id,
            content: testMemo.content,
            updatedAt: testMemo.updateTime,
            isSelected: false,
          ),
        ),
      ));

      // Act
      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);
      final cardWidget = tester.widget<Card>(cardFinder);
      // theme variable not needed for this assertion
      // final theme = Theme.of(tester.element(cardFinder));

      // Assert: Check against expected default colors/borders for light theme
      // In light mode, color is null which allows Card to use theme.cardColor internally
      const expectedDefaultBorder = BorderSide.none;

      expect(
        cardWidget.color,
        isNull,
        reason: 'Default background color property should be null (Light)',
      );
      expect((cardWidget.shape as RoundedRectangleBorder).side, expectedDefaultBorder, reason: 'Default border style mismatch (Light)');
    });

    testWidgets('renders with default style when not selected (Dark Theme)', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(buildTestableWidget(
        // Explicitly set dark theme for this test
        Theme(
          data: ThemeData.dark().copyWith(
            // Ensure specific colors used in MemoCard are defined
             colorScheme: const ColorScheme.dark(
               outline: Colors.grey, // Example outline
             ),
          ),
          child: MemoCard(
            id: testMemo.id,
            content: testMemo.content,
            updatedAt: testMemo.updateTime,
            isSelected: false,
          ),
        ),
      ));

      // Act
      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);
      final cardWidget = tester.widget<Card>(cardFinder);

      // Assert: Check against expected default colors/borders for dark theme
      const expectedDefaultColor = Color(0xFF262626);
      final expectedDefaultBorder = BorderSide(color: Colors.grey[850]!, width: 0.5);

      expect(cardWidget.color, expectedDefaultColor, reason: 'Default background color mismatch (Dark)');
      expect((cardWidget.shape as RoundedRectangleBorder).side, expectedDefaultBorder, reason: 'Default border style mismatch (Dark)');
    });

    testWidgets('renders with selected style when selected (Light Theme)', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(buildTestableWidget(
        Theme(
          data: ThemeData.light().copyWith(
             colorScheme: ColorScheme.light(
               outline: Colors.grey.shade400, // Example light outline
             ),
          ),
          child: MemoCard(
            id: testMemo.id,
            content: testMemo.content,
            updatedAt: testMemo.updateTime,
            isSelected: true, // Set isSelected to true
          ),
        ),
      ));

      // Act
      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);
      final cardWidget = tester.widget<Card>(cardFinder);
      final theme = Theme.of(tester.element(cardFinder));

      // Assert: Check against the specific selected style colors/borders for light theme
      final expectedSelectedColor = Colors.grey.shade300;
      final expectedSelectedBorder = BorderSide(
        color: theme.colorScheme.outline.withAlpha(
          (0.5 * 255).round(),
        ), // Use withAlpha
        width: 1,
      );

      expect(cardWidget.color, expectedSelectedColor, reason: 'Selected background color mismatch (Light)');
      expect((cardWidget.shape as RoundedRectangleBorder).side, expectedSelectedBorder, reason: 'Selected border style mismatch (Light)');
    });

    testWidgets('renders with selected style when selected (Dark Theme)', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(buildTestableWidget(
        Theme(
          data: ThemeData.dark().copyWith(
             colorScheme: const ColorScheme.dark(
               outline: Colors.grey, // Example dark outline
             ),
          ),
          child: MemoCard(
            id: testMemo.id,
            content: testMemo.content,
            updatedAt: testMemo.updateTime,
            isSelected: true, // Set isSelected to true
          ),
        ),
      ));

      // Act
      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);
      final cardWidget = tester.widget<Card>(cardFinder);
      final theme = Theme.of(tester.element(cardFinder));

      // Assert: Check against the specific selected style colors/borders for dark theme
      final expectedSelectedColor = Colors.grey.shade700.withAlpha(
        (0.6 * 255).round(),
      ); // Use withAlpha
      final expectedSelectedBorder = BorderSide(
        color: theme.colorScheme.outline.withAlpha(
          (0.5 * 255).round(),
        ), // Use withAlpha
        width: 1,
      );

      expect(cardWidget.color, expectedSelectedColor, reason: 'Selected background color mismatch (Dark)');
      expect((cardWidget.shape as RoundedRectangleBorder).side, expectedSelectedBorder, reason: 'Selected border style mismatch (Dark)');
    });

    testWidgets('shows InkWell default highlight/splash on press', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(buildTestableWidget(
        MemoCard(
          id: testMemo.id,
          content: testMemo.content,
          updatedAt: testMemo.updateTime,
          isSelected: false, // Test on a non-selected card
        ),
      ));
      final inkWellFinder = find.byType(InkWell);
      expect(inkWellFinder, findsOneWidget);

      // Act: Simulate a press
      // Act: Simulate a press
      final Offset center = tester.getCenter(inkWellFinder);
      final TestGesture gesture = await tester.startGesture(center);
      await tester.pump(kPressTimeout); // Hold long enough for highlight/splash
      // Assert: Check that InkWell's highlight/splash colors are NOT transparent
      // We check for null because the default behavior uses null, letting Material handle it.
      // If they were explicitly set to Colors.transparent, this test would fail.
      final inkWell = tester.widget<InkWell>(inkWellFinder);
      expect(inkWell.highlightColor, isNull, reason: 'Highlight color should use default (null), not transparent');
      expect(inkWell.splashColor, isNull, reason: 'Splash color should use default (null), not transparent');

      // Clean up gesture
      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}
