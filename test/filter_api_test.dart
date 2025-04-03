import 'dart:math' show min;

import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

// Set this to true to run the API tests
// Since there's no '--no-skip' flag in Flutter test, we'll use a manual toggle
const bool RUN_FILTER_API_TESTS = true;

void main() {
  group('Filter Expression API Tests', () {
    late ApiService apiService;
    
    setUp(() {
      apiService = ApiService();
      ApiService.verboseLogging = true;
      ApiService.useFilterExpressions = true;
    });
    
    test('Basic filter expressions work with the API', () async {
      // Skip this test unless RUN_FILTER_API_TESTS is true
      if (!RUN_FILTER_API_TESTS) {
        print('Skipping filter API test - set RUN_FILTER_API_TESTS = true to run this test');
        return;
      }
      
      print('\n=== TESTING BASIC FILTER EXPRESSIONS ===');
      
      // Test basic tag filter
      print('\n[TEST] Filtering by tag: "test"');
      final memosByTag = await apiService.listMemos(
        parent: 'users/1',
        tags: ['test'],
      );
      print('[RESULT] Found ${memosByTag.memos.length} memos with tag "test"');
      
      // Test filtering by visibility
      print('\n[TEST] Filtering by visibility: PUBLIC');
      final memosByVisibility = await apiService.listMemos(
        parent: 'users/1',
        visibility: 'PUBLIC',
      );
      print('[RESULT] Found ${memosByVisibility.memos.length} PUBLIC memos');
      
      // Test filtering by content - choose a keyword likely to be in your memos
      final searchTerm = 'test';
      print('\n[TEST] Filtering by content containing: "$searchTerm"');
      final memosByContent = await apiService.listMemos(
        parent: 'users/1',
        contentSearch: searchTerm,
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
        
        expect(foundMatch, isTrue, reason: 'At least one result should contain the search term');
      }
    });
    
    test('Time-based filter expressions work with the API', () async {
      // Skip this test unless RUN_FILTER_API_TESTS is true
      if (!RUN_FILTER_API_TESTS) {
        print('Skipping filter API test - set RUN_FILTER_API_TESTS = true to run this test');
        return;
      }
      
      print('\n=== TESTING TIME-BASED FILTER EXPRESSIONS ===');
      
      // Test filtering by time expression
      print('\n[TEST] Filtering by time expression: "today"');
      final memosFromToday = await apiService.listMemos(
        parent: 'users/1',
        timeExpression: 'today',
      );
      print('[RESULT] Found ${memosFromToday.memos.length} memos from today');
      
      // Test filtering by time expression
      print('\n[TEST] Filtering by time expression: "this week"');
      final memosFromThisWeek = await apiService.listMemos(
        parent: 'users/1',
        timeExpression: 'this week',
      );
      print(
        '[RESULT] Found ${memosFromThisWeek.memos.length} memos from this week',
      );
      
      // Test filtering by time range
      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
      print('\n[TEST] Filtering by created after: ${oneWeekAgo.toIso8601String()}');
      final recentMemos = await apiService.listMemos(
        parent: 'users/1',
        createdAfter: oneWeekAgo,
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
    });
    
    test('Combined filter expressions work with the API', () async {
      // Skip this test unless RUN_FILTER_API_TESTS is true
      if (!RUN_FILTER_API_TESTS) {
        print('Skipping filter API test - set RUN_FILTER_API_TESTS = true to run this test');
        return;
      }
      
      print('\n=== TESTING COMBINED FILTER EXPRESSIONS ===');
      
      // Test combining content search with visibility
      final searchTerm = 'test';
      print('\n[TEST] Filtering by content: "$searchTerm" AND visibility: PUBLIC');
      final combinedFilter = await apiService.listMemos(
        parent: 'users/1',
        contentSearch: searchTerm,
        visibility: 'PUBLIC',
      );
      print(
        '[RESULT] Found ${combinedFilter.memos.length} PUBLIC memos containing "$searchTerm"',
      );
      
      // Test filtering by content and time expression
      print('\n[TEST] Filtering by content: "$searchTerm" AND time: "this month"');
      final contentAndTimeMemos = await apiService.listMemos(
        parent: 'users/1',
        contentSearch: searchTerm,
        timeExpression: 'this month',
      );
      print(
        '[RESULT] Found ${contentAndTimeMemos.memos.length} memos from this month containing "$searchTerm"',
      );
      
      // Print a sample memo from each result
      if (combinedFilter.memos.isNotEmpty) {
        print('\nExample memo matching combined filter:');
        print('ID: ${combinedFilter.memos[0].id}');
        print('Visibility: ${combinedFilter.memos[0].visibility}');
        print(
          'Content: ${combinedFilter.memos[0].content.substring(0, min(50, combinedFilter.memos[0].content.length))}...',
        );
      }
      
      // Verify that the combined filter works as expected
      if (combinedFilter.memos.isNotEmpty) {
        for (var memo in combinedFilter.memos) {
          expect(memo.visibility, equals('PUBLIC'));
          expect(memo.content.toLowerCase().contains(searchTerm.toLowerCase()), isTrue);
        }
      }
    });
    test('Raw CEL filter expressions work with the API', () async {
      // Skip this test unless RUN_FILTER_API_TESTS is true
      if (!RUN_FILTER_API_TESTS) {
        print(
          'Skipping filter API test - set RUN_FILTER_API_TESTS = true to run this test',
        );
        return;
      }
      
      print('\n=== TESTING RAW CEL FILTER EXPRESSIONS ===');
      
      // Test direct CEL filter expression
      // Using a filter that we know matches existing data based on the previous tests
      final rawCelFilter = 'content.contains("test") && visibility == "PUBLIC"';
      print('\n[TEST] Using raw CEL filter: "$rawCelFilter"');
      
      final response = await apiService.listMemos(
        parent: 'users/1',
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
      }
      
      // Test a more complex CEL filter with dates
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final formattedDate = yesterday.toUtc().toIso8601String();
      
      final dateFilter =
          'update_time > "$formattedDate" && visibility == "PUBLIC"';
      print('\n[TEST] Using date-based CEL filter: "$dateFilter"');
      
      final dateFilterResponse = await apiService.listMemos(
        parent: 'users/1',
        filter: dateFilter,
      );
      
      print(
        '[RESULT] Found ${dateFilterResponse.memos.length} memos updated in the last day',
      );
      
      if (dateFilterResponse.memos.isNotEmpty) {
        print('\nExample recently updated memo:');
        print('ID: ${dateFilterResponse.memos[0].id}');
        print('Updated: ${dateFilterResponse.memos[0].updateTime}');
        print(
          'Content: ${dateFilterResponse.memos[0].content.substring(0, min(50, dateFilterResponse.memos[0].content.length))}...',
        );
      }

      // We know from the test output that this response should have memos
      expect(
        response.memos.isNotEmpty,
        true,
        reason:
            'Expected to find memos matching content.contains("test") && visibility == "PUBLIC"',
      );

      if (response.memos.isNotEmpty) {
        print('First memo: ${response.memos[0]}');
        // Verify that the memo contains "test" in its content, which we know should be true
        expect(
          response.memos[0].content.toLowerCase().contains('test'),
          true,
          reason: 'Expected memo content to contain "test"',
        );
        expect(
          response.memos[0].visibility,
          equals('PUBLIC'),
          reason: 'Expected memo visibility to be PUBLIC',
        );
      }
    });
  });
}
