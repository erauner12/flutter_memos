import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
// Remove Material RefreshIndicator import and only keep what's needed
import 'package:flutter/services.dart'; // Add for haptic feedback
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_memos/providers/ui_providers.dart'
    as ui_providers; // Add import
import 'package:flutter_memos/screens/memos/memo_list_item.dart';
import 'package:flutter_memos/screens/memos/memos_empty_state.dart'; // Import MemosEmptyState
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Assuming MemosBody is a ConsumerWidget or ConsumerStatefulWidget
class MemosBody extends ConsumerStatefulWidget {
  // Add the callback as an optional named parameter
  final void Function(String memoId)? onMoveMemoToServer;
  // Add the scrollController property
  final ScrollController scrollController;

  const MemosBody({
    super.key,
    required this.scrollController, // Make it required
    this.onMoveMemoToServer, // Add to constructor
  });

  @override
  ConsumerState<MemosBody> createState() => _MemosBodyState();
}

class _MemosBodyState extends ConsumerState<MemosBody> {
  // REMOVE: final ScrollController _scrollController = ScrollController();
  // Remove RefreshIndicator key as it's no longer needed

  @override
  void initState() {
    super.initState();
    // Use the controller from the widget
    widget.scrollController.addListener(_onScroll);
    // Ensure the first memo is selected after initial load/refresh
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _ensureInitialSelection(),
    );
  }

  // Helper to select the first memo if none is selected
  void _ensureInitialSelection() {
    // Only run if mounted
    if (!mounted) return;

    final memos = ref.read(filteredNotesProvider); // Use renamed provider
    final selectedId = ref.read(ui_providers.selectedMemoIdProvider);

    // Select the first memo only if the list is not empty AND nothing is currently selected
    if (memos.isNotEmpty && selectedId == null) {
      final firstMemoId = memos.first.id;
      ref.read(ui_providers.selectedMemoIdProvider.notifier).state =
          firstMemoId;
      if (kDebugMode) {
        print(
          '[MemosBody] Selected first note (ID=$firstMemoId) after initial load/refresh.', // Updated log
        );
      }
    }
  }

  @override
  void dispose() {
    // Remove listener from the widget's controller
    widget.scrollController.removeListener(_onScroll);
    // DO NOT dispose the controller here: _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Use widget's controller
    if (widget.scrollController.position.pixels >=
        widget.scrollController.position.maxScrollExtent - 200) {
      // Trigger load more slightly before reaching the end
      final notifier = ref.read(notesNotifierProvider.notifier);
      // Check if we can load more before calling
      if (ref.read(notesNotifierProvider).canLoadMore) {
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

    await ref
        .read(notesNotifierProvider.notifier)
        .refresh(); // Use renamed provider

    // Add success haptic feedback when refresh completes
    HapticFeedback.mediumImpact();

    // Ensure selection after refresh
    _ensureInitialSelection();
  }

  // Add this method to the _MemosBodyState class
  Widget _buildRefreshIndicator(
    BuildContext context,
    RefreshIndicatorMode refreshState,
    double pulledExtent,
    double refreshTriggerPullDistance,
    double refreshIndicatorExtent,
  ) {
    // Calculate the opacity based on pull distance
    final double opacity = pulledExtent / refreshTriggerPullDistance;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (refreshState == RefreshIndicatorMode.refresh ||
              refreshState == RefreshIndicatorMode.armed)
            const CupertinoActivityIndicator(radius: 14.0)
          else if (refreshState == RefreshIndicatorMode.drag)
            Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: const CupertinoActivityIndicator(radius: 14.0),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesState = ref.watch(notesNotifierProvider); // Use renamed provider
    final visibleNotes = ref.watch(
      filteredNotesProvider, // Use renamed provider
    ); // Use filtered notes for display
    final hasSearchResults = ref.watch(hasSearchResultsProvider);

    // Loading State
    if (notesState.isLoading && notesState.notes.isEmpty) {
      // Use notesState.notes
      return const Center(child: CupertinoActivityIndicator());
    }

    // Error State
    if (notesState.error != null && notesState.notes.isEmpty) {
      // Use notesState.notes
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
            Text(
              'Error: ${notesState.error}',
              textAlign: TextAlign.center,
            ), // Use notesState.error
            const SizedBox(height: 10),
            CupertinoButton(onPressed: _onRefresh, child: const Text('Retry')),
          ],
        ),
      );
    }

    // Empty State (or No Search Results)
    if (visibleNotes.isEmpty) {
      // Use visibleNotes
      // Delegate to MemosEmptyState widget
      return MemosEmptyState(onRefresh: _onRefresh);
    }

    // In the build method, wrap the ScrollConfiguration with CupertinoScrollbar
    // Data State (List View)
    return CupertinoScrollbar(
      // Use widget's controller
      controller: widget.scrollController,
      thumbVisibility: true,
      thickness: 6.0,
      radius: const Radius.circular(3.0),
      child: ScrollConfiguration(
        behavior: const CupertinoScrollBehavior(),
        child: CustomScrollView(
          // Use widget's controller
          controller: widget.scrollController,
          slivers: [
            // Existing slivers...
            CupertinoSliverRefreshControl(
              onRefresh: _onRefresh,
              refreshIndicatorExtent: 60.0,
              refreshTriggerPullDistance: 100.0,
              builder: _buildRefreshIndicator,
            ),
            // Rest of your slivers...

            // Padding for the list
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  // Memo List Item
                  final note = visibleNotes[index]; // Use visibleNotes and note
                  if (kDebugMode) {
                    // Log only when the specific callback is actually being passed
                    if (widget.onMoveMemoToServer != null) {
                      print(
                        '[MemosBody] Building MemoListItem for ${note.id}, passing onMoveToServer callback.', // Updated log
                      );
                    }
                  }
                  return MemoListItem(
                    // Keep MemoListItem name for now
                    key: ValueKey(
                      note.id, // Use note.id
                    ), // Use ValueKey for better list updates
                    memo: note, // Pass NoteItem as memo prop
                    index: index,
                    // Pass the callback received by MemosBody down to MemoListItem
                    // Use a lambda to capture the specific note.id for the callback
                    onMoveToServer:
                        widget.onMoveMemoToServer != null
                            ? () => widget.onMoveMemoToServer!(
                              note.id,
                            ) // Use note.id
                            : null,
                  );
                }, childCount: visibleNotes.length), // Use visibleNotes.length
              ),
            ),

            // Loading More Indicator
            if (notesState.isLoadingMore) // Use notesState.isLoadingMore
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(child: CupertinoActivityIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
