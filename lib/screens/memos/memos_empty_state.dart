import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter_memos/providers/filter_providers.dart'; // Import filter providers
import 'package:flutter_memos/providers/memo_providers.dart'; // Import memo providers
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MemosEmptyState extends ConsumerWidget {
  // Removed message and icon from constructor, as they are determined by filter state
  final VoidCallback? onRefresh;

  const MemosEmptyState({
    super.key,
    this.onRefresh,
  });

  // Helper method to apply status filter and clear hidden memos
  void _applyStatusFilter(String filterOption, WidgetRef ref) {
    ref.read(statusFilterProvider.notifier).state = filterOption;
    ref.read(hiddenMemoIdsProvider.notifier).state = {}; // Clear hidden memos
    // Save preferences (assuming filterPreferencesProvider exists and is adapted)
    // final timeFilter = ref.read(timeFilterProvider);
    // ref.read(filterPreferencesProvider)(timeFilter, filterOption);
  }

  // Helper method to apply time filter and clear hidden memos
  void _applyTimeFilter(String filterOption, WidgetRef ref) {
    ref.read(timeFilterProvider.notifier).state = filterOption;
    ref.read(hiddenMemoIdsProvider.notifier).state = {}; // Clear hidden memos
    // Save preferences (assuming filterPreferencesProvider exists and is adapted)
    // final statusFilter = ref.read(statusFilterProvider);
    // ref.read(filterPreferencesProvider)(filterOption, statusFilter);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeFilterOption = ref.watch(timeFilterProvider);
    final statusFilterOption = ref.watch(statusFilterProvider);
    final bool hasActiveFilters =
        timeFilterOption != 'all' || statusFilterOption != 'all';

    // Use CupertinoTheme for styling
    final theme = CupertinoTheme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Define colors using Cupertino dynamic colors
    final Color iconColor = CupertinoColors.secondaryLabel.resolveFrom(context);
    final TextStyle textStyle = theme.textTheme.textStyle.copyWith(
      color: CupertinoColors.secondaryLabel.resolveFrom(context),
      fontSize: 16,
    );
    final Color filterInfoBackgroundColor =
        isDarkMode
            ? CupertinoColors.systemYellow.darkColor.withAlpha(
              77,
            ) // Approx 0.3 opacity
            : CupertinoColors.systemYellow.color.withAlpha(
              51,
            ); // Lighter yellow
    final Color filterInfoBorderColor =
        isDarkMode
            ? CupertinoColors
                .systemYellow
                .darkColor // Darker border in dark mode
            : CupertinoColors
                .systemYellow
                .color; // Lighter border in light mode
    final Color filterInfoTextColor =
        isDarkMode
            ? CupertinoColors
                .systemYellow
                .color // Lighter text in dark mode
            : CupertinoColors
                .black; // Darker text in light mode (adjust if needed)
    final Color clearButtonColor =
        isDarkMode ? CupertinoColors.systemYellow.color : theme.primaryColor;

    return Column(
      children: [
        // Indicator for active filters with no results
        if (hasActiveFilters)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: filterInfoBackgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: filterInfoBorderColor,
                width: 0.5, // Use a subtle border
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.line_horizontal_3_decrease,
                      color: filterInfoTextColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No memos found with the current filters',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: filterInfoTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Display active status filter and clear button
                if (statusFilterOption != 'all')
                  Padding(
                    padding: const EdgeInsets.only(left: 28.0, bottom: 4.0),
                    child: Row(
                      children: [
                        Text(
                          '• Status: $statusFilterOption',
                          style: TextStyle(color: filterInfoTextColor),
                        ),
                        const Spacer(),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                          minSize: 24,
                          onPressed: () => _applyStatusFilter('all', ref),
                          child: Text(
                            'Clear',
                            style: TextStyle(
                              color: clearButtonColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Display active time filter and clear button
                if (timeFilterOption != 'all')
                  Padding(
                    padding: const EdgeInsets.only(left: 28.0, bottom: 4.0),
                    child: Row(
                      children: [
                        Text(
                          '• Time: $timeFilterOption',
                          style: TextStyle(color: filterInfoTextColor),
                        ),
                        const Spacer(),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                          minSize: 24,
                          onPressed: () => _applyTimeFilter('all', ref),
                          child: Text(
                            'Clear',
                            style: TextStyle(
                              color: clearButtonColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Button to clear all filters
                Padding(
                  padding: const EdgeInsets.only(left: 28.0, top: 4.0),
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minSize: 30,
                    onPressed: () {
                      _applyStatusFilter('all', ref);
                      _applyTimeFilter('all', ref);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.clear_circled,
                          size: 16,
                          color: clearButtonColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Clear All Filters',
                          style: TextStyle(
                            color: clearButtonColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Main empty state message (shown regardless of filters if list is empty)
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0), // Increased padding
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.square_list, // Default icon
                  size: 64,
                  color: iconColor,
                ),
                const SizedBox(height: 16),
                Text(
                  hasActiveFilters
                      ? 'Try adjusting your filters.'
                      : 'No memos yet. Create one!',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                if (onRefresh != null) ...[
                  const SizedBox(height: 24),
                  CupertinoButton(
                    onPressed: onRefresh,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.refresh, size: 18),
                        SizedBox(width: 8),
                        Text('Refresh'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
