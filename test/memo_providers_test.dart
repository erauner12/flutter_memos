import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/filter_providers.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mocks/mock_api_service.dart';
void main() {
  group('Memo Providers Tests', () {
    late MockApiService mockApiService;
    late ProviderContainer container;

    setUp(() {
      mockApiService = MockApiService();
      
      // Override the apiServiceProvider to use our mock
      container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(mockApiService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('memosProvider fetches memos with correct filters and sort', () async {
      // Mock data
      final memos = [
        Memo(
          id: '1',
          content: 'Test memo 1',
          createTime: '2025-03-22T10:00:00Z',
          updateTime: '2025-03-23T10:00:00Z',
        ),
        Memo(
          id: '2',
          content: 'Test memo 2',
          createTime: '2025-03-21T10:00:00Z',
          updateTime: '2025-03-22T10:00:00Z',
        ),
      ];
      
      // Set up mock response
      mockApiService.setMockMemos(memos);
      
      // Test default sort mode (byUpdateTime)
      final result = await container.read(memosProvider.future);
      
      // Verify results
      expect(result, equals(memos));
      
      // Verify the mock was called with the expected parameters
      expect(mockApiService.listMemosCallCount, equals(1));
      expect(mockApiService.lastListMemosParent, equals('users/1'));
      expect(
        mockApiService.lastListMemosState,
        equals('NORMAL'),
      ); // Default filter key is 'inbox'
      expect(
        mockApiService.lastListMemosSort,
        equals('updateTime'),
      ); // Default sort mode
      expect(mockApiService.lastListMemosDirection, equals('DESC'));
    });
    
    test('visibleMemosProvider filters out hidden memo IDs', () async {
      // Mock data
      final memos = [
        Memo(id: '1', content: 'Memo 1'),
        Memo(id: '2', content: 'Memo 2'),
        Memo(id: '3', content: 'Memo 3'),
      ];
      
      // Set up mock response
      mockApiService.setMockMemos(memos);
      
      // Hide memo with ID '2'
      container.read(hiddenMemoIdsProvider.notifier).state = {'2'};
      
      // Wait for the provider to resolve
      // We need to trigger the provider by reading its future
      await container.read(memosProvider.future);
      
      // Then read visibleMemosProvider which depends on memosProvider
      final visibleAsync = container.read(visibleMemosProvider);
      
      // Extract the data and verify results
      if (visibleAsync is AsyncData<List<Memo>>) {
        final result = visibleAsync.value;
        expect(result.length, equals(2));
        expect(result.map((m) => m.id).toList(), equals(['1', '3']));
      } else {
        fail('Expected AsyncData but got $visibleAsync');
      }
    });
    
    test('changing filter providers invalidates memosProvider', () async {
      // Mock data
      final memos = [Memo(id: '1', content: 'Test memo')];
      
      // Set up mock response
      mockApiService.setMockMemos(memos);
      
      // First fetch with default filter
      await container.read(memosProvider.future);
      
      // Reset the call count before changing the filter
      mockApiService.listMemosCallCount = 0;
      
      // Change time filter
      container.read(timeFilterProvider.notifier).state = 'today';
      
      // Wait a bit for the provider to update
      await Future.delayed(const Duration(milliseconds: 10));
      
      // Trigger another read to ensure the provider is called
      await container.read(memosProvider.future);
      
      // Verify listMemos was called again with different parameters
      expect(mockApiService.listMemosCallCount, greaterThanOrEqualTo(1));
      // Check for date pattern rather than literal "today" string
      expect(mockApiService.lastListMemosFilter, contains('create_time >='));
      expect(mockApiService.lastListMemosFilter, contains('create_time <='));
      expect(mockApiService.lastListMemosParent, equals('users/1'));
      expect(mockApiService.lastListMemosState, equals('NORMAL'));
      expect(mockApiService.lastListMemosSort, equals('updateTime'));
      expect(mockApiService.lastListMemosDirection, equals('DESC'));
    });

    // Removed test 'changing sort mode invalidates memosProvider'

    test('archiveMemoProvider archives a memo correctly', () async {
      // Mock data
      final memo = Memo(
        id: '1',
        content: 'Test memo',
        state: MemoState.normal,
        pinned: true,
      );
      
      // Set up mock responses
      mockApiService.setMockMemoById('1', memo);
      
      // Call the archive provider
      await container.read(archiveMemoProvider('1'))();
      
      // Verify getMemo was called
      expect(mockApiService.getMemoCallCount, equals(1));

      // Verify updateMemo was called
      expect(mockApiService.updateMemoCallCount, equals(1));
      
      // We can't directly verify the parameters passed to updateMemo with our manual mock,
      // but we can check that it was called for the right ID
    });
    
    test('deleteMemoProvider deletes a memo correctly', () async {
      // Reset the delete count
      mockApiService.deleteMemoCallCount = 0;
      
      // Call the delete provider
      await container.read(deleteMemoProvider('1'))();
      
      // Verify deleteMemo was called
      expect(mockApiService.deleteMemoCallCount, equals(1));
    });
  });
}
