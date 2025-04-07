import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter_memos/main.dart' as app;
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // Keep Slidable if still used
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDownAll(() async {
    await cleanupTestMemos();
  });

  testWidgets('Selection maintained after list actions (delete, pin)',
      (WidgetTester tester) async {
    // 1. Setup
    app.main();
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 2));

    final testMemos = await createTestMemos(12);
    // Use generic Scrollable finder
    await tester.fling(
      find.byType(Scrollable).first,
      const Offset(0.0, 400.0),
      1000.0,
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // 2. Scroll and Select
    final initialSelectionIndex = 6;
    final memoSelected = testMemos[initialSelectionIndex];
    final memoSelectedFinder = findMemoCardByMemo(memoSelected);

    await scrollMemosListDown(tester, 500);
    // Send 7 key presses to select the item at index 6
    await selectMemoWithKeys(tester, initialSelectionIndex + 1);
    await tester.pumpAndSettle();

    // Verify selection state by checking the ID returned by the helper (which reads the provider)
    final selectedMemoBefore = getSelectedMemo(tester);
    expect(
      selectedMemoBefore,
      isNotNull,
      reason: "getSelectedMemo returned null before delete",
    );
    expect(
      selectedMemoBefore!.id,
      memoSelected.id,
      reason: "Incorrect memo ID selected before delete",
    );
    // Optionally, verify the widget exists and has the correct ID, but don't rely on isSelected prop timing
    expect(
      memoSelectedFinder,
      findsOneWidget,
      reason: "Selected memo card widget not found before delete",
    );


    // 3. Delete Memo *Above* Selection (Assuming Slidable is still used)
    final memoToDeleteIndex = initialSelectionIndex - 2; // Index 4
    final memoToDelete = testMemos[memoToDeleteIndex];
    final memoToDeleteFinder = findMemoCardByMemo(memoToDelete);
    expect(memoToDeleteFinder, findsOneWidget);

    debugPrint('[Test Action] Swiping to delete memo ${memoToDelete.id} (above selection)...');
    // Swipe left to reveal delete action
    await tester.drag(memoToDeleteFinder, const Offset(-500.0, 0.0));
    await tester.pumpAndSettle();
    // Tap the delete action (find by label or icon)
    final deleteActionFinder = find.widgetWithText(SlidableAction, 'Delete');
    expect(deleteActionFinder, findsOneWidget);
    await tester.tap(deleteActionFinder);
    await tester.pumpAndSettle(); // Use default pumpAndSettle

    // Handle potential CupertinoAlertDialog confirmation
    final alertDialogFinder = find.byType(CupertinoAlertDialog);
    if (alertDialogFinder.evaluate().isNotEmpty) {
      debugPrint('[Test Action] Found confirmation dialog, tapping Delete...');
      final deleteConfirmButtonFinder = find.descendant(
        of: alertDialogFinder,
        matching: find.widgetWithText(CupertinoDialogAction, 'Delete'),
      );
      expect(deleteConfirmButtonFinder, findsOneWidget);
      await tester.tap(deleteConfirmButtonFinder);
      await tester.pumpAndSettle();
    } else {
      debugPrint('[Test Info] No confirmation dialog found after delete tap.');
    }

    await Future.delayed(
      const Duration(
        milliseconds: 500,
      ), // Increased delay for UI to settle after potential dialog
    );
    await tester.pumpAndSettle();


    debugPrint('[Test Assertion] Verifying selection after deleting memo above...');
    // Assert: Original memo is still selected (its index in the provider might change)
    final selectedMemoAfterDelete = getSelectedMemo(tester);
    expect(
      selectedMemoAfterDelete,
      isNotNull,
      reason: "Selected memo is null after deleting item above",
    ); // Check null first
    expect(selectedMemoAfterDelete!.id, memoSelected.id, reason: "Selection lost after deleting item above");
    // Re-find the widget to ensure it's still there
    final memoSelectedFinderAfterDelete = findMemoCardByMemo(memoSelected);
    expect(
      memoSelectedFinderAfterDelete,
      findsOneWidget,
      reason: "Selected card widget not found after delete",
    );
    // Check the deleted memo is gone
    expect(find.byWidgetPredicate((w) => w is MemoCard && w.id == memoToDelete.id), findsNothing, reason: "Deleted memo still visible");


    // 4. Pin the *Selected* Memo (Assuming Slidable is still used)
    debugPrint('[Test Action] Swiping to pin selected memo ${memoSelected.id}...');
    // Swipe right to reveal pin action
    await tester.drag(memoSelectedFinderAfterDelete, const Offset(500.0, 0.0));
    await tester.pumpAndSettle();
    // Tap the pin action
    final pinActionFinder = find.widgetWithText(SlidableAction, 'Pin'); // Assuming it's not pinned yet
    expect(pinActionFinder, findsOneWidget);
    await tester.tap(pinActionFinder);
    await tester.pumpAndSettle(const Duration(seconds: 2)); // Wait for API + state update + potential re-sort

    debugPrint('[Test Assertion] Verifying selection after pinning...');
    // Assert: The same memo is still selected and shows pinned status
    final selectedMemoAfterPin = getSelectedMemo(tester);
    expect(selectedMemoAfterPin, isNotNull);
    expect(selectedMemoAfterPin!.id, memoSelected.id, reason: "Selection lost after pinning");

    // Find the widget again and check its properties directly
    final memoSelectedFinderAfterPin = findMemoCardByMemo(memoSelected);
    expect(
      memoSelectedFinderAfterPin,
      findsOneWidget,
      reason: "Selected card widget not found after pin",
    );
    // Check the pinned state directly from the widget found via the selected ID
    expect(
      tester.widget<MemoCard>(memoSelectedFinderAfterPin).pinned,
      isTrue,
      reason: "Selected card widget not marked as pinned",
    );

    // It might have moved to the top, ensure it's visible
    await tester.ensureVisible(memoSelectedFinderAfterPin);
    await tester.pumpAndSettle();

    debugPrint('[Test Result] State preservation after list actions successful.');
  });
}
