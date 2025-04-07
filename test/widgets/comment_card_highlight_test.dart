import 'package:flutter/material.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/providers/ui_providers.dart';
import 'package:flutter_memos/services/url_launcher_service.dart'; // Import url launcher service
import 'package:flutter_memos/widgets/comment_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart'; // Import mockito

// Import mocks
import '../services/url_launcher_service_test.mocks.dart'; // For MockUrlLauncherService


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
        // Ensure the theme uses the exact colors from CommentCard for highlight
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          // Explicitly define teal colors used in CommentCard
          tertiary: Colors.teal,
          tertiaryContainer: Colors.teal.shade50,
        ),
        cardColor: Colors.white, // Default card color
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
          outline: Colors.grey.shade600,
          // Explicitly define dark theme teal colors used in CommentCard
          tertiary: Colors.tealAccent,
          tertiaryContainer: Colors.teal.shade800.withAlpha(128),
        ),
        cardColor: const Color(0xFF222222), // Default dark card color
      ),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('CommentCard shows highlight when ID matches provider state', (
    WidgetTester tester,
  ) async {
    // Create a test comment
    final testComment = Comment(
      id: 'test-comment-id',
      content: 'Test comment content',
      createTime: DateTime.now().millisecondsSinceEpoch,
    );

    // Set up a ProviderScope with highlight ID matching the comment
    await tester.pumpWidget(
      buildTestableWidget(
        CommentCard(comment: testComment, memoId: 'test-memo-id'),
        highlightedCommentId: testComment.id,
      ),
    );

    // IMPORTANT: Pump only once initially to render the highlighted state.
    await tester.pump();

    // Find the Card within the CommentCard
    final cardFinder = find.descendant(
      of: find.byType(CommentCard),
      matching: find.byType(Card),
    );
    expect(cardFinder, findsOneWidget);

    // --- Assert Highlighted State ---
    final card = tester.widget<Card>(cardFinder);
    final theme = Theme.of(tester.element(cardFinder)); // Get theme context

    // Define expected highlight styles based on theme brightness
    final Color expectedHighlightColor;
    final BorderSide expectedHighlightBorder;

    if (theme.brightness == Brightness.dark) {
      expectedHighlightColor = Colors.teal.shade800.withAlpha(128);
      expectedHighlightBorder = const BorderSide(
        color: Colors.tealAccent,
        width: 2,
      );
    } else {
      expectedHighlightColor = Colors.teal.shade50;
      expectedHighlightBorder = const BorderSide(color: Colors.teal, width: 2);
    }

    // Assert background color
    expect(
      card.color,
      expectedHighlightColor,
      reason:
          'Highlighted background color mismatch (Theme: ${theme.brightness})',
    );

    // Assert border properties
    final actualBorder = (card.shape as RoundedRectangleBorder).side;
    expect(
      actualBorder.width,
      expectedHighlightBorder.width,
      reason: 'Highlighted border width mismatch (Theme: ${theme.brightness})',
    );
    expect(
      actualBorder.color,
      expectedHighlightBorder.color,
      reason: 'Highlighted border color mismatch (Theme: ${theme.brightness})',
    );
    expect(
      actualBorder.style,
      BorderStyle.solid, // Expect a solid border
      reason: 'Highlighted border style mismatch (Theme: ${theme.brightness})',
    );

    // --- Assert Reset State ---
    // Now pump and settle to allow the post-frame callback to execute and reset the highlight
    await tester.pumpAndSettle();

    // Get the card again AFTER the reset pump and verify it's no longer highlighted
    final cardAfterCallback = tester.widget<Card>(cardFinder);
    final borderAfterCallback =
        (cardAfterCallback.shape as RoundedRectangleBorder).side;
    final defaultCardColor =
        theme.brightness == Brightness.dark
            ? const Color(0xFF222222)
            : Colors.white;

    // Assert background color is back to default
    expect(
      cardAfterCallback.color,
      defaultCardColor,
      reason:
          'Card background color should reset to default (Theme: ${theme.brightness})',
    );

    // Assert border is reset (BorderSide.none or width 0)
    expect(
      borderAfterCallback == BorderSide.none ||
          borderAfterCallback.width == 0.0,
      isTrue,
      reason:
          'Border should be reset (BorderSide.none or width 0.0) after highlight is cleared',
    );
  });

  testWidgets('CommentCard shows normal styling when not highlighted', (
    WidgetTester tester,
  ) async {
    // Create a test comment
    final testComment = Comment(
      id: 'test-comment-id',
      content: 'Test comment content',
      createTime: DateTime.now().millisecondsSinceEpoch,
    );

    // Create mock
    final mockUrlLauncherService = MockUrlLauncherService();
    when(mockUrlLauncherService.launch(any)).thenAnswer((_) async => true);

    // Set up a ProviderScope with no highlight
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          highlightedCommentIdProvider.overrideWith((_) => null),
          urlLauncherServiceProvider.overrideWithValue(
            mockUrlLauncherService,
          ), // Add override
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CommentCard(comment: testComment, memoId: 'test-memo-id'),
          ),
        ),
      ),
    );

    // Find the Card within the CommentCard
    final cardFinder = find.descendant(
      of: find.byType(CommentCard),
      matching: find.byType(Card),
    );
    expect(cardFinder, findsOneWidget);

    // Check that the card does NOT have highlighted style
    final card = tester.widget<Card>(cardFinder);
    final expectedHighlightBorder = const BorderSide(
      color: Colors.teal,
      width: 2,
    );

    // Assert that the border does NOT match the highlight border
    expect(
      (card.shape as RoundedRectangleBorder).side,
      isNot(equals(expectedHighlightBorder)),
      reason: 'Card should not have highlight border when not highlighted',
    );
  });
}
