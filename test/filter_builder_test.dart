import 'package:flutter_memos/utils/filter_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FilterBuilder Tests', () {
    test('byTags should build correct tag filter expressions', () {
      expect(FilterBuilder.byTags(['work']), equals('tag in ["work"]'));
      expect(FilterBuilder.byTags(['work', 'important']), equals('tag in ["work", "important"]'));
      expect(FilterBuilder.byTags([]), equals(''));
    });

    test('byVisibility should build correct visibility filter expressions', () {
      expect(FilterBuilder.byVisibility('PUBLIC'), equals('visibility == "PUBLIC"'));
      expect(
        FilterBuilder.byVisibility(['PUBLIC', 'PROTECTED']),
        equals('visibility in ["PUBLIC", "PROTECTED"]')
      );
      expect(FilterBuilder.byVisibility([]), equals(''));
    });

    test('byContent should build correct content filter expressions', () {
      expect(
        FilterBuilder.byContent('search term'),
        equals('content.contains("search term")')
      );
      expect(
        FilterBuilder.byContent('exact match', exactMatch: true),
        equals('content == "exact match"')
      );
      expect(FilterBuilder.byContent(''), equals(''));
    });

    test('byCreateTime should build correct create_time filter expressions', () {
      final date = DateTime.utc(2023, 1, 1);
      expect(
        FilterBuilder.byCreateTime(date),
        equals('create_time == "2023-01-01T00:00:00.000Z"')
      );
      expect(
        FilterBuilder.byCreateTime(date, operator: '>'),
        equals('create_time > "2023-01-01T00:00:00.000Z"')
      );
    });

    test('byUpdateTime should build correct update_time filter expressions', () {
      final date = DateTime.utc(2023, 1, 1);
      expect(
        FilterBuilder.byUpdateTime(date),
        equals('update_time == "2023-01-01T00:00:00.000Z"')
      );
      expect(
        FilterBuilder.byUpdateTime(date, operator: '<'),
        equals('update_time < "2023-01-01T00:00:00.000Z"')
      );
    });

    test('byCreateTimeRange should build correct date range filter', () {
      final start = DateTime.utc(2023, 1, 1);
      final end = DateTime.utc(2023, 1, 31, 23, 59, 59);
      expect(
        FilterBuilder.byCreateTimeRange(start, end),
        equals(
          'create_time >= "2023-01-01T00:00:00.000Z" && create_time <= "2023-01-31T23:59:59.000Z"'
        )
      );
    });

    test('byUpdateTimeRange should build correct date range filter', () {
      final start = DateTime.utc(2023, 1, 1);
      final end = DateTime.utc(2023, 1, 31, 23, 59, 59);
      expect(
        FilterBuilder.byUpdateTimeRange(start, end),
        equals(
          'update_time >= "2023-01-01T00:00:00.000Z" && update_time <= "2023-01-31T23:59:59.000Z"'
        )
      );
    });

    test('and should combine filters with logical AND', () {
      final filter1 = FilterBuilder.byTags(['work']);
      final filter2 = FilterBuilder.byVisibility('PUBLIC');
      
      expect(
        FilterBuilder.and([filter1, filter2]),
        equals('tag in ["work"] && visibility == "PUBLIC"')
      );
      
      // Should handle empty filters
      expect(FilterBuilder.and([filter1, '', filter2]), equals('tag in ["work"] && visibility == "PUBLIC"'));
      expect(FilterBuilder.and([]), equals(''));
      expect(FilterBuilder.and([filter1]), equals(filter1));
    });

    test('or should combine filters with logical OR', () {
      final filter1 = FilterBuilder.byTags(['work']);
      final filter2 = FilterBuilder.byTags(['important']);
      
      expect(
        FilterBuilder.or([filter1, filter2]),
        equals('tag in ["work"] || tag in ["important"]')
      );
      
      // Should handle empty filters
      expect(FilterBuilder.or([filter1, '', filter2]), equals('tag in ["work"] || tag in ["important"]'));
      expect(FilterBuilder.or([]), equals(''));
      expect(FilterBuilder.or([filter1]), equals(filter1));
    });

    test('not should negate a filter with logical NOT', () {
      final filter = FilterBuilder.byContent('obsolete');
      
      expect(
        FilterBuilder.not(filter),
        equals('!(content.contains("obsolete"))')
      );
      
      expect(FilterBuilder.not(''), equals(''));
    });

    test('Combining multiple filter conditions', () {
      final tagFilter = FilterBuilder.byTags(['work', 'important']);
      final visibilityFilter = FilterBuilder.byVisibility('PUBLIC');
      final contentFilter = FilterBuilder.byContent('meeting');
      
      // Combine with AND
      final combinedAnd = FilterBuilder.and([tagFilter, visibilityFilter, contentFilter]);
      expect(
        combinedAnd,
        equals('tag in ["work", "important"] && visibility == "PUBLIC" && content.contains("meeting")')
      );
      
      // Combine with OR
      final combinedOr = FilterBuilder.or([tagFilter, visibilityFilter]);
      expect(
        combinedOr,
        equals('tag in ["work", "important"] || visibility == "PUBLIC"')
      );
      
      // Complex combination with AND and OR
      final complexFilter = FilterBuilder.and([
        tagFilter,
        FilterBuilder.or([visibilityFilter, contentFilter])
      ]);
      expect(
        complexFilter,
        equals('tag in ["work", "important"] && (visibility == "PUBLIC" || content.contains("meeting"))')
      );
    });

    test('byTimeExpression should build correct time-based filters', () {
      // Since these tests use DateTime.now(), we can't test the exact string output
      // Instead, we'll test that they contain the expected format elements
      
      final today = FilterBuilder.byTimeExpression('today');
      expect(today, contains('create_time >= "'));
      expect(today, contains('create_time <= "'));
      
      final yesterday = FilterBuilder.byTimeExpression('yesterday');
      expect(yesterday, contains('create_time >= "'));
      expect(yesterday, contains('create_time <= "'));
      
      final thisWeek = FilterBuilder.byTimeExpression('this week');
      expect(thisWeek, contains('create_time >= "'));
      expect(thisWeek, contains('create_time <= "'));
      
      final lastWeek = FilterBuilder.byTimeExpression('last week');
      expect(lastWeek, contains('create_time >= "'));
      expect(lastWeek, contains('create_time <= "'));
      
      final thisMonth = FilterBuilder.byTimeExpression('this month');
      expect(thisMonth, contains('create_time >= "'));
      expect(thisMonth, contains('create_time <= "'));
      
      final lastMonth = FilterBuilder.byTimeExpression('last month');
      expect(lastMonth, contains('create_time >= "'));
      expect(lastMonth, contains('create_time <= "'));
      
      // Test with update_time instead of create_time
      final todayUpdated = FilterBuilder.byTimeExpression('today', useUpdateTime: true);
      expect(todayUpdated, contains('update_time >= "'));
      expect(todayUpdated, contains('update_time <= "'));
      
      // Invalid expression should return empty string
      expect(FilterBuilder.byTimeExpression('invalid expression'), equals(''));
    });
  });
}