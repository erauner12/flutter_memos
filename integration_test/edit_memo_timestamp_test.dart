import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_memos/main.dart' as app;
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_memos/screens/edit_memo/edit_memo_screen.dart';
import 'package:flutter_memos/screens/memo_detail/memo_detail_screen.dart';
import 'package:flutter_memos/screens/memos/memos_screen.dart';
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// This test verifies that after editing and saving a memo,
/// it correctly appears at the top of the list when the list is sorted by "Updated Time".
/// It addresses the issue where memos might seem to disappear or lose their position
/// due to timestamp handling inconsistencies between the client and server,
/// especially concerning the `createTime` potentially being reset by the server response.
/// The test ensures our client-side fixes and sorting work correctly in the UI flow.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Use a ProviderContainer to access providers directly in the test setup
  ProviderContainer? container;
  ApiService? apiService;
  String? createdMemoId;

  setUpAll(() async {
    // Initialize ApiService for programmatic creation/deletion
    apiService = ApiService();
    // Ensure the service is configured (assuming defaults or Env vars are okay)
    apiService!.configureService(baseUrl: '', authToken: '');
    await Future.delayed(const Duration(milliseconds: 500)); // Allow config time
  });

  // Teardown function to delete the memo after the test
  tearDown(() async {
    if (createdMemoId != null && apiService != null) {
      debugPrint('[Test Teardown] Deleting test memo: $createdMemoId');
      try {
        await apiService!.deleteMemo(createdMemoId!);
        debugPrint('[Test Teardown] Successfully deleted test memo.');
      } catch (e) {
        debugPrint('[Test Teardown] Error deleting test memo $createdMemoId: $e');
      }
      createdMemoId = null;
    }
    container?.dispose(); // Dispose container if used
  });

  testWidgets('Edit memo, save, and verify position in list sorted by update time', (WidgetTester tester) async {
    // --- Test Setup ---
    debugPrint('[Test Setup] Creating initial memo programmatically...');
    final initialContent = 'Timestamp Integration Test - ${DateTime.now()}';
    final initialMemo = Memo(id: 'temp', content: initialContent, visibility: 'PUBLIC');
    final createdMemo = await apiService!.createMemo(initialMemo);
    createdMemoId = createdMemo.id; // Store for teardown
    expect(createdMemoId, isNotNull);
    expect(createdMemoId, isNotEmpty);
    debugPrint('[Test Setup] Created memo ID: $createdMemoId');

    // --- Test Execution ---
    // Launch the app
    app.main();
    // Wait significantly longer for initial load, API calls, and rendering
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Get the ProviderContainer from the app's root widget
    final element = tester.element(find.byType(ProviderScope));
    container = ProviderScope.containerOf(element);

    // Ensure we are on the MemosScreen and sorting by Updated Time
    expect(find.byType(MemosScreen), findsOneWidget, reason: 'Should be on MemosScreen');
    final sortMode = container!.read(memoSortModeProvider);
    if (sortMode != MemoSortMode.byUpdateTime) {
      debugPrint('[Test Action] Setting sort mode to byUpdateTime');
      await tester.tap(find.textContaining('Sort by:'));
      await tester.pumpAndSettle();
    }
    expect(container!.read(memoSortModeProvider), MemoSortMode.byUpdateTime);
    debugPrint('[Test State] Sort mode is byUpdateTime');

    // Refresh list to ensure the new memo is visible
    debugPrint('[Test Action] Refreshing memo list...');
    await tester.fling(find.byType(ListView), const Offset(0.0, 400.0), 1000.0);
    await tester.pumpAndSettle(const Duration(seconds: 3)); // Wait for refresh

    // Find the newly created memo card
    debugPrint('[Test Verification] Looking for memo card with ID: $createdMemoId');
    final memoCardFinder = find.widgetWithText(MemoCard, initialContent, skipOffstage: false);

    // Scroll until the memo is found (it might not be on the first screen)
    int scrollAttempts = 0;
    while (memoCardFinder.evaluate().isEmpty && scrollAttempts < 5) {
      debugPrint('[Test Action] Scrolling down to find memo...');
      await tester.drag(find.byType(ListView).first, const Offset(0, -300));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      scrollAttempts++;
    }
    expect(memoCardFinder, findsOneWidget, reason: 'Failed to find the created memo card ($createdMemoId) in the list');
    debugPrint('[Test Verification] Found memo card');

    // Tap the memo card to navigate to detail
    await tester.tap(memoCardFinder);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byType(MemoDetailScreen), findsOneWidget, reason: 'Should navigate to MemoDetailScreen');
    debugPrint('[Test Action] Navigated to Memo Detail');

    // Tap the edit button
    await tester.tap(find.widgetWithIcon(IconButton, Icons.edit));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byType(EditMemoScreen), findsOneWidget, reason: 'Should navigate to EditMemoScreen');
    debugPrint('[Test Action] Navigated to Edit Memo');

    // Modify the content
    final String textToAppend = ' - Edited @ ${DateTime.now()}';
    final textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);
    await tester.enterText(textFieldFinder, initialContent + textToAppend);
    await tester.pumpAndSettle();
    debugPrint('[Test Action] Entered new text');

    // Save using Command+Enter
    debugPrint('[Test Action] Simulating Command+Enter to save...');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pumpAndSettle(const Duration(seconds: 3)); // Wait for save and navigation back

    // Verify back on Detail Screen
    expect(find.byType(MemoDetailScreen), findsOneWidget, reason: 'Should navigate back to MemoDetailScreen after saving');
    debugPrint('[Test Verification] Navigated back to Detail Screen');

    // Navigate back to the List Screen
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle(const Duration(seconds: 2)); // Wait for list to potentially refresh
    expect(find.byType(MemosScreen), findsOneWidget, reason: 'Should navigate back to MemosScreen');
    debugPrint('[Test Verification] Navigated back to List Screen');

    // --- Final Verification ---
    debugPrint('[Test Verification] Verifying updated memo is at the top of the list...');

    // Ensure the list has finished loading/updating
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Find all MemoCard widgets again
    final memoCardsAfterUpdate = find.byType(MemoCard);
    expect(memoCardsAfterUpdate, findsWidgets);

    // Get the widget associated with the first MemoCard
    final firstMemoCardWidget = tester.widget<MemoCard>(memoCardsAfterUpdate.first);

    debugPrint('[Test Verification] First memo card ID in list: ${firstMemoCardWidget.id}');
    debugPrint('[Test Verification] Expected memo card ID: $createdMemoId');

    // Assert that the ID of the first memo card matches the ID of the memo we created and edited
    expect(
      firstMemoCardWidget.id,
      equals(createdMemoId),
      reason: 'The edited memo (ID: $createdMemoId) should be the first item in the list when sorted by update time.',
    );
    debugPrint('[Test Verification] SUCCESS: Edited memo is correctly positioned at the top.');
  });
}
