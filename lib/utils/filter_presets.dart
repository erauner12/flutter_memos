import 'package:flutter_memos/utils/filter_builder.dart';

/// Utility class providing predefined filter expressions for common use cases
class FilterPresets {
  /// Today's content (created OR updated today)
  static String todayFilter() {
    final today = FilterBuilder.byTimeExpression('today');
    final todayUpdated = FilterBuilder.byTimeExpression('today', useUpdateTime: true);
    return FilterBuilder.or([today, todayUpdated]);
  }
  
  /// Only content created today
  static String createdTodayFilter() {
    return FilterBuilder.byTimeExpression('today');
  }
  
  /// Only content updated today
  static String updatedTodayFilter() {
    return FilterBuilder.byTimeExpression('today', useUpdateTime: true);
  }
  
  /// Content from this week
  static String thisWeekFilter() {
    return FilterBuilder.byTimeExpression('this week');
  }
  
  /// Important content (assuming there's an "important" tag)
  static String importantFilter() {
    return FilterBuilder.byTags(['important']);
  }
  
  /// Untagged content (memos without any tags)
  static String untaggedFilter() {
    // The server doesn't support direct access to the tags array size
    // Instead we use a negative filter to exclude any memo with a tag
    return '!content.contains("#")';
  }
}
