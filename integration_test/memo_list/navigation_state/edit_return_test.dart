import 'package:flutter/cupertino.dart'; // Import Cupertino
// Remove unused Icons import
import 'package:flutter/services.dart'; // Add this for LogicalKeyboardKey
import 'package:flutter_memos/main.dart' as app;
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDownAll(() async {
    await cleanupTestMemos();
  });

  testWidgets('Scroll position and selection maintained after editing memo',
      (WidgetTester tester) async {
    // 1. Setup
    app.main();
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 2));

    final testMemos = await createTestMemos(10);
    // Use generic Scrollable finder
    await tester.fling(
      find.byType(Scrollable).first,
      const Offset(0.0, 400.0),
      1000.0,
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // 2. Scroll and Select
    final memoToEditIndex = 5;
    final memoToEdit = testMemos[memoToEditIndex];
    final memoToEditFinder = findMemoCardByMemo(memoToEdit);

    await scrollMemosListDown(tester, 400);
    // Send 6 key presses to select the item at index 5
    await selectMemoWithKeys(tester, memoToEditIndex + 1);
    await tester.pumpAndSettle();

    // Verify selection state by checking the ID returned by the helper (which reads the provider)
    final selectedMemoBefore = getSelectedMemo(tester);
    expect(
      selectedMemoBefore,
      isNotNull,
      reason: "getSelectedMemo returned null before navigation",
    );
    expect(
      selectedMemoBefore!.id,
      memoToEdit.id,
      reason: "Incorrect memo ID selected before navigation",
    );
    // Optionally, verify the widget exists
    expect(
      memoToEditFinder,
      findsOneWidget,
      reason: "Selected memo card widget not found before navigation",
    );

    // 3. Navigate to Detail -> Edit
    await tester.tap(memoToEditFinder);
    await tester.pumpAndSettle();
    // Check CupertinoNavigationBar title
    expect(
      find.descendant(
        of: find.byType(CupertinoNavigationBar),
        matching: find.text('Memo Detail'),
      ),
      findsOneWidget,
    );

    // Find edit button in CupertinoNavigationBar trailing
    await tester.tap(find.widgetWithIcon(CupertinoButton, Icons.edit));
    await tester.pumpAndSettle();
    // Check CupertinoNavigationBar title
    expect(
      find.descendant(
        of: find.byType(CupertinoNavigationBar),
        matching: find.text('Edit Memo'),
      ),
      findsOneWidget,
    );

    // 4. Edit and Save
    final editTextField = find.byType(
      CupertinoTextField,
    ); // Use CupertinoTextField
    expect(editTextField, findsOneWidget);
    const suffix = ' - Edited';
    await tester.enterText(editTextField, memoToEdit.content + suffix);
    await tester.pumpAndSettle();

    // Find and tap the save button (assuming CupertinoButton with text or icon)
    // Using Command+Enter shortcut instead of tapping a button
    debugPrint('Sending Command+Enter to save...');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pumpAndSettle(
      const Duration(seconds: 3),
    ); // Wait for save and navigation

    // Should be back on Detail screen after save
    expect(
      find.descendant(
        of: find.byType(CupertinoNavigationBar),
        matching: find.text('Memo Detail'),
      ),
      findsOneWidget,
    );
    // Verify edited content is shown on detail screen
    expect(find.textContaining(suffix, findRichText: true), findsWidgets);

    // 5. Navigate Back to List
    await tester.pageBack(); // Use tester.pageBack() for Cupertino navigation
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(CupertinoNavigationBar),
        matching: find.text('Memo Detail'),
      ),
      findsNothing,
    );
    // Check for Memos screen title
    expect(
      find.descendant(
        of: find.byType(CupertinoNavigationBar),
        matching: find.text('Memos'),
      ),
      findsOneWidget,
    );


    // 6. Assert State Preservation
    final selectedMemoAfter = getSelectedMemo(tester);
    expect(selectedMemoAfter, isNotNull);
    expect(selectedMemoAfter!.id, memoToEdit.id, reason: "Selection changed after edit");

    // Find the widget again and check its properties directly
    final editedMemoCardFinder = findMemoCardByMemo(memoToEdit);
    expect(
      editedMemoCardFinder,
      findsOneWidget,
      reason: "Edited memo card widget not found after returning",
    );
    expect(
      tester.widget<MemoCard>(editedMemoCardFinder).content,
      contains(suffix),
      reason: "Edited content not visible on card after returning",
    );

    // Check visibility (proxy for scroll)
    expect(
      editedMemoCardFinder,
      findsOneWidget,
      reason: "Edited memo card widget not visible after returning",
    );
    debugPrint('[Test Result] State preservation after edit successful.');
  });

  testWidgets('Selection maintained after returning from edit view', (
    WidgetTester tester,
  ) async {
    // 1. Setup
    app.main();
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 2));

    final testMemos = await createTestMemos(8);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 2. Select a memo
    final memoToSelectIndex = 4;
    final selectedMemo = testMemos[memoToSelectIndex];
    await selectMemoWithKeys(tester, memoToSelectIndex + 1);
    await tester.pumpAndSettle();

    // Verify selection state
    final selectedMemoBefore = getSelectedMemo(tester);
    expect(
      selectedMemoBefore,
      isNotNull,
      reason: "getSelectedMemo returned null before navigation",
    );
    expect(
      selectedMemoBefore!.id,
      selectedMemo.id,
      reason: "Incorrect memo ID selected before navigation",
    );

    // 3. Navigate to edit view
    await tester.sendKeyEvent(
      LogicalKeyboardKey.keyE,
    ); // Assuming 'e' key opens edit
    await tester.pumpAndSettle();

    // Verify we're in edit view (check CupertinoNavigationBar title)
    expect(
      find.descendant(
        of: find.byType(CupertinoNavigationBar),
        matching: find.text('Edit Memo'),
      ),
      findsOneWidget,
      reason: "Not navigated to edit view",
    );

    // 4. Make a small edit
    final titleField =
        find.byType(CupertinoTextField).first; // Use CupertinoTextField
    await tester.enterText(
      titleField,
      "${selectedMemo.content} (edited)",
    ); // Using the correct property 'content' instead of 'text'

    // 5. Save and return using Command+Enter
    debugPrint('Sending Command+Enter to save...');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pumpAndSettle(
      const Duration(seconds: 3),
    ); // Wait for save and return

    // Should be back on Detail screen after save
    expect(
      find.descendant(
        of: find.byType(CupertinoNavigationBar),
        matching: find.text('Memo Detail'),
      ),
      findsOneWidget,
    );

    // Navigate back to list
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 6. Verify selection state is preserved
    final selectedMemoAfterReturn = getSelectedMemo(tester);
    expect(
      selectedMemoAfterReturn,
      isNotNull,
      reason: "Selection lost after returning from edit view",
    );
    expect(
      selectedMemoAfterReturn!.id,
      selectedMemo.id,
      reason: "Different memo selected after returning from edit view",
    );

    // Verify the widget visually indicates selection
    final memoSelectedFinder = findMemoCardByMemo(selectedMemo);
    expect(
      memoSelectedFinder,
      findsOneWidget,
      reason: "Selected memo card widget not found after returning",
    );

    // Additional visual verification if needed
    expect(
      tester.widget<MemoCard>(memoSelectedFinder).isSelected,
      isTrue,
      reason: "Selected card not visually shown as selected",
    );
  });
}
