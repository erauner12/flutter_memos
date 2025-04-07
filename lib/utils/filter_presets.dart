import 'package:flutter_memos/utils/filter_builder.dart';

/// Utility class providing predefined filter expressions for common use cases
class FilterPresets {
  /// Today's content (created OR updated today)
  static String todayFilter() {
    final todayCreated = FilterBuilder.byTimeExpression('today');
    final todayUpdated = FilterBuilder.byTimeExpression('today', useUpdateTime: true);
    // Use proper OR combination
    return FilterBuilder.or([todayCreated, todayUpdated]);
  }

  /// Only content created today
  static String createdTodayFilter() {
    return FilterBuilder.byTimeExpression('today');
  }

  /// Only content updated today
  static String updatedTodayFilter() {
    return FilterBuilder.byTimeExpression('today', useUpdateTime: true);
  }

  /// Content from this week (created OR updated)
  static String thisWeekFilter() {
    final weekCreated = FilterBuilder.byTimeExpression('this week');
    final weekUpdated = FilterBuilder.byTimeExpression(
      'this week',
      useUpdateTime: true,
    );
    return FilterBuilder.or([weekCreated, weekUpdated]);
  }

  /// Important content (assuming there's an "important" tag)
  static String importantFilter() {
    return FilterBuilder.byTags(['important']);
  }

  /// Untagged content (memos without any tags)
  static String untaggedFilter() {
    // The server doesn't support direct access to the tags array size
    // Instead we use a negative filter to exclude any memo with a tag
    // Assuming tags start with #
    // This might need refinement based on actual tag implementation
    return '!content.contains("#")';
  }

  /// Tagged content (memos with at least one tag)
  static String taggedFilter() {
    // Filter for memos that contain at least one hashtag
    // Assuming tags start with #
    // This might need refinement based on actual tag implementation
    return 'content.contains("#")';
  }

  /// All content (no filter)
  static String allFilter() {
    return '';
  }
}
