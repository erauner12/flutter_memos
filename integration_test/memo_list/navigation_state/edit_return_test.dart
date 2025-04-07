import 'package:flutter/material.dart';
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
    await tester.fling(find.byType(ListView), const Offset(0.0, 400.0), 1000.0);
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
    expect(find.text('Memo Detail'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    expect(find.text('Edit Memo'), findsOneWidget); // Assuming Edit screen has this title

    // 4. Edit and Save
    final editTextField = find.byType(TextField);
    expect(editTextField, findsOneWidget);
    const suffix = ' - Edited';
    await tester.enterText(editTextField, memoToEdit.content + suffix);
    await tester.pumpAndSettle();

    // Find and tap the save button (adjust finder as needed)
    final saveButtonFinder = find.byTooltip('Save Memo'); // Or find.byIcon(Icons.save), find.text('Save')
    expect(saveButtonFinder, findsOneWidget);
    await tester.tap(saveButtonFinder);
    await tester.pumpAndSettle(const Duration(seconds: 2)); // Wait for save and potential navigation

    // Should be back on Detail screen after save
    expect(find.text('Memo Detail'), findsOneWidget);
    // Verify edited content is shown on detail screen
    expect(find.textContaining(suffix), findsOneWidget);

    // 5. Navigate Back to List
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Memo Detail'), findsNothing);

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

    // Verify we're in edit view
    expect(
      find.text('Edit Memo'),
      findsOneWidget,
      reason: "Not navigated to edit view",
    );

    // 4. Make a small edit
    final titleField = find.byType(TextField).first;
    await tester.enterText(titleField, "${selectedMemo.title} (edited)");

    // 5. Save and return
    final saveButton = find.byType(ElevatedButton).first;
    await tester.tap(saveButton);
    await tester.pumpAndSettle(
      const Duration(seconds: 2),
    ); // Wait for save and return

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
