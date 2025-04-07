import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter_memos/main.dart' as app;
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Pull-to-Refresh Integration Test', () {
    // Helper function to create a memo PROGRAMMATICALLY
    Future<Memo?> createMemoProgrammatically(String content) async {
      debugPrint(
        '[Test Setup] Attempting to create memo programmatically: "$content"',
      );
      try {
        final apiService = ApiService();
        final newMemo = Memo(
          id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
          content: content,
          visibility: 'PUBLIC',
        );
        final createdMemo = await apiService.createMemo(newMemo);
        debugPrint(
          '[Test Setup] Programmatic memo creation successful. ID: ${createdMemo.id}',
        );
        return createdMemo;
      } catch (e, stackTrace) {
        debugPrint(
          '[Test Setup] Error creating memo programmatically: $e\n$stackTrace',
        );
        // Fail the test explicitly if setup fails
        fail('Failed to create memo programmatically: $e');
      }
    }

    testWidgets('Pull-to-refresh fetches newly created memo',
        (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2)); // Wait for initial load

      // --- Test Setup ---
      final uniqueContent =
          'Pull-to-refresh test memo ${DateTime.now().millisecondsSinceEpoch}';
      // Use find.textContaining with findRichText for markdown content
      final memoFinder = find.textContaining(uniqueContent, findRichText: true);

      // 1. Verify the memo is NOT initially visible
      expect(memoFinder, findsNothing,
          reason: 'Memo should not be visible before creation and refresh');

      // 2. Create a memo PROGRAMMATICALLY (behind the scenes)
      final createdMemo = await createMemoProgrammatically(uniqueContent);
      expect(createdMemo, isNotNull, reason: 'Memo creation should succeed');

      // 3. Verify the memo is STILL NOT visible (before refresh)
      await tester.pumpAndSettle(); // Allow UI to potentially update if auto-refresh existed
      expect(memoFinder, findsNothing,
          reason: 'Memo should not be visible before manual refresh');

      // 4. Find the scrollable list (might be ListView, CustomScrollView, etc.)
      // Use a more generic finder
      final listFinder = find.byType(Scrollable).first;
      expect(listFinder, findsOneWidget,
        reason: 'Scrollable list should be present to refresh',
      );

      // 5. Simulate the pull-to-refresh gesture (CupertinoSliverRefreshControl handles this)
      debugPrint('[Test Action] Simulating pull-to-refresh...');
      // Drag down from the center of the list view
      await tester.fling(listFinder, const Offset(0.0, 400.0), 1000.0);
      // Wait for the refresh indicator to appear and the refresh operation to complete
      // CupertinoSliverRefreshControl might have different timing
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 500)); // Show indicator
      await tester.pumpAndSettle(
        const Duration(seconds: 3),
      ); // Allow time for API call + UI update + indicator dismiss
      debugPrint('[Test Action] Pull-to-refresh simulation complete.');


      // 6. Verify the memo IS NOW visible
      // Scroll down slightly in case it's just off-screen
      await tester.drag(listFinder, const Offset(0.0, -100.0));
      await tester.pumpAndSettle();
      expect(memoFinder, findsOneWidget,
          reason: 'Memo should be visible after pull-to-refresh');

      debugPrint('[Test Verification] Memo found in the list after refresh.');

      // Optional: Clean up the created memo
      try {
        final apiService = ApiService();
        await apiService.deleteMemo(createdMemo!.id);
        debugPrint('[Test Cleanup] Deleted test memo ID: ${createdMemo.id}');
      } catch (e) {
        debugPrint('[Test Cleanup] Error deleting test memo: $e');
        // Don't fail the test for cleanup errors, but log them.
      }
    });
  });
}
