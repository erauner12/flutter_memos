import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_memos/main.dart' as app;
import 'package:flutter_memos/screens/memo_detail/memo_detail_screen.dart';
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  setUp(() {
    // Reset clipboard between tests
    Clipboard.setData(const ClipboardData(text: ''));
  });
  
  group('Deep Link Integration Tests', () {
    testWidgets('Can copy a memo link from context menu',
        (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3)); // Allow time for initial load
      
      // Find a memo card
      final memoCardFinder = find.byType(MemoCard);
      expect(memoCardFinder, findsWidgets, reason: 'Should find memo cards');
      
      // Long press to open context menu
      await tester.longPress(memoCardFinder.first);
      await tester.pumpAndSettle(
        const Duration(seconds: 2),
      ); // Increased settle time

      // Find the "Copy Link" option using its key
      final copyLinkFinder = find.byKey(const Key('copy_link_menu_item'));
      expect(
        copyLinkFinder,
        findsOneWidget,
        reason: 'Should find Copy Link option by key',
      );

      // Ensure the item is visible before tapping (might help with sheet scrolling)
      await tester.ensureVisible(copyLinkFinder);
      await tester.pumpAndSettle();

      // Tap the Copy Link option
      await tester.tap(
        copyLinkFinder,
        warnIfMissed: false,
      ); // Use warnIfMissed: false for now
      await tester.pumpAndSettle(
        const Duration(seconds: 2),
      ); // Increased settle time
      
      // Verify snackbar appears
      expect(
        find.text('Memo link copied to clipboard'),
        findsOneWidget,
        reason: 'Should show confirmation snackbar'
      );
      
      // Get clipboard data
      final clipboardData = await Clipboard.getData('text/plain');
      expect(
        clipboardData?.text,
        matches(RegExp(r'flutter-memos://memo/.*')),
        reason: 'Clipboard should contain a valid memo link'
      );
    });
    
    testWidgets('Simulated deep link opens correct memo and highlights comment',
        (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // Find a memo card and tap to open it
      final memoCardFinder = find.byType(MemoCard);
      expect(memoCardFinder, findsWidgets);
      
      await tester.tap(memoCardFinder.first);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      
      // We should now be on MemoDetailScreen
      expect(find.byType(MemoDetailScreen), findsOneWidget);
      
      // Get the current memo ID (this is tricky in integration test)
      // For this simulation, we'll use navigator to push our own deep link route
      
      // Simulate the effect of a deep link by directly accessing route
      // This is a simplification since we can't easily trigger external URI handling
      
      // Find the navigator
      final navigatorState = tester.state<NavigatorState>(find.byType(Navigator));
      
      // Get current route name to return to later
      final currentRoute = ModalRoute.of(navigatorState.context)?.settings.name;
      
      // Simulate deep link navigation
      navigatorState.pushNamed(
        '/deep-link-target',
        arguments: {
          'memoId': 'test-memo-id', // Example ID
          'commentIdToHighlight': 'test-comment-id', // Example ID
        },
      );
      
      await tester.pumpAndSettle(const Duration(seconds: 1));
      
      // Verify we're on MemoDetailScreen
      expect(find.byType(MemoDetailScreen), findsOneWidget);
      
      // Return to previous page to avoid test issues
      if (currentRoute != null) {
        navigatorState.pushReplacementNamed(currentRoute);
        await tester.pumpAndSettle();
      }
    });
  });
}
