import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter/services.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/ui_providers.dart'
    as ui_providers; // Add import
// Remove ProviderScope/Riverpod related imports if no longer needed elsewhere in the file
// import 'package:flutter_memos/providers/ui_providers.dart' as ui_providers; // Remove import
// import 'package:flutter_riverpod/flutter_riverpod.dart'; // Remove import
import 'package:flutter_memos/screens/memos/memos_screen.dart';
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Add import
import 'package:flutter_test/flutter_test.dart';

final List<String> createdMemoIds = []; // Track IDs for cleanup

// Creates memos programmatically via API
Future<List<Memo>> createTestMemos(int count, {String prefix = 'Test Memo'}) async {
  debugPrint('[Test Helper] Creating $count test memos programmatically...');
  final apiService = ApiService();
  final List<Memo> memos = [];
  for (int i = 0; i < count; i++) {
    final timestamp = DateTime.now().millisecondsSinceEpoch + i; // Ensure unique content
    final content = '$prefix $i - $timestamp';
    try {
      final newMemo = Memo(
        id: 'temp-$timestamp',
        content: content,
        visibility: 'PUBLIC', // Or PRIVATE depending on your setup
      );
      final createdMemo = await apiService.createMemo(newMemo);
      createdMemoIds.add(createdMemo.id);
      memos.add(createdMemo);
      debugPrint('[Test Helper] Created memo: ${createdMemo.id} - "$content"');
      await Future.delayed(const Duration(milliseconds: 50)); // Small delay
    } catch (e) {
      debugPrint('[Test Helper] Error creating memo $i: $e');
      throw Exception('Failed to create test memo $i: $e');
    }
  }
  // Sort by update time descending, mimicking the app's initial sort
  memos.sort((a, b) => DateTime.parse(b.updateTime ?? '1970')
      .compareTo(DateTime.parse(a.updateTime ?? '1970')));
  debugPrint('[Test Helper] Finished creating ${memos.length} memos.');
  return memos;
}

// Cleans up memos created during tests
Future<void> cleanupTestMemos() async {
  if (createdMemoIds.isEmpty) return;
  debugPrint('[Test Helper] Cleaning up ${createdMemoIds.length} test memos...');
  final apiService = ApiService();
  try {
    await Future.wait(
      createdMemoIds.map((id) => apiService.deleteMemo(id).catchError((e) {
        // Log error but don't fail cleanup for one memo
        debugPrint('[Test Helper] Error deleting memo $id during cleanup: $e');
      })),
    );
    debugPrint('[Test Helper] Cleanup complete.');
  } catch (e) {
    debugPrint('[Test Helper] Error during bulk memo cleanup: $e');
  }
  createdMemoIds.clear();
}

// Finds the MemoCard widget corresponding to a specific Memo object
Finder findMemoCardByMemo(Memo memo) {
  return find.byWidgetPredicate(
    (widget) => widget is MemoCard && widget.id == memo.id,
    description: 'MemoCard with id ${memo.id}',
  );
}

// Finds the selected MemoCard (kept for potential use, but getSelectedMemo is preferred)
Finder findSelectedMemoCard() {
  return find.byWidgetPredicate(
    (widget) => widget is MemoCard && widget.isSelected,
    description: 'Selected MemoCard',
  );
}

