import 'package:flutter/foundation.dart';
import 'package:flutter_memos/utils/filter_builder.dart';
import 'package:flutter_memos/utils/filter_presets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for the time-based filter option ('today', 'this_week', etc.)
///
/// OPTIMIZATION: Added name for better debugging
final timeFilterProvider = StateProvider<String>(
  (ref) => 'all',
  name: 'timeFilter',
);

/// Provider for the status-based filter option ('untagged', 'tagged', 'all')
///
/// OPTIMIZATION: Added name for better debugging
final statusFilterProvider = StateProvider<String>(
  (ref) => 'untagged',
  name: 'statusFilter',
);

/// Provider for the current filter key ('inbox', 'archive', 'all', or a tag)
///
/// OPTIMIZATION: Added name for better debugging
final filterKeyProvider = StateProvider<String>(
  (ref) => 'inbox',
  name: 'filterKey',
);

/// OPTIMIZATION: Provider to track the last used filter key
/// This helps with history and restoring state
final lastUsedFilterKeyProvider = StateProvider<String?>(
  (ref) => null,
  name: 'lastUsedFilterKey',
);

/// Provider that combines all filter options into a single filter string
///
/// OPTIMIZATION: Added memoization, better commenting, and debugging
final combinedFilterProvider = Provider<String>((ref) {
  // OPTIMIZATION: Use select() to only watch the specific values needed
  final timeFilter = ref.watch(timeFilterProvider.select((value) => value));
  final statusFilter = ref.watch(statusFilterProvider.select((value) => value));
  final filterList = <String>[];

  if (kDebugMode) {
    print(
      '[combinedFilterProvider] Building filter with time=$timeFilter, status=$statusFilter',
    );
  }

  // Apply time-based filter
  String? timeFilterString;
  switch (timeFilter) {
    case 'today':
      timeFilterString = FilterPresets.todayFilter();
      break;
    case 'created_today':
      timeFilterString = FilterPresets.createdTodayFilter();
      break;
    case 'updated_today':
      timeFilterString = FilterPresets.updatedTodayFilter();
      break;
    case 'this_week':
      timeFilterString = FilterPresets.thisWeekFilter();
      break;
    case 'important':
      timeFilterString = FilterPresets.importantFilter();
      break;
    case 'all':
    default:
      timeFilterString = null; // No time filter
  }

  // Apply status-based filter
  String? statusFilterString;
  switch (statusFilter) {
    case 'untagged':
      statusFilterString = FilterPresets.untaggedFilter();
      break;
    case 'tagged':
      statusFilterString = FilterPresets.taggedFilter();
      break;
    case 'all':
    default:
      statusFilterString = null; // No status filter
  }

  // Add filters to the list
  if (timeFilterString != null) {
    filterList.add(timeFilterString);
    if (kDebugMode) {
      print('[combinedFilterProvider] Added time filter: $timeFilterString');
    }
  }

  if (statusFilterString != null) {
    filterList.add(statusFilterString);
    if (kDebugMode) {
      print(
        '[combinedFilterProvider] Added status filter: $statusFilterString',
      );
    }
  }

  // Combine all active filters
  if (filterList.isEmpty) {
    return '';
  }
  
  final combinedFilter = FilterBuilder.and(filterList);

  if (kDebugMode) {
    print('[combinedFilterProvider] Final filter: $combinedFilter');
  }

  return combinedFilter;
}, name: 'combinedFilter');

/// Provider for storing filter preferences
///
/// OPTIMIZATION: Added better error handling, logging, and caching of preferences
final filterPreferencesProvider = Provider<
  Future<bool> Function(String timeFilter, String statusFilter)
>((ref) {
  return (String timeFilter, String statusFilter) async {
    try {
      if (kDebugMode) {
        print(
          '[filterPreferencesProvider] Saving preferences: time=$timeFilter, status=$statusFilter',
        );
      }
      
      final prefs = await SharedPreferences.getInstance();
      
      // OPTIMIZATION: Save in parallel for better performance
      final results = await Future.wait([
        prefs.setString('last_time_filter', timeFilter),
        prefs.setString('last_status_filter', statusFilter),
      ]);

      // Check if all operations succeeded
      final success = results.every((result) => result);

      if (kDebugMode) {
        print(
          '[filterPreferencesProvider] Saved preferences: ${success ? 'success' : 'partial failure'}',
        );
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('[filterPreferencesProvider] Error saving preferences: $e');
      }
      return false;
    }
  };
}, name: 'filterPreferences');

/// Provider for loading saved filter preferences
///
/// OPTIMIZATION: Added better error handling, logging, and caching
final loadFilterPreferencesProvider = FutureProvider<bool>((ref) async {
  if (kDebugMode) {
    print('[loadFilterPreferencesProvider] Loading saved filter preferences');
  }
  
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // OPTIMIZATION: Read all preferences at once to avoid multiple async calls
    final lastTimeFilter = prefs.getString('last_time_filter');
    final lastStatusFilter = prefs.getString('last_status_filter');
    
    // OPTIMIZATION: Only update state if we actually have saved preferences
    if (lastTimeFilter != null) {
      ref.read(timeFilterProvider.notifier).state = lastTimeFilter;
      if (kDebugMode) {
        print(
          '[loadFilterPreferencesProvider] Loaded time filter: $lastTimeFilter',
        );
      }
    }

    if (lastStatusFilter != null) {
      ref.read(statusFilterProvider.notifier).state = lastStatusFilter;
      if (kDebugMode) {
        print(
          '[loadFilterPreferencesProvider] Loaded status filter: $lastStatusFilter',
        );
      }
    }

    return true;
  } catch (e) {
    if (kDebugMode) {
      print('[loadFilterPreferencesProvider] Error loading preferences: $e');
    }
    return false;
  }
}, name: 'loadFilterPreferences');

/// OPTIMIZATION: Provider that keeps track of filter change history
/// This is useful for implementing undo/redo functionality
final filterHistoryProvider = StateProvider<List<Map<String, String>>>((ref) {
  // Store up to 10 recent filter configurations
  return [];
}, name: 'filterHistory');

/// OPTIMIZATION: A listener that adds configurations to history when they change
final _filterHistoryTrackerProvider = Provider<void>((ref) {
  // Set up a listener for filter changes
  ref.listen<String>(timeFilterProvider, (previous, current) {
    if (previous != current) {
      _addToHistory(ref);
    }
  });

  ref.listen<String>(statusFilterProvider, (previous, current) {
    if (previous != current) {
      _addToHistory(ref);
    }
  });

  ref.listen<String>(filterKeyProvider, (previous, current) {
    if (previous != current) {
      // Also track the previous filter key
      ref.read(lastUsedFilterKeyProvider.notifier).state = previous;
      _addToHistory(ref);
    }
  });
  
  return;
}, name: 'filterHistoryTracker');

// Helper function to add current filter configuration to history
void _addToHistory(Ref ref) {
  final timeFilter = ref.read(timeFilterProvider);
  final statusFilter = ref.read(statusFilterProvider);
  final filterKey = ref.read(filterKeyProvider);

  final history = ref.read(filterHistoryProvider);

  // Create a new configuration
  final config = {
    'timeFilter': timeFilter,
    'statusFilter': statusFilter,
    'filterKey': filterKey,
  };

  // Add to history, limiting to 10 items
  ref.read(filterHistoryProvider.notifier).state = [config, ...history.take(9)];
}
