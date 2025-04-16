import 'package:flutter/cupertino.dart'; // Import Cupertino for IconData
import 'package:flutter/foundation.dart';
import 'package:flutter_memos/utils/filter_presets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Define preset details including the CEL filter string
class QuickFilterPreset {
  final String key;
  final String label;
  final String celFilter; // The actual filter string for this preset
  final IconData? icon; // Optional icon for display

  const QuickFilterPreset({
    required this.key,
    required this.label,
    required this.celFilter,
    this.icon,
  });
}

// Define the available quick filter presets
final Map<String, QuickFilterPreset> quickFilterPresets = {
  'inbox': QuickFilterPreset(
    key: 'inbox',
    label: 'Inbox',
    celFilter: FilterPresets.untaggedFilter(), // Example: Inbox = Untagged
    icon: CupertinoIcons.tray_arrow_down,
  ),
  'today': QuickFilterPreset(
    key: 'today',
    label: 'Today',
    celFilter: FilterPresets.todayFilter(),
    icon: CupertinoIcons.today,
  ),
  'tagged': QuickFilterPreset(
    key: 'tagged',
    label: 'Tagged',
    celFilter: FilterPresets.taggedFilter(),
    icon: CupertinoIcons.tag,
  ),
  'all': QuickFilterPreset(
    key: 'all',
    label: 'All',
    celFilter: FilterPresets.allFilter(), // Use the new allFilter preset
    icon: CupertinoIcons.collections,
  ),
  // Add the new 'hidden' preset
  'hidden': const QuickFilterPreset(
    key: 'hidden',
    label: 'Hidden',
    celFilter: '', // Filter logic handled client-side in filteredNotesProvider
    icon: CupertinoIcons.eye_slash,
  ),
  // Special key to indicate a custom filter from the advanced panel is active
  'custom': const QuickFilterPreset(
    key: 'custom',
    label: 'Custom', // Label for when advanced filter is used
    celFilter: '', // Filter comes from rawCelFilterProvider
    icon: CupertinoIcons.tuningfork,
  ),
};

/// Provider for the key of the currently selected quick filter preset.
/// Defaults to 'today'.
final quickFilterPresetProvider = StateProvider<String>(
  (ref) => 'today', // Default preset changed to 'today'
  name: 'quickFilterPresetProvider',
);

/// Provider for advanced CEL filter expressions entered directly by the user
/// This allows users to enter complex filter expressions that can't be
/// easily expressed through the UI controls. Used when quickFilterPresetProvider is 'custom'.
final rawCelFilterProvider = StateProvider<String>(
  (ref) => '',
  name: 'rawCelFilter',
);

/// Flag to indicate if the advanced filter UI is visible
final showAdvancedFilterProvider = StateProvider<bool>(
  (ref) => false,
  name: 'showAdvancedFilter',
);

/// Provider for toggling visibility of pinned items.
/// When true, pinned items will be hidden from view
final hidePinnedProvider = StateProvider<bool>((ref) => false);

// REMOVED: timeFilterProvider
// REMOVED: statusFilterProvider

/// Provider for the current filter key ('inbox', 'archive', 'all', or a tag)
/// This seems redundant now with quickFilterPresetProvider, consider removing or refactoring if not used elsewhere.
/// Keeping it for now in case MemosNotifier or other parts rely on it directly.
/// It now attempts to derive its state from the quick preset.
final filterKeyProvider = StateProvider<String>(
  (ref) {
  // Attempt to sync with quickFilterPresetProvider if possible
  final presetKey = ref.watch(quickFilterPresetProvider);
  // Map preset keys to legacy filter keys if needed, otherwise return preset key
  // This mapping might need adjustment based on how MemosNotifier uses filterKey
  if (presetKey == 'inbox') {
    return 'inbox'; // Assuming 'inbox' preset maps to 'inbox' key
  }
  if (presetKey == 'all') {
    return 'all'; // Assuming 'all' preset maps to 'all' key
  }
  if (presetKey == 'tagged') {
    return 'all'; // Example: Maybe 'tagged' should show 'all' states? Adjust as needed.
  }
  if (presetKey == 'today') {
    return 'all'; // Example: Maybe 'today' should show 'all' states? Adjust as needed.
  }
  // Handle the new 'hidden' preset - likely applies to 'all' states for API, filtered client-side
  if (presetKey == 'hidden') {
    return 'all'; // Hidden notes are filtered client-side, fetch all non-archived
  }
  if (presetKey == 'custom') {
    return 'all'; // Custom filter likely applies to 'all' states
  }

  // Fallback if presetKey doesn't match known legacy keys (e.g., a tag)
  return presetKey;
},
  name: 'filterKey',
);

