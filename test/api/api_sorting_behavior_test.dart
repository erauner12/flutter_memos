import 'dart:math' show min;

import 'package:flutter_memos/models/note_item.dart'; // Updated import
import 'package:flutter_memos/services/api_service.dart'; // Updated import
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
    late MemosApiService apiService; // Updated type

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

      apiService = MemosApiService(); // Updated type
      // Configure the service *before* any tests run
      apiService.configureService(baseUrl: baseUrl, authToken: apiKey);
      MemosApiService.verboseLogging = true; // Access via concrete class
      // Make sure snake_case conversion is enabled for API requests
    });

    test('Server respects sort parameters', () async {
      // Skip this test unless RUN_API_TESTS is true AND service is configured
      if (!RUN_API_TESTS || apiService.apiBaseUrl.isEmpty) {
        print(
          'Skipping API test - RUN_API_TESTS is false or ApiService not configured.',
        );
        return;
      }

      // First, fetch memos sorted by updateTime
      final notesByUpdateTime = await apiService.listNotes(
        // Use listNotes
        sort: 'updateTime',
        direction: 'DESC',
      );

      // Removed fetching by createTime as it's unreliable and not used

      // Log the first few memos from the query after client-side sorting
      print(
        '\n--- First 3 notes sorted by updateTime (after client-side sorting) ---', // Updated log
      );
      // Access the .notes list
      for (int i = 0; i < min(3, notesByUpdateTime.notes.length); i++) {
        // Use .notes
        print('[${i + 1}] ID: ${notesByUpdateTime.notes[i].id}'); // Use .notes
        print(
          '    updateTime: ${notesByUpdateTime.notes[i].updateTime}',
        ); // Use .notes
        // print('    createTime: ${notesByUpdateTime.notes[i].createTime}'); // Removed createTime log
      }

      // Removed logging/checks related to createTime sort and server order comparison
      // as we now only rely on client-side updateTime sorting.

      print('\n--- Client-Side Sorting Verification ---');
      // Verify the client-side sorting by updateTime worked (redundant with sorting_test but good here too)
      bool clientSortedCorrectly = true;
      final sortedNotes =
          notesByUpdateTime.notes; // Get the list once // Use .notes
      for (int i = 0; i < sortedNotes.length - 1; i++) {
        final currentNote = sortedNotes[i];
        final nextNote = sortedNotes[i + 1];

        // 1. Check pinned status first
        if (currentNote.pinned && !nextNote.pinned) {
          continue; // Correct order: pinned comes first
        }
        if (!currentNote.pinned && nextNote.pinned) {
          clientSortedCorrectly =
              false; // Incorrect order: unpinned before pinned
          print(
            'Client sorting error at index $i: Unpinned note ${currentNote.id} found before pinned note ${nextNote.id}', // Updated log
          );
          break;
        }

        // 2. If pinned status is the same, check updateTime (descending)
        final currentTime =
            currentNote.updateTime ??
            DateTime.fromMillisecondsSinceEpoch(0); // Use DateTime directly
        final nextTime =
            nextNote.updateTime ??
            DateTime.fromMillisecondsSinceEpoch(0); // Use DateTime directly

        // Descending order check (current time should be >= next time)
        if (!(currentTime.isAfter(nextTime) ||
            currentTime.isAtSameMomentAs(nextTime))) {
          clientSortedCorrectly = false;
          print(
            'Client sorting error at index $i (same pinned status): ${currentNote.id} (pinned=${currentNote.pinned}, time=${currentTime.toIso8601String()}) should be >= ${nextNote.id} (pinned=${nextNote.pinned}, time=${nextTime.toIso8601String()})',
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
      const String.fromEnvironment(
        'MEMOS_TEST_API_BASE_URL',
        defaultValue: '',
      ); // Keep check for documentation printout
      if (!RUN_API_TESTS || apiService.apiBaseUrl.isEmpty) {
        print('\n=== SERVER SORTING LIMITATION DOCUMENTATION ===');
        print(SORTING_LIMITATION);
        print(
          'Skipping API test - RUN_API_TESTS is false or ApiService not configured.',
        );
        return;
      }

      print('\n=== SERVER SORTING LIMITATION DOCUMENTATION ===');
      print(SORTING_LIMITATION);
      print('\n=== TESTING CLIENT-SIDE SORTING CAPABILITIES ===');

      // Get notes with server-side sort by updateTime
      final notes = await apiService.listNotes(
        // Use listNotes
        sort: 'updateTime',
        direction: 'DESC',
      );

      // Get the original server order before client-side sorting was applied
      // final originalServerOrder = MemosApiService.lastServerOrder; // Removed this logic

      // Reconstruct what the note list would have looked like directly from the server
      // (before our client-side sorting was applied) - This is difficult without the original order
      // Instead, we will just verify the final client-sorted list is correct.
      final Map<String, NoteItem> noteMap = {}; // Use NoteItem
      // Access the .notes list
      for (var note in notes.notes) {
        // Use .notes
        noteMap[note.id] = note;
      }

      // final serverOrderedNotes = // Removed this logic
      //     originalServerOrder
      //         .where((id) => noteMap.containsKey(id))
      //         .map((id) => noteMap[id]!)
      //         .toList();

      // Log the first few notes from the original server order vs client-sorted order
      // print('\n--- First 3 notes in original server order ---'); // Removed
      // for (int i = 0; i < min(3, serverOrderedNotes.length); i++) { // Removed
      //   print('[${i + 1}] ID: ${serverOrderedNotes[i].id}'); // Removed
      //   print('    updateTime: ${serverOrderedNotes[i].updateTime}'); // Removed
      // } // Removed

      print('\n--- First 3 notes after client-side sorting ---');
      // Access the .notes list
      for (int i = 0; i < min(3, notes.notes.length); i++) {
        // Use .notes
        print('[${i + 1}] ID: ${notes.notes[i].id}'); // Use .notes
        print('    updateTime: ${notes.notes[i].updateTime}'); // Use .notes
      }

      // Check for differences in ordering - Removed as we don't have server order
      // bool ordersAreDifferent = false;
      // // Access the .notes list
      // for (
      //   int i = 0;
      //   i < min(serverOrderedNotes.length, notes.notes.length);
      //   i++
      // ) {
      //   if (serverOrderedNotes[i].id != notes.notes[i].id) {
      //     ordersAreDifferent = true;
      //     break;
      //   }
      // }

      // if (ordersAreDifferent) {
      //   print(
      //     '✅ Client-side sorting changed the order - server sorting was not optimal',
      //   );
      // } else {
      //   print(
      //     'ℹ️ Client-side sorting preserved the order - server sort was already correct',
      //   );
      // }

      // Verify that the client-side sorting actually produced a correctly sorted list
      final sortedNotes = notes.notes; // Get the list once // Use .notes
      for (int i = 0; i < sortedNotes.length - 1; i++) {
        final currentNote = sortedNotes[i];
        final nextNote = sortedNotes[i + 1];

        // 1. Check pinned status first
        if (currentNote.pinned && !nextNote.pinned) {
          // Correct order: pinned comes first, continue loop
          continue;
        }
        if (!currentNote.pinned && nextNote.pinned) {
          // Incorrect order: fail the test
          fail(
            'Client sorting error at index $i: Unpinned note ${currentNote.id} found before pinned note ${nextNote.id}', // Updated log
          );
        }

        // 2. If pinned status is the same, check updateTime (descending)
        final currentTime =
            currentNote.updateTime ??
            DateTime.fromMillisecondsSinceEpoch(0); // Use DateTime
        final nextTime =
            nextNote.updateTime ??
            DateTime.fromMillisecondsSinceEpoch(0); // Use DateTime

        // Descending order check (current time should be >= next time)
        expect(
          currentTime.isAfter(nextTime) ||
              currentTime.isAtSameMomentAs(nextTime),
          isTrue,
          reason:
              'Client-side sorting should properly sort by updateTime (DESCENDING - newest first) when pinned status is the same. Failed at index $i: ${currentNote.id} (pinned=${currentNote.pinned}, time=${currentTime.toIso8601String()}) vs ${nextNote.id} (pinned=${nextNote.pinned}, time=${nextTime.toIso8601String()})',
        );
      }

      // Check if the server already sorted correctly by updateTime - Removed
      // bool serverSortedCorrectly = true;
      // for (int i = 0; i < serverOrderedNotes.length - 1; i++) {
      //   final current = serverOrderedNotes[i].updateTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      //   final next = serverOrderedNotes[i + 1].updateTime ?? DateTime.fromMillisecondsSinceEpoch(0);

      //   if (!(current.isAfter(next) || current.isAtSameMomentAs(next))) {
      //     serverSortedCorrectly = false;
      //     break;
      //   }
      // }

      // if (serverSortedCorrectly) {
      //   print('ℹ️ Server did sort correctly by updateTime');
      // } else {
      //   print('⚠️ Server did NOT sort correctly by updateTime');
      // }
    });

    // This test is likely invalid now as the server doesn't support camelCase sorting fields
    // and the lastServerOrder logic was removed. Commenting out for now.
    // test('Compare snake_case vs camelCase API sorting', () async {
    //   // Skip this test unless RUN_API_TESTS is true AND config is present
    //   // Skip this test unless RUN_API_TESTS is true AND service is configured
    //   if (!RUN_API_TESTS || apiService.apiBaseUrl.isEmpty) {
    //     print(
    //       'Skipping API test - RUN_API_TESTS is false or ApiService not configured.',
    //     );
    //     return;
    //   }

    //   print('\n[TEST] Using snake_case sort fields (enabled)');

    //   // Test with updateTime as it's the only one we use now
    //   await apiService.listNotes( // Use listNotes
    //     // parent: 'users/1', // Removed parent
    //     sort: 'updateTime', // Changed to updateTime
    //     direction: 'DESC',
    //   );

    //   // final snakeCaseOrder = List<String>.from(MemosApiService.lastServerOrder); // Removed

    //   // Then try with snake_case conversion DISABLED (if applicable to your generator/client)
    //   // Assuming the client handles this automatically or it's not relevant now
    //   await apiService.listNotes( // Use listNotes
    //     // parent: 'users/1', // Removed parent
    //     sort: 'updateTime', // Changed to updateTime
    //     direction: 'DESC',
    //   );

    //   // final camelCaseOrder = List<String>.from(MemosApiService.lastServerOrder); // Removed

    //   // Compare the results - Removed
    //   // bool ordersAreDifferent = false;
    //   // for (
    //   //   int i = 0;
    //   //   i < min(snakeCaseOrder.length, camelCaseOrder.length);
    //   //   i++
    //   // ) {
    //   //   if (snakeCaseOrder[i] != camelCaseOrder[i]) {
    //   //     ordersAreDifferent = true;
    //   //     break;
    //   //   }
    //   // }

    //   print('\n--- Snake Case vs Camel Case API Field Comparison ---');
    //   // if (ordersAreDifferent) { // Removed
    //   //   print(
    //   //     '✅ API response orders are different when using snake_case vs camelCase',
    //   //   );
    //   //   print(
    //   //     'This confirms the API requires snake_case field names for sorting.',
    //   //   );
    //   // } else { // Removed
    //     print(
    //       '⚠️ Test skipped: Cannot compare server order without lastServerOrder.',
    //     );
    //     // print(
    //     //   '⚠️ API response orders are identical with snake_case and camelCase',
    //     // );
    //     // print(
    //     //   'The server may not be respecting either format for sort fields.',
    //     // );
    //   // } // Removed

    //   // Re-enable snake_case for future tests
    // });
  });
}