import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

// Set this to true to run integration tests against a real server
// WARNING: These tests will create and modify real data!
const bool RUN_INTEGRATION_TESTS = false;

void main() {
  group('API Integration Tests', () {
    late ApiService apiService;
    
    setUp(() {
      apiService = ApiService();
    });
    
    test('Create, retrieve, update, and delete memo', () async {
      // Skip unless integration tests are enabled
      if (!RUN_INTEGRATION_TESTS) {
        print('Skipping integration test - set RUN_INTEGRATION_TESTS = true to run');
        return;
      }
      
      // 1. Create a test memo
      final testMemo = Memo(
        id: 'test',
        content: 'Test memo ${DateTime.now().toIso8601String()}',
        pinned: false,
      );
      
      final createdMemo = await apiService.createMemo(testMemo);
      expect(createdMemo.content, equals(testMemo.content));
      print('Created memo with ID: ${createdMemo.id}');
      
      // 2. Retrieve the memo
      final retrievedMemo = await apiService.getMemo(createdMemo.id);
      expect(retrievedMemo.id, equals(createdMemo.id));
      expect(retrievedMemo.content, equals(createdMemo.content));
      print('Retrieved memo successfully');
      
      // 3. Update the memo
      final updatedContent = 'Updated content ${DateTime.now().toIso8601String()}';
      final memoToUpdate = retrievedMemo.copyWith(
        content: updatedContent,
        pinned: true,
      );
      
      final updatedMemo = await apiService.updateMemo(retrievedMemo.id, memoToUpdate);
      expect(updatedMemo.content, equals(updatedContent));
      expect(updatedMemo.pinned, isTrue);
      print('Updated memo successfully');
      
      // 4. Delete the memo
      await apiService.deleteMemo(updatedMemo.id);
      print('Deleted memo successfully');
      
      // 5. Verify deletion (should throw)
      try {
        await apiService.getMemo(updatedMemo.id);
        fail('Memo should have been deleted');
      } catch (e) {
        // Expected exception
        expect(e.toString(), contains('Failed to load memo'));
        print('Verified deletion (memo not found as expected)');
      }
    });
    
    test('List memos with different sort parameters', () async {
      // Skip unless integration tests are enabled
      if (!RUN_INTEGRATION_TESTS) {
        print('Skipping integration test - set RUN_INTEGRATION_TESTS = true to run');
        return;
      }
      
      // Get memos sorted by update time
      final memosByUpdateTime = await apiService.listMemos(
        parent: 'users/1',
        sort: 'updateTime',
        direction: 'DESC',
      );
      
      // Get memos sorted by create time
      final memosByCreateTime = await apiService.listMemos(
        parent: 'users/1',
        sort: 'createTime',
        direction: 'DESC',
      );
      
      // Check that we got results
      expect(memosByUpdateTime, isNotEmpty);
      expect(memosByCreateTime, isNotEmpty);
      
      // Print the first few results from each query
      print('\nMemos sorted by updateTime:');
      for (int i = 0; i < 3 && i < memosByUpdateTime.length; i++) {
        print('${i+1}. ID: ${memosByUpdateTime[i].id}');
        print('   UpdateTime: ${memosByUpdateTime[i].updateTime}');
      }
      
      print('\nMemos sorted by createTime:');
      for (int i = 0; i < 3 && i < memosByCreateTime.length; i++) {
        print('${i+1}. ID: ${memosByCreateTime[i].id}');
        print('   CreateTime: ${memosByCreateTime[i].createTime}');
      }
    });
    
    // Additional integration tests can be added here
  });
}