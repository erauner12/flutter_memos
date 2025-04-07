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

    // Create mock
    final mockUrlLauncherService = MockUrlLauncherService();
    when(mockUrlLauncherService.launch(any)).thenAnswer((_) async => true);

    // Set up a ProviderScope with highlight ID matching the comment
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          highlightedCommentIdProvider.overrideWith((_) => 'test-comment-id'),
          urlLauncherServiceProvider.overrideWithValue(
            mockUrlLauncherService,
          ), // Add override
        ],
        child: MaterialApp(
          // Use a custom theme that explicitly defines the colors used for highlighting
          theme: ThemeData(
            brightness: Brightness.light,
            useMaterial3: true,
            colorScheme: const ColorScheme.light(
              // Explicitly define the teal colors used for highlighting
              tertiary: Colors.teal, // Ensure tertiary is teal for border check
              tertiaryContainer: Color(0xFFE0F2F1), // Explicit highlight color
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
            colorScheme: ColorScheme.dark(
              tertiary: Colors.tealAccent,
              tertiaryContainer: Colors.teal.shade800.withAlpha(
                128,
              ), // Updated from withOpacity(0.5)
            ),
          ),
          home: Scaffold(
            body: CommentCard(comment: testComment, memoId: 'test-memo-id'),
          ),
        ),
      ),
    );
    // IMPORTANT: Just pump once after pumpWidget to render the initial frame.
    // Do not use pumpAndSettle() here, as it would execute the post-frame callback
    // that resets the highlight *before* we can check it.
    await tester.pump();

    // Find the Card within the CommentCard
    final cardFinder = find.descendant(
      of: find.byType(CommentCard),
      matching: find.byType(Card),
    );
    expect(cardFinder, findsOneWidget);

    // Check that the card has the highlighted style BEFORE the reset pump
    final card = tester.widget<Card>(cardFinder);
    final theme = Theme.of(tester.element(cardFinder)); // Get theme context

    // Define expected highlight styles based on theme brightness
    final BorderSide expectedHighlightBorder;

    if (theme.brightness == Brightness.dark) {
      expectedHighlightBorder = const BorderSide(
        color: Colors.tealAccent,
        width: 2,
      ); // Adjusted dark theme border
    } else {
      expectedHighlightBorder = const BorderSide(color: Colors.teal, width: 2);
    }

    // Compare border properties individually with more flexibility
    final actualBorder = (card.shape as RoundedRectangleBorder).side;

    // Check border width and style
    expect(
      actualBorder.width,
      expectedHighlightBorder.width,
      reason: 'Highlighted border width mismatch (Theme: ${theme.brightness})',
    );
    expect(
      actualBorder.style,
      BorderStyle.solid, // Expect a solid border
      reason: 'Highlighted border style mismatch (Theme: ${theme.brightness})',
    );

    // DO NOT pump again here. Assertions above check the highlighted state.

    // Now pump and settle to allow the post-frame callback to execute and reset the highlight
    await tester.pumpAndSettle();

    // Get the card again AFTER the reset pump and verify it's no longer highlighted
    final cardAfterCallback = tester.widget<Card>(cardFinder);
    final borderAfterCallback =
        (cardAfterCallback.shape as RoundedRectangleBorder).side;
    expect(
      // Check if the border is effectively none (either BorderSide.none or width 0)
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
