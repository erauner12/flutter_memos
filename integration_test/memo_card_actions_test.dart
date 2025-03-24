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

      // Get the current number of MemoCards displayed
      final initialCount = find.byType(MemoCard).evaluate().length;

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

      // Verify the memo is hidden (count of visible memos decreases by 1)
      final finalCount = find.byType(MemoCard).evaluate().length;
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

      // Check for success message
      expect(find.text('Memo archived successfully'), findsOneWidget);
    });
  });
}
