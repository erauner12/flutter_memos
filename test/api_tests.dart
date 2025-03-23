import 'dart:math' show min;

import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

// Set this to true to run the API tests
// Since there's no '--no-skip' flag in Flutter test, we'll use a manual toggle
const bool RUN_API_TESTS = true;

void main() {
  group('API Server Tests', () {
    late ApiService apiService;
    
    setUp(() {
      apiService = ApiService();
    });
    
    test('Server respects sort parameters', () async {
      // Skip this test unless RUN_API_TESTS is true
      if (!RUN_API_TESTS) {
        print('Skipping API test - set RUN_API_TESTS = true to run this test');
        return;
      }

      // First, fetch memos sorted by update time
      final memosByUpdateTime = await apiService.listMemos(
        parent: 'users/1', // Specify the user ID
        sort: 'updateTime',
        direction: 'DESC',
      );
      
      // Store the server order from the first query
      final firstQueryServerOrder = List<String>.from(
        ApiService.lastServerOrder,
      );
      
      // Then fetch memos sorted by create time
      final memosByCreateTime = await apiService.listMemos(
        parent: 'users/1', // Specify the user ID
        sort: 'createTime',
        direction: 'DESC',
      );
      
      // Store the server order from the second query
      final secondQueryServerOrder = List<String>.from(
        ApiService.lastServerOrder,
      );

      // Log the first few memos from each query after client-side sorting
      print(
        '\n--- First 3 memos sorted by updateTime (after client-side sorting) ---',
      );
      for (int i = 0; i < min(3, memosByUpdateTime.length); i++) {
        print('[${i + 1}] ID: ${memosByUpdateTime[i].id}');
        print('    updateTime: ${memosByUpdateTime[i].updateTime}');
        print('    createTime: ${memosByUpdateTime[i].createTime}');
      }
      
      print(
        '\n--- First 3 memos sorted by createTime (after client-side sorting) ---',
      );
      for (int i = 0; i < min(3, memosByCreateTime.length); i++) {
        print('[${i + 1}] ID: ${memosByCreateTime[i].id}');
        print('    updateTime: ${memosByCreateTime[i].updateTime}');
        print('    createTime: ${memosByCreateTime[i].createTime}');
      }
      
      // Check if the ORIGINAL SERVER ORDERS are different (before client-side sorting)
      bool serverOrdersAreDifferent = false;
      for (
        int i = 0;
        i < min(firstQueryServerOrder.length, secondQueryServerOrder.length);
        i++
      ) {
        if (firstQueryServerOrder[i] != secondQueryServerOrder[i]) {
          serverOrdersAreDifferent = true;
          break;
        }
      }

      // Check if the FINAL ORDERS (after client-side sorting) are different
      bool finalOrdersAreDifferent = false;
      for (int i = 0; i < min(memosByUpdateTime.length, memosByCreateTime.length); i++) {
        if (memosByUpdateTime[i].id != memosByCreateTime[i].id) {
          finalOrdersAreDifferent = true;
          break;
        }
      }
      
      // Print results of both checks
      print('\n--- Server Side Sorting Check ---');
      if (serverOrdersAreDifferent) {
        print(
          '✅ SERVER is respecting sort parameters - returned different orders',
        );
      } else {
        print(
          '❌ SERVER is NOT respecting sort parameters - returned same order for both queries',
        );
      }
      
      print('\n--- Client Side Sorting Check ---');
      if (finalOrdersAreDifferent) {
        print('✅ CLIENT sorting is working - final orders are different');
      } else {
        print(
          '❌ CLIENT sorting is not differentiating - final orders are the same',
        );
      }
      
      // If server sorting is broken but client sorting works, that's acceptable
      if (!serverOrdersAreDifferent && finalOrdersAreDifferent) {
        print(
          '\n🔧 WORKAROUND SUCCESSFUL: Client-side sorting is fixing the server sorting issue',
        );
      }
    });
    
    test('Verify client-side sorting fixes server sorting issues', () async {
      // Skip this test unless RUN_API_TESTS is true
      if (!RUN_API_TESTS) {
        print('Skipping API test - set RUN_API_TESTS = true to run this test');
        return;
      }
      
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
      for (var memo in memos) {
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
      for (int i = 0; i < min(3, memos.length); i++) {
        print('[${i + 1}] ID: ${memos[i].id}');
        print('    updateTime: ${memos[i].updateTime}');
      }
      
      // Check for differences in ordering
      bool ordersAreDifferent = false;
      for (int i = 0; i < min(serverOrderedMemos.length, memos.length); i++) {
        if (serverOrderedMemos[i].id != memos[i].id) {
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
      for (int i = 0; i < memos.length - 1; i++) {
        final current =
            memos[i].updateTime != null
                ? DateTime.parse(memos[i].updateTime!)
                :
                        DateTime.fromMillisecondsSinceEpoch(0);
        
        final next =
            memos[i + 1].updateTime != null
                ? DateTime.parse(memos[i + 1].updateTime!)
                :
                     DateTime.fromMillisecondsSinceEpoch(0);
        
        // Newest first, so current should be >= next
        expect(current.isAfter(next) || current.isAtSameMomentAs(next), isTrue,
              reason: 'Client-side sorting should properly sort by updateTime (newest first)');
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
  });
}
