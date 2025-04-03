import 'package:flutter/material.dart';
import 'package:flutter_memos/providers/filter_providers.dart' as filter;
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
  
  void _showFilterSyntaxHelp(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('CEL Filter Syntax'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Supported Factors:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('• tag: Use with "in" operator'),
                  const Text('• visibility: Can use ==, !=, in'),
                  const Text('• content: Use with contains, ==, !='),
                  const Text(
                    '• create_time: Compare with ==, !=, <, >, <=, >=',
                  ),
                  const Text(
                    '• update_time: Compare with ==, !=, <, >, <=, >=',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Examples:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'tag in ["work", "important"]',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'visibility == "PUBLIC" && content.contains("meeting")',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'create_time > "2023-01-01T00:00:00Z"',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Logical Operators:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('• && - AND: Both conditions must be true'),
                  const Text('• || - OR: Either condition can be true'),
                  const Text('• ! - NOT: Negates a condition'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _applyTimeFilter(
    String filterOption,
    WidgetRef ref,
    BuildContext context,
  ) {
    // Update provider state instead of local state
    ref.read(filter.timeFilterProvider.notifier).state = filterOption;

    // Clear any hidden memo IDs when changing filters
    ref.read(hiddenMemoIdsProvider.notifier).state = {};

    // Save filter preferences
    final statusFilter = ref.read(filter.statusFilterProvider);
    ref.read(filter.filterPreferencesProvider)(filterOption, statusFilter);
  }

  void _applyStatusFilter(
    String filterOption,
    WidgetRef ref,
    BuildContext context,
  ) {
    // Update provider state instead of local state
    ref.read(filter.statusFilterProvider.notifier).state = filterOption;

    // Clear any hidden memo IDs when changing filters
    ref.read(hiddenMemoIdsProvider.notifier).state = {};

    // Save filter preferences
    final timeFilter = ref.read(filter.timeFilterProvider);
    ref.read(filter.filterPreferencesProvider)(timeFilter, filterOption);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeFilterOptionKey = ref.watch(filter.timeFilterProvider);
    final statusFilterOptionKey = ref.watch(filter.statusFilterProvider);
    final hiddenMemoIds = ref.watch(hiddenMemoIdsProvider);
    final hidePinned = ref.watch(filter.hidePinnedProvider);
    final showAdvancedFilter = ref.watch(filter.showAdvancedFilterProvider);
    final rawCelFilter = ref.watch(filter.rawCelFilterProvider);
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
                                ).iconTheme.color?.withAlpha(179),
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
                                ).iconTheme.color?.withAlpha(179),
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

          // Add toggle for pinned items
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    // Toggle the hidePinned state
                    ref.read(filter.hidePinnedProvider.notifier).state =
                        !hidePinned;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          hidePinned
                              ? (isDarkMode
                                  ? Colors.purple.shade900
                                  : Colors.purple.shade100)
                              : (isDarkMode
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            hidePinned
                                ? (isDarkMode
                                    ? Colors.purple.shade700
                                    : Colors.purple.shade300)
                                : (isDarkMode
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hidePinned ? Icons.push_pin_outlined : Icons.push_pin,
                          size: 16,
                          color:
                              hidePinned
                                  ? (isDarkMode
                                      ? Colors.purple.shade200
                                      : Colors.purple.shade800)
                                  : Theme.of(context).iconTheme.color,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hidePinned ? 'Show Pinned' : 'Hide Pinned',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                hidePinned
                                    ? (isDarkMode
                                        ? Colors.purple.shade200
                                        : Colors.purple.shade800)
                                    : Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
                          ? const Color(0xFF1A237E).withAlpha(77)
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
          
          // Advanced filter section
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    // Toggle advanced filter visibility
                    ref.read(filter.showAdvancedFilterProvider.notifier).state =
                        !showAdvancedFilter;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          showAdvancedFilter
                              ? (isDarkMode
                                  ? Colors.amber.shade900
                                  : Colors.amber.shade100)
                              : (isDarkMode
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            showAdvancedFilter
                                ? (isDarkMode
                                    ? Colors.amber.shade700
                                    : Colors.amber.shade300)
                                : (isDarkMode
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          showAdvancedFilter ? Icons.code : Icons.code_outlined,
                          size: 16,
                          color:
                              showAdvancedFilter
                                  ? (isDarkMode
                                      ? Colors.amber.shade200
                                      : Colors.amber.shade800)
                                  : Theme.of(context).iconTheme.color,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          showAdvancedFilter
                              ? 'Hide Advanced Filter'
                              : 'Advanced Filter',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                showAdvancedFilter
                                    ? (isDarkMode
                                        ? Colors.amber.shade200
                                        : Colors.amber.shade800)
                                    : Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 18),
                  tooltip: 'Filter Syntax Help',
                  onPressed: () => _showFilterSyntaxHelp(context),
                ),
              ],
            ),
          ),

          // Show advanced filter input if enabled
          if (showAdvancedFilter)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CEL Filter Expression',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color:
                          isDarkMode
                              ? Colors.amber.shade200
                              : Colors.amber.shade800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    initialValue: rawCelFilter,
                    decoration: InputDecoration(
                      hintText:
                          'E.g., tag in ["work"] && visibility == "PUBLIC"',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color:
                            isDarkMode
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      isDense: true,
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                      color:
                          isDarkMode
                              ? Colors.amber.shade100
                              : Colors.amber.shade900,
                    ),
                    onChanged: (value) {
                      ref.read(filter.rawCelFilterProvider.notifier).state =
                          value;
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'When using advanced filter, UI filters are ignored',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color:
                              isDarkMode
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.search, size: 16),
                        label: const Text('Apply Filter'),
                        onPressed: () {
                          // Clear focus
                          FocusScope.of(context).unfocus();
                          // Apply the filter by triggering refresh
                          ref.read(memosNotifierProvider.notifier).refresh();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor:
                              isDarkMode
                                  ? Colors.amber.shade900
                                  : Colors.amber.shade100,
                          foregroundColor:
                              isDarkMode
                                  ? Colors.amber.shade100
                                  : Colors.amber.shade900,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
