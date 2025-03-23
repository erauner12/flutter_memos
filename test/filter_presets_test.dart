import 'package:flutter_memos/utils/filter_presets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FilterPresets Tests', () {
    test('todayFilter creates a filter for content created OR updated today', () {
      final filter = FilterPresets.todayFilter();
      
      // Check that the filter contains components for both create_time and update_time
      expect(filter, contains('create_time >='));
      expect(filter, contains('update_time >='));
      expect(filter, contains('||')); // Should use OR operator
    });

    test('createdTodayFilter creates a filter for content created today', () {
      final filter = FilterPresets.createdTodayFilter();
      
      // Check that the filter contains only create_time
      expect(filter, contains('create_time >='));
      expect(filter, isNot(contains('update_time'))); // Should not mention update_time
    });

    test('updatedTodayFilter creates a filter for content updated today', () {
      final filter = FilterPresets.updatedTodayFilter();
      
      // Check that the filter contains only update_time
      expect(filter, contains('update_time >='));
      expect(filter, isNot(contains('create_time'))); // Should not mention create_time
    });

    test('thisWeekFilter creates a filter for content from this week', () {
      final filter = FilterPresets.thisWeekFilter();
      
      // Check that the filter contains week references
      expect(filter, contains('create_time >='));
      expect(filter, contains('create_time <='));
    });

    test('importantFilter creates a filter for content tagged as important', () {
      final filter = FilterPresets.importantFilter();
      
      // Check that the filter contains the important tag
      expect(filter, contains('tag in ["important"]'));
    });
    
    test('untaggedFilter creates a filter for content without any tags', () {
      final filter = FilterPresets.untaggedFilter();

      // Check that the filter checks for empty tags array
      expect(filter, contains('tags.size() == 0'));
    });
  });
}
