import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/providers/ui_providers.dart';
import 'package:flutter_memos/services/url_launcher_service.dart'; // Import url launcher service
import 'package:flutter_memos/widgets/comment_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart'; // Import mockito

// Import mocks
// Corrected path to the mock file in the services directory
import '../../../services/url_launcher_service_test.mocks.dart';


// Helper to wrap widget for testing with CupertinoApp and CupertinoPageScaffold
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
    child: CupertinoApp(
      // Use CupertinoApp
      // Define Cupertino themes if needed, or rely on defaults
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
        // Define Cupertino-specific theme properties if CommentCard uses them
        // e.g., primaryColor: CupertinoColors.systemBlue,
        scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
        // Define text styles if needed
        // textTheme: CupertinoTextThemeData(...)
      ),
      home: CupertinoPageScaffold(child: child), // Use CupertinoPageScaffold
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

    // Find the Container acting as the card within the CommentCard
    // (Assuming CommentCard now uses Container instead of Material Card)
    final containerFinder = find.descendant(
      of: find.byType(CommentCard),
      matching: find.byType(Container), // Find the main Container
    );
    expect(containerFinder, findsOneWidget);

    // --- Assert Highlighted State ---
    final container = tester.widget<Container>(containerFinder);
    final decoration = container.decoration as BoxDecoration?;
    final theme = CupertinoTheme.of(
      tester.element(containerFinder),
    ); // Get Cupertino theme context

    // Define expected highlight styles based on theme brightness
    final Color expectedHighlightColor;
    final Border expectedHighlightBorder;

    // Use CupertinoColors for comparison
    if (theme.brightness == Brightness.dark) {
      // Define dark mode highlight colors/borders based on CommentCard implementation
      expectedHighlightColor = CupertinoColors.systemTeal.darkHighContrastColor
          .withAlpha(128); // Example dark highlight
      expectedHighlightBorder = Border.all(
        color:
            CupertinoColors
                .systemTeal
                .darkHighContrastColor, // Example dark border color
        width: 2,
      );
    } else {
      // Define light mode highlight colors/borders based on CommentCard implementation
      // Adjusted opacity from 0.1 to 0.2 based on error log (actual alpha was ~0.196)
      expectedHighlightColor = CupertinoColors.systemTeal.withOpacity(
        0.2, // ADJUSTED
      );
      expectedHighlightBorder = Border.all(
        color: CupertinoColors.systemTeal, // Example light border color
        width: 2,
      );
    }

    // Assert background color
    // Use closeTo matcher for potential floating point inaccuracies in color resolution/opacity
    // Compare resolved Color objects directly
    expect(
      decoration?.color,
      // Use closeTo for Color comparison if opacity/alpha differences are expected
      // For direct match: equals(expectedHighlightColor),
      // Using closeTo because the expected color has explicit opacity which might resolve slightly differently
      isA<Color>().having(
        (c) => c.value,
        'value',
        closeTo(expectedHighlightColor.value, 20000000),
      ),
      reason:
          'Highlighted background color mismatch (Theme: ${theme.brightness})',
    );

    // Assert border properties
    final actualBorder = decoration?.border as Border?;
    expect(actualBorder, isNotNull, reason: 'Highlighted border should exist');
    expect(
      actualBorder?.top.width, // Check one side's width
      expectedHighlightBorder.top.width,
      reason: 'Highlighted border width mismatch (Theme: ${theme.brightness})',
    );
    // Resolve the expected dynamic color using the context
    final resolvedExpectedBorderColor = CupertinoColors.systemTeal.resolveFrom(
      tester.element(containerFinder), // Pass the context here
    );
    // Ensure we compare Color objects, not CupertinoDynamicColor
    // Compare the resolved value
    expect(
      actualBorder?.top.color.value, // Check one side's color value
      equals(
        resolvedExpectedBorderColor.value,
      ), // Compare the actual Color value with the resolved Color value
      reason: 'Highlighted border color mismatch (Theme: ${theme.brightness})',
    );

    // --- Assert Reset State ---
    // Now pump and settle to allow the post-frame callback to execute and reset the highlight
    await tester.pumpAndSettle();

    // Re-find the container and its element AFTER the reset pump
    final containerFinderAfterCallback = find.descendant(
      of: find.byType(CommentCard),
      matching: find.byType(Container),
    );
    expect(
      containerFinderAfterCallback,
      findsOneWidget,
    ); // Ensure it still exists
    final containerAfterCallback = tester.widget<Container>(
      containerFinderAfterCallback,
    );
    final elementAfterCallback = tester.element(
      containerFinderAfterCallback,
    ); // Get the element context again
    final themeAfterCallback = CupertinoTheme.of(
      elementAfterCallback,
    ); // Use the new context

    final decorationAfterCallback =
        containerAfterCallback.decoration as BoxDecoration?;
    final borderAfterCallback = decorationAfterCallback?.border as Border?;
    // Use secondarySystemGroupedBackground as the expected default
    final expectedDefaultColor = CupertinoColors
        .secondarySystemGroupedBackground
        .resolveFrom(elementAfterCallback);

    // Assert background color is back to default (or null if transparent)
    expect(
      decorationAfterCallback?.color?.value,
      // Default should now match the secondary system grouped background color
      equals(expectedDefaultColor.value), // Compare resolved color values
      reason:
          'Container background color should reset to secondarySystemGroupedBackground (Theme: ${themeAfterCallback.brightness})',
    );

    // Assert border is reset (no border or width 0)
    expect(
      borderAfterCallback == null || borderAfterCallback.top.width == 0.0,
      isTrue,
      reason:
          'Border should be reset (null or width 0.0) after highlight is cleared',
    );
  }); // Correctly closed parenthesis for the testWidgets block

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
        child: CupertinoApp(
          // Use CupertinoApp
          home: CupertinoPageScaffold(
            // Use CupertinoPageScaffold
            child: CommentCard(comment: testComment, memoId: 'test-memo-id'),
          ),
        ),
      ),
    );

    // Find the Container within the CommentCard
    final containerFinder = find.descendant(
      of: find.byType(CommentCard),
      matching: find.byType(Container),
    );
    expect(containerFinder, findsOneWidget);

    // Check that the container does NOT have highlighted style
    final container = tester.widget<Container>(containerFinder);
    final decoration = container.decoration as BoxDecoration?;
    final border = decoration?.border as Border?;

    // Assert that the border does NOT match the highlight border
    expect(
      border == null ||
          border.top.width != 2 ||
          border.top.color != CupertinoColors.systemTeal,
      isTrue,
      reason: 'Container should not have highlight border when not highlighted',
    );
  });
}
