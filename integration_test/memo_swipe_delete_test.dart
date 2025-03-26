import 'package:flutter/material.dart';
import 'package:flutter_memos/main.dart' as app;
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_memos/widgets/capture_utility.dart';
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

      // Find a MemoCard that contains our test content
      Finder? memoCardFinder;
      final textWidgets = find.text(testMemoContent);
      
      for (int i = 0; i < textWidgets.evaluate().length; i++) {
        final currentTextFinder = find.text(testMemoContent).at(i);
        final ancestorFinder = find.ancestor(
          of: currentTextFinder,
          matching: find.byType(MemoCard),
        );
        
        if (ancestorFinder.evaluate().isNotEmpty) {
          memoCardFinder = ancestorFinder.first;
          debugPrint(
            'Found MemoCard containing our test memo text at index $i',
          );
          break;
        }
      }
      
      // Verify we found a MemoCard
      expect(
        memoCardFinder != null,
        isTrue,
        reason: 'Could not find MemoCard containing test memo content',
      );
      
      // Now we can safely use memoCardFinder!
      final memoCardWidget = tester.widget(memoCardFinder!) as MemoCard;
      debugPrint('Found memo card with ID: ${memoCardWidget.id}');

      // Find the Dismissible widget that wraps the MemoCard
      final dismissibleFinder = find.ancestor(
        of: memoCardFinder,
        matching: find.byType(Dismissible),
      );
      expect(dismissibleFinder, findsOneWidget, reason: 'Dismissible widget not found');

      // Swipe left to delete
      await tester.drag(dismissibleFinder, const Offset(-500, 0));
      await tester.pumpAndSettle();
      
      // Tap "Delete" on the confirmation dialog - using a more specific approach
      // since there might be multiple "Delete" widgets in the app

      // First find the alert dialog
      final alertDialogFinder = find.byType(AlertDialog);
      expect(
        alertDialogFinder,
        findsOneWidget,
        reason: 'Alert dialog not found after swipe',
      );

      // Find the Delete button within the dialog
      final deleteButtonFinder = find.descendant(
        of: alertDialogFinder,
        matching: find.text('Delete'),
      );
      expect(
        deleteButtonFinder,
        findsOneWidget,
        reason: 'Delete button not found in dialog',
      );

      // Tap the delete button
      await tester.tap(deleteButtonFinder);
      await tester.pumpAndSettle();

      // Wait for deletion to complete
      await tester.pump(const Duration(seconds: 1));
      
      // Give more time for deletion animation and UI updates to complete
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Log the counts for debugging
      final afterDeleteCount = find.byType(MemoCard).evaluate().length;
      debugPrint('Memo count after deletion: $afterDeleteCount');
      
      // Check if our memo is still visible anywhere
      bool memoFound = false;
      
      // Look for our text in any MemoCard
      final textWidgetsAfterDelete = find.text(testMemoContent);
      if (textWidgetsAfterDelete.evaluate().isNotEmpty) {
        for (int i = 0; i < textWidgetsAfterDelete.evaluate().length; i++) {
          final ancestorFinder = find.ancestor(
            of: textWidgetsAfterDelete.at(i),
            matching: find.byType(MemoCard),
          );
          
          if (ancestorFinder.evaluate().isNotEmpty) {
            memoFound = true;
            debugPrint(
              'Found memo in MemoCard after deletion attempt - deletion failed',
            );
            break;
          }
        }
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
            final textAfterScroll = find.text(testMemoContent);
            if (textAfterScroll.evaluate().isNotEmpty) {
              // Check if this text is part of a MemoCard
              for (int j = 0; j < textAfterScroll.evaluate().length; j++) {
                final ancestorFinder = find.ancestor(
                  of: textAfterScroll.at(j),
                  matching: find.byType(MemoCard),
                );

                if (ancestorFinder.evaluate().isNotEmpty) {
                  memoFound = true;
                  debugPrint(
                    'Found memo after scrolling $i times - deletion failed',
                  );
                  break;
                }
              }

              if (memoFound) break;
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