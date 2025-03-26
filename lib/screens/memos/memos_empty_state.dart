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

    return Column(
      children: [
        // Indicator for active filters with no results
        if (timeFilterOption != 'all' || statusFilterOption != 'all')
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.filter_alt,
                      color: Colors.amber.shade800,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No memos found with the current filters',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
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
                          style: TextStyle(color: Colors.amber.shade900),
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
                          style: TextStyle(color: Colors.amber.shade900),
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
                  ),
                ),
              ],
            ),
          ),

        // Use Flexible instead of Expanded for better adaptability in this context
        const Flexible(
          child: Center(
            child: Text(
              'No memos found.',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
