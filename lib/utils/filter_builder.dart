/// Utility class for building CEL filter expressions for Memos API
/// 
/// Based on the Memos documentation about filter expressions:
/// https://usememos.com/docs/advanced-usage/shortcuts
class FilterBuilder {
  /// Builds a filter for tags (IN operation)
  /// 
  /// Example: `tag in ["work", "important"]`
  static String byTags(List<String> tags) {
    if (tags.isEmpty) return '';
    
    final quotedTags = tags.map((tag) => '"$tag"').join(', ');
    return 'tag in [$quotedTags]';
  }

  /// Builds a filter for visibility
  /// 
  /// Examples: 
  /// - `visibility == "PUBLIC"`
  /// - `visibility in ["PUBLIC", "PROTECTED"]`
  static String byVisibility(dynamic visibility) {
    if (visibility is String) {
      return 'visibility == "$visibility"';
    } else if (visibility is List<String>) {
      if (visibility.isEmpty) return '';
      final quotedValues = visibility.map((v) => '"$v"').join(', ');
      return 'visibility in [$quotedValues]';
    }
    return '';
  }

  /// Builds a filter for memo content
  /// 
  /// Examples:
  /// - `content.contains("search term")`
  /// - `content == "exact match"`
  static String byContent(String content, {bool exactMatch = false}) {
    if (content.isEmpty) return '';
    
    if (exactMatch) {
      return 'content == "$content"';
    } else {
      return 'content.contains("$content")';
    }
  }

  /// Builds a filter for creation time with a comparison operator
  /// 
  /// Example: `create_time > "2023-01-01T00:00:00Z"`
  static String byCreateTime(
    DateTime dateTime, {
    String operator = '==',
  }) {
    final formattedDate = dateTime.toUtc().toIso8601String();
    return 'create_time $operator "$formattedDate"';
  }

  /// Builds a filter for update time with a comparison operator
  /// 
  /// Example: `update_time > "2023-01-01T00:00:00Z"`
  static String byUpdateTime(
    DateTime dateTime, {
    String operator = '==',
  }) {
    final formattedDate = dateTime.toUtc().toIso8601String();
    return 'update_time $operator "$formattedDate"';
  }

  /// Builds a filter for a date range (inclusive) on creation time
  /// 
  /// Example: `create_time >= "2023-01-01T00:00:00Z" && create_time <= "2023-01-31T23:59:59Z"`
  static String byCreateTimeRange(DateTime start, DateTime end) {
    final formattedStart = start.toUtc().toIso8601String();
    final formattedEnd = end.toUtc().toIso8601String();
    return 'create_time >= "$formattedStart" && create_time <= "$formattedEnd"';
  }

  /// Builds a filter for a date range (inclusive) on update time
  /// 
  /// Example: `update_time >= "2023-01-01T00:00:00Z" && update_time <= "2023-01-31T23:59:59Z"`
  static String byUpdateTimeRange(DateTime start, DateTime end) {
    final formattedStart = start.toUtc().toIso8601String();
    final formattedEnd = end.toUtc().toIso8601String();
    return 'update_time >= "$formattedStart" && update_time <= "$formattedEnd"';
  }

  /// Combines multiple filters with logical AND (&&)
  /// 
  /// Example: `tag in ["work"] && visibility == "PUBLIC"`
  static String and(List<String> filters) {
    // Remove any empty filters
    final validFilters = filters.where((f) => f.isNotEmpty).toList();
    
    if (validFilters.isEmpty) return '';
    if (validFilters.length == 1) return validFilters.first;
    
    // Process each filter to properly handle nested expressions
    final processedFilters = validFilters.map((filter) {
      // If the filter contains a standalone OR operator not already in parentheses,
      // wrap it in parentheses to ensure proper operator precedence
      if (filter.contains('||') && !filter.startsWith('(')) {
        return '($filter)';
      }
      return filter;
    }).toList();
    
    return processedFilters.join(' && ');
  }

  /// Combines multiple filters with logical OR (||)
  /// 
  /// Example: `tag in ["work"] || tag in ["important"]`
  static String or(List<String> filters) {
    // Remove any empty filters
    final validFilters = filters.where((f) => f.isNotEmpty).toList();
    
    if (validFilters.isEmpty) return '';
    if (validFilters.length == 1) return validFilters.first;
    
    return validFilters.join(' || ');
  }