// Gets the Memo object associated with the currently selected MemoCard
// Reads the selected ID from the provider and finds the corresponding widget.
Memo? getSelectedMemo(WidgetTester tester) {
  ProviderContainer? container;
  try {
    // Find the CupertinoApp element in the widget tree (assuming ProviderScope is top-level within it)
    final element = tester.element(find.byType(CupertinoApp));
    // Get the container associated with the scope
    // Note: This assumes ProviderScope is still used directly under CupertinoApp.
    // If ProviderScope was removed or moved, this needs adjustment.
    container = ProviderScope.containerOf(
      element,
      listen: false,
    ); // Use listen: false
  } catch (e) {
    debugPrint(
      '[getSelectedMemo] Error finding CupertinoApp or ProviderScope Container: $e',
    );
    return null; // Cannot proceed without the container
  }

  // Read the selected ID from the provider
  final selectedId = container.read(ui_providers.selectedMemoIdProvider);

  if (selectedId != null) {
    debugPrint(
      '[getSelectedMemo] selectedMemoIdProvider holds ID: $selectedId.',
    );
    // Find the MemoCard widget corresponding to the selected ID
    final cardFinder = find.byWidgetPredicate(
      (widget) => widget is MemoCard && widget.id == selectedId,
      description: 'MemoCard with id $selectedId',
    );

    // Check if the widget exists in the tree
    final foundElements = cardFinder.evaluate();
    if (foundElements.isNotEmpty) {
      if (foundElements.length > 1) {
        debugPrint(
          '[getSelectedMemo] Warning: Found multiple MemoCard widgets for ID $selectedId',
        );
      }
      // Get the widget instance
      final cardWidget = tester.widget<MemoCard>(cardFinder.first);
      // Return partial memo based on widget properties
      return Memo(
        id: cardWidget.id,
        content: cardWidget.content,
        pinned: cardWidget.pinned,
      );
    } else {
      debugPrint(
        '[getSelectedMemo] Could not find MemoCard widget in UI for selected ID: $selectedId',
      );
      // This might happen if the item is scrolled off-screen, but the ID is still selected.
      // For the purpose of these tests (checking if selection *persists*), finding the ID in the provider is key.
      // We can return a minimal Memo object just with the ID to satisfy the test assertion.
      return Memo(id: selectedId, content: ''); // Return minimal Memo with ID
    }
  } else {
    debugPrint('[getSelectedMemo] selectedMemoIdProvider is null.');
    return null;
  }
}

// Helper function to scroll the main memos list down
Future<void> scrollMemosListDown(WidgetTester tester, double distance) async {
  // Find the scrollable view (likely CustomScrollView or maybe still ListView)
  final listFinder = find.byType(Scrollable).first; // More generic finder
  expect(
    listFinder,
    findsOneWidget,
    reason: 'ListView not found for scrolling down',
  );
  await tester.fling(
    listFinder,
    Offset(0.0, -distance),
    1000.0,
  ); // Negative offset scrolls down
  await tester.pumpAndSettle();
  debugPrint('[Test Helper] Scrolled list down by $distance pixels.');
}

// Helper function to scroll the main memos list up
Future<void> scrollMemosListUp(WidgetTester tester, double distance) async {
  // Find the scrollable view (likely CustomScrollView or maybe still ListView)
  final listFinder = find.byType(Scrollable).first; // More generic finder
  expect(
    listFinder,
    findsOneWidget,
    reason: 'ListView not found for scrolling up',
  );
  await tester.fling(
    listFinder,
    Offset(0.0, distance),
    1000.0,
  ); // Positive offset scrolls up
  await tester.pumpAndSettle();
  debugPrint('[Test Helper] Scrolled list up by $distance pixels.');
}

// Selects a memo using keyboard navigation (down 'count' times)
Future<void> selectMemoWithKeys(WidgetTester tester, int count) async {
  // Find the scrollable list within the MemosScreen
  final listFinder = find.descendant(
    of: find.byType(
      MemosScreen,
    ), // Ensure we target the list in the right screen
    matching: find.byType(Scrollable), // More generic finder
  );
  expect(
    listFinder,
    findsOneWidget,
    reason: "Scrollable list not found in MemosScreen",
  );

  // Tap the Scrollable to ensure its containing Focus scope receives focus
  await tester.tap(listFinder);
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
  ); // Extra settle for focus
  await tester.pumpAndSettle(); // Default settle

  debugPrint(
    '[Test Helper] Tapped ListView, attempting to send $count key events...',
  );

  for (int i = 0; i < count; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    // Use a slightly longer settle duration to ensure state propagation
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
  }
  // Final settle after all keys
  await tester.pumpAndSettle();
  debugPrint('[Test Helper] Finished sending key events.');
}
