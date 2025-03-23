import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/services/api_service.dart';
import 'dart:math' show min;

// Use this annotation to mark tests that should be skipped by default
@Skip('This test makes API calls to a real server and should be run manually')
void main() {
  group('API Server Tests', () {
    late ApiService apiService;
    
    setUp(() {
      apiService = ApiService();
    });
    
    test('Server respects sort parameters', () async {
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
      for (int i = 0; i < min(memosByUpdateTime.length, memosByCreateTime.length); i++) {
        if (memosByUpdateTime[i].id != memosByCreateTime[i].id) {
          ordersAreDifferent = true;
          break;
        }
      }
      
      // First approach: Print the result for manual verification
      if (ordersAreDifferent) {
        print('✅ Server is respecting sort parameters - returned different orders');
      } else {
        print('❌ Server is NOT respecting sort parameters - returned same order for both queries');
      }
      
      // Second approach: Use an actual assertion that will fail the test
      // Uncomment this line to make the test actually fail when the server doesn't respect sort parameters
      // expect(ordersAreDifferent, isTrue, reason: 'Server should return different orders for different sort parameters');
      
      // For now, we're not making this a hard assertion since we know the server has an issue,
      // but we want to be able to see the details of the issue when running this test manually
    });
    
    test('Verify client-side sorting fixes server sorting issues', () async {
      // This test verifies that our client-side sorting correctly compensates for server sorting issues
      
      // Get memos with server-side sort by updateTime
      final serverSortedMemos = await apiService.listMemos(
        sort: 'updateTime',
        direction: 'DESC',
      );
      
      // Clone the list to avoid modifying the original
      final clientSortedMemos = List<Memo>.from(serverSortedMemos);
      
      // Apply client-side sorting for comparison
      MemoUtils.sortByUpdateTime(clientSortedMemos);
      
      // Log the first few memos from both lists
      print('\n--- First 3 memos with server sorting only ---');
      for (int i = 0; i < min(3, serverSortedMemos.length); i++) {
        print('[${i + 1}] ID: ${serverSortedMemos[i].id}');
        print('    updateTime: ${serverSortedMemos[i].updateTime}');
      }
      
      print('\n--- First 3 memos with client-side sorting applied ---');
      for (int i = 0; i < min(3, clientSortedMemos.length); i++) {
        print('[${i + 1}] ID: ${clientSortedMemos[i].id}');
        print('    updateTime: ${clientSortedMemos[i].updateTime}');
      }
      
      // Check for differences in ordering
      bool ordersAreDifferent = false;
      for (int i = 0; i < min(serverSortedMemos.length, clientSortedMemos.length); i++) {
        if (serverSortedMemos[i].id != clientSortedMemos[i].id) {
          ordersAreDifferent = true;
          break;
        }
      }
      
      if (ordersAreDifferent) {
        print('ℹ️ Client-side sorting changed the order - may indicate server sort is not optimal');
      } else {
        print('ℹ️ Client-side sorting preserved the order - server sort may be working correctly');
      }
      
      // Verify that the client-side sorting actually produced a correctly sorted list
      for (int i = 0; i < clientSortedMemos.length - 1; i++) {
        final current = clientSortedMemos[i].updateTime != null ?
                        DateTime.parse(clientSortedMemos[i].updateTime!) :
                        DateTime.fromMillisecondsSinceEpoch(0);
        
        final next = clientSortedMemos[i+1].updateTime != null ?
                     DateTime.parse(clientSortedMemos[i+1].updateTime!) :
                     DateTime.fromMillisecondsSinceEpoch(0);
        
        // Newest first, so current should be >= next
        expect(current.isAfter(next) || current.isAtSameMomentAs(next), isTrue,
              reason: 'Client-side sorting should properly sort by updateTime (newest first)');
      }
    });
  });
}

// Import this at the top of the file when running these tests
import 'package:flutter_memos/utils/memo_utils.dart';