/// OPTIMIZATION: Provider to track the last used filter key
/// This helps with history and restoring state
final lastUsedFilterKeyProvider = StateProvider<String?>(
  (ref) => null,
  name: 'lastUsedFilterKey',
);

/// Provider for the current search query used for local filtering
/// This is used for quick, client-side filtering as the user types
final searchQueryProvider = StateProvider<String>(
  (ref) => '',
  name: 'searchQuery',
);

/// Flag to determine if search is performed locally (true) or via server (false)
final localSearchEnabledProvider = StateProvider<bool>(
  (ref) => true, // Default to local search for faster response
  name: 'localSearchEnabled',
);

/// Debounce period for sending searches to the server (in milliseconds)
final searchDebounceProvider = StateProvider<int>(
  (ref) => 300, // 300ms is a typical debounce time
  name: 'searchDebounce',
);

/// Provider that combines all filter options into a single filter string
/// Prioritizes quick presets, falls back to raw CEL filter if preset is 'custom'.
final combinedFilterProvider = Provider<String>((ref) {
  final selectedPresetKey = ref.watch(quickFilterPresetProvider);

  if (kDebugMode) {
    print('[combinedFilterProvider] Selected preset key: $selectedPresetKey');
  }

  if (selectedPresetKey == 'custom') {
    // Use the raw CEL filter from the advanced panel
    final rawFilter = ref.watch(rawCelFilterProvider);
    if (kDebugMode) {
      print('[combinedFilterProvider] Using raw CEL filter: $rawFilter');
    }
    return rawFilter;
  } else {
    // Look up the CEL filter associated with the selected quick preset
    final preset = quickFilterPresets[selectedPresetKey];
    final presetFilter =
        preset?.celFilter ?? ''; // Default to empty if key not found
    if (kDebugMode) {
      print(
        '[combinedFilterProvider] Using filter for preset "$selectedPresetKey": $presetFilter',
      );
    }
    return presetFilter;
  }
}, name: 'combinedFilter');

/// Provider for storing filter preferences (now stores the preset key)
final filterPreferencesProvider = Provider<
  Future<bool> Function(String presetKey)
>((ref) {
  return (String presetKey) async {
    try {
      if (kDebugMode) {
        print(
          '[filterPreferencesProvider] Saving preset preference: $presetKey',
        );
      }
      final prefs = await SharedPreferences.getInstance();
      // Ensure we only save valid preset keys (excluding 'custom')
      final keyToSave =
          quickFilterPresets.containsKey(presetKey) && presetKey != 'custom'
              ? presetKey
              : 'today'; // Default to 'today' if invalid or 'custom'
      final success = await prefs.setString('last_quick_preset', keyToSave);

      if (kDebugMode) {
        print(
          '[filterPreferencesProvider] Saved preset preference ($keyToSave): ${success ? 'success' : 'failure'}',
        );
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('[filterPreferencesProvider] Error saving preset preference: $e');
      }
      return false;
    }
  };
}, name: 'filterPreferences');

