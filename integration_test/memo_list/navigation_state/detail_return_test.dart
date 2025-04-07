import 'package:flutter/cupertino.dart'; // Import Cupertino
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

  testWidgets('Selection maintained after returning from detail view',
      (WidgetTester tester) async {
    // 1. Setup
    app.main();
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 2));

    final testMemos = await createTestMemos(8);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 2. Select a memo
    final memoToSelectIndex = 3;
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

    // 3. Navigate to detail view
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    // Verify we're in detail view (check CupertinoNavigationBar title)
    expect(
      find.descendant(
        of: find.byType(CupertinoNavigationBar),
        matching: find.text('Memo Detail'),
      ),
      findsOneWidget,
      reason: "Not navigated to detail view",
    );

    // 4. Return to list view using Cupertino back button
    final backButtonFinder = find.byType(CupertinoNavigationBarBackButton);
    expect(
      backButtonFinder,
      findsOneWidget,
      reason: 'Cupertino back button not found',
    );
    await tester.tap(backButtonFinder);
    await tester.pumpAndSettle();

    // 5. Verify selection state is preserved
    final selectedMemoAfterReturn = getSelectedMemo(tester);
    expect(
      selectedMemoAfterReturn,
      isNotNull,
      reason: "Selection lost after returning from detail view",
    );
    expect(
      selectedMemoAfterReturn!.id,
      selectedMemo.id,
      reason: "Different memo selected after returning from detail view",
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
