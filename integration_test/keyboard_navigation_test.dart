import 'package:flutter/services.dart';
import 'package:flutter_memos/main.dart' as app;
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Keyboard Navigation Integration Tests', () {
    testWidgets(
      'Navigate through memos and comments using consistent keyboard shortcuts',
      (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();
      
      // Wait a bit to ensure the app is fully loaded and ready
      await Future.delayed(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Find memo cards (there should be at least one)
      final memoCards = find.byType(MemoCard);
      expect(memoCards, findsWidgets);
      
        // Since we've added auto-selection in the MemosBody widget,
        // there should already be a selected memo (index 0)
      await tester.pumpAndSettle();
      
        // Find cards that are marked as selected (isSelected = true)
        final initialSelectedCards = find.byWidgetPredicate(
          (widget) => widget is MemoCard && widget.isSelected,
          description: 'Selected memo cards',
        );
      
        // Verify that auto-selection worked - we should have a selected memo
        expect(initialSelectedCards, findsOneWidget);

        // Send a J key to move to the next memo
      await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
      await tester.pumpAndSettle();
      
        // Verify selection changed after J key
        final secondSelectedCards = find.byWidgetPredicate(
          (widget) => widget is MemoCard && widget.isSelected,
          description: 'Memo card selected after J key',
        );
        expect(secondSelectedCards, findsOneWidget);

        // Ensure it's not the same card as before
        expect(
          tester.getCenter(initialSelectedCards.first).dy !=
              tester.getCenter(secondSelectedCards.first).dy,
          isTrue,
          reason: 'Selection should have moved to a different card after J key',
        );

        // Send a K key to go back to the first memo
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.pumpAndSettle();
      
        // Verify we're back to the first card
        final thirdSelectedCards = find.byWidgetPredicate(
          (widget) => widget is MemoCard && widget.isSelected,
          description: 'Memo card selected after K key',
        );
        expect(thirdSelectedCards, findsOneWidget);
      
        // Tap on the selected memo to navigate to detail view
        await tester.tap(thirdSelectedCards);
      await tester.pumpAndSettle();
      
      // Verify we're on the detail screen
      expect(find.text('Memo Detail'), findsOneWidget);
      
        // Now test comments navigation if there are comments
        await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
        await tester.pumpAndSettle();
      
        await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
        await tester.pumpAndSettle();
      
      // Navigate back to the main screen
        await tester.pageBack();
      await tester.pumpAndSettle();
      
      // Verify we're back on the main screen
        expect(find.text('Flutter Memos'), findsOneWidget);
    });
  });
}
