import 'dart:math' show min;

import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

// Set this to true to run the API tests
// Since there's no '--no-skip' flag in Flutter test, we'll use a manual toggle
const bool RUN_FILTER_API_TESTS = false;

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
      
      // Test filtering by tag - assuming you have memos with the "test" tag
      print('\n[TEST] Filtering by tag: "test"');
      final memosByTag = await apiService.listMemos(
        parent: 'users/1',
        tags: ['test'],
      );
      print('[RESULT] Found ${memosByTag.length} memos with tag "test"');
      
      // Test filtering by visibility
      print('\n[TEST] Filtering by visibility: PUBLIC');
      final memosByVisibility = await apiService.listMemos(
        parent: 'users/1',
        visibility: 'PUBLIC',
      );
      print('[RESULT] Found ${memosByVisibility.length} PUBLIC memos');
      
      // Test filtering by content - choose a keyword likely to be in your memos
      final searchTerm = 'test';
      print('\n[TEST] Filtering by content containing: "$searchTerm"');
      final memosByContent = await apiService.listMemos(
        parent: 'users/1',
        contentSearch: searchTerm,
      );
      print('[RESULT] Found ${memosByContent.length} memos containing "$searchTerm"');
      
      // Print a sample memo from each result
      if (memosByTag.isNotEmpty) {
        print('\nExample memo with tag "test":');
        print('ID: ${memosByTag[0].id}');
        print('Content: ${memosByTag[0].content.substring(0, min(50, memosByTag[0].content.length))}...');
      }
      
      if (memosByContent.isNotEmpty) {
        print('\nExample memo containing "$searchTerm":');
        print('ID: ${memosByContent[0].id}');
        print('Content: ${memosByContent[0].content.substring(0, min(50, memosByContent[0].content.length))}...');
      }
      
      // Verify that the content filter works as expected
      if (memosByContent.isNotEmpty) {
        bool foundMatch = false;
        for (var memo in memosByContent) {
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
      print('[RESULT] Found ${memosFromToday.length} memos from today');
      
      // Test filtering by time expression
      print('\n[TEST] Filtering by time expression: "this week"');
      final memosFromThisWeek = await apiService.listMemos(
        parent: 'users/1',
        timeExpression: 'this week',
      );
      print('[RESULT] Found ${memosFromThisWeek.length} memos from this week');
      
      // Test filtering by time range
      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
      print('\n[TEST] Filtering by created after: ${oneWeekAgo.toIso8601String()}');
      final recentMemos = await apiService.listMemos(
        parent: 'users/1',
        createdAfter: oneWeekAgo,
      );
      print('[RESULT] Found ${recentMemos.length} memos created in the last 7 days');
      
      // Print a sample memo from each result
      if (memosFromToday.isNotEmpty) {
        print('\nExample memo from today:');
        print('ID: ${memosFromToday[0].id}');
        print('Create Time: ${memosFromToday[0].createTime}');
        print('Content: ${memosFromToday[0].content.substring(0, min(50, memosFromToday[0].content.length))}...');
      }
      
      if (recentMemos.isNotEmpty) {
        print('\nExample memo from last 7 days:');
        print('ID: ${recentMemos[0].id}');
        print('Create Time: ${recentMemos[0].createTime}');
        print('Content: ${recentMemos[0].content.substring(0, min(50, recentMemos[0].content.length))}...');
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
      print('[RESULT] Found ${combinedFilter.length} PUBLIC memos containing "$searchTerm"');
      
      // Test filtering by content and time expression
      print('\n[TEST] Filtering by content: "$searchTerm" AND time: "this month"');
      final contentAndTimeMemos = await apiService.listMemos(
        parent: 'users/1',
        contentSearch: searchTerm,
        timeExpression: 'this month',
      );
      print('[RESULT] Found ${contentAndTimeMemos.length} memos from this month containing "$searchTerm"');
      
      // Print a sample memo from each result
      if (combinedFilter.isNotEmpty) {
        print('\nExample memo matching combined filter:');
        print('ID: ${combinedFilter[0].id}');
        print('Visibility: ${combinedFilter[0].visibility}');
        print('Content: ${combinedFilter[0].content.substring(0, min(50, combinedFilter[0].content.length))}...');
      }
      
      // Verify that the combined filter works as expected
      if (combinedFilter.isNotEmpty) {
        for (var memo in combinedFilter) {
          expect(memo.visibility, equals('PUBLIC'));
          expect(memo.content.toLowerCase().contains(searchTerm.toLowerCase()), isTrue);
        }
      }
    });
  });
}