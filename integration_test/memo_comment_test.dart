import 'package:flutter/material.dart';
import 'package:flutter_memos/main.dart' as app;
// Add imports for Memo model and ApiService
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_memos/widgets/capture_utility.dart';
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

  group('Memo Comment Integration Tests', () {
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

    testWidgets('Create a memo, add a comment, and verify it appears', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // STEP 1: Create a new memo first (Programmatically)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final testMemoContent = 'Test Memo for Comments - $timestamp';
      final createdMemo = await createMemoProgrammatically(
        tester,
        testMemoContent,
      );
      expect(createdMemo, isNotNull, reason: 'Failed to create test memo');

      // Refresh the list to show the newly created memo
      debugPrint('[Test Action] Simulating pull-to-refresh...');
      final listFinder = find.byType(ListView);
      expect(listFinder, findsOneWidget, reason: 'ListView not found');
      await tester.fling(listFinder, const Offset(0.0, 400.0), 1000.0);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      debugPrint('[Test Action] Pull-to-refresh complete.');

      // Find our specific memo card by its content
      final memoCardFinder = find.widgetWithText(MemoCard, testMemoContent);
      expect(
        memoCardFinder,
        findsOneWidget,
        reason: 'Created memo card not found in list',
      );

      // STEP 2: Navigate to memo detail screen
      await tester.tap(memoCardFinder);
      await tester.pumpAndSettle();

      // Verify we're on the detail screen
      expect(find.text('Memo Detail'), findsOneWidget, reason: 'Not on memo detail screen');

      // STEP 3: Add a comment (Keep UI interaction for comment adding)
      final commentTimestamp = DateTime.now().millisecondsSinceEpoch;
      final testCommentText = 'Test Comment - $commentTimestamp';

      // Find the comment capture utility
      final commentCaptureUtility = find.byType(CaptureUtility);
      expect(commentCaptureUtility, findsOneWidget, reason: 'Comment CaptureUtility not found');
      
      // Tap on the placeholder text to expand
      await tester.tap(find.text('Add a comment...'));
      await tester.pumpAndSettle();
      
      // Type the comment text
      final commentTextFieldFinder = find.byType(TextField);
      expect(commentTextFieldFinder, findsAtLeastNWidgets(1), reason: 'Comment TextField not found');
      await tester.enterText(commentTextFieldFinder.first, testCommentText);
      await tester.pumpAndSettle();
      
      // Tap the "Add Comment" button
      final addCommentButtonFinder = find.text('Add Comment');
      expect(addCommentButtonFinder, findsOneWidget, reason: 'Add Comment button not found');
      await tester.tap(addCommentButtonFinder);
      await tester.pumpAndSettle();
      
      // Wait for comment to be added
      await tester.pump(const Duration(seconds: 1));
      
      // STEP 4: Verify the comment appears
      
      // Find the comment text in the UI
      final commentTextFinder = find.text(testCommentText);
      expect(commentTextFinder, findsOneWidget, reason: 'Added comment not found');
      
      // Verify the success snackbar (optional)
      final commentSnackbarFinder = find.text('Comment added successfully');
      if (commentSnackbarFinder.evaluate().isNotEmpty) {
        debugPrint('Found comment added confirmation snackbar');
      }
      
      // STEP 5: Go back to the main screen
      
      // Find and tap the back button
      final backButtonFinder = find.byType(BackButton);
      expect(backButtonFinder, findsOneWidget, reason: 'Back button not found');
      await tester.tap(backButtonFinder);
      await tester.pumpAndSettle();
      
      // Verify we're back on the main screen
      expect(find.text('Memos'), findsOneWidget, reason: 'Not back on main screen');
      
      debugPrint('Comment creation test completed successfully');
    });
  });
}
