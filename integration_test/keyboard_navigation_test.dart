import 'package:flutter/material.dart';
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

    testWidgets('Can type j and k in text input fields', (
      WidgetTester tester,
    ) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for app to be fully loaded
      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Find a text input field - e.g., the capture utility
      final captureUtilityFinder = find.text('Capture something ...');
      expect(captureUtilityFinder, findsOneWidget);

      // Tap to focus the text field
      await tester.tap(captureUtilityFinder);
      await tester.pumpAndSettle();

      // Find the TextField that appears when we tap the capture utility
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsAtLeastNWidgets(1));

      // Enter text containing j and k
      await tester.enterText(textFieldFinder.first, 'Testing j and k keys');
      await tester.pumpAndSettle();

      // Verify the text was entered correctly
      final textField = tester.widget<TextField>(textFieldFinder.first);
      expect(
        textField.controller?.text,
        contains('j'),
        reason: 'TextField should contain the letter j',
      );
      expect(
        textField.controller?.text,
        contains('k'),
        reason: 'TextField should contain the letter k',
      );
    });
  });
}
