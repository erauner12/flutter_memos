import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:flutter_memos/providers/filter_providers.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_memos/utils/memo_utils.dart';
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MemosScreen extends ConsumerStatefulWidget {
  const MemosScreen({super.key});

  @override
  ConsumerState<MemosScreen> createState() => _MemosScreenState();
}

class _MemosScreenState extends ConsumerState<MemosScreen> {
  // Keep track only of the UI state that's truly local to this widget
  // Other state is managed by Riverpod providers

  @override
  void initState() {
    super.initState();
    // Load saved filter preferences
    ref.read(loadFilterPreferencesProvider);
  }

  void _toggleHideMemo(String memoId) {
    final hiddenMemoIds = ref.read(hiddenMemoIdsProvider);
    if (hiddenMemoIds.contains(memoId)) {
      ref
          .read(hiddenMemoIdsProvider.notifier)
          .update((state) => state..remove(memoId));
    } else {
      ref
          .read(hiddenMemoIdsProvider.notifier)
          .update((state) => state..add(memoId));
    }
  }

  void _showAllMemos() {
    ref.read(hiddenMemoIdsProvider.notifier).state = {};
  }

  void _applyTimeFilter(String filterOption) {
    // Update provider state instead of local state
    ref.read(timeFilterProvider.notifier).state = filterOption;
    
    // Clear any hidden memo IDs when changing filters
    ref.read(hiddenMemoIdsProvider.notifier).state = {};

    // Save filter preferences
    final statusFilter = ref.read(statusFilterProvider);
    ref.read(filterPreferencesProvider)(filterOption, statusFilter);
  }

  void _applyStatusFilter(String filterOption) {
    // Update provider state instead of local state
    ref.read(statusFilterProvider.notifier).state = filterOption;
    
    // Clear any hidden memo IDs when changing filters
    ref.read(hiddenMemoIdsProvider.notifier).state = {};
    
    // Save filter preferences
    final timeFilter = ref.read(timeFilterProvider);
    ref.read(filterPreferencesProvider)(timeFilter, filterOption);
  }

  void _navigateToMemoDetail(String id) {
    Navigator.pushNamed(
      context,
      '/memo-detail',
      arguments: {'memoId': id},
    ).then((_) {
      // Refresh memos after returning from detail screen
      ref.invalidate(memosProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memos'),
        actions: [
          // Sort toggle button with more descriptive text
          Consumer(
            builder: (context, ref, child) {
              final sortMode = ref.watch(memoSortModeProvider);
              return TextButton.icon(
                icon: Icon(
                  sortMode == MemoSortMode.byUpdateTime
                      ? Icons.update
                      : Icons.calendar_today,
                  size: 20,
                ),
                label: Text(
                  sortMode == MemoSortMode.byUpdateTime
                      ? 'Sort by: Updated'
                      : 'Sort by: Created',
                  style: const TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  backgroundColor: Colors.grey[100],
                ),
                onPressed: _toggleSortMode,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(child: _buildBody()),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/new-memo').then((_) {
            // Refresh memos after returning from creating a new memo
            ref.invalidate(memosProvider);
          });
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _toggleSortMode() {
    final sortMode = ref.read(memoSortModeProvider);
    ref.read(memoSortModeProvider.notifier).state =
        sortMode == MemoSortMode.byUpdateTime
            ? MemoSortMode.byCreateTime
            : MemoSortMode.byUpdateTime;
    
    // Show a snackbar to indicate the sort mode changed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sorting by ${ref.read(memoSortModeProvider) == MemoSortMode.byUpdateTime ? 'update time' : 'creation time'} (newest first)',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildFilterChips() {
    final timeFilterOption = ref.watch(timeFilterProvider);
    final statusFilterOption = ref.watch(statusFilterProvider);
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
                    onPressed: () => _applyStatusFilter('all'),
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
                  onSelected: (_) => _applyStatusFilter('untagged'),
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
                  onSelected: (_) => _applyStatusFilter('tagged'),
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
                  onSelected: (_) => _applyStatusFilter('all'),
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
                    onPressed: () => _applyTimeFilter('all'),
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
                  _buildTimeFilterChip('Today', 'today'),
                  const SizedBox(width: 8),
                  _buildTimeFilterChip('Created Today', 'created_today'),
                  const SizedBox(width: 8),
                  _buildTimeFilterChip('Updated Today', 'updated_today'),
                  const SizedBox(width: 8),
                  _buildTimeFilterChip('This Week', 'this_week'),
                  const SizedBox(width: 8),
                  _buildTimeFilterChip('Important', 'important'),
                  const SizedBox(width: 8),
                  _buildTimeFilterChip('All Time', 'all'),
                ],
              ),
            ),
          ),

          // Show hidden memos section (only if needed)
          Consumer(
            builder: (context, ref, child) {
              final hiddenMemoIds = ref.watch(hiddenMemoIdsProvider);
              if (hiddenMemoIds.isEmpty) {
                return const SizedBox.shrink();
              }

              return Container(
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
                      onPressed: _showAllMemos,
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
              );
            },
          ),
        ],
      ),
    );
  }

