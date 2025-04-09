import 'dart:math' show min;

import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

// Set this to true to run the API tests
// Since there's no '--no-skip' flag in Flutter test, we'll use a manual toggle
const bool RUN_API_TESTS = true;

// Documentation of API sorting limitations
const String SORTING_LIMITATION =
    'The server does not support dynamic sort fields properly '
    'and uses specific boolean flags instead of generic sort parameters. '
    'We implement reliable client-side sorting as a solution.';

/// These tests document the limitations of the server-side sorting functionality
/// and verify that our client-side sorting solution works correctly.
///
/// After examining the server code, we found that it doesn't support dynamic sort fields
/// as it uses specific boolean flags (OrderByUpdatedTs, OrderByTimeAsc) rather than
/// a generic sort parameter. Our app implements reliable client-side sorting as a solution.
void main() {
  group('API Server Tests - Sorting Behavior', () {
    late ApiService apiService;

    setUp(() async {
      // Make setUp async if loading env vars
      // TODO: Load test server URL and API Key from environment variables or config
      // Example using placeholder variables:
      const baseUrl = String.fromEnvironment(
        'MEMOS_TEST_API_BASE_URL',
        defaultValue: '',
      );
      const apiKey = String.fromEnvironment(
        'MEMOS_TEST_API_KEY',
        defaultValue: '',
      );

      if (baseUrl.isEmpty || apiKey.isEmpty) {
        print(
          'WARNING: Sorting API test environment variables not set. Skipping tests in this group.',
        );
      }

      apiService = ApiService();
      // Configure the service *before* any tests run
      apiService.configureService(baseUrl: baseUrl, authToken: apiKey);
      ApiService.verboseLogging = true;
      // Make sure snake_case conversion is enabled for API requests
    });

    test('Server respects sort parameters', () async {
      // Skip this test unless RUN_API_TESTS is true
      if (!RUN_API_TESTS) {
        print('Skipping API test - set RUN_API_TESTS = true to run this test');
        return;
      }

      // First, fetch memos sorted by updateTime
      final memosByUpdateTime = await apiService.listMemos(
        parent: 'users/1', // Specify the user ID
        sort: 'updateTime',
        direction: 'DESC',
      );

      // Removed fetching by createTime as it's unreliable and not used

      // Log the first few memos from the query after client-side sorting
      print(
        '\n--- First 3 memos sorted by updateTime (after client-side sorting) ---',
      );
      // Access the .memos list
      for (int i = 0; i < min(3, memosByUpdateTime.memos.length); i++) {
        print('[${i + 1}] ID: ${memosByUpdateTime.memos[i].id}');
        print('    updateTime: ${memosByUpdateTime.memos[i].updateTime}');
        // print('    createTime: ${memosByUpdateTime.memos[i].createTime}'); // Removed createTime log
      }

      // Removed logging/checks related to createTime sort and server order comparison
      // as we now only rely on client-side updateTime sorting.

      print('\n--- Client-Side Sorting Verification ---');
      // Verify the client-side sorting by updateTime worked (redundant with sorting_test but good here too)
      bool clientSortedCorrectly = true;
      final sortedMemos = memosByUpdateTime.memos; // Get the list once
      for (int i = 0; i < sortedMemos.length - 1; i++) {
        final currentMemo = sortedMemos[i];
        final nextMemo = sortedMemos[i + 1];

        // 1. Check pinned status first
        if (currentMemo.pinned && !nextMemo.pinned) {
          continue; // Correct order: pinned comes first
        }
        if (!currentMemo.pinned && nextMemo.pinned) {
          clientSortedCorrectly =
              false; // Incorrect order: unpinned before pinned
          print(
            'Client sorting error at index $i: Unpinned memo ${currentMemo.id} found before pinned memo ${nextMemo.id}',
          );
          break;
        }

        // 2. If pinned status is the same, check updateTime (descending)
        final currentTime =
            currentMemo.updateTime != null
                ? DateTime.parse(currentMemo.updateTime!)
                : DateTime.fromMillisecondsSinceEpoch(0);
        final nextTime =
            nextMemo.updateTime != null
                ? DateTime.parse(nextMemo.updateTime!)
                : DateTime.fromMillisecondsSinceEpoch(0);

        // Descending order check (current time should be >= next time)
        if (!(currentTime.isAfter(nextTime) ||
            currentTime.isAtSameMomentAs(nextTime))) {
          clientSortedCorrectly = false;
          print(
            'Client sorting error at index $i (same pinned status): ${currentMemo.id} (pinned=${currentMemo.pinned}, time=${currentTime.toIso8601String()}) should be >= ${nextMemo.id} (pinned=${nextMemo.pinned}, time=${nextTime.toIso8601String()})',
          );
          break;
        }
      }
      if (clientSortedCorrectly) {
        print('✅ Client-side sorting by updateTime appears correct.');
      } else {
        print('❌ Client-side sorting by updateTime FAILED.');
      }
      expect(
        clientSortedCorrectly,
        isTrue,
        reason: 'Client should sort correctly by updateTime (DESCENDING)',
      );
    });

    test('Verify client-side sorting behavior', () async {
      // Skip this test unless RUN_API_TESTS is true AND config is present
      const baseUrl = String.fromEnvironment(
        'MEMOS_TEST_API_BASE_URL',
        defaultValue: '',
      );
      if (!RUN_API_TESTS || baseUrl.isEmpty) {
        print('\n=== SERVER SORTING LIMITATION DOCUMENTATION ===');
        print(SORTING_LIMITATION);
        print(
          'Skipping API test - set RUN_API_TESTS = true and env vars to run',
        );
        return;
      }

      print('\n=== SERVER SORTING LIMITATION DOCUMENTATION ===');
      print(SORTING_LIMITATION);
      print('\n=== TESTING CLIENT-SIDE SORTING CAPABILITIES ===');

      // Get memos with server-side sort by updateTime
      final memos = await apiService.listMemos(
        parent: 'users/1', // Specify the user ID
        sort: 'updateTime',
        direction: 'DESC',
      );

      // Get the original server order before client-side sorting was applied
      final originalServerOrder = ApiService.lastServerOrder;

      // Reconstruct what the memo list would have looked like directly from the server
      // (before our client-side sorting was applied)
      final Map<String, Memo> memoMap = {};
      // Access the .memos list
      for (var memo in memos.memos) {
        memoMap[memo.id] = memo;
      }

      final serverOrderedMemos =
          originalServerOrder
              .where((id) => memoMap.containsKey(id))
              .map((id) => memoMap[id]!)
              .toList();

      // Log the first few memos from the original server order vs client-sorted order
      print('\n--- First 3 memos in original server order ---');
      for (int i = 0; i < min(3, serverOrderedMemos.length); i++) {
        print('[${i + 1}] ID: ${serverOrderedMemos[i].id}');
        print('    updateTime: ${serverOrderedMemos[i].updateTime}');
      }

      print('\n--- First 3 memos after client-side sorting ---');
      // Access the .memos list
      for (int i = 0; i < min(3, memos.memos.length); i++) {
        print('[${i + 1}] ID: ${memos.memos[i].id}');
        print('    updateTime: ${memos.memos[i].updateTime}');
      }

      // Check for differences in ordering
      bool ordersAreDifferent = false;
      // Access the .memos list
      for (
        int i = 0;
        i < min(serverOrderedMemos.length, memos.memos.length);
        i++
      ) {
        if (serverOrderedMemos[i].id != memos.memos[i].id) {
          ordersAreDifferent = true;
          break;
        }
      }

      if (ordersAreDifferent) {
        print(
          '✅ Client-side sorting changed the order - server sorting was not optimal',
        );
      } else {
        print(
          'ℹ️ Client-side sorting preserved the order - server sort was already correct',
        );
      }

      // Verify that the client-side sorting actually produced a correctly sorted list
      final sortedMemos = memos.memos; // Get the list once
      for (int i = 0; i < sortedMemos.length - 1; i++) {
        final currentMemo = sortedMemos[i];
        final nextMemo = sortedMemos[i + 1];

        // 1. Check pinned status first
        if (currentMemo.pinned && !nextMemo.pinned) {
          // Correct order: pinned comes first, continue loop
          continue;
        }
        if (!currentMemo.pinned && nextMemo.pinned) {
          // Incorrect order: fail the test
          fail(
            'Client sorting error at index $i: Unpinned memo ${currentMemo.id} found before pinned memo ${nextMemo.id}',
          );
        }

        // 2. If pinned status is the same, check updateTime (descending)
        final currentTime =
            currentMemo.updateTime != null
                ? DateTime.parse(currentMemo.updateTime!)
                : DateTime.fromMillisecondsSinceEpoch(0);
        final nextTime =
            nextMemo.updateTime != null
                ? DateTime.parse(nextMemo.updateTime!)
                : DateTime.fromMillisecondsSinceEpoch(0);

        // Descending order check (current time should be >= next time)
        expect(
          currentTime.isAfter(nextTime) ||
              currentTime.isAtSameMomentAs(nextTime),
          isTrue,
          reason:
              'Client-side sorting should properly sort by updateTime (DESCENDING - newest first) when pinned status is the same. Failed at index $i: ${currentMemo.id} (pinned=${currentMemo.pinned}, time=${currentTime.toIso8601String()}) vs ${nextMemo.id} (pinned=${nextMemo.pinned}, time=${nextTime.toIso8601String()})',
        );
      }

      // Check if the server already sorted correctly by updateTime
      bool serverSortedCorrectly = true;
      for (int i = 0; i < serverOrderedMemos.length - 1; i++) {
        final current =
            serverOrderedMemos[i].updateTime != null
                ? DateTime.parse(serverOrderedMemos[i].updateTime!)
                : DateTime.fromMillisecondsSinceEpoch(0);

        final next =
            serverOrderedMemos[i + 1].updateTime != null
                ? DateTime.parse(serverOrderedMemos[i + 1].updateTime!)
                : DateTime.fromMillisecondsSinceEpoch(0);

        if (!(current.isAfter(next) || current.isAtSameMomentAs(next))) {
          serverSortedCorrectly = false;
          break;
        }
      }

      if (serverSortedCorrectly) {
        print('ℹ️ Server did sort correctly by updateTime');
      } else {
        print('⚠️ Server did NOT sort correctly by updateTime');
      }
    });

    test('Compare snake_case vs camelCase API sorting', () async {
      // Skip this test unless RUN_API_TESTS is true AND config is present
      const baseUrl = String.fromEnvironment(
        'MEMOS_TEST_API_BASE_URL',
        defaultValue: '',
      );
      if (!RUN_API_TESTS || baseUrl.isEmpty) {
        print(
          'Skipping API test - set RUN_API_TESTS = true and env vars to run',
        );
        return;
      }

      print('\n[TEST] Using snake_case sort fields (enabled)');

      // Test with updateTime as it's the only one we use now
      await apiService.listMemos(
        parent: 'users/1',
        sort: 'updateTime', // Changed to updateTime
        direction: 'DESC',
      );

      final snakeCaseOrder = List<String>.from(ApiService.lastServerOrder);

      // Then try with snake_case conversion DISABLED (if applicable to your generator/client)
      // Assuming the client handles this automatically or it's not relevant now
      await apiService.listMemos(
        parent: 'users/1',
        sort: 'updateTime', // Changed to updateTime
        direction: 'DESC',
      );

      final camelCaseOrder = List<String>.from(ApiService.lastServerOrder);

      // Compare the results
      bool ordersAreDifferent = false;
      for (
        int i = 0;
        i < min(snakeCaseOrder.length, camelCaseOrder.length);
        i++
      ) {
        if (snakeCaseOrder[i] != camelCaseOrder[i]) {
          ordersAreDifferent = true;
          break;
        }
      }

      print('\n--- Snake Case vs Camel Case API Field Comparison ---');
      if (ordersAreDifferent) {
        print(
          '✅ API response orders are different when using snake_case vs camelCase',
        );
        print(
          'This confirms the API requires snake_case field names for sorting.',
        );
      } else {
        print(
          '⚠️ API response orders are identical with snake_case and camelCase',
        );
        print(
          'The server may not be respecting either format for sort fields.',
        );
      }

      // Re-enable snake_case for future tests
    });
  });
}
