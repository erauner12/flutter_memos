// Import required packages
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
      final memoCardFinder = find.byType(MemoCard).first;
      expect(memoCardFinder, findsWidgets);

      // Open context menu with appropriate gesture for the platform
      await tester.longPress(memoCardFinder);
      await tester.pumpAndSettle();

      // Verify context menu is shown
      expect(find.text('Memo Actions'), findsOneWidget);
      expect(find.text('Hide'), findsOneWidget);

      // Tap the Hide option
      await tester.tap(find.text('Hide'));
      await tester.pumpAndSettle();
      
      // Wait a bit more for state to update completely
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Verify the hidden memos indicator appears
      expect(find.textContaining('memos hidden'), findsOneWidget);
    });

    testWidgets('Open context menu and perform Archive action', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Find the MemoCard widget
      final memoCardFinder = find.byType(MemoCard).first;
      expect(memoCardFinder, findsWidgets);

      // Get the initial number of memo cards for later comparison
      final initialMemoCount = find.byType(MemoCard).evaluate().length;

      // Open context menu
      await tester.longPress(memoCardFinder);
      await tester.pumpAndSettle();

      // Verify context menu is shown
      expect(find.text('Archive'), findsOneWidget);

      // Tap the Archive option
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      
      // Wait for the archive operation to complete and UI to update
      // The API call is asynchronous, so we need to wait longer
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Look for any indication that the archive was successful
      // This could be a SnackBar containing "archived" text
      final snackBarWithArchivedText = find.textContaining('archived');
      
      // Or a change in the number of visible memo cards
      final finalMemoCount = find.byType(MemoCard).evaluate().length;
      
      // The test passes if we either:
      // 1. See a SnackBar with "archived" text, OR
      // 2. The number of memo cards has decreased (which means archive worked)
      expect(
        snackBarWithArchivedText.evaluate().isNotEmpty ||
            finalMemoCount < initialMemoCount,
        isTrue,
        reason:
            'Either an archive confirmation should be visible or the memo count should decrease',
      );
    });
  });
}
