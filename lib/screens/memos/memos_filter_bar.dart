import 'package:flutter/material.dart';
import 'package:flutter_memos/providers/filter_providers.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MemosFilterBar extends ConsumerWidget {
  const MemosFilterBar({super.key});

  void _toggleHideMemo(String memoId, BuildContext context, WidgetRef ref) {
    final hiddenMemoIds = ref.read(hiddenMemoIdsProvider);
    if (hiddenMemoIds.contains(memoId)) {
      // Unhide memo
      ref
          .read(hiddenMemoIdsProvider.notifier)
          .update((state) => state..remove(memoId));
    } else {
      // Hide memo
      ref
          .read(hiddenMemoIdsProvider.notifier)
          .update((state) => state..add(memoId));

      // Show a confirmation that the memo was hidden
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Memo hidden'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    // Force UI refresh to update visibility
    ref.invalidate(memosProvider);
  }

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
    final timeFilterOption = ref.watch(timeFilterProvider);
    final statusFilterOption = ref.watch(statusFilterProvider);
    final hiddenMemoIds = ref.watch(hiddenMemoIdsProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status filter group (Tagged/Untagged)
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 2.0),
            child: Row(
              children: [
                Icon(
                  Icons.label_outline,
                  size: 14,
                  color:
                      isDarkMode ? Colors.grey.shade400 : Colors.grey.shade800,
                ),
                const SizedBox(width: 4),
                Text(
                  'Status:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color:
                        isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                if (statusFilterOption != 'all')
                  TextButton.icon(
                    onPressed: () => _applyStatusFilter('all', ref, context),
                    icon: const Icon(Icons.close, size: 14),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      minimumSize: const Size(0, 24),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: isDarkMode ? Colors.grey.shade300 : null,
                    ),
                  ),
              ],
            ),
          ),

          // Status filter chips (Tagged/Untagged)
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
            child: Row(
              children: [
                // Untagged filter
                FilterChip(
                  label: const Text('Untagged'),
                  selected: statusFilterOption == 'untagged',
                  onSelected:
                      (_) => _applyStatusFilter('untagged', ref, context),
                  backgroundColor:
                      isDarkMode
                          ? (statusFilterOption == 'untagged'
                              ? Colors.blue.shade900
                              : const Color(0xFF333333))
                          : (statusFilterOption == 'untagged'
                              ? Colors.blue.shade100
                              : Colors.blue.shade50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color:
                          isDarkMode
                              ? Colors.blue.shade800
                              : Colors.blue.shade300,
                      width: 1.5,
                    ),
                  ),
                  labelStyle: TextStyle(
                    color:
                        isDarkMode
                            ? (statusFilterOption == 'untagged'
                                ? Colors.blue.shade100
                                : Colors.blue.shade200)
                            : Colors.blue.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                  avatar: Icon(
                    Icons.new_releases_outlined,
                    size: 16,
                    color:
                        isDarkMode
                            ? Colors.blue.shade200
                            : Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 8),

                // Tagged filter
                FilterChip(
                  label: const Text('Tagged'),
                  selected: statusFilterOption == 'tagged',
                  onSelected: (_) => _applyStatusFilter('tagged', ref, context),
                  backgroundColor:
                      isDarkMode
                          ? (statusFilterOption == 'tagged'
                              ? Colors.green.shade900
                              : const Color(0xFF333333))
                          : (statusFilterOption == 'tagged'
                              ? Colors.green.shade100
                              : Colors.green.shade50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color:
                          isDarkMode
                              ? Colors.green.shade800
                              : Colors.green.shade300,
                      width: 1.5,
                    ),
                  ),
                  labelStyle: TextStyle(
                    color:
                        isDarkMode
                            ? (statusFilterOption == 'tagged'
                                ? Colors.green.shade100
                                : Colors.green.shade200)
                            : Colors.green.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                  avatar: Icon(
                    Icons.label,
                    size: 16,
                    color:
                        isDarkMode
                            ? Colors.green.shade200
                            : Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 8),

                // All status filter
                FilterChip(
                  label: const Text('All Status'),
                  selected: statusFilterOption == 'all',
                  onSelected: (_) => _applyStatusFilter('all', ref, context),
                  backgroundColor:
                      isDarkMode ? const Color(0xFF333333) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color:
                          isDarkMode
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                    ),
                  ),
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.grey.shade300 : null,
                  ),
                ),
              ],
            ),
          ),

          // Divider between filter groups
          Divider(
            height: 1,
            thickness: 1,
            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
          ),

          // Time-based filter group
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 2.0),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color:
                      isDarkMode ? Colors.grey.shade400 : Colors.grey.shade800,
                ),
                const SizedBox(width: 4),
                Text(
                  'Time Range:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color:
                        isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                if (timeFilterOption != 'all')
                  TextButton.icon(
                    onPressed: () => _applyTimeFilter('all', ref, context),
                    icon: const Icon(Icons.close, size: 14),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      minimumSize: const Size(0, 24),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: isDarkMode ? Colors.grey.shade300 : null,
                    ),
                  ),
              ],
            ),
          ),

          // Time-based filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
              child: Row(
                children: [
                  _buildTimeFilterChip(
                    'Today',
                    'today',
                    timeFilterOption,
                    isDarkMode,
                    ref,
                    context,
                  ),
                  const SizedBox(width: 8),
                  _buildTimeFilterChip(
                    'Created Today',
                    'created_today',
                    timeFilterOption,
                    isDarkMode,
                    ref,
                    context,
                  ),
                  const SizedBox(width: 8),
                  _buildTimeFilterChip(
                    'Updated Today',
                    'updated_today',
                    timeFilterOption,
                    isDarkMode,
                    ref,
                    context,
                  ),
                  const SizedBox(width: 8),
                  _buildTimeFilterChip(
                    'This Week',
                    'this_week',
                    timeFilterOption,
                    isDarkMode,
                    ref,
                    context,
                  ),
                  const SizedBox(width: 8),
                  _buildTimeFilterChip(
                    'Important',
                    'important',
                    timeFilterOption,
                    isDarkMode,
                    ref,
                    context,
                  ),
                  const SizedBox(width: 8),
                  _buildTimeFilterChip(
                    'All Time',
                    'all',
                    timeFilterOption,
                    isDarkMode,
                    ref,
                    context,
                  ),
                ],
              ),
            ),
          ),

          // Show hidden memos section (only if needed)
          if (hiddenMemoIds.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
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
                      isDarkMode ? Colors.blue.shade900 : Colors.blue.shade200,
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
        ],
      ),
    );
  }

  // Helper method to build time filter chips with consistent styling
  Widget _buildTimeFilterChip(
    String label,
    String value,
    String timeFilterOption,
    bool isDarkMode,
    WidgetRef ref,
    BuildContext context,
  ) {
    final isSelected = timeFilterOption == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _applyTimeFilter(value, ref, context),
      backgroundColor:
          isDarkMode
              ? (isSelected ? const Color(0xFF4A4A4A) : const Color(0xFF333333))
              : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color:
              isDarkMode
                  ? (isSelected
                      ? const Color(0xFF757575)
                      : Colors.grey.shade700)
                  : Colors.grey.shade300,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      labelStyle: TextStyle(
        color:
            isDarkMode
                ? (isSelected ? Colors.white : Colors.grey.shade300)
                : isSelected
                ? Theme.of(context).colorScheme.primary
                : null,
        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
      ),
    );
  }
}
