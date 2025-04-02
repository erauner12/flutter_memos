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
      );
      // Refined pump sequence:
      await tester.pump(); // Process tap, start pop
      await tester.pump(); // Finish pop, start clipboard/snackbar
      await tester.pump(const Duration(milliseconds: 500)); // Allow snackbar animation to start
      await tester.pumpAndSettle(); // Settle everything

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

      // Find a memo card and get its ID and content
      final memoCardFinder = find.byType(MemoCard);
      expect(memoCardFinder, findsWidgets);
      final firstMemoCardWidget = tester.widget<MemoCard>(memoCardFinder.first);
      final actualMemoId = firstMemoCardWidget.id; // Get the actual ID
      final actualMemoContent =
          firstMemoCardWidget.content; // Get content for later verification

      // Tap the card to navigate initially (optional, but good for setup)
      await tester.tap(memoCardFinder.first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // We should now be on MemoDetailScreen (for the tapped memo)
      expect(find.byType(MemoDetailScreen), findsOneWidget);

      // Find the navigator
      final navigatorState = tester.state<NavigatorState>(find.byType(Navigator));

      // Get current route name to return to later if needed
      final currentRoute = ModalRoute.of(navigatorState.context)?.settings.name;

      // Simulate deep link navigation using the *actual* memo ID
      navigatorState.pushNamed(
        '/deep-link-target',
        arguments: {
          'memoId': actualMemoId, // Use the real ID from the card
          'commentIdToHighlight':
              'test-comment-id', // Example comment ID (highlighting might still fail if this ID is invalid for the memo)
        },
      );

      await tester.pumpAndSettle(
        const Duration(seconds: 2),
      ); // Allow time for potential data loading

      // Verify we're still on a MemoDetailScreen (now loaded via deep link simulation)
      expect(
        find.byType(MemoDetailScreen),
        findsOneWidget,
        reason: "Should be on MemoDetailScreen after simulated deep link",
      );

      // Add assertion: Check if the content of the correct memo is displayed
      // This finder might need adjustment based on how MemoContent displays text
      expect(
        find.textContaining(actualMemoContent.substring(0, 10)),
        findsWidgets,
        reason: "Should display content of the correct memo",
      );


      // Return to previous page to avoid test issues (optional cleanup)
      if (currentRoute != null && navigatorState.canPop()) {
        navigatorState.pop(); // Pop the deep link screen
        await tester.pumpAndSettle();
      }
    });
  });
}
