import 'package:flutter/material.dart';
import 'package:flutter_memos/main.dart' as app;
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
      print('Initial memo count: $initialCount');

      // Tap the FAB to create a new memo
      final fabFinder = find.byIcon(Icons.add);
      expect(fabFinder, findsOneWidget, reason: 'FAB not found');
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // Enter text in the memo content field
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget, reason: 'TextField not found');
      
      const testMemoContent = 'Test Memo for Swipe Delete';
      await tester.enterText(textFieldFinder, testMemoContent);
      await tester.pumpAndSettle();

      // Tap the "Create Memo" button
      final createButtonFinder = find.text('Create Memo');
      expect(createButtonFinder, findsOneWidget, reason: 'Create Memo button not found');
      await tester.tap(createButtonFinder);
      await tester.pumpAndSettle();

      // Verify the memo was created
      expect(find.byType(MemoCard), findsWidgets);
      final afterCreateCount = find.byType(MemoCard).evaluate().length;
      print('Memo count after creation: $afterCreateCount');
      
      // Ensure we have one more memo than before
      expect(afterCreateCount, initialCount + 1, reason: 'Memo count did not increase after creation');

      // Find the new memo by its content
      final newMemoFinder = find.descendant(
        of: find.byType(MemoCard),
        matching: find.text(testMemoContent),
      );
      expect(newMemoFinder, findsOneWidget, reason: 'Newly created memo not found');

      // Get the position of the memo card to swipe
      final memoCardFinder = find.ancestor(
        of: newMemoFinder,
        matching: find.byType(MemoCard),
      ).first;
      
      final memoCardWidget = tester.widget(memoCardFinder) as MemoCard;
      print('Found memo card with ID: ${memoCardWidget.id}');

      // Find the Dismissible widget that wraps the MemoCard
      final dismissibleFinder = find.ancestor(
        of: memoCardFinder,
        matching: find.byType(Dismissible),
      );
      expect(dismissibleFinder, findsOneWidget, reason: 'Dismissible widget not found');

      // Swipe left to delete
      await tester.drag(dismissibleFinder, const Offset(-500, 0));
      await tester.pumpAndSettle();
      
      // Tap "Delete" on the confirmation dialog
      final deleteButtonFinder = find.text('Delete');
      expect(deleteButtonFinder, findsOneWidget, reason: 'Delete confirmation button not found');
      await tester.tap(deleteButtonFinder);
      await tester.pumpAndSettle();

      // Wait for deletion to complete
      await tester.pump(const Duration(seconds: 1));
      
      // Verify deletion by checking memo count or trying to find the deleted memo
      final afterDeleteCount = find.byType(MemoCard).evaluate().length;
      print('Memo count after deletion: $afterDeleteCount');
      
      // Make sure our memo is no longer in the list
      final deletedMemoFinder = find.descendant(
        of: find.byType(MemoCard),
        matching: find.text(testMemoContent),
      );
      
      expect(deletedMemoFinder, findsNothing, reason: 'Deleted memo is still visible');
      
      // Optional: Also verify a snackbar confirmation is shown
      final snackbarFinder = find.descendant(
        of: find.byType(SnackBar),
        matching: find.textContaining('deleted'),
      );
      // We don't fail the test if the snackbar isn't found - it's not critical
      if (snackbarFinder.evaluate().isEmpty) {
        print('Warning: Deletion confirmation snackbar not found');
      } else {
        print('Found deletion confirmation snackbar');
      }
    });
  });
}
