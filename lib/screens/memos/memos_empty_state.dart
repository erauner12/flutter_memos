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

  // Helper method to apply filter preset and clear hidden memos
  void _applyFilterPreset(String presetKey, WidgetRef ref) {
    ref.read(quickFilterPresetProvider.notifier).state = presetKey;
    ref.read(hiddenMemoIdsProvider.notifier).state = {}; // Clear hidden memos
    // Save preferences using the new provider
    ref.read(filterPreferencesProvider)(presetKey);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPresetKey = ref.watch(quickFilterPresetProvider);
    final bool hasActiveFilters = currentPresetKey != 'all';

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
                // Display active filter preset and clear button
                if (currentPresetKey != 'all')
                  Padding(
                    padding: const EdgeInsets.only(left: 28.0, bottom: 4.0),
                    child: Row(
                      children: [
                        Text(
                          '• Filter: ${quickFilterPresets[currentPresetKey]?.label ?? currentPresetKey}',
                          style: TextStyle(color: filterInfoTextColor),
                        ),
                        const Spacer(),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                          minSize: 24,
                          onPressed: () => _applyFilterPreset('all', ref),
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
                    onPressed: () => _applyFilterPreset('all', ref),
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
                  quickFilterPresets[currentPresetKey]?.icon ??
                      CupertinoIcons
                          .square_list, // Use preset icon if available
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
