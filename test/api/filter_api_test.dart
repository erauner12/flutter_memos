import 'dart:math' show min;

import 'package:flutter_memos/services/api_service.dart'; // Import MemosApiService
import 'package:flutter_memos/utils/filter_builder.dart'; // Import FilterBuilder
import 'package:flutter_test/flutter_test.dart';

// Set this to true to run the API tests
// Since there's no '--no-skip' flag in Flutter test, we'll use a manual toggle
const bool RUN_FILTER_API_TESTS =
    true; // Default to false to avoid accidental runs

void main() {
  group('Filter Expression API Tests', () {
    late MemosApiService apiService; // Use MemosApiService

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
          'WARNING: Filter API test environment variables not set. Skipping tests in this group.',
        );
      }

      apiService = MemosApiService(); // Use MemosApiService
      // Configure the service *before* any tests run
      apiService.configureService(baseUrl: baseUrl, authToken: apiKey);
      MemosApiService.verboseLogging = true; // Access via concrete class
      // ApiService.useFilterExpressions = true; // This flag is likely removed/obsolete
    });

    test('Basic filter expressions work with the API', () async {
      // Skip this test unless RUN_FILTER_API_TESTS is true AND config is present
      const baseUrl = String.fromEnvironment(
        'MEMOS_TEST_API_BASE_URL',
        defaultValue: '',
      );
      if (!RUN_FILTER_API_TESTS || baseUrl.isEmpty) {
        print(
          'Skipping filter API test - RUN_FILTER_API_TESTS is false or env vars missing',
        );
        return;
      }

      print('\n=== TESTING BASIC FILTER EXPRESSIONS ===');

      // Test basic tag filter using FilterBuilder
      final tagFilter = FilterBuilder.byTags(['test']);
      print('\n[TEST] Filtering by tag using CEL: "$tagFilter"');
      final memosByTag = await apiService.listNotes(
        // Use listNotes
        filter: tagFilter,
      );
      print(
        '[RESULT] Found ${memosByTag.notes.length} memos with tag "test"',
      ); // Use .notes

      // Test filtering by visibility using FilterBuilder
      final visibilityFilter = FilterBuilder.byVisibility('PUBLIC');
      print('\n[TEST] Filtering by visibility using CEL: "$visibilityFilter"');
      final memosByVisibility = await apiService.listNotes(
        // Use listNotes
        filter: visibilityFilter,
      );
      print(
        '[RESULT] Found ${memosByVisibility.notes.length} PUBLIC memos',
      ); // Use .notes

      // Test filtering by content using FilterBuilder
      final searchTerm = 'test';
      final contentFilter = FilterBuilder.byContent(searchTerm);
      print('\n[TEST] Filtering by content using CEL: "$contentFilter"');
      final memosByContent = await apiService.listNotes(
        // Use listNotes
        filter: contentFilter,
      );
      print(
        '[RESULT] Found ${memosByContent.notes.length} memos containing "$searchTerm"', // Use .notes
      );

      // Print a sample memo from each result
      if (memosByTag.notes.isNotEmpty) {
        // Use .notes
        print('\nExample memo with tag "test":');
        print('ID: ${memosByTag.notes[0].id}'); // Use .notes
        print(
          'Content: ${memosByTag.notes[0].content.substring(0, min(50, memosByTag.notes[0].content.length))}...', // Use .notes
        );
      }

      if (memosByContent.notes.isNotEmpty) {
        // Use .notes
        print('\nExample memo containing "$searchTerm":');
        print('ID: ${memosByContent.notes[0].id}'); // Use .notes
        print(
          'Content: ${memosByContent.notes[0].content.substring(0, min(50, memosByContent.notes[0].content.length))}...', // Use .notes
        );
      }

      // Verify that the content filter works as expected
      if (memosByContent.notes.isNotEmpty) {
        // Use .notes
        bool foundMatch = false;
        for (var memo in memosByContent.notes) {
          // Use .notes
          if (memo.content.toLowerCase().contains(searchTerm.toLowerCase())) {
            foundMatch = true;
            break;
          }
        }

        expect(
          foundMatch,
          isTrue,
          reason: 'At least one result should contain the search term',
        );
      }
    }, skip: !RUN_FILTER_API_TESTS); // Add skip condition directly to test

    test('Time-based filter expressions work with the API', () async {
        // Skip this test unless RUN_FILTER_API_TESTS is true AND config is present
        const baseUrl = String.fromEnvironment(
          'MEMOS_TEST_API_BASE_URL',
          defaultValue: '',
        );
        if (!RUN_FILTER_API_TESTS || baseUrl.isEmpty) {
          print(
            'Skipping filter API test - RUN_FILTER_API_TESTS is false or env vars missing',
          );
        return;
      }

      print('\n=== TESTING TIME-BASED FILTER EXPRESSIONS ===');

        // Test filtering by time expression "today" using FilterBuilder
        final todayFilter = FilterBuilder.byTimeExpression('today');
        print(
          '\n[TEST] Filtering by time expression using CEL: "$todayFilter"',
        );
        final memosFromToday = await apiService.listNotes(
          // Use listNotes
          filter: todayFilter,
      );
        print(
          '[RESULT] Found ${memosFromToday.notes.length} memos from today',
        ); // Use .notes

        // Test filtering by time expression "this week" using FilterBuilder
        final thisWeekFilter = FilterBuilder.byTimeExpression('this week');
        print(
          '\n[TEST] Filtering by time expression using CEL: "$thisWeekFilter"',
        );
        final memosFromThisWeek = await apiService.listNotes(
          // Use listNotes
          filter: thisWeekFilter,
      );
      print(
          '[RESULT] Found ${memosFromThisWeek.notes.length} memos from this week', // Use .notes
      );

        // Test filtering by time range (created after) using FilterBuilder
      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
        final recentFilter = FilterBuilder.byCreateTime(
          oneWeekAgo,
          operator: '>',
        );
        print('\n[TEST] Filtering by created after using CEL: "$recentFilter"');
        final recentMemos = await apiService.listNotes(
          // Use listNotes
          filter: recentFilter,
      );
      print(
          '[RESULT] Found ${recentMemos.notes.length} memos created in the last 7 days', // Use .notes
      );

      // Print a sample memo from each result
        if (memosFromToday.notes.isNotEmpty) {
          // Use .notes
        print('\nExample memo from today:');
          print('ID: ${memosFromToday.notes[0].id}'); // Use .notes
          print(
            'Create Time: ${memosFromToday.notes[0].createTime}',
          ); // Use .notes
          print(
            'Content: ${memosFromToday.notes[0].content.substring(0, min(50, memosFromToday.notes[0].content.length))}...', // Use .notes
        );
      }

        if (recentMemos.notes.isNotEmpty) {
          // Use .notes
        print('\nExample memo from last 7 days:');
          print('ID: ${recentMemos.notes[0].id}'); // Use .notes
          print(
            'Create Time: ${recentMemos.notes[0].createTime}',
          ); // Use .notes
          print(
            'Content: ${recentMemos.notes[0].content.substring(0, min(50, recentMemos.notes[0].content.length))}...', // Use .notes
        );
      }
      },
      skip: !RUN_FILTER_API_TESTS,
    ); // Add skip condition directly to test

    test('Combined filter expressions work with the API', () async {
      // Skip this test unless RUN_FILTER_API_TESTS is true AND config is present
      const baseUrl = String.fromEnvironment(
        'MEMOS_TEST_API_BASE_URL',
        defaultValue: '',
      );
      if (!RUN_FILTER_API_TESTS || baseUrl.isEmpty) {
        print(
          'Skipping filter API test - RUN_FILTER_API_TESTS is false or env vars missing',
        );
        return;
      }

      print('\n=== TESTING COMBINED FILTER EXPRESSIONS ===');

      // Test combining content search with visibility using FilterBuilder.and
      final searchTerm = 'test';
      final contentFilter = FilterBuilder.byContent(searchTerm);
      final visibilityFilter = FilterBuilder.byVisibility('PUBLIC');
      final combinedAndFilter = FilterBuilder.and([
        contentFilter,
        visibilityFilter,
      ]);
      print('\n[TEST] Filtering using combined CEL: "$combinedAndFilter"');
      final combinedFilterResponse = await apiService.listNotes(
        // Use listNotes
        filter: combinedAndFilter,
      );
      print(
        '[RESULT] Found ${combinedFilterResponse.notes.length} PUBLIC memos containing "$searchTerm"', // Use .notes
      );

      // Test filtering by content and time expression "this month"
      final thisMonthFilter = FilterBuilder.byTimeExpression('this month');
      final contentAndTimeFilter = FilterBuilder.and([
        contentFilter,
        thisMonthFilter,
      ]);
      print('\n[TEST] Filtering using combined CEL: "$contentAndTimeFilter"');
      final contentAndTimeMemos = await apiService.listNotes(
        // Use listNotes
        filter: contentAndTimeFilter,
      );
      print(
        '[RESULT] Found ${contentAndTimeMemos.notes.length} memos from this month containing "$searchTerm"', // Use .notes
      );

      // Print a sample memo from each result
      if (combinedFilterResponse.notes.isNotEmpty) {
        // Use .notes
        print('\nExample memo matching combined filter:');
        print('ID: ${combinedFilterResponse.notes[0].id}'); // Use .notes
        print(
          'Visibility: ${combinedFilterResponse.notes[0].visibility}',
        ); // Use .notes
        print(
          'Content: ${combinedFilterResponse.notes[0].content.substring(0, min(50, combinedFilterResponse.notes[0].content.length))}...', // Use .notes
        );
      }

      // Verify that the combined filter works as expected
      if (combinedFilterResponse.notes.isNotEmpty) {
        // Use .notes
        for (var memo in combinedFilterResponse.notes) {
          // Use .notes
          expect(
            memo.visibility.toString().split('.').last.toUpperCase(),
            equals('PUBLIC'),
          ); // Compare enum string representation
          expect(
            memo.content.toLowerCase().contains(searchTerm.toLowerCase()),
            isTrue,
          );
        }
      }
    }, skip: !RUN_FILTER_API_TESTS); // Add skip condition directly to test

    // This test remains largely the same as it already used the 'filter' parameter
    test('Raw CEL filter expressions work with the API', () async {
      // Skip this test unless RUN_FILTER_API_TESTS is true AND config is present
      const baseUrl = String.fromEnvironment(
        'MEMOS_TEST_API_BASE_URL',
        defaultValue: '',
      );
      if (!RUN_FILTER_API_TESTS || baseUrl.isEmpty) {
        print(
          'Skipping filter API test - RUN_FILTER_API_TESTS is false or env vars missing',
        );
        return;
      }

      print('\n=== TESTING RAW CEL FILTER EXPRESSIONS ===');

      // Test direct CEL filter expression
      // Using a filter that we know matches existing data based on the previous tests
      final rawCelFilter = 'content.contains("test") && visibility == "PUBLIC"';
      print('\n[TEST] Using raw CEL filter: "$rawCelFilter"');

      final response = await apiService.listNotes(
        // Use listNotes
        filter: rawCelFilter,
      );

      print(
        '[RESULT] Found ${response.notes.length} memos matching raw CEL filter', // Use .notes
      );

      // Print a sample memo
      if (response.notes.isNotEmpty) {
        // Use .notes
        print('\nExample memo matching raw CEL filter:');
        print('ID: ${response.notes[0].id}'); // Use .notes
        print('Visibility: ${response.notes[0].visibility}'); // Use .notes
        print(
          'Content: ${response.notes[0].content.substring(0, min(50, response.notes[0].content.length))}...', // Use .notes
        );

        // Verify it matches the filter criteria
        expect(
          response.notes[0].visibility.toString().split('.').last.toUpperCase(),
          equals('PUBLIC'),
        ); // Compare enum string representation
        expect(
          response.notes[0].content.toLowerCase().contains('test'),
          isTrue,
        );
      }

      // Test a more complex CEL filter with dates
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final formattedDate = yesterday.toUtc().toIso8601String();

      final dateFilter =
          'update_time > timestamp("$formattedDate") && visibility == "PUBLIC"'; // Use timestamp() for CEL
      print('\n[TEST] Using date-based CEL filter: "$dateFilter"');

      final dateFilterResponse = await apiService.listNotes(
        // Use listNotes
        filter: dateFilter,
      );

      print(
        '[RESULT] Found ${dateFilterResponse.notes.length} PUBLIC memos updated since yesterday', // Use .notes
      );

      if (dateFilterResponse.notes.isNotEmpty) {
        // Use .notes
        print('\nExample recently updated memo:');
        print('ID: ${dateFilterResponse.notes[0].id}'); // Use .notes
        print(
          'Updated: ${dateFilterResponse.notes[0].updateTime}',
        ); // Use .notes
        print(
          'Content: ${dateFilterResponse.notes[0].content.substring(0, min(50, dateFilterResponse.notes[0].content.length))}...', // Use .notes
        );
      }

      // Basic assertion: Expect some results if the filter is valid and data exists
      // Note: This might fail if your test server has no matching data.
      // expect(response.notes, isNotEmpty, reason: 'Expected results for raw CEL filter');
      // expect(dateFilterResponse.notes, isNotEmpty, reason: 'Expected results for date-based CEL filter');

    }, skip: !RUN_FILTER_API_TESTS); // Add skip condition directly to test
  });
}