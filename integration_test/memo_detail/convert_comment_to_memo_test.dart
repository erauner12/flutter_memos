import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter_memos/main.dart' as app;
// Add imports for Memo model and ApiService
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_memos/widgets/capture_utility.dart';
import 'package:flutter_memos/widgets/comment_card.dart';
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  // Initialize integration test binding
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // List to store IDs of memos created during the test for cleanup
  final List<String> createdMemoIds = [];

  // Helper function to create a memo PROGRAMMATICALLY and return it
  Future<Memo?> createMemoProgrammatically(
    WidgetTester tester,
    String content,
  ) async {
    debugPrint(
      '[Test Setup] Attempting to create memo programmatically: "$content"',
    );
    try {
      final apiService = ApiService();
      final newMemo = Memo(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        content: content,
        visibility: 'PUBLIC',
      );
      final createdMemo = await apiService.createMemo(newMemo);
      debugPrint(
        '[Test Setup] Programmatic memo creation successful. ID: ${createdMemo.id}',
      );
      createdMemoIds.add(createdMemo.id); // Store ID for cleanup
      return createdMemo;
    } catch (e, stackTrace) {
      debugPrint(
        '[Test Setup] Error creating memo programmatically: $e\n$stackTrace',
      );
      fail('Failed to create memo programmatically: $e');
    }
  }

  group('Comment To Memo Integration Tests', () {
    // Cleanup after all tests in the group
    tearDownAll(() async {
      if (createdMemoIds.isNotEmpty) {
        debugPrint(
          '[Test Cleanup] Deleting ${createdMemoIds.length} test memos...',
        );
        final apiService = ApiService();
        try {
          await Future.wait(
            createdMemoIds.map((id) => apiService.deleteMemo(id)),
          );
          debugPrint('[Test Cleanup] Successfully deleted test memos.');
        } catch (e) {
          debugPrint('[Test Cleanup] Error deleting test memos: $e');
        }
        createdMemoIds.clear();
      }
    });

    testWidgets('Convert a comment to a memo and verify it appears', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // STEP 1: Create a new memo with a comment (Programmatically)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final testMemoContent = 'Test Memo for Comment Conversion - $timestamp';
      final createdMemo = await createMemoProgrammatically(
        tester,
        testMemoContent,
      );
      expect(createdMemo, isNotNull, reason: 'Failed to create test memo');

      // Refresh the list to show the newly created memo
      debugPrint('[Test Action] Simulating pull-to-refresh...');
      final listFinder = find.byType(Scrollable).first; // Use Scrollable
      expect(listFinder, findsOneWidget, reason: 'Scrollable list not found');
      await tester.fling(listFinder, const Offset(0.0, 400.0), 1000.0);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      debugPrint('[Test Action] Pull-to-refresh complete.');

      // Log the memo content we're looking for to help with debugging
      debugPrint('Looking for memo with content: $testMemoContent');

      // Find the MemoCard containing our test content
      final memoCardFinder = find.widgetWithText(MemoCard, testMemoContent);
      expect(
        memoCardFinder,
        findsOneWidget,
        reason: 'Created memo card not found in list',
      );

      // STEP 2: Navigate to memo detail screen
      await tester.tap(memoCardFinder);
      await tester.pumpAndSettle();

      // Verify we're on the detail screen (check CupertinoNavigationBar title)
      expect(
        find.descendant(
          of: find.byType(CupertinoNavigationBar),
          matching: find.text('Memo Detail'),
        ),
        findsOneWidget,
        reason: 'Not on memo detail screen',
      );

      // STEP 3: Add a comment (Keep UI interaction for comment adding)
      final commentTimestamp = DateTime.now().millisecondsSinceEpoch;
      final testCommentText = 'Test Comment to Convert to Memo - $commentTimestamp';

      // Find the comment capture utility
      final commentCaptureUtility = find.byType(CaptureUtility);
      expect(commentCaptureUtility, findsOneWidget, reason: 'Comment CaptureUtility not found');

      // Tap on the placeholder text to expand
      await tester.tap(find.text('Add a comment...'));
      await tester.pumpAndSettle();

      // Type the comment text
      final commentTextFieldFinder = find.byType(
        CupertinoTextField,
      ); // Use CupertinoTextField
      expect(
        commentTextFieldFinder,
        findsAtLeastNWidgets(1),
        reason: 'Comment CupertinoTextField not found',
      );
      await tester.enterText(commentTextFieldFinder.first, testCommentText);
      await tester.pumpAndSettle();

      // Tap the "Add Comment" button (assuming it's a CupertinoButton)
      final addCommentButtonFinder = find.widgetWithText(
        CupertinoButton,
        'Add Comment',
      ); // Use CupertinoButton
      expect(addCommentButtonFinder, findsOneWidget, reason: 'Add Comment button not found');
      await tester.tap(addCommentButtonFinder);
      await tester.pumpAndSettle();

      // Wait longer for comment to be added
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // STEP 4: Convert comment to memo

      // Find the comment card
      final commentTextFinder = find.text(testCommentText);
      expect(commentTextFinder, findsOneWidget, reason: 'Added comment not found');

      // Find the CommentCard containing our test content
      final commentCardFinder = find.ancestor(
        of: commentTextFinder.first,
        matching: find.byType(CommentCard),
      );
      expect(commentCardFinder, findsOneWidget, reason: 'CommentCard not found');

      // Long press to open context menu
      await tester.longPress(commentCardFinder);
      await tester.pumpAndSettle(); // Wait for CupertinoContextMenu animation

      // Find and tap the "Convert to Memo" option within the CupertinoContextMenu
      // The text might be inside a CupertinoContextMenuAction
      final convertToMemoFinder = find.widgetWithText(
        CupertinoContextMenuAction,
        'Convert to Memo',
      );
      expect(
        convertToMemoFinder,
        findsOneWidget,
        reason: 'Convert to Memo option not found in context menu',
      );
      await tester.tap(convertToMemoFinder);
      await tester.pumpAndSettle(); // Wait for action and menu dismissal

      // Wait longer for conversion and UI update
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Check for success message (accept either message since relation might fail but conversion succeeds)
      bool foundSuccessMessage = false;
      if (find.text('Comment converted to memo').evaluate().isNotEmpty) {
        foundSuccessMessage = true;
      } else if (find
          .textContaining('converted to memo')
          .evaluate()
          .isNotEmpty) {
        foundSuccessMessage = true;
      }

      expect(
        foundSuccessMessage,
        isTrue,
        reason: 'No conversion success message found',
      );

      // STEP 5: Go back to main screen and verify new memo

      // Find and tap the Cupertino back button
      final backButtonFinder = find.byType(CupertinoNavigationBarBackButton);
      expect(
        backButtonFinder,
        findsOneWidget,
        reason: 'Cupertino back button not found',
      );
      await tester.tap(backButtonFinder);
      await tester.pumpAndSettle();

      // Verify we're back on the main screen (check CupertinoNavigationBar title)
      expect(
        find.descendant(
          of: find.byType(CupertinoNavigationBar),
          matching: find.text('Memos'),
        ),
        findsOneWidget,
        reason: 'Not back on main screen',
      );

      // Wait longer for the new memo to appear after returning to the list
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Look for the new memo (which contains the comment text)
      // Need to find by partial text since the memo list might truncate content
      final newMemoText = testCommentText.substring(0, 20); // First part of comment text
      debugPrint(
        'Looking for converted memo with content starting with: $newMemoText',
      );
      final newMemoFinder = find.textContaining(newMemoText);

      expect(newMemoFinder, findsAtLeastNWidgets(1), reason: 'Newly created memo from comment not found');

      debugPrint('Comment to memo conversion test completed successfully');
    });
  });
}
