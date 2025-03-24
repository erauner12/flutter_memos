// Import required packages
import 'package:flutter/material.dart';
import 'package:flutter_memos/main.dart' as app;
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  // Initialize integration test binding
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('MemoCard Context Menu Integration Tests', () {
    testWidgets('Open context menu and perform Hide action', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Find the MemoCard widget - we'll need to adjust the finder based on your UI
      final memoCardFinder = find.byType(MemoCard);
      expect(memoCardFinder, findsWidgets);
      
      // Print how many memo cards we found initially
      final initialMemoCount = memoCardFinder.evaluate().length;
      print('Initial memo card count: $initialMemoCount');

      // Open context menu with appropriate gesture for the platform
      await tester.longPress(memoCardFinder.first);
      await tester.pumpAndSettle();

      // Verify context menu is shown
      expect(find.text('Memo Actions'), findsOneWidget);
      expect(find.text('Hide'), findsOneWidget);
      print('Found context menu with Hide option');

      // Tap the Hide option
      await tester.tap(find.text('Hide'));
      await tester.pumpAndSettle();
      
      // Wait a bit more for state to update completely
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      
      // Check for any widget containing 'hidden' in its text
      final hiddenFinder = find.textContaining('hidden', findRichText: true);
      if (hiddenFinder.evaluate().isNotEmpty) {
        print('Found widget with "hidden" text: ${hiddenFinder.toString()}');
      } else {
        print('No "hidden" text found, checking for memo count change');
      }

      // Count memo cards after hiding - this is our primary verification method
      final finalMemoCount = find.byType(MemoCard).evaluate().length;
      print('Final memo card count: $finalMemoCount');

      // Verify the memo was hidden by checking that the count decreased
      expect(
        finalMemoCount,
        lessThan(initialMemoCount),
        reason: 'Memo count should decrease after hiding a memo',
      );
    });

    testWidgets('Open context menu and perform Archive action', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Find the MemoCard widget
      final memoCardFinder = find.byType(MemoCard);
      expect(memoCardFinder, findsWidgets);

      // Get the initial number of memo cards for later comparison
      final initialMemoCount = memoCardFinder.evaluate().length;
      print('Initial memo card count: $initialMemoCount');

      // Open context menu
      await tester.longPress(memoCardFinder.first);
      await tester.pumpAndSettle();

      // Verify context menu is shown
      expect(find.text('Archive'), findsOneWidget);
      print('Found context menu with Archive option');

      // Tap the Archive option
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      
      // Wait for the archive operation to complete and UI to update
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Look for any SnackBar or success indicator
      final snackBarFinder = find.byType(SnackBar);
      if (snackBarFinder.evaluate().isNotEmpty) {
        print('Found SnackBar: ${snackBarFinder.toString()}');
      }
      
      // Check for any text containing "archive" or "success"
      final successFinder = find.textContaining('archive', findRichText: true);
      if (successFinder.evaluate().isNotEmpty) {
        print('Found success message: ${successFinder.toString()}');
      }
      
      // Count memo cards after archiving
      final finalMemoCount = find.byType(MemoCard).evaluate().length;
      print('Final memo card count: $finalMemoCount');
      
      // Verify the memo was archived by checking that the count decreased
      expect(
        finalMemoCount,
        lessThan(initialMemoCount),
        reason: 'Memo count should decrease after archiving a memo',
      );
    });
  });
}
