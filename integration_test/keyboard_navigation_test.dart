import 'package:flutter/services.dart';
import 'package:flutter_memos/main.dart' as app;
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Keyboard Navigation Integration Tests', () {
    testWidgets('Navigate through memos and comments using keyboard', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Find memo cards (there should be at least one)
      final memoCards = find.byType(MemoCard);
      expect(memoCards, findsWidgets);

      // First, use the 'j' key to navigate through memos
      await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
      await tester.pumpAndSettle();

      // Use 'k' key to navigate back
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.pumpAndSettle();

      // Find the first memo card
      final firstMemoCard = find.byType(MemoCard).first;
      
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

      // Navigate back to the main screen
      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
      await tester.pumpAndSettle();

      // Verify we're back on the main screen
      expect(find.text('Flutter Memos'), findsOneWidget);
    });
  });
}
