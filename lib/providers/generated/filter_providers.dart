import 'package:flutter_memos/utils/filter_builder.dart';
import 'package:flutter_memos/utils/filter_presets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Generate the .g.dart file
part 'filter_providers.g.dart';

/// Time filter provider (all, today, this_week, etc.)
@riverpod
class TimeFilter extends _$TimeFilter {
  @override
  String build() => 'all';
  
  /// Update the time filter and save it to preferences
  Future<void> updateFilter(String filter) async {
    state = filter;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_time_filter', filter);
    } catch (e) {
      // Silently fail if we can't save the preference
    }
  }
  
  /// Load the saved time filter from preferences
  Future<void> loadSavedFilter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedFilter = prefs.getString('last_time_filter');
      if (savedFilter != null) {
        state = savedFilter;
      }
    } catch (e) {
      // Use default if we can't load the preference
    }
  }
}

/// Status filter provider (all, untagged, tagged)
@riverpod
class StatusFilter extends _$StatusFilter {
  @override
  String build() => 'untagged';
  
  /// Update the status filter and save it to preferences
  Future<void> updateFilter(String filter) async {
    state = filter;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_status_filter', filter);
    } catch (e) {
      // Silently fail if we can't save the preference
    }
  }
  
  /// Load the saved status filter from preferences
  Future<void> loadSavedFilter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedFilter = prefs.getString('last_status_filter');
      if (savedFilter != null) {
        state = savedFilter;
      }
    } catch (e) {
      // Use default if we can't load the preference
    }
  }
}

/// Filter key provider (inbox, archive, all, or a tag)
@riverpod
class FilterKey extends _$FilterKey {
  @override
  String build() => 'inbox';
  
  /// Set the filter key
  void setFilterKey(String key) {
    state = key;
  }
}

/// Combined filter provider that builds a filter expression from all filters
@riverpod
String combinedFilter(CombinedFilterRef ref) {
  final timeFilter = ref.watch(timeFilterProvider);
  final statusFilter = ref.watch(statusFilterProvider);
  final filterList = <String>[];

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
  if (timeFilterString != null) filterList.add(timeFilterString);
  if (statusFilterString != null) filterList.add(statusFilterString);

  // Combine all active filters
  if (filterList.isEmpty) {
    return '';
  }
  
  return FilterBuilder.and(filterList);
}

/// Load saved filter preferences
@riverpod
Future<void> loadFilterPreferences(LoadFilterPreferencesRef ref) async {
  await ref.read(timeFilterProvider.notifier).loadSavedFilter();
  await ref.read(statusFilterProvider.notifier).loadSavedFilter();
}