import 'package:flutter/material.dart';
import 'package:flutter_memos/main.dart' as app;
import 'package:flutter_memos/widgets/capture_utility.dart';
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  // Initialize integration test binding
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Memo Create and Delete Integration Tests', () {
    testWidgets('Create a new memo and delete it by swiping', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Find the initial count of memos for comparison later
      final initialMemoCards = find.byType(MemoCard);
      final initialCount = initialMemoCards.evaluate().length;
      debugPrint('Initial memo count: $initialCount');

      // Find and tap the CaptureUtility to expand it
      final captureUtilityFinder = find.byType(CaptureUtility);
      expect(captureUtilityFinder, findsOneWidget, reason: 'CaptureUtility not found');
      
      // Tap on the placeholder text to expand
      await tester.tap(find.text('Capture something ...'));
      await tester.pumpAndSettle();

      // Enter text in the memo content field
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsAtLeastNWidgets(1), reason: 'TextField not found after expanding CaptureUtility');
      
      // Create unique test content with timestamp to avoid collisions
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final testMemoContent = 'Test Memo for Swipe Delete - $timestamp';
      await tester.enterText(textFieldFinder.first, testMemoContent);
      await tester.pumpAndSettle();

      // Tap the "Add Memo" button
      final addMemoButtonFinder = find.text('Add Memo');
      expect(addMemoButtonFinder, findsOneWidget, reason: 'Add Memo button not found');
      await tester.tap(addMemoButtonFinder);
      await tester.pumpAndSettle();

      // Give the app time to fully refresh the memo list after creation
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Verify there are MemoCards displayed
      expect(find.byType(MemoCard), findsWidgets);
      final afterCreateCount = find.byType(MemoCard).evaluate().length;
      debugPrint('Memo count after creation: $afterCreateCount');
      
      // Let's find our specific memo by its content
      Finder textFinder = find.text(testMemoContent);
      
      // If the memo isn't found immediately, try scrolling to find it
      if (textFinder.evaluate().isEmpty) {
        debugPrint('Memo not immediately visible, searching by scrolling...');
        // Find the list view
        final listViewFinder = find.byType(ListView);
        expect(listViewFinder, findsOneWidget, reason: 'ListView not found');

        // Try scrolling down to find the memo
        for (int i = 0; i < 3; i++) {
          await tester.drag(listViewFinder, const Offset(0, -300));
          await tester.pumpAndSettle();

          // Check if memo is visible after scroll
          if (find.text(testMemoContent).evaluate().isNotEmpty) {
            debugPrint('Found memo after scrolling $i times');
            break;
          }
        }
      }

      // Now verify we can find our memo (might be multiple instances of the text)
      expect(
        find.text(testMemoContent),
        findsWidgets,
        reason: 'Newly created memo not found',
      );

      // Find the MemoCard that contains our content - MemoCard is itself a Slidable
      final memoTextFinder = find.text(testMemoContent);
      expect(memoTextFinder, findsOneWidget, reason: 'Memo text not found');
      
      // Try to locate the closest MemoCard widget
      final memoCard = find.ancestor(
        of: memoTextFinder,
        matching: find.byType(Card),
      );
      expect(memoCard, findsOneWidget, reason: 'Card containing memo text not found');
     
      // Find the slidable action to delete by dragging and then tapping Delete
      await tester.drag(memoCard, const Offset(-300, 0));
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
