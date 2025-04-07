import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
// Remove Material RefreshIndicator import and only keep what's needed
import 'package:flutter/services.dart'; // Add for haptic feedback
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_memos/providers/ui_providers.dart'
    as ui_providers; // Add import
import 'package:flutter_memos/screens/memos/memo_list_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Assuming MemosBody is a ConsumerWidget or ConsumerStatefulWidget
class MemosBody extends ConsumerStatefulWidget {
  // Add the callback as an optional named parameter
  final void Function(String memoId)? onMoveMemoToServer;

  const MemosBody({
    super.key,
    this.onMoveMemoToServer, // Add to constructor
  });

  @override
  ConsumerState<MemosBody> createState() => _MemosBodyState();
}

class _MemosBodyState extends ConsumerState<MemosBody> {
  final ScrollController _scrollController = ScrollController();
  // Remove RefreshIndicator key as it's no longer needed

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Ensure the first memo is selected after initial load/refresh
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _ensureInitialSelection(),
    );
  }

  // Helper to select the first memo if none is selected
  void _ensureInitialSelection() {
    // Only run if mounted
    if (!mounted) return;

    final memos = ref.read(filteredMemosProvider);
    final selectedId = ref.read(ui_providers.selectedMemoIdProvider);

    // Select the first memo only if the list is not empty AND nothing is currently selected
    if (memos.isNotEmpty && selectedId == null) {
      final firstMemoId = memos.first.id;
      ref.read(ui_providers.selectedMemoIdProvider.notifier).state =
          firstMemoId;
      if (kDebugMode) {
        print(
          '[MemosBody] Selected first memo (ID=$firstMemoId) after initial load/refresh.',
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Trigger load more slightly before reaching the end
      final notifier = ref.read(memosNotifierProvider.notifier);
      // Check if we can load more before calling
      if (ref.read(memosNotifierProvider).canLoadMore) {
        if (kDebugMode) {
          print(
            '[MemosBody] Reached near bottom, attempting to fetch more memos.',
          );
        }
        notifier.fetchMoreMemos();
      } else {
        if (kDebugMode) {
          // Avoid spamming logs if already loading or at end
          // print('[MemosBody] Reached near bottom, but cannot load more.');
        }
      }
    }
  }

  Future<void> _onRefresh() async {
    if (kDebugMode) {
      print('[MemosBody] Pull-to-refresh triggered.');
    }

    // Add light haptic feedback when refresh begins
    HapticFeedback.lightImpact();

    await ref.read(memosNotifierProvider.notifier).refresh();

    // Add success haptic feedback when refresh completes
    HapticFeedback.mediumImpact();

    // Ensure selection after refresh
    _ensureInitialSelection();
  }

  @override
  Widget build(BuildContext context) {
    final memosState = ref.watch(memosNotifierProvider);
    final visibleMemos = ref.watch(
      filteredMemosProvider,
    ); // Use filtered memos for display
    final hasSearchResults = ref.watch(hasSearchResultsProvider);

    // Loading State
    if (memosState.isLoading && memosState.memos.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }

    // Error State
    if (memosState.error != null && memosState.memos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 40,
              color: CupertinoColors.systemRed,
            ),
            const SizedBox(height: 10),
            Text('Error: ${memosState.error}', textAlign: TextAlign.center),
            const SizedBox(height: 10),
            CupertinoButton(onPressed: _onRefresh, child: const Text('Retry')),
          ],
        ),
      );
    }

    // Empty State (or No Search Results)
    if (visibleMemos.isEmpty) {
      return Center(
        child: Text(
          hasSearchResults
              ? 'No memos found matching your filters.'
              : 'No memos found matching your search.',
          style: TextStyle(
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      );
    }

    // Data State (List View) - Now using CustomScrollView with slivers
    return ScrollConfiguration(
      behavior: const CupertinoScrollBehavior(), // Use Cupertino scroll physics
      child: CustomScrollView(
        controller: _scrollController, // Use the same scroll controller
        slivers: [
          // Pull-to-refresh using CupertinoSliverRefreshControl
          CupertinoSliverRefreshControl(onRefresh: _onRefresh),

          // Padding for the list
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                // Memo List Item
                final memo = visibleMemos[index];
                if (kDebugMode) {
                  // Log only when the specific callback is actually being passed
                  if (widget.onMoveMemoToServer != null) {
                    print(
                      '[MemosBody] Building MemoListItem for ${memo.id}, passing onMoveToServer callback.',
                    );
                  }
                }
                return MemoListItem(
                  key: ValueKey(
                    memo.id,
                  ), // Use ValueKey for better list updates
                  memo: memo,
                  index: index,
                  // Pass the callback received by MemosBody down to MemoListItem
                  // Use a lambda to capture the specific memo.id for the callback
                  onMoveToServer:
                      widget.onMoveMemoToServer != null
                          ? () => widget.onMoveMemoToServer!(memo.id)
                          : null,
                );
              }, childCount: visibleMemos.length),
            ),
          ),

          // Loading More Indicator
          if (memosState.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(child: CupertinoActivityIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
