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
          // Advanced filter button
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Advanced Filters',
            onPressed: () => _showAdvancedFilterPanel(context),
          ),
          
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
        // Add search bar in the app bar bottom
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0),
            child: _buildSearchBar(),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter chips can go here (if needed in the future)
          
          // Main list of memos
          Expanded(child: _buildMemosList(memosState, visibleMemos)),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Advanced filter button
          FloatingActionButton.small(
            heroTag: 'advancedFilterFAB',
            onPressed: () => _showAdvancedFilterPanel(context),
            tooltip: 'Advanced Filters',
            child: const Icon(Icons.filter_alt),
          ),
          const SizedBox(height: 16),
          // Add new memo button
          FloatingActionButton(
            heroTag: 'newMemoFAB',
            onPressed: () {
              Navigator.pushNamed(context, '/new-memo').then((_) {
                ref.read(memosNotifierProvider.notifier).refresh();
              });
            },
            tooltip: 'New Memo',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  void _showAdvancedFilterPanel(BuildContext context) {
    // Show the advanced filter panel as a modal bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Takes up full screen height
      backgroundColor: Colors.transparent, // Transparent background
      builder: (context) {
        // Determine initial sheet size based on screen dimensions
        final screenWidth = MediaQuery.of(context).size.width;
        final initialChildSize = screenWidth > 600 ? 0.7 : 0.8; // More space on larger screens
        
        return DraggableScrollableSheet(
          initialChildSize: initialChildSize,
          minChildSize: 0.5, // At least half the screen
          maxChildSize: 0.95, // Almost full screen
          builder: (_, scrollController) {
            return _buildAdvancedFilterPanel(scrollController);
          },
        );
      },
    );
  }

  // Define the AdvancedFilterPanel
  Widget _buildAdvancedFilterPanel(ScrollController scrollController) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text(
                  'Advanced Filters',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Filter content - to be implemented
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16.0),
              children: const [
                Text('Filter options will be implemented here'),
                // TODO: Implement actual filter options
              ],
            ),
          ),
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

  // Build the search bar widget
  Widget _buildSearchBar() {
    final searchQuery = ref.watch(searchQueryProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      decoration: InputDecoration(
        hintText: 'Search memos...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon:
            searchQuery.isNotEmpty
                ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    ref.read(searchQueryProvider.notifier).state = '';
                  },
                )
                : null,
        filled: true,
        fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (value) {
        // Update the search query provider as user types
        ref.read(searchQueryProvider.notifier).state = value;

        // If value is non-empty and we have local search disabled, we might want
        // to trigger a server search after debouncing
        final isLocalSearch = ref.read(localSearchEnabledProvider);
        if (!isLocalSearch && value.isNotEmpty) {
          // In a real app, you'd add debouncing logic here
          // For now, we'll refresh immediately when local search is disabled
          ref.read(memosNotifierProvider.notifier).refresh();
        }
      },
    );
  }

  Widget _buildMemosList(MemosState memosState, List<Memo> visibleMemos) {
    // Use filteredMemos instead of visibleMemos directly
    final filteredMemos = ref.watch(filteredMemosProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    
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

    // Show empty state for search with no results
    if (filteredMemos.isEmpty && searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No results found for "$searchQuery"',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                ref.read(searchQueryProvider.notifier).state = '';
              },
              child: const Text('Clear Search'),
            ),
          ],
        ),
      );
    }

    // Show general empty state message if no memos and not loading
    if (visibleMemos.isEmpty && !memosState.isLoading && searchQuery.isEmpty) {
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
        itemCount: filteredMemos.length + (memosState.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Show loading indicator as the last item when loading more
          if (index == filteredMemos.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          
          // Regular memo list item - now using filtered memos
          final memo = filteredMemos[index];
          return MemoListItem(memo: memo, index: index);
        },
      ),
    );
  }
}
