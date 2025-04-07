import 'package:flutter/cupertino.dart'; // Use Cupertino
// Remove unused Icons import
import 'package:flutter/services.dart';
import 'package:flutter_memos/main.dart' as app;
import 'package:flutter_memos/screens/edit_memo/edit_memo_screen.dart';
import 'package:flutter_memos/screens/memo_detail/memo_detail_screen.dart';
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Edit Memo Integration Tests (Cupertino)', () {
    testWidgets(
      'Edit a memo and save using Command+Enter shortcut',
      (WidgetTester tester) async {
        // Launch the app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3)); // Allow time for initial load

      // Ensure we are on the MemosScreen (check for CupertinoNavigationBar title)
      expect(
        find.descendant(
          of: find.byType(CupertinoNavigationBar),
          matching: find.text('Memos'), // Assuming 'Memos' is the title
        ),
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

      // Ensure we are on the MemoDetailScreen (check CupertinoNavigationBar title)
      expect(
        find.descendant(
          of: find.byType(CupertinoNavigationBar),
          matching: find.text('Memo Detail'),
        ),
        findsOneWidget,
        reason: 'Should be on the memo detail screen',
      );

      // Find and tap the Edit button in the CupertinoNavigationBar's trailing widget
      final editButton = find.widgetWithIcon(
        CupertinoButton,
        CupertinoIcons.pencil,
      ); // Use Cupertino icon
      expect(
        editButton,
        findsOneWidget,
        reason: 'Edit button should be visible',
      );
        await tester.tap(editButton);
        await tester.pumpAndSettle(const Duration(seconds: 1));

      // Ensure we are on the EditMemoScreen (check CupertinoNavigationBar title)
      expect(
        find.byType(EditMemoScreen),
        findsOneWidget,
        reason: 'Should be on the edit screen',
      );
      expect(
        find.descendant(
          of: find.byType(CupertinoNavigationBar),
          matching: find.text('Edit Memo'),
        ),
        findsOneWidget,
        reason: 'Title should be "Edit Memo"',
      );

      // Find the CupertinoTextField for the memo content
      final textFieldFinder = find.byType(CupertinoTextField);
      expect(
        textFieldFinder,
        findsOneWidget,
        reason: 'CupertinoTextField should be visible',
      );

        // Get the current text
      final textFieldWidget = tester.widget<CupertinoTextField>(
        textFieldFinder,
      );
        final initialText = textFieldWidget.controller?.text ?? '';
      debugPrint('Initial text: "$initialText"');

      // Append text to the CupertinoTextField
        final String textToAppend = ' - Edited via test';
        await tester.enterText(textFieldFinder, initialText + textToAppend);
        await tester.pumpAndSettle();

        // Verify the text was appended
      final updatedText =
          tester.widget<CupertinoTextField>(textFieldFinder).controller?.text;
      debugPrint('Updated text: "$updatedText"');
        expect(
        updatedText,
          initialText + textToAppend,
        reason: 'CupertinoTextField should contain the appended text',
        );

      // Debug existing widget types before sending Command+Enter
      debugPrint('Widget tree before Command+Enter:');
      tester.allWidgets
          .where(
            (w) =>
                w is CupertinoPageScaffold ||
                w is EditMemoScreen ||
                w is MemoDetailScreen,
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
                w is CupertinoPageScaffold ||
                w is EditMemoScreen ||
                w is MemoDetailScreen,
          )
          .forEach((w) => debugPrint('  Found widget: ${w.runtimeType}'));

      // Verify we navigated back to the MemoDetailScreen (check title)
        expect(
        find.descendant(
          of: find.byType(CupertinoNavigationBar),
          matching: find.text('Memo Detail'),
        ),
          findsOneWidget,
        reason: 'Should navigate back to MemoDetailScreen after saving',
      );
      },
    );
  });
}
