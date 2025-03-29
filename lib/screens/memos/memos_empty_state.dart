import 'package:flutter/material.dart';
import 'package:flutter_memos/providers/filter_providers.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MemosEmptyState extends ConsumerWidget {
  const MemosEmptyState({super.key});

  void _applyStatusFilter(String filterOption, WidgetRef ref) {
    ref.read(statusFilterProvider.notifier).state = filterOption;
    
    // Clear any hidden memo IDs when changing filters
    ref.read(hiddenMemoIdsProvider.notifier).state = {};
    
    // Save filter preferences
    final timeFilter = ref.read(timeFilterProvider);
    ref.read(filterPreferencesProvider)(timeFilter, filterOption);
  }

  void _applyTimeFilter(String filterOption, WidgetRef ref) {
    ref.read(timeFilterProvider.notifier).state = filterOption;
    
    // Clear any hidden memo IDs when changing filters
    ref.read(hiddenMemoIdsProvider.notifier).state = {};

    // Save filter preferences
    final statusFilter = ref.read(statusFilterProvider);
    ref.read(filterPreferencesProvider)(filterOption, statusFilter);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeFilterOption = ref.watch(timeFilterProvider);
    final statusFilterOption = ref.watch(statusFilterProvider);
    final isDarkMode =
        Theme.of(context).brightness == Brightness.dark; // Check dark mode

    // The main Column for the empty state content
    return Column(
      // mainAxisAlignment: MainAxisAlignment.center, // Optional: Uncomment to center everything vertically
      children: [
        // Indicator for active filters with no results
        if (timeFilterOption != 'all' || statusFilterOption != 'all')
          Container(
            // Keep existing filter info container setup
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  isDarkMode
                      ? Colors.amber.shade900.withOpacity(0.3)
                      : Colors.amber.shade100, // Dark mode color
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                // Add border for better visibility in dark mode
                color:
                    isDarkMode ? Colors.amber.shade800 : Colors.amber.shade300,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Keep existing filter info content (Row, Text, Buttons etc.)
                Row(
                  children: [
                    Icon(
                      Icons.filter_alt,
                      color:
                          isDarkMode
                              ? Colors.amber.shade300
                              : Colors.amber.shade800, // Dark mode icon color
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No memos found with the current filters',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              isDarkMode
                                  ? Colors.amber.shade200
                                  : Colors
                                      .amber
                                      .shade900, // Dark mode text color
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (statusFilterOption != 'all')
                  Padding(
                    padding: const EdgeInsets.only(left: 28.0, bottom: 4.0),
                    child: Row(
                      children: [
                        Text(
                          '• Status filter: $statusFilterOption',
                          style: TextStyle(
                            color:
                                isDarkMode
                                    ? Colors.amber.shade200
                                    : Colors.amber.shade900,
                          ), // Dark mode text color
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => _applyStatusFilter('all', ref),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                            minimumSize: const Size(0, 24),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor:
                                isDarkMode
                                    ? Colors.amber.shade100
                                    : Theme.of(context)
                                        .colorScheme
                                        .primary, // Dark mode button color
                          ),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),
                if (timeFilterOption != 'all')
                  Padding(
                    padding: const EdgeInsets.only(left: 28.0, bottom: 4.0),
                    child: Row(
                      children: [
                        Text(
                          '• Time filter: $timeFilterOption',
                          style: TextStyle(
                            color:
                                isDarkMode
                                    ? Colors.amber.shade200
                                    : Colors.amber.shade900,
                          ), // Dark mode text color
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => _applyTimeFilter('all', ref),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                            minimumSize: const Size(0, 24),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor:
                                isDarkMode
                                    ? Colors.amber.shade100
                                    : Theme.of(context)
                                        .colorScheme
                                        .primary, // Dark mode button color
                          ),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(left: 28.0, top: 4.0),
                  child: TextButton.icon(
                    onPressed: () {
                      _applyStatusFilter('all', ref);
                      _applyTimeFilter('all', ref);
                    },
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Clear All Filters'),
                    style: TextButton.styleFrom(
                      // Ensure consistent styling
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: const Size(0, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor:
                          isDarkMode
                              ? Colors.amber.shade100
                              : Theme.of(
                                context,
                              ).colorScheme.primary, // Dark mode button color
                    ),
                  ),
                ),
              ],
            ),
          ),

        // REMOVED the Expanded widget that previously wrapped this Center.
        // The Center widget now renders directly below the filter info container.
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Keep padding for spacing
            child: Text(
              'No memos found.',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color:
                    Colors
                        .grey[600], // Slightly darker grey, works okay in both modes
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        // Optional: If you need the text pushed further down, uncomment Spacer
        // Spacer(),
      ],
    );
  }
}