// Helper method to build time filter chips with consistent styling
  Widget _buildTimeFilterChip(String label, String value) {
    final timeFilterOption = ref.watch(timeFilterProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSelected = timeFilterOption == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _applyTimeFilter(value),
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

  Widget _buildBody() {
    // Watch the providers for data changes
    final memosAsync = ref.watch(visibleMemosProvider);
    final sortMode = ref.watch(memoSortModeProvider);
    
    return Column(
      children: [
        // Filter chips for predefined filters - always shown first
        _buildFilterChips(),

        // Expanded to let memo list take up all available space
        Expanded(
          child: memosAsync.when(
            data: (memos) {
              if (memos.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  // Invalidate the memosProvider to force refresh
                  ref.invalidate(memosProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: memos.length,
                  itemBuilder: (context, index) {
                    final memo = memos[index];
                    return Dismissible(
                      key: Key(memo.id),
                      background: Container(
                        color: Colors.orange,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 16.0),
                        child: const Row(
                          children: [
                            SizedBox(width: 16),
                            Icon(Icons.visibility_off, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Hide',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      secondaryBackground: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onDismissed: (direction) {
                        if (direction == DismissDirection.endToStart) {
                          ref.read(deleteMemoProvider(memo.id))();
                        }
                      },
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          // Hide memo
                          _toggleHideMemo(memo.id);
                          return false; // Don't remove from list
                        } else if (direction == DismissDirection.endToStart) {
                          // Delete memo
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Confirm Delete'),
                                content: const Text(
                                  'Are you sure you want to delete this memo?',
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                        return false;
                      },
                      child: Stack(
                        children: [
                          MemoCard(
                            content: memo.content,
                            pinned: memo.pinned,
                            createdAt: memo.createTime,
                            updatedAt: memo.updateTime,
                            showTimeStamps: true,
                            // Display relevant timestamp based on sort mode
                            highlightTimestamp:
                                sortMode == MemoSortMode.byUpdateTime
                                    ? MemoUtils.formatTimestamp(memo.updateTime)
                                    : MemoUtils.formatTimestamp(
                                      memo.createTime,
                                    ),
                            timestampType:
                                sortMode == MemoSortMode.byUpdateTime
                                    ? 'Updated'
                                    : 'Created',
                            onTap: () => _navigateToMemoDetail(memo.id),
                          ),
                          // Archive button positioned at top-right corner
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              icon: const Icon(
                                Icons.archive_outlined,
                                size: 20,
                              ),
                              tooltip: 'Archive',
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                              color: Colors.grey[600],
                              onPressed: () {
                                // Use the archive memo provider
                                ref.read(archiveMemoProvider(memo.id))().then((
                                  _,
                                ) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Memo archived successfully',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
            loading: () {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              );
            },
            error: (error, stackTrace) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Error loading memos: ${error.toString().substring(0, Math.min(error.toString().length, 100))}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
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
                          onPressed: () => _applyStatusFilter('all'),
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
                          onPressed: () => _applyTimeFilter('all'),
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
                      _applyStatusFilter('all');
                      _applyTimeFilter('all');
                    },
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Clear All Filters'),
                  ),
                ),
              ],
            ),
          ),

        const Expanded(
          child: Center(
            child: Text(
              'No memos found.',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
