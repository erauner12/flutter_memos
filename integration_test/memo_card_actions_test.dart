// Import required packages
// Import your app
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
      // On iOS/Android, use longPress
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

      // Verify the memo is hidden by checking for the hidden memos indicator
      expect(find.textContaining('memos hidden'), findsOneWidget);

      // Alternative verification by checking hidden message text directly
      final hiddenIndicator = find.textContaining('memos hidden');
      expect(hiddenIndicator, findsOneWidget);
      expect(finalCount, initialCount - 1);
      
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

      // Open context menu
      await tester.longPress(memoCardFinder);
      await tester.pumpAndSettle();

      // Verify context menu is shown
      expect(find.text('Archive'), findsOneWidget);

      // Tap the Archive option
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      
      // Wait for the archive operation to complete and SnackBar to appear
      // The API call is asynchronous, so we need to wait longer
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Verify the archiving worked by checking for changes in the UI
      // We can either check for the SnackBar or verify the memo is no longer in the list

      // Option 1: Check the API service was called by looking for updated memos count
      // This will be more reliable than looking for the specific SnackBar message

      // Verify that the memo was archived successfully
      // We can check for a decrease in the memo count as an alternative verification
      final memoCountAfterArchive = find.byType(MemoCard).evaluate().length;
      expect(memoCountAfterArchive, lessThan(4)); // Initial count was 4

      // Check for success message - using textContaining to be more flexible
      expect(find.textContaining('archived'), findsOneWidget);
    });
  });
}
