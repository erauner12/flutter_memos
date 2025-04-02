import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/filter_providers.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_memos/screens/memos/memo_list_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MemosScreen extends ConsumerStatefulWidget {
  const MemosScreen({super.key});

  @override
  ConsumerState<MemosScreen> createState() => _MemosScreenState();
}

class _MemosScreenState extends ConsumerState<MemosScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  
  @override
  void initState() {
    super.initState();
    // Add scroll listener to detect when we're near the bottom
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // Check if we need to load more memos when scrolling
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    const loadMoreThreshold = 300.0; // Load more when within 300px of bottom

    // Check if we're close to the bottom and can load more
    if (maxScroll - currentScroll <= loadMoreThreshold) {
      final memosState = ref.read(memosNotifierProvider);

      if (memosState.canLoadMore) {
        if (kDebugMode) {
          print('[MemosScreen] Near bottom, loading more memos...');
        }
        ref.read(memosNotifierProvider.notifier).fetchMoreMemos();
      }
    }
  }

  // Pull to refresh handler
  Future<void> _onRefresh() async {
    if (kDebugMode) {
      print('[MemosScreen] Pull-to-refresh triggered');
    }
    return ref.read(memosNotifierProvider.notifier).refresh();
  }
  
  @override
  Widget build(BuildContext context) {
    // Watch the memos notifier state
    final memosState = ref.watch(memosNotifierProvider);

    // Watch visible memos list (filtered by hiddenMemoIds)
    final visibleMemos = ref.watch(visibleMemosListProvider);

    // Watch current filter
    final currentFilter = ref.watch(filterKeyProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Memos (${currentFilter.toUpperCase()})'),
        actions: [
          // Filter dropdown
          _buildFilterButton(),

          // Create new memo button
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Memo',
            onPressed: () {
              Navigator.pushNamed(context, '/new-memo').then((_) {
                // Refresh list when returning from create screen
                ref.read(memosNotifierProvider.notifier).refresh();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips can go here
          // _buildFilterChips(),

          // Main list of memos
          Expanded(child: _buildMemosList(memosState, visibleMemos)),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    final currentFilter = ref.watch(filterKeyProvider);

    return PopupMenuButton<String>(
      tooltip: 'Filter',
      // Removed icon property since we're using child property instead
      onSelected: (String filter) {
        ref.read(filterKeyProvider.notifier).state = filter;
      },
      itemBuilder:
          (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(value: 'all', child: Text('All Memos')),
            const PopupMenuItem<String>(value: 'inbox', child: Text('Inbox')),
            const PopupMenuItem<String>(
              value: 'archive',
              child: Text('Archive'),
            ),
            // Add more filter options as needed
          ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(
            label: Text(currentFilter),
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withOpacity(0.2),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }

  Widget _buildMemosList(MemosState memosState, List<Memo> visibleMemos) {
    // Show loading spinner for initial load
    if (memosState.isLoading && visibleMemos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error message if there's an error and no memos to display
    if (memosState.error != null && visibleMemos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error loading memos',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  () => ref.read(memosNotifierProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show empty state message if no memos and not loading
    if (visibleMemos.isEmpty && !memosState.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No memos found'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/new-memo'),
              child: const Text('Create New Memo'),
            ),
          ],
        ),
      );
    }
    
    // Show list with pull-to-refresh
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        // Add +1 item if we're loading more (for the loading indicator)
        itemCount: visibleMemos.length + (memosState.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Show loading indicator as the last item when loading more
          if (index == visibleMemos.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          
          // Regular memo list item
          final memo = visibleMemos[index];
          return MemoListItem(memo: memo, index: index);
        },
      ),
    );
  }
}