/// Provider for loading saved filter preferences (now loads the preset key)
final loadFilterPreferencesProvider = FutureProvider<bool>((ref) async {
  if (kDebugMode) {
    print('[loadFilterPreferencesProvider] Loading saved preset preference');
  }
  try {
    final prefs = await SharedPreferences.getInstance();
    final lastPresetKey = prefs.getString('last_quick_preset');

    // Load the saved preset if it's valid and exists in our map
    if (lastPresetKey != null &&
        quickFilterPresets.containsKey(lastPresetKey)) {
      // Do not load 'custom' as the initial state, default to 'today' instead
      final keyToLoad =
          lastPresetKey == 'custom'
              ? 'today'
              : lastPresetKey; // Default to 'today'
      ref.read(quickFilterPresetProvider.notifier).state = keyToLoad;
      if (kDebugMode) {
        print(
          '[loadFilterPreferencesProvider] Loaded preset preference: $keyToLoad',
        );
      }
    } else if (lastPresetKey != null) {
      if (kDebugMode) {
        print(
          '[loadFilterPreferencesProvider] Ignored invalid saved preset key: $lastPresetKey',
        );
      }
      // Optionally set to default if saved key is invalid
      // ref.read(quickFilterPresetProvider.notifier).state = 'today'; // Default to 'today'
    } else {
      // If no preference saved, ensure default is set (although provider default handles this)
      // ref.read(quickFilterPresetProvider.notifier).state = 'today'; // Default to 'today'
    }

    return true;
  } catch (e) {
    if (kDebugMode) {
      print(
        '[loadFilterPreferencesProvider] Error loading preset preference: $e',
      );
    }
    return false;
  }
}, name: 'loadFilterPreferences');

/// OPTIMIZATION: Provider that keeps track of filter change history
final filterHistoryProvider = StateProvider<List<Map<String, String>>>((ref) {
  // Store up to 10 recent filter configurations
  return [];
}, name: 'filterHistory');

/// OPTIMIZATION: A listener that adds configurations to history when they change
final filterHistoryTrackerProvider = Provider<void>((ref) {
  // Listen to the quick preset provider
  ref.listen<String>(quickFilterPresetProvider, (previous, current) {
    if (previous != current) {
      // Track the previous preset key
      ref.read(lastUsedFilterKeyProvider.notifier).state = previous;
      _addToHistory(ref); // Add the new state to history
    }
  });

  // Also listen to raw filter changes when the mode is 'custom'
  ref.listen<String>(rawCelFilterProvider, (previous, current) {
    final currentPreset = ref.read(quickFilterPresetProvider);
    // Only add raw filter changes to history if we are in custom mode
    if (currentPreset == 'custom' && previous != current) {
      _addToHistory(ref);
    }
  });

  // No need to listen to filterKeyProvider anymore if it's derived

  return;
}, name: 'filterHistoryTracker');

// Helper function to add current filter configuration to history
void _addToHistory(Ref ref) {
  final presetKey = ref.read(quickFilterPresetProvider);
  final rawFilter = ref.read(rawCelFilterProvider);

  final history = ref.read(filterHistoryProvider);

  // Create a new configuration
  final config = {
    'presetKey': presetKey,
    // Store raw filter only if relevant (i.e., preset is 'custom')
    'rawFilter': presetKey == 'custom' ? rawFilter : '',
  };

  // Avoid adding duplicate consecutive states
  if (history.isNotEmpty &&
      history.first['presetKey'] == config['presetKey'] &&
      history.first['rawFilter'] == config['rawFilter']) {
    if (kDebugMode) {
      print('[filterHistory] Skipping duplicate state: $config');
    }
    return;
  }

  // Add to history, limiting to 10 items
  ref.read(filterHistoryProvider.notifier).state = [config, ...history.take(9)];
  if (kDebugMode) {
    print('[filterHistory] Added state: $config');
  }
}

// REMOVED: hideFutureStartDateProvider (logic merged into filteredNotesProvider controlled by showHiddenNotesProvider)
// final hideFutureStartDateProvider = StateProvider<bool>((ref) {
//   // TODO: Load this preference from SharedPreferences if needed
//   return true; // Default to hiding future notes
// }, name: 'hideFutureStartDateProvider');

/// Provider to control whether manually hidden and future-dated notes are shown in the list.
final showHiddenNotesProvider = StateProvider<bool>((ref) {
  // TODO: Persist this preference if needed (e.g., using SharedPreferences or another PersistentNotifier)
  return false; // Default to hiding the hidden notes
}, name: 'showHiddenNotesProvider');
