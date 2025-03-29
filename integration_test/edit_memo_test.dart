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
        expect(find.byType(MemosScreen), findsOneWidget);

        // Find the first memo card
        final memoCards = find.byType(MemoCard);
        expect(memoCards, findsWidgets, reason: 'Should find memo cards');
        final firstMemoCard = memoCards.first;

        // Tap the first memo to navigate to MemoDetailScreen
        await tester.tap(firstMemoCard);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Ensure we are on the MemoDetailScreen
        expect(find.byType(MemoDetailScreen), findsOneWidget);

        // Find and tap the Edit button in the AppBar
        final editButton = find.widgetWithIcon(IconButton, Icons.edit);
        expect(editButton, findsOneWidget);
        await tester.tap(editButton);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Ensure we are on the EditMemoScreen
        expect(find.byType(EditMemoScreen), findsOneWidget);

        // Find the TextField for the memo content
        final textFieldFinder = find.byType(TextField);
        expect(textFieldFinder, findsOneWidget);

        // Get the current text
        final textFieldWidget = tester.widget<TextField>(textFieldFinder);
        final initialText = textFieldWidget.controller?.text ?? '';

        // Append text to the TextField
        final String textToAppend = ' - Edited via test';
        await tester.enterText(textFieldFinder, initialText + textToAppend);
        await tester.pumpAndSettle();

        // Verify the text was appended
        expect(
          tester.widget<TextField>(textFieldFinder).controller?.text,
          initialText + textToAppend,
        );

        // Simulate pressing Command + Enter
        await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
        await tester.pumpAndSettle(const Duration(seconds: 2)); // Allow time for save and navigation

      // Verify we navigated back to the MemoDetailScreen
        expect(
        find.byType(MemoDetailScreen), // Changed from MemosScreen
          findsOneWidget,
        reason: 'Should navigate back to MemoDetailScreen after saving',
        );

      // (Optional but recommended) Verify the content on the detail screen
      // You might need to find the MemoContent widget and check its text.
      // final memoContentFinder = find.byType(MemoContent);
      // expect(memoContentFinder, findsOneWidget);
      // expect(find.textContaining(textToAppend, findRichText: true), findsOneWidget);

      // (Optional) Navigate back to MemosScreen if needed for further checks
      // await tester.pageBack();
      // await tester.pumpAndSettle();
      // expect(find.byType(MemosScreen), findsOneWidget);
      },
    );
  });
}
