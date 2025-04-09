import 'dart:math' show min;

import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_memos/utils/filter_builder.dart'; // Import FilterBuilder
import 'package:flutter_test/flutter_test.dart';

// Set this to true to run the API tests
// Since there's no '--no-skip' flag in Flutter test, we'll use a manual toggle
const bool RUN_FILTER_API_TESTS =
    true; // Default to false to avoid accidental runs

void main() {
  group('Filter Expression API Tests', () {
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
          'WARNING: Filter API test environment variables not set. Skipping tests in this group.',
        );
      }

      apiService = ApiService();
      // Configure the service *before* any tests run
      apiService.configureService(baseUrl: baseUrl, authToken: apiKey);
      ApiService.verboseLogging = true;
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
      final memosByTag = await apiService.listMemos(
        parent: 'users/-', // Use 'users/-' for current user
        filter: tagFilter,
      );
      print('[RESULT] Found ${memosByTag.memos.length} memos with tag "test"');

      // Test filtering by visibility using FilterBuilder
      final visibilityFilter = FilterBuilder.byVisibility('PUBLIC');
      print('\n[TEST] Filtering by visibility using CEL: "$visibilityFilter"');
      final memosByVisibility = await apiService.listMemos(
        parent: 'users/-',
        filter: visibilityFilter,
      );
      print('[RESULT] Found ${memosByVisibility.memos.length} PUBLIC memos');

      // Test filtering by content using FilterBuilder
      final searchTerm = 'test';
      final contentFilter = FilterBuilder.byContent(searchTerm);
      print('\n[TEST] Filtering by content using CEL: "$contentFilter"');
      final memosByContent = await apiService.listMemos(
        parent: 'users/-',
        filter: contentFilter,
      );
      print(
        '[RESULT] Found ${memosByContent.memos.length} memos containing "$searchTerm"',
      );

      // Print a sample memo from each result
      if (memosByTag.memos.isNotEmpty) {
        print('\nExample memo with tag "test":');
        print('ID: ${memosByTag.memos[0].id}');
        print(
          'Content: ${memosByTag.memos[0].content.substring(0, min(50, memosByTag.memos[0].content.length))}...',
        );
      }

      if (memosByContent.memos.isNotEmpty) {
        print('\nExample memo containing "$searchTerm":');
        print('ID: ${memosByContent.memos[0].id}');
        print(
          'Content: ${memosByContent.memos[0].content.substring(0, min(50, memosByContent.memos[0].content.length))}...',
        );
      }

      // Verify that the content filter works as expected
      if (memosByContent.memos.isNotEmpty) {
        bool foundMatch = false;
        for (var memo in memosByContent.memos) {
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
      final memosFromToday = await apiService.listMemos(
          parent: 'users/-',
          filter: todayFilter,
      );
      print('[RESULT] Found ${memosFromToday.memos.length} memos from today');

        // Test filtering by time expression "this week" using FilterBuilder
        final thisWeekFilter = FilterBuilder.byTimeExpression('this week');
        print(
          '\n[TEST] Filtering by time expression using CEL: "$thisWeekFilter"',
        );
      final memosFromThisWeek = await apiService.listMemos(
          parent: 'users/-',
          filter: thisWeekFilter,
      );
      print(
        '[RESULT] Found ${memosFromThisWeek.memos.length} memos from this week',
      );

        // Test filtering by time range (created after) using FilterBuilder
      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
        final recentFilter = FilterBuilder.byCreateTime(
          oneWeekAgo,
          operator: '>',
        );
        print('\n[TEST] Filtering by created after using CEL: "$recentFilter"');
      final recentMemos = await apiService.listMemos(
          parent: 'users/-',
          filter: recentFilter,
      );
      print(
        '[RESULT] Found ${recentMemos.memos.length} memos created in the last 7 days',
      );

      // Print a sample memo from each result
      if (memosFromToday.memos.isNotEmpty) {
        print('\nExample memo from today:');
        print('ID: ${memosFromToday.memos[0].id}');
        print('Create Time: ${memosFromToday.memos[0].createTime}');
        print(
          'Content: ${memosFromToday.memos[0].content.substring(0, min(50, memosFromToday.memos[0].content.length))}...',
        );
      }

      if (recentMemos.memos.isNotEmpty) {
        print('\nExample memo from last 7 days:');
        print('ID: ${recentMemos.memos[0].id}');
        print('Create Time: ${recentMemos.memos[0].createTime}');
        print(
          'Content: ${recentMemos.memos[0].content.substring(0, min(50, recentMemos.memos[0].content.length))}...',
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
      final combinedFilterResponse = await apiService.listMemos(
        parent: 'users/-',
        filter: combinedAndFilter,
      );
      print(
        '[RESULT] Found ${combinedFilterResponse.memos.length} PUBLIC memos containing "$searchTerm"',
      );

      // Test filtering by content and time expression "this month"
      final thisMonthFilter = FilterBuilder.byTimeExpression('this month');
      final contentAndTimeFilter = FilterBuilder.and([
        contentFilter,
        thisMonthFilter,
      ]);
      print('\n[TEST] Filtering using combined CEL: "$contentAndTimeFilter"');
      final contentAndTimeMemos = await apiService.listMemos(
        parent: 'users/-',
        filter: contentAndTimeFilter,
      );
      print(
        '[RESULT] Found ${contentAndTimeMemos.memos.length} memos from this month containing "$searchTerm"',
      );

      // Print a sample memo from each result
      if (combinedFilterResponse.memos.isNotEmpty) {
        print('\nExample memo matching combined filter:');
        print('ID: ${combinedFilterResponse.memos[0].id}');
        print('Visibility: ${combinedFilterResponse.memos[0].visibility}');
        print(
          'Content: ${combinedFilterResponse.memos[0].content.substring(0, min(50, combinedFilterResponse.memos[0].content.length))}...',
        );
      }

      // Verify that the combined filter works as expected
      if (combinedFilterResponse.memos.isNotEmpty) {
        for (var memo in combinedFilterResponse.memos) {
          expect(memo.visibility, equals('PUBLIC'));
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

      final response = await apiService.listMemos(
        parent: 'users/-',
        filter: rawCelFilter,
      );

      print(
        '[RESULT] Found ${response.memos.length} memos matching raw CEL filter',
      );

      // Print a sample memo
      if (response.memos.isNotEmpty) {
        print('\nExample memo matching raw CEL filter:');
        print('ID: ${response.memos[0].id}');
        print('Visibility: ${response.memos[0].visibility}');
        print(
          'Content: ${response.memos[0].content.substring(0, min(50, response.memos[0].content.length))}...',
        );

        // Verify it matches the filter criteria
        expect(response.memos[0].visibility, equals('PUBLIC'));
        expect(
          response.memos[0].content.toLowerCase().contains('test'),
          isTrue,
        );
      }

      // Test a more complex CEL filter with dates
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final formattedDate = yesterday.toUtc().toIso8601String();

      final dateFilter =
          'update_time > "$formattedDate" && visibility == "PUBLIC"';
      print('\n[TEST] Using date-based CEL filter: "$dateFilter"');

      final dateFilterResponse = await apiService.listMemos(
        parent: 'users/-',
        filter: dateFilter,
      );

      print(
        '[RESULT] Found ${dateFilterResponse.memos.length} PUBLIC memos updated since yesterday',
      );

      if (dateFilterResponse.memos.isNotEmpty) {
        print('\nExample recently updated memo:');
        print('ID: ${dateFilterResponse.memos[0].id}');
        print('Updated: ${dateFilterResponse.memos[0].updateTime}');
        print(
          'Content: ${dateFilterResponse.memos[0].content.substring(0, min(50, dateFilterResponse.memos[0].content.length))}...',
        );
      }

      // Basic assertion: Expect some results if the filter is valid and data exists
      // Note: This might fail if your test server has no matching data.
      // expect(response.memos, isNotEmpty, reason: 'Expected results for raw CEL filter');
      // expect(dateFilterResponse.memos, isNotEmpty, reason: 'Expected results for date-based CEL filter');

    }, skip: !RUN_FILTER_API_TESTS); // Add skip condition directly to test
  });
}
