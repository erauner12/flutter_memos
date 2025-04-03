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
  
  /// Validates if a CEL filter expression has basic correct syntax
  /// This is a basic validation - not a full CEL parser
  ///
  /// Returns a string with error message if invalid, empty string if valid
  static String validateCelExpression(String expression) {
    if (expression.isEmpty) {
      return '';
    }

    // Check for balanced parentheses
    int openParens = 0;
    for (int i = 0; i < expression.length; i++) {
      if (expression[i] == '(') openParens++;
      if (expression[i] == ')') openParens--;
      if (openParens < 0) {
        return 'Unbalanced parentheses at position $i';
      }
    }
    if (openParens != 0) {
      return 'Unbalanced parentheses: missing ${openParens > 0 ? "closing" : "opening"} parentheses';
    }

    // Check for balanced quotes
    bool inQuote = false;
    for (int i = 0; i < expression.length; i++) {
      if (expression[i] == '"' && (i == 0 || expression[i - 1] != '\\')) {
        inQuote = !inQuote;
      }
    }
    if (inQuote) {
      return 'Unbalanced quotes: missing closing quote';
    }

    // Check for balanced square brackets
    int openBrackets = 0;
    for (int i = 0; i < expression.length; i++) {
      if (expression[i] == '[') openBrackets++;
      if (expression[i] == ']') openBrackets--;
      if (openBrackets < 0) {
        return 'Unbalanced brackets at position $i';
      }
    }
    if (openBrackets != 0) {
      return 'Unbalanced brackets: missing ${openBrackets > 0 ? "closing" : "opening"} bracket';
    }

    // All good!
    return '';
  }

  /// Creates a filter for searching content with text (case-insensitive)
  /// This is useful for implementing a simple search box
  ///
  /// Example: content.toLowerCase().contains("search term")
  static String bySearchText(String searchText) {
    if (searchText.isEmpty) return '';
    
    // Escape quotes in the search text
    final escaped = searchText.replaceAll('"', '\\"');
    
    // Create a case-insensitive search
    return 'content.toLowerCase().contains("${escaped.toLowerCase()}")';
  }
  
  /// Creates a month filter for the specified year and month
  ///
  /// Example: (create_time >= "2023-09-01T00:00:00Z" && create_time <= "2023-09-30T23:59:59Z")
  static String byMonth(int year, int month) {
    final startDate = DateTime(year, month, 1);

    // Calculate the last day of the month by getting the first day of the next month
    // and subtracting one day
    final lastDayOfMonth =
        month < 12 ? DateTime(year, month + 1, 0) : DateTime(year + 1, 1, 0);

    return byCreateTimeRange(startDate, lastDayOfMonth);
  }

  /// Validates a CEL filter expression more thoroughly, checking for common syntax errors
  /// Returns an empty string if valid, or an error message if invalid
  static String validateCelExpressionDetailed(String expression) {
    if (expression.isEmpty) {
      return '';
    }

    // Check for balanced parentheses
    int openParens = 0;
    int lastOpenParenPos = -1;
    int lastCloseParenPos = -1;

    for (int i = 0; i < expression.length; i++) {
      if (expression[i] == '(') {
        openParens++;
        lastOpenParenPos = i;
      }
      if (expression[i] == ')') {
        openParens--;
        lastCloseParenPos = i;

        if (openParens < 0) {
          return 'Unbalanced parentheses: extra closing parenthesis at position $i';
        }
      }
    }

    if (openParens > 0) {
      return 'Unbalanced parentheses: missing $openParens closing parenthesis';
    }

    // Check for balanced quotes
    bool inQuote = false;
    int quoteStartPos = -1;

    for (int i = 0; i < expression.length; i++) {
      if (expression[i] == '"' && (i == 0 || expression[i - 1] != '\\')) {
        if (!inQuote) {
          quoteStartPos = i;
          inQuote = true;
        } else {
          inQuote = false;
        }
      }
    }

    if (inQuote) {
      return 'Unbalanced quotes: missing closing quote for quote starting at position $quoteStartPos';
    }

    // Check for balanced square brackets
    int openBrackets = 0;
    int lastOpenBracketPos = -1;

    for (int i = 0; i < expression.length; i++) {
      if (expression[i] == '[') {
        openBrackets++;
        lastOpenBracketPos = i;
      }
      if (expression[i] == ']') {
        openBrackets--;

        if (openBrackets < 0) {
          return 'Unbalanced brackets: extra closing bracket at position $i';
        }
      }
    }

    if (openBrackets > 0) {
      return 'Unbalanced brackets: missing $openBrackets closing bracket';
    }

    // Check for empty expressions within parentheses
    if (expression.contains('()')) {
      return 'Empty parentheses are not allowed';
    }

    // Check for common operators
    if (expression.contains('=') && !expression.contains('==')) {
      return 'Use "==" for equality comparison, not "="';
    }

    // Check if time format seems correct for create_time and update_time
    if (expression.contains('create_time') ||
        expression.contains('update_time')) {
      // Very basic check for "YYYY-MM-DDThh:mm:ss" format inside quotes
      final timeRegex = RegExp(
        r'"[\d]{4}-[\d]{2}-[\d]{2}T[\d]{2}:[\d]{2}:[\d]{2}',
      );
      if (!timeRegex.hasMatch(expression)) {
        return 'Time format should be "YYYY-MM-DDThh:mm:ss" (e.g., "2023-01-01T00:00:00Z")';
      }
    }

    // All checks passed
    return '';
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
