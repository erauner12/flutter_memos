import 'package:flutter/material.dart';
import 'package:flutter_memos/main.dart' as app;
// Add imports for Memo model and ApiService
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  // Initialize integration test binding
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // List to store IDs of memos created during the test for cleanup
  // Note: Cleanup might not be strictly necessary here as the test deletes the memo,
  // but it's good practice in case the deletion step fails.
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
      createdMemoIds.add(createdMemo.id); // Store ID for potential cleanup
      return createdMemo;
    } catch (e, stackTrace) {
      debugPrint(
        '[Test Setup] Error creating memo programmatically: $e\n$stackTrace',
      );
      fail('Failed to create memo programmatically: $e');
    }
  }

  group('Memo Create and Delete Integration Tests', () {
    // Cleanup after all tests in the group (optional but good practice)
    tearDownAll(() async {
      if (createdMemoIds.isNotEmpty) {
        debugPrint(
          '[Test Cleanup] Deleting ${createdMemoIds.length} potentially remaining test memos...',
        );
        final apiService = ApiService();
        try {
          await Future.wait(
            createdMemoIds.map((id) => apiService.deleteMemo(id)),
          );
          debugPrint(
            '[Test Cleanup] Successfully deleted remaining test memos.',
          );
        } catch (e) {
          debugPrint('[Test Cleanup] Error deleting remaining test memos: $e');
        }
        createdMemoIds.clear();
      }
    });

    testWidgets('Create a new memo and delete it by swiping', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Find the initial count of memos for comparison later (optional)
      final initialCount = find.byType(MemoCard).evaluate().length;
      debugPrint('Initial memo count: $initialCount');

      // Create a new memo PROGRAMMATICALLY
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final testMemoContent = 'Test Memo for Swipe Delete - $timestamp';
      final createdMemo = await createMemoProgrammatically(
        tester,
        testMemoContent,
      );
      expect(createdMemo, isNotNull, reason: 'Failed to create test memo');
      // Remove the created ID from cleanup list immediately since this test WILL delete it.
      createdMemoIds.remove(createdMemo!.id);

      // Refresh the list to show the newly created memo
      debugPrint('[Test Action] Simulating pull-to-refresh...');
      final listFinder = find.byType(ListView);
      expect(listFinder, findsOneWidget, reason: 'ListView not found');
      await tester.fling(listFinder, const Offset(0.0, 400.0), 1000.0);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      debugPrint('[Test Action] Pull-to-refresh complete.');

      // Verify the memo card is displayed
      final memoCardFinder = find.widgetWithText(MemoCard, testMemoContent);
      expect(
        memoCardFinder,
        findsOneWidget,
        reason: 'Created memo card not found',
      );
      final afterCreateCount = find.byType(MemoCard).evaluate().length;
      debugPrint('Memo count after creation: $afterCreateCount');

      // Find the Card widget associated with the memo to swipe
      final cardFinder = find.ancestor(
        of: find.textContaining(testMemoContent),
        matching: find.byType(
          Card,
        ), // Target the Card which is often the Slidable container
      );
      expect(
        cardFinder,
        findsOneWidget,
        reason: 'Card containing memo text not found',
      );

      // Find the slidable action to delete by dragging and then tapping Delete
      await tester.drag(cardFinder, const Offset(-300, 0)); // Swipe left
      await tester.pumpAndSettle();

      // Wait for animations to complete
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Find and tap the Delete button that appears after sliding
      final deleteButtonFinder = find.text('Delete');
      expect(deleteButtonFinder, findsOneWidget, reason: 'Delete button not found after sliding');
      await tester.tap(deleteButtonFinder);
      await tester.pumpAndSettle();

      // Tap "Delete" on the confirmation dialog
      final alertDialogFinder = find.byType(AlertDialog);
      expect(
        alertDialogFinder,
        findsOneWidget,
        reason: 'Alert dialog not found after tapping Delete',
      );

      // Find the Delete button within the dialog
      final deleteConfirmButtonFinder = find.descendant(
        of: alertDialogFinder,
        matching: find.text('Delete'),
      );
      expect(
        deleteConfirmButtonFinder,
        findsOneWidget,
        reason: 'Delete button not found in dialog',
      );

      // Tap the delete button
      await tester.tap(deleteConfirmButtonFinder);
      await tester.pumpAndSettle();

      // Wait longer for deletion to complete and UI to refresh
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      
      // Force an additional pump with delay to ensure all animations and state updates complete
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Log the counts for debugging
      final afterDeleteCount = find.byType(MemoCard).evaluate().length;
      debugPrint('Memo count after deletion: $afterDeleteCount');
      
      // Check if our memo is still visible anywhere - add more debugging
      bool memoFound = find.text(testMemoContent).evaluate().isNotEmpty;
      if (memoFound) {
        debugPrint(
          'WARNING: Memo content still found in the UI after deletion!',
        );

        // Log all visible memos for debugging
        final allVisibleMemoCards = find.byType(MemoCard);
        debugPrint(
          'Number of memo cards visible: ${allVisibleMemoCards.evaluate().length}',
        );

        // Try to find our specific text again and get more details
        final specificTextFinder = find.text(testMemoContent);
        debugPrint(
          'Number of instances of memo text: ${specificTextFinder.evaluate().length}',
        );
      } else {
        debugPrint(
          'SUCCESS: Memo content no longer found in the UI after deletion',
        );
      }
      
      // If not found immediately, try scrolling to find it
      if (!memoFound) {
        debugPrint('Checking if memo is really gone by scrolling...');
        final listViewFinder = find.byType(ListView);

        // Only try scrolling if there are memos to scroll through
        if (find.byType(MemoCard).evaluate().isNotEmpty &&
            listViewFinder.evaluate().isNotEmpty) {
          for (int i = 0; i < 3; i++) {
            await tester.drag(listViewFinder.first, const Offset(0, -300));
            await tester.pumpAndSettle();

            // Check after each scroll if we can find our memo
            memoFound = find.text(testMemoContent).evaluate().isNotEmpty;
            if (memoFound) {
              debugPrint('Found memo after scrolling $i times - deletion failed');
              break;
            }
          }
        }
      }
      
      // Final verification - memo should not be found
      expect(memoFound, isFalse, reason: 'Deleted memo is still visible');
      
      // Optional: Check for a snackbar confirmation
      final snackbarFinder = find.descendant(
        of: find.byType(SnackBar),
        matching: find.textContaining('deleted'),
      );
      
      // Just log this result, don't fail the test if snackbar isn't shown
      if (snackbarFinder.evaluate().isEmpty) {
        debugPrint('Warning: Deletion confirmation snackbar not found');
      } else {
        debugPrint('Found deletion confirmation snackbar');
      }
    });
  });
}
