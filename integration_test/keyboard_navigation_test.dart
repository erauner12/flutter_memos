import 'package:flutter/services.dart';
import 'package:flutter_memos/main.dart' as app;
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Keyboard Navigation Integration Tests', () {
    testWidgets(
      'Navigate through memos using keyboard shortcuts',
      (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();
        
      // Wait for app to be fully loaded
      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Verify that memo cards exist
      final memoCards = find.byType(MemoCard);
      expect(memoCards, findsWidgets, reason: 'Should find memo cards');
        
      // Send a J key to move selection down
      await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
      await tester.pumpAndSettle();
        
      // Send a K key to move selection up
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.pumpAndSettle();
        
      // Test navigation to detail screen by tapping on a memo
      await tester.tap(memoCards.first);
      await tester.pumpAndSettle();

      // Verify we're on the detail screen
      expect(find.text('Memo Detail'), findsOneWidget);
        
      // Go back to main screen
        await tester.pageBack();
      await tester.pumpAndSettle();

      // Verify we're back on the main screen
        expect(find.text('Flutter Memos'), findsOneWidget);
    });
  });
}
