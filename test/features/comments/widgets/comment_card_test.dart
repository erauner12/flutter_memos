import 'package:flutter/gestures.dart'; // Import for kPressTimeout
import 'package:flutter/material.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/providers/ui_providers.dart';
import 'package:flutter_memos/services/url_launcher_service.dart'; // Import url launcher service
import 'package:flutter_memos/widgets/comment_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart'; // Import mockito

// Import mocks
// Corrected path to the mock file in the core/services directory
import '../../../core/services/url_launcher_service_test.mocks.dart';

// Helper to wrap widget for testing with MaterialApp and Scaffold
Widget buildTestableWidget(Widget child, {String? highlightedCommentId}) {
  // Create mock inside helper or pass it in
  final mockUrlLauncherService = MockUrlLauncherService();
  when(mockUrlLauncherService.launch(any)).thenAnswer((_) async => true);

  return ProviderScope(
    overrides: [
      urlLauncherServiceProvider.overrideWithValue(
        mockUrlLauncherService,
      ), // Add override
      // Override highlightedCommentIdProvider if a value is provided
      if (highlightedCommentId != null)
        highlightedCommentIdProvider.overrideWith(
          (ref) => highlightedCommentId,
        ),
    ],
    child: MaterialApp(
      // Define both light and dark themes to test against
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        cardColor: Colors.white,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
          outline: Colors.grey.shade600,
        ),
        cardColor: const Color(0xFF2C2C2C),
      ),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  // Create a dummy comment object to pass to CommentCard
  final testComment = Comment(
    id: 'test-comment-123',
    content: 'This is a test comment.',
    createTime: DateTime.now().millisecondsSinceEpoch,
  );

  group('CommentCard Visual Selection State', () {
    testWidgets('renders with default style when not selected (Light Theme)', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(buildTestableWidget(
        Theme(
          data: ThemeData.light(),
          child: CommentCard(
            comment: testComment,
            memoId: 'test-memo-456',
            isSelected: false,
          ),
        ),
      ));

      // Act
      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);
      final cardWidget = tester.widget<Card>(cardFinder);

      // Assert: Check against expected default colors/borders for light theme
      expect(cardWidget.color, Colors.white, reason: 'Default background color mismatch (Light)');
      expect((cardWidget.shape as RoundedRectangleBorder).side, BorderSide.none,
        reason: 'Default border style mismatch (Light)');
    });

    testWidgets('renders with default style when not selected (Dark Theme)', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(buildTestableWidget(
        Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              outline: Colors.grey,
            ),
          ),
          child: CommentCard(
            comment: testComment,
            memoId: 'test-memo-456',
            isSelected: false,
          ),
        ),
      ));

      // Act
      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);
      final cardWidget = tester.widget<Card>(cardFinder);

      // Assert: Check against expected default colors/borders for dark theme
      expect(cardWidget.color, const Color(0xFF222222),
        reason: 'Default background color mismatch (Dark)');
      expect((cardWidget.shape as RoundedRectangleBorder).side, BorderSide.none,
        reason: 'Default border style mismatch (Dark)');
    });

    testWidgets('renders with selected style when selected (Light Theme)', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(buildTestableWidget(
        Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              outline: Colors.grey.shade400,
            ),
          ),
          child: CommentCard(
            comment: testComment,
            memoId: 'test-memo-456',
            isSelected: true,
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
        color: theme.colorScheme.outline.withOpacity(0.5),
        width: 1,
      );

      expect(cardWidget.color, expectedSelectedColor,
        reason: 'Selected background color mismatch (Light)');
      expect((cardWidget.shape as RoundedRectangleBorder).side.color, expectedSelectedBorder.color,
        reason: 'Selected border color mismatch (Light)');
      expect((cardWidget.shape as RoundedRectangleBorder).side.width, expectedSelectedBorder.width,
        reason: 'Selected border width mismatch (Light)');
    });

    testWidgets('renders with selected style when selected (Dark Theme)', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(buildTestableWidget(
        Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              outline: Colors.grey,
            ),
          ),
          child: CommentCard(
            comment: testComment,
            memoId: 'test-memo-456',
            isSelected: true,
          ),
        ),
      ));

      // Act
      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);
      final cardWidget = tester.widget<Card>(cardFinder);
      final theme = Theme.of(tester.element(cardFinder));

      // Assert: Check against the specific selected style colors/borders for dark theme
      // Allow slight flexibility in the color comparison due to opacity calculations
      final expectedSelectedColor = Colors.grey.shade700.withOpacity(0.6);
      final expectedSelectedBorder = BorderSide(
        color: theme.colorScheme.outline.withOpacity(0.5),
        width: 1,
      );

      expect(cardWidget.color?.value, closeTo(expectedSelectedColor.value, 10),
        reason: 'Selected background color mismatch (Dark)');
      expect((cardWidget.shape as RoundedRectangleBorder).side.color.value,
        closeTo(expectedSelectedBorder.color.value, 10),
        reason: 'Selected border color mismatch (Dark)');
      expect((cardWidget.shape as RoundedRectangleBorder).side.width, expectedSelectedBorder.width,
        reason: 'Selected border width mismatch (Dark)');
    });

    testWidgets('renders with highlighted style when highlighted (Light Theme)', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(buildTestableWidget(
        Theme(
          data: ThemeData.light(),
          child: CommentCard(
            comment: testComment,
            memoId: 'test-memo-456',
            isSelected: false, // Not selected, but highlighted
          ),
        ),
        highlightedCommentId: testComment.id, // Set the highlighted comment ID
      ));

      // Act
      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);
      final cardWidget = tester.widget<Card>(cardFinder);

      // Assert: Check against expected highlighted colors/borders for light theme
      expect(cardWidget.color, Colors.teal.shade50,
        reason: 'Highlighted background color mismatch (Light)');
      expect((cardWidget.shape as RoundedRectangleBorder).side,
        const BorderSide(color: Colors.teal, width: 2),
        reason: 'Highlighted border style mismatch (Light)');
    });

    testWidgets('highlighted style overrides selected style', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(buildTestableWidget(
        Theme(
          data: ThemeData.light(),
          child: CommentCard(
            comment: testComment,
            memoId: 'test-memo-456',
            isSelected: true, // Selected AND highlighted
          ),
        ),
        highlightedCommentId: testComment.id, // Set the highlighted comment ID
      ));

      // Act
      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);
      final cardWidget = tester.widget<Card>(cardFinder);

      // Assert: Should use highlighted style, not selected style
      expect(cardWidget.color, Colors.teal.shade50,
        reason: 'Highlight should override selection (background color)');
      expect((cardWidget.shape as RoundedRectangleBorder).side,
        const BorderSide(color: Colors.teal, width: 2),
        reason: 'Highlight should override selection (border style)');
    });

    testWidgets('InkWell allows default highlight/splash on press', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(buildTestableWidget(
        CommentCard(
          comment: testComment,
          memoId: 'test-memo-456',
          isSelected: false,
        ),
      ));
      final inkWellFinder = find.byType(InkWell);
      expect(inkWellFinder, findsOneWidget);

      // Act: Simulate a press
      final Offset center = tester.getCenter(inkWellFinder);
      final TestGesture gesture = await tester.startGesture(center);
      await tester.pump(kPressTimeout); // Hold long enough for highlight/splash

      // Assert: Check that InkWell's highlight/splash colors are NOT transparent
      final inkWell = tester.widget<InkWell>(inkWellFinder);
      expect(inkWell.highlightColor, isNull,
        reason: 'Highlight color should use default (null), not transparent');
      expect(inkWell.splashColor, isNull,
        reason: 'Splash color should use default (null), not transparent');

      // Clean up gesture
      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}
