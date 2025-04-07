import 'package:integration_test/integration_test.dart';

import '../../helpers/test_helpers.dart'; // Import helpers

void main() {
import 'package:flutter/material.dart';
import 'package:flutter_memos/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../helpers/test_helpers.dart'; // Import helpers

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDownAll(() async {
    await cleanupTestMemos(); // Cleanup memos after all tests in this file
  });

  testWidgets('Scroll position and selection maintained after viewing detail',
      (WidgetTester tester) async {
    // 1. Setup
    app.main();
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 2)); // Wait for initial load

    final testMemos = await createTestMemos(15); // Create enough memos to scroll
    expect(testMemos.length, 15);

    // Refresh list to show new memos
    await tester.fling(find.byType(ListView), const Offset(0.0, 400.0), 1000.0);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // 2. Scroll and Select
    final memoToSelectIndex = 8; // Select a memo somewhere in the middle
    final memoToSelect = testMemos[memoToSelectIndex];
    final memoToSelectFinder = findMemoCardByMemo(memoToSelect);

    await scrollMemosListDown(tester, 600); // Scroll down significantly
    // Send 9 key presses to select the item at index 8
    await selectMemoWithKeys(tester, memoToSelectIndex + 1);
    await tester.pumpAndSettle();

    // Verify selection before navigating
    final selectedMemoBefore = getSelectedMemo(tester);
    expect(
      selectedMemoBefore,
      isNotNull,
      reason: "getSelectedMemo returned null before navigation",
    );
    expect(
      selectedMemoBefore!.id,
      memoToSelect.id,
      reason: "Correct memo ID not selected before navigation",
    );
    expect(
      memoToSelectFinder,
      findsOneWidget,
      reason: "Selected memo card widget not found before navigation",
    );


    // 3. Navigate to Detail
    debugPrint('[Test Action] Tapping selected memo to view detail...');
    await tester.tap(memoToSelectFinder);
    await tester.pumpAndSettle();
    expect(find.text('Memo Detail'), findsOneWidget, reason: "Did not navigate to Memo Detail screen");

    // 4. Navigate Back
    debugPrint('[Test Action] Navigating back to memos list...');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Memo Detail'), findsNothing, reason: "Still on Memo Detail screen after pageBack");

    // 5. Assert State Preservation
    debugPrint('[Test Assertion] Verifying selection and scroll position...');

    // Verify the *same* memo is still selected
    final selectedMemoAfter = getSelectedMemo(tester);
    expect(selectedMemoAfter, isNotNull, reason: "No memo selected after returning");
    expect(
      selectedMemoAfter!.id,
      memoToSelect.id,
      reason: "Different memo ID selected after returning",
    );

    // Verify the selected MemoCard widget is still present
    final selectedMemoCardFinderAfter = findMemoCardByMemo(memoToSelect);
    expect(
      selectedMemoCardFinderAfter,
      findsOneWidget,
      reason: "Selected memo card widget not found after returning",
    );

    // Verify scroll position (check if the selected item is still visible)
    // This is a proxy for scroll position preservation.
    expect(selectedMemoCardFinderAfter, findsOneWidget, reason: "Selected memo card is not visible after returning");

    // Optional: Try scrolling up slightly and see if it works immediately
    await scrollMemosListUp(tester, 50);
    expect(selectedMemoCardFinderAfter, findsOneWidget, reason: "Selected memo card disappeared after small scroll up");

    debugPrint('[Test Result] State preservation after detail view successful.');
  });
}