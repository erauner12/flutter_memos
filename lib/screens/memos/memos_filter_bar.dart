import 'package:flutter/material.dart';
import 'package:flutter_memos/providers/filter_providers.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Add FilterOption class for dropdown items
class FilterOption {
  final String key;
  final String label;
  final IconData? icon;

  const FilterOption({required this.key, required this.label, this.icon});
}

// Define filter options
const List<FilterOption> statusFilterOptions = [
  FilterOption(key: 'all', label: 'All Status'),
  FilterOption(
    key: 'untagged',
    label: 'Untagged',
    icon: Icons.new_releases_outlined,
  ),
  FilterOption(key: 'tagged', label: 'Tagged', icon: Icons.label),
];

const List<FilterOption> timeFilterOptions = [
  FilterOption(key: 'all', label: 'All Time'),
  FilterOption(key: 'today', label: 'Today', icon: Icons.today),
  FilterOption(
    key: 'created_today',
    label: 'Created Today',
    icon: Icons.add_circle_outline,
  ),
  FilterOption(
    key: 'updated_today',
    label: 'Updated Today',
    icon: Icons.update,
  ),
  FilterOption(key: 'this_week', label: 'This Week', icon: Icons.date_range),
  FilterOption(key: 'important', label: 'Important', icon: Icons.star_outline),
];

class MemosFilterBar extends ConsumerWidget {
  const MemosFilterBar({super.key});

  void _showAllMemos(WidgetRef ref) {
    ref.read(hiddenMemoIdsProvider.notifier).state = {};
  }

  void _applyTimeFilter(
    String filterOption,
    WidgetRef ref,
    BuildContext context,
  ) {
    // Update provider state instead of local state
    ref.read(timeFilterProvider.notifier).state = filterOption;

    // Clear any hidden memo IDs when changing filters
    ref.read(hiddenMemoIdsProvider.notifier).state = {};

    // Save filter preferences
    final statusFilter = ref.read(statusFilterProvider);
    ref.read(filterPreferencesProvider)(filterOption, statusFilter);
  }

  void _applyStatusFilter(
    String filterOption,
    WidgetRef ref,
    BuildContext context,
  ) {
    // Update provider state instead of local state
    ref.read(statusFilterProvider.notifier).state = filterOption;

    // Clear any hidden memo IDs when changing filters
    ref.read(hiddenMemoIdsProvider.notifier).state = {};

    // Save filter preferences
    final timeFilter = ref.read(timeFilterProvider);
    ref.read(filterPreferencesProvider)(timeFilter, filterOption);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeFilterOptionKey = ref.watch(timeFilterProvider);
    final statusFilterOptionKey = ref.watch(statusFilterProvider);
    final hiddenMemoIds = ref.watch(hiddenMemoIdsProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Helper to find the label for the current key
    String getLabelForKey(String key, List<FilterOption> options) {
      return options
          .firstWhere((o) => o.key == key, orElse: () => options.last)
          .label;
    }

    final currentStatusLabel = getLabelForKey(
      statusFilterOptionKey,
      statusFilterOptions,
    );
    final currentTimeLabel = getLabelForKey(
      timeFilterOptionKey,
      timeFilterOptions,
    );

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF242424) : Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? const Color(0xFF333333) : Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Status Filter Dropdown
              Expanded(
                child: PopupMenuButton<String>(
                  tooltip: 'Filter by Status',
                  onSelected: (String selectedKey) {
                    _applyStatusFilter(selectedKey, ref, context);
                  },
                  itemBuilder: (BuildContext context) {
                    return statusFilterOptions.map((FilterOption option) {
                      return PopupMenuItem<String>(
                        value: option.key,
                        child: Row(
                          children: [
                            if (option.icon != null)
                              Icon(
                                option.icon,
                                size: 18,
                                color: Theme.of(
                                  context,
                                ).iconTheme.color?.withOpacity(0.7),
                              ),
                            if (option.icon != null) const SizedBox(width: 8),
                            Text(option.label),
                            if (option.key == statusFilterOptionKey) ...[
                              const Spacer(),
                              Icon(
                                Icons.check,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.label_outline,
                          size: 16,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            currentStatusLabel,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 18),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Time Filter Dropdown
              Expanded(
                child: PopupMenuButton<String>(
                  tooltip: 'Filter by Time Range',
                  onSelected: (String selectedKey) {
                    _applyTimeFilter(selectedKey, ref, context);
                  },
                  itemBuilder: (BuildContext context) {
                    return timeFilterOptions.map((FilterOption option) {
                      return PopupMenuItem<String>(
                        value: option.key,
                        child: Row(
                          children: [
                            if (option.icon != null)
                              Icon(
                                option.icon,
                                size: 18,
                                color: Theme.of(
                                  context,
                                ).iconTheme.color?.withOpacity(0.7),
                              ),
                            if (option.icon != null) const SizedBox(width: 8),
                            Text(option.label),
                            if (option.key == timeFilterOptionKey) ...[
                              const Spacer(),
                              Icon(
                                Icons.check,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            currentTimeLabel,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Show hidden memos section
          if (hiddenMemoIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 6.0,
                  horizontal: 12.0,
                ),
                decoration: BoxDecoration(
                  color:
                      isDarkMode
                          ? const Color(0xFF1A237E).withOpacity(0.3)
                          : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isDarkMode
                            ? Colors.blue.shade900
                            : Colors.blue.shade200,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.visibility_off,
                      size: 16,
                      color:
                          isDarkMode
                              ? Colors.blue.shade200
                              : Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${hiddenMemoIds.length} memos hidden',
                      style: TextStyle(
                        color:
                            isDarkMode
                                ? Colors.blue.shade200
                                : Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _showAllMemos(ref),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        minimumSize: const Size(0, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor:
                            isDarkMode
                                ? Colors.blue.shade100
                                : Colors.blue.shade700,
                      ),
                      child: const Text('Show All'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
