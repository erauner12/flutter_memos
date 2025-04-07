import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_memos/main.dart' as app;
import 'package:flutter_memos/screens/edit_memo/edit_memo_screen.dart';
import 'package:flutter_memos/screens/memo_detail/memo_detail_screen.dart';
import 'package:flutter_memos/screens/memos/memos_screen.dart';
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Edit Memo Integration Tests', () {
    testWidgets(
      'Edit a memo and save using Command+Enter shortcut',
      (WidgetTester tester) async {
        // Launch the app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3)); // Allow time for initial load

        // Ensure we are on the MemosScreen
      expect(
        find.byType(MemosScreen),
        findsOneWidget,
        reason: 'Should be on the memos screen',
      );

        // Find the first memo card
        final memoCards = find.byType(MemoCard);
        expect(memoCards, findsWidgets, reason: 'Should find memo cards');
        final firstMemoCard = memoCards.first;

        // Tap the first memo to navigate to MemoDetailScreen
        await tester.tap(firstMemoCard);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Ensure we are on the MemoDetailScreen
      expect(
        find.byType(MemoDetailScreen),
        findsOneWidget,
        reason: 'Should be on the memo detail screen',
      );

        // Find and tap the Edit button in the AppBar
        final editButton = find.widgetWithIcon(IconButton, Icons.edit);
      expect(
        editButton,
        findsOneWidget,
        reason: 'Edit button should be visible',
      );
        await tester.tap(editButton);
        await tester.pumpAndSettle(const Duration(seconds: 1));

      // Ensure we are on the EditMemoScreen (check title for 'Edit Memo')
      expect(
        find.byType(EditMemoScreen),
        findsOneWidget,
        reason: 'Should be on the edit screen',
      );
      expect(
        find.widgetWithText(AppBar, 'Edit Memo'),
        findsOneWidget,
        reason: 'Title should be "Edit Memo"',
      );


        // Find the TextField for the memo content
        final textFieldFinder = find.byType(TextField);
      expect(
        textFieldFinder,
        findsOneWidget,
        reason: 'TextField should be visible',
      );

        // Get the current text
        final textFieldWidget = tester.widget<TextField>(textFieldFinder);
        final initialText = textFieldWidget.controller?.text ?? '';
      debugPrint('Initial text: "$initialText"');

        // Append text to the TextField
        final String textToAppend = ' - Edited via test';
        await tester.enterText(textFieldFinder, initialText + textToAppend);
        await tester.pumpAndSettle();

        // Verify the text was appended
      final updatedText =
          tester.widget<TextField>(textFieldFinder).controller?.text;
      debugPrint('Updated text: "$updatedText"');
        expect(
        updatedText,
          initialText + textToAppend,
        reason: 'TextField should contain the appended text'
        );

      // Debug existing widget types before sending Command+Enter
      debugPrint('Widget tree before Command+Enter:');
      tester.allWidgets
          .where(
            (w) =>
                w is Scaffold || w is EditMemoScreen || w is MemoDetailScreen,
          )
          .forEach((w) => debugPrint('  Found widget: ${w.runtimeType}'));

        // Simulate pressing Command + Enter
      debugPrint('Sending Command+Enter key sequence...');
        await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);

      // Wait longer to ensure the save completes and navigation happens
      debugPrint('Waiting for save to complete and navigation to occur...');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Debug widget types after sending Command+Enter
      debugPrint('Widget tree after Command+Enter:');
      tester.allWidgets
          .where(
            (w) =>
                w is Scaffold || w is EditMemoScreen || w is MemoDetailScreen,
          )
          .forEach((w) => debugPrint('  Found widget: ${w.runtimeType}'));

      // Verify we navigated back to the MemoDetailScreen
        expect(
        find.byType(MemoDetailScreen),
          findsOneWidget,
        reason: 'Should navigate back to MemoDetailScreen after saving',
      );
      },
    );
  });
}