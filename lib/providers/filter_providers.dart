import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_memos/utils/filter_builder.dart';
import 'package:flutter_memos/utils/filter_presets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for the time-based filter option ('today', 'this_week', etc.)
final timeFilterProvider = StateProvider<String>((ref) => 'all');

/// Provider for the status-based filter option ('untagged', 'tagged', 'all')
final statusFilterProvider = StateProvider<String>((ref) => 'untagged');

/// Provider that combines all filter options into a single filter string
final combinedFilterProvider = Provider<String>((ref) {
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
});

/// Provider for storing filter preferences
final filterPreferencesProvider = Provider<Future<void> Function(String timeFilter, String statusFilter)>((ref) {
  return (String timeFilter, String statusFilter) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_time_filter', timeFilter);
      await prefs.setString('last_status_filter', statusFilter);
    } catch (e) {
      // Silently fail if we can't save the preference
    }
  };
});

/// Provider for loading saved filter preferences
final loadFilterPreferencesProvider = FutureProvider<void>((ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final lastTimeFilter = prefs.getString('last_time_filter') ?? 'all';
    final lastStatusFilter = prefs.getString('last_status_filter') ?? 'untagged';
    
    ref.read(timeFilterProvider.notifier).state = lastTimeFilter;
    ref.read(statusFilterProvider.notifier).state = lastStatusFilter;
  } catch (e) {
    // If there's an error, use defaults (already set in the providers)
  }
});