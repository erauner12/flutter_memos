import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/services/api_service.dart';
import 'dart:math';

void main() {
  group('Memo Sorting Tests', () {
    late ApiService apiService;
    
    setUp(() {
      apiService = ApiService();
    });
    
    test('Local sorting by updateTime works correctly', () {
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
      
      // Apply sorting
      sortMemosByUpdateTime(memos);
      
      // Verify the order (newest first)
      expect(memos[0].id, '3');
      expect(memos[1].id, '2');
      expect(memos[2].id, '1');
    });
    
    test('Local sorting by createTime works correctly', () {
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
      
      // Apply sorting
      sortMemosByCreateTime(memos);
      
      // Verify the order (newest first)
      expect(memos[0].id, '3');
      expect(memos[1].id, '2');
      expect(memos[2].id, '1');
    });
    
    // Utility function to sort by update time
    void sortMemosByUpdateTime(List<Memo> memos) {
      memos.sort((a, b) {
        final dateA = a.updateTime != null ? DateTime.parse(a.updateTime!) : null;
        final dateB = b.updateTime != null ? DateTime.parse(b.updateTime!) : null;
        
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        
        return dateB.compareTo(dateA);
      });
    }
    
    // Utility function to sort by creation time
    void sortMemosByCreateTime(List<Memo> memos) {
      memos.sort((a, b) {
        final dateA = a.createTime != null ? DateTime.parse(a.createTime!) : null;
        final dateB = b.createTime != null ? DateTime.parse(b.createTime!) : null;
        
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        
        return dateB.compareTo(dateA);
      });
    }
  });
}