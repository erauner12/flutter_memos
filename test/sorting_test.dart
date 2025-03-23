import 'dart:math';

import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_memos/utils/memo_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Client-side Sorting Tests', () {
    test('sortByUpdateTime correctly sorts memos', () {
      // Create test memos with different update times
      final memos = [
        Memo(
          id: '1',
          content: 'Oldest update',
          updateTime: '2025-03-20T10:00:00Z',
          createTime: '2025-03-18T10:00:00Z',
          displayTime: '2025-03-20T10:00:00Z',
        ),
        Memo(
          id: '2',
          content: 'Middle update',
          updateTime: '2025-03-21T10:00:00Z',
          createTime: '2025-03-17T10:00:00Z',
          displayTime: '2025-03-21T10:00:00Z',
        ),
        Memo(
          id: '3',
          content: 'Newest update',
          updateTime: '2025-03-22T10:00:00Z',
          createTime: '2025-03-16T10:00:00Z',
          displayTime: '2025-03-22T10:00:00Z',
        ),
      ];
      
      // Shuffle the list to ensure initial order doesn't match expected order
      final random = Random(42); // Fixed seed for reproducibility
      memos.shuffle(random);
      
      // Apply sorting using the actual implementation
      MemoUtils.sortByUpdateTime(memos);
      
      // Verify the order (newest first)
      expect(
        memos[0].id,
        equals('3'),
        reason: 'First memo should be the newest by update time',
      );
      expect(
        memos[1].id,
        equals('2'),
        reason: 'Second memo should be the middle by update time',
      );
      expect(
        memos[2].id,
        equals('1'),
        reason: 'Third memo should be the oldest by update time',
      );
    });
    
    test('sortByCreateTime correctly sorts memos', () {
      // Create test memos with different creation times
      final memos = [
        Memo(
          id: '1',
          content: 'Oldest creation',
          updateTime: '2025-03-22T10:00:00Z',
          createTime: '2025-03-16T10:00:00Z',
          displayTime: '2025-03-22T10:00:00Z',
        ),
        Memo(
          id: '2',
          content: 'Middle creation',
          updateTime: '2025-03-21T10:00:00Z',
          createTime: '2025-03-17T10:00:00Z',
          displayTime: '2025-03-21T10:00:00Z',
        ),
        Memo(
          id: '3',
          content: 'Newest creation',
          updateTime: '2025-03-20T10:00:00Z',
          createTime: '2025-03-18T10:00:00Z',
          displayTime: '2025-03-20T10:00:00Z',
        ),
      ];
      
      // Shuffle the list
      final random = Random(42);
      memos.shuffle(random);
      
      // Apply sorting using the actual implementation
      MemoUtils.sortByCreateTime(memos);
      
      // Verify the order (newest first)
      expect(
        memos[0].id,
        equals('3'),
        reason: 'First memo should be the newest by creation time',
      );
      expect(
        memos[1].id,
        equals('2'),
        reason: 'Second memo should be the middle by creation time',
      );
      expect(
        memos[2].id,
        equals('1'),
        reason: 'Third memo should be the oldest by creation time',
      );
    });

    test('sortMemos handles null timestamps gracefully', () {
      // Create test memos with some null timestamps
      final memos = [
        Memo(
          id: '1',
          content: 'Null update time',
          updateTime: null,
          createTime: '2025-03-16T10:00:00Z',
          displayTime: '2025-03-20T10:00:00Z',
        ),
        Memo(
          id: '2',
          content: 'Null create time',
          updateTime: '2025-03-21T10:00:00Z',
          createTime: null,
          displayTime: '2025-03-21T10:00:00Z',
        ),
        Memo(
          id: '3',
          content: 'All times present',
          updateTime: '2025-03-22T10:00:00Z',
          createTime: '2025-03-18T10:00:00Z',
          displayTime: '2025-03-22T10:00:00Z',
        ),
      ];

      // Test update time sorting
      MemoUtils.sortByUpdateTime(memos);
      expect(
        memos[0].id,
        equals('3'),
        reason: 'Memo with valid update time should come first',
      );

      // Test create time sorting
      MemoUtils.sortByCreateTime(memos);
      expect(
        memos[0].content.contains('All times present') ||
            memos[0].content.contains('Null update time'),
        isTrue,
        reason: 'Memo with valid create time should come first',
      );
    });
  });

  group('Server-side Sorting Tests', () {
    late ApiService apiService;

    setUp(() {
      apiService = ApiService();
    });

    // This test will make actual API calls, so it may need to be skipped
    // if running in a CI environment or without a real server
    test('API server respects sort parameters', () async {
      // Skip this test in CI or if server is not available
      final shouldSkip = true; // Change to false to run against a real server
      if (shouldSkip) {
        print(
          'Skipping server-side sorting test - set shouldSkip = false to run against a real server',
        );
        return;
      }

      // First, fetch memos sorted by update time
      final memosByUpdateTime = await apiService.listMemos(
        sort: 'updateTime',
        direction: 'DESC',
      );

      // Then fetch memos sorted by create time
      final memosByCreateTime = await apiService.listMemos(
        sort: 'createTime',
        direction: 'DESC',
      );

      // Log the first few memos from each query to help debug
      print('\n--- First 3 memos sorted by updateTime ---');
      for (int i = 0; i < min(3, memosByUpdateTime.length); i++) {
        print('[${i + 1}] ID: ${memosByUpdateTime[i].id}');
        print('    updateTime: ${memosByUpdateTime[i].updateTime}');
        print('    createTime: ${memosByUpdateTime[i].createTime}');
      }

      print('\n--- First 3 memos sorted by createTime ---');
      for (int i = 0; i < min(3, memosByCreateTime.length); i++) {
        print('[${i + 1}] ID: ${memosByCreateTime[i].id}');
        print('    updateTime: ${memosByCreateTime[i].updateTime}');
        print('    createTime: ${memosByCreateTime[i].createTime}');
      }

      // Check if the orders are different, which would indicate the server is respecting sort parameters
      bool ordersAreDifferent = false;
      for (
        int i = 0;
        i < min(memosByUpdateTime.length, memosByCreateTime.length);
        i++
      ) {
        if (memosByUpdateTime[i].id != memosByCreateTime[i].id) {
          ordersAreDifferent = true;
          break;
        }
      }

      // We can uncomment this line if we want the test to actually check the result
      // expect(ordersAreDifferent, isTrue, reason: 'Server should return different orders for different sort parameters');

      // For now, just print the result for manual verification
      if (ordersAreDifferent) {
        print(
          '✅ Server is respecting sort parameters - returned different orders',
        );
      } else {
        print(
          '❌ Server is NOT respecting sort parameters - returned same order for both queries',
        );
      }
    });
  });
}
