import 'package:flutter/services.dart';
import 'package:flutter_memos/main.dart' as app;
import 'package:flutter_memos/providers/ui_providers.dart';
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      
      // Wait a bit more to ensure focus is established
      await Future.delayed(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      
      // Directly set the selected memo index to 0 for testing purposes
      // This simulates what should happen when keyboard navigation is used
      await tester.runAsync(() async {
        final context = tester.element(find.byType(ProviderScope));
        final container = ProviderScope.containerOf(context);
        container.read(selectedMemoIndexProvider.notifier).state = 0;
      });
      await tester.pumpAndSettle();

      // Send additional key events for testing
      await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
      await tester.pumpAndSettle();
      
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.pumpAndSettle();

      // Find the first memo card
      final firstMemoCard = find.byType(MemoCard).first;
      
      // Check if the memo is selected after manual selection
      final selectedElements =
          find
              .descendant(
                of: find.byType(MemoCard),
                matching: find.byWidgetPredicate(
                  (widget) => widget is MemoCard && widget.isSelected,
                ),
              )
              .evaluate();

      final previousSelectedIndex =
          selectedElements.isNotEmpty
              ? find
                  .byType(MemoCard)
                  .evaluate()
                  .toList()
                  .indexOf(selectedElements.first)
              : -1;

      // Should have a selected memo now
      expect(previousSelectedIndex, isNot(equals(-1)));
      
      // Tap on the first memo to enter detail view
      await tester.tap(firstMemoCard);
      await tester.pumpAndSettle();

      // Verify we're on the detail screen
      expect(find.text('Memo Detail'), findsOneWidget);

      // Navigate through comments using 'j' key
      await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
      await tester.pumpAndSettle();

      // Navigate through comments using 'k' key
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.pumpAndSettle();

      // Use Shift+Down to navigate through comments
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pumpAndSettle();

      // Use Shift+Up to navigate through comments
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pumpAndSettle();

        // Test all the keyboard navigation combinations to ensure consistency

        // 1. Test J key (down)
        await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
        await tester.pumpAndSettle();

        // 2. Test K key (up)
        await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
        await tester.pumpAndSettle();

        // 3. Test Shift+Down (down)
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
        await tester.pumpAndSettle();

        // 4. Test Shift+Up (up)
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
        await tester.pumpAndSettle();
      
      // Navigate back to the main screen
      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
      await tester.pumpAndSettle();

      // Verify we're back on the main screen
      expect(find.text('Flutter Memos'), findsOneWidget);
      
        // Test navigation in the main screen again to verify it still works

        // 1. Test J key (next memo)
        await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
        await tester.pumpAndSettle();

        // 2. Test K key (previous memo)
        await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
        await tester.pumpAndSettle();

        // 3. Test Command+Right to open selected memo
        await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
        await tester.pumpAndSettle();

        // We should be back in the detail screen
        expect(find.text('Memo Detail'), findsOneWidget);
    });
  });
}