  /// Negates a filter with logical NOT (!)
  /// 
  /// Example: `!content.contains("obsolete")`
  static String not(String filter) {
    if (filter.isEmpty) return '';
    
    return '!($filter)';
  }

  /// Builds a sort filter to order by creation time
  /// 
  /// While this doesn't strictly filter results, it's a useful pattern
  /// to include in filter expressions to encourage proper server-side sorting
  static String orderByCreateTime({bool ascending = false}) {
    // Note: This is a best-effort attempt at server-side sorting
    // The server may not respect this, but we include it as a hint
    final now = DateTime.now().toUtc();
    
    if (ascending) {
      // For ascending order, we prioritize older items
      // This is a workaround, not a guarantee
      return 'create_time < "${now.toIso8601String()}"';
    } else {
      // For descending order, we prioritize newer items
      // This is a workaround, not a guarantee
      return 'create_time < "${now.toIso8601String()}"';
    }
  }

  /// Builds a sort filter to order by update time
  /// 
  /// While this doesn't strictly filter results, it's a useful pattern
  /// to include in filter expressions to encourage proper server-side sorting
  static String orderByUpdateTime({bool ascending = false}) {
    // Note: This is a best-effort attempt at server-side sorting
    // The server may not respect this, but we include it as a hint
    final now = DateTime.now().toUtc();
    
    if (ascending) {
      // For ascending order, we prioritize older items
      // This is a workaround, not a guarantee
      return 'update_time < "${now.toIso8601String()}"';
    } else {
      // For descending order, we prioritize newer items
      // This is a workaround, not a guarantee
      return 'update_time < "${now.toIso8601String()}"';
    }
  }

  /// Builds time-based filters for relative time expressions
  /// 
  /// Examples:
  /// - "today" -> create_time between start and end of today
  /// - "yesterday" -> create_time between start and end of yesterday
  /// - "this week" -> create_time between start and end of current week
  /// - "last week" -> create_time between start and end of last week
  /// - "this month" -> create_time between start and end of current month
  /// - "last month" -> create_time between start and end of last month
  static String byTimeExpression(String expression, {bool useUpdateTime = false}) {
    final now = DateTime.now();
    late DateTime start;
    late DateTime end;
    
    // Parse the time expression
    switch (expression.toLowerCase()) {
      case 'today':
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        break;
        
      case 'yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        start = DateTime(yesterday.year, yesterday.month, yesterday.day);
        end = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59, 999);
        break;
        
      case 'this week':
        // Calculate start of week (assuming Monday is first day of week)
        int daysToSubtract = (now.weekday - 1) % 7;
        start = DateTime(now.year, now.month, now.day - daysToSubtract);
        end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59, milliseconds: 999));
        break;
        
      case 'last week':
        // Calculate start of last week
        int daysToSubtract = (now.weekday - 1) % 7 + 7;
        start = DateTime(now.year, now.month, now.day - daysToSubtract);
        end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59, milliseconds: 999));
        break;
        
      case 'this month':
        start = DateTime(now.year, now.month, 1);
        // Last day of current month
        end =
            (now.month < 12) 
            ? DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1))
            : DateTime(now.year + 1, 1, 1).subtract(const Duration(seconds: 1));
        break;
        
      case 'last month':
        // First day of last month
        final lastMonth =
            now.month > 1
                ? DateTime(now.year, now.month - 1) 
            : DateTime(now.year - 1, 12);
        start = DateTime(lastMonth.year, lastMonth.month, 1);
        // Last day of last month
        end = DateTime(now.year, now.month, 1).subtract(const Duration(seconds: 1));
        break;
        
      default:
        return ''; // Invalid expression
    }
    
    // Build the filter based on specified time field
    final timeField = useUpdateTime ? 'update_time' : 'create_time';
    final formattedStart = start.toUtc().toIso8601String();
    final formattedEnd = end.toUtc().toIso8601String();
    
    return '$timeField >= "$formattedStart" && $timeField <= "$formattedEnd"';
  }
}