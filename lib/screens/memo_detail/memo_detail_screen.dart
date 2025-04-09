import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'package:flutter/services.dart'; // Import for HapticFeedback
import 'package:flutter_memos/providers/memo_providers.dart' as memo_providers;
import 'package:flutter_memos/providers/ui_providers.dart';
import 'package:flutter_memos/utils/keyboard_navigation.dart';
import 'package:flutter_memos/widgets/capture_utility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'memo_comments.dart';
import 'memo_content.dart';
import 'memo_detail_providers.dart';

class MemoDetailScreen extends ConsumerStatefulWidget {
  final String memoId;

  const MemoDetailScreen({super.key, required this.memoId});

  @override
  ConsumerState<MemoDetailScreen> createState() => _MemoDetailScreenState();
}

class _MemoDetailScreenState extends ConsumerState<MemoDetailScreen>
    with KeyboardNavigationMixin<MemoDetailScreen> {
  // Create a focus node to manage focus for the entire screen
  final FocusNode _screenFocusNode = FocusNode(
    debugLabel: 'MemoDetailScreenFocus',
  );
  // Add ScrollController
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    // Initialize ScrollController
    _scrollController = ScrollController();
    // Request focus after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _screenFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _screenFocusNode.dispose();
    _scrollController.dispose(); // Dispose ScrollController
    super.dispose();
  }

  // --- Add Refresh Logic ---
  Future<void> _onRefresh() async {
    if (kDebugMode) {
      print('[MemoDetailScreen] Pull-to-refresh triggered.');
    }
    HapticFeedback.mediumImpact();
    // Invalidate the providers to trigger a refetch
    ref.invalidate(memoDetailProvider(widget.memoId));
    ref.invalidate(memoCommentsProvider(widget.memoId));
    // No need to manually await, FutureProvider handles the loading state
  }

  // --- Add Refresh Indicator Builder ---
  // (This builder provides a standard Cupertino activity indicator during refresh)
  Widget _buildRefreshIndicator(
    BuildContext context,
    RefreshIndicatorMode refreshState,
    double pulledExtent,
    double refreshTriggerPullDistance,
    double refreshIndicatorExtent,
  ) {
    final double opacity = (pulledExtent / refreshTriggerPullDistance).clamp(
      0.0,
      1.0,
    );
    return Center(
      child: Stack(
        clipBehavior:
            Clip.none, // Allow indicator to show outside bounds slightly
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            top: 16.0, // Adjust position as needed
            child: Opacity(
              opacity:
                  (refreshState == RefreshIndicatorMode.drag) ? opacity : 1.0,
              child:
                  (refreshState == RefreshIndicatorMode.refresh ||
                          refreshState == RefreshIndicatorMode.armed)
                      ? const CupertinoActivityIndicator(radius: 14.0)
                      : const SizedBox.shrink(), // Show indicator only when refreshing or armed
            ),
          ),
        ],
      ),
    );
  }
  // --- End Refresh Logic ---

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _screenFocusNode,
      autofocus: true,
      canRequestFocus: true,
      skipTraversal: false,
      includeSemantics: true,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        // Use the shared keyboard navigation handler
        return handleKeyEvent(
          event,
          ref,
          onUp: () => _selectPreviousComment(),
          onDown: () => _selectNextComment(),
          onBack: () => Navigator.of(context).pop(),
          onEscape: () {
            // Clear any text input focus and return focus to screen
            FocusManager.instance.primaryFocus?.unfocus();
            _screenFocusNode.requestFocus();
          },
        );
      },
      child: GestureDetector(
        // Ensure tapping anywhere gives focus back to the screen
        onTap: () => _screenFocusNode.requestFocus(),
        behavior: HitTestBehavior.translucent,
        child: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: const Text('Memo Detail'),
            transitionBetweenRoutes: false, // Disable default hero animation
            trailing: CupertinoButton(
              // Replace IconButton with CupertinoButton
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.pencil), // Use Cupertino icon
              onPressed: () {
                Navigator.of(context, rootNavigator: true)
                    .pushNamed(
                  '/edit-entity', // Use the generic route
                  arguments: {
                    'entityType': 'memo',
                    'entityId': widget.memoId,
                  }, // Specify type and ID
                ).then((_) {
                  // Refresh only the detail data, not the entire memos list
                  ref.invalidate(memoDetailProvider(widget.memoId));
                  ref.invalidate(memoCommentsProvider(widget.memoId));

                  // Ensure memo is not hidden
                  ref
                      .read(memo_providers.hiddenMemoIdsProvider.notifier)
                      .update(
                        (state) =>
                            state.contains(widget.memoId)
                                ? (state..remove(widget.memoId))
                                : state,
                      );
                });
              },
            ),
          ),
          child: Column(
            // Column as the child of CupertinoPageScaffold
            children: [
              // Content area (expandable)
              Expanded(child: _buildBody()),
              // Fixed bottom area for CaptureUtility
              CaptureUtility(
                mode: CaptureMode.addComment,
                memoId: widget.memoId,
                hintText: 'Add a comment...',
                buttonText: 'Add Comment',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods for keyboard navigation
  void _selectNextComment() {
    // Get the current list of comments
    final commentsAsync = ref.read(memoCommentsProvider(widget.memoId));

    commentsAsync.whenData((comments) {
      if (comments.isEmpty) return;

      // Get the current selection
      final currentIndex = ref.read(selectedCommentIndexProvider);

      // Calculate next index using helper from mixin
      final nextIndex = getNextIndex(currentIndex, comments.length);

      // Only update if the index actually changed, to avoid unnecessary rebuilds
      if (nextIndex != currentIndex) {
        // Update the selection
        ref.read(selectedCommentIndexProvider.notifier).state = nextIndex;
      }
    });
  }

  void _selectPreviousComment() {
    // Get the current list of comments
    final commentsAsync = ref.read(memoCommentsProvider(widget.memoId));

    commentsAsync.whenData((comments) {
      if (comments.isEmpty) return;

      // Get the current selection
      final currentIndex = ref.read(selectedCommentIndexProvider);

      // Calculate previous index using helper from mixin
      final prevIndex = getPreviousIndex(currentIndex, comments.length);

      // Only update if the index actually changed, to avoid unnecessary rebuilds
      if (prevIndex != currentIndex) {
        // Update the selection
        ref.read(selectedCommentIndexProvider.notifier).state = prevIndex;
      }
    });
  }

  Widget _buildBody() {
    final memoAsync = ref.watch(memoDetailProvider(widget.memoId));

    return memoAsync.when(
      data: (memo) {
        // --- Use CustomScrollView with Refresh Control ---
        return CupertinoScrollbar(
          controller: _scrollController, // Pass controller
          thumbVisibility: true,
          thickness: 6.0,
          radius: const Radius.circular(3.0),
          child: CustomScrollView(
            controller: _scrollController, // Pass controller
            physics:
                const AlwaysScrollableScrollPhysics(), // Ensure scrolling is always possible for refresh
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: _onRefresh,
                builder: _buildRefreshIndicator,
              ),
              // Memo content section wrapped in SliverToBoxAdapter
              SliverToBoxAdapter(
                child: MemoContent(memo: memo, memoId: widget.memoId),
              ),
              // Divider wrapped in SliverToBoxAdapter
              SliverToBoxAdapter(
                child: Container(
                  height: 0.5,
                  color: CupertinoColors.separator.resolveFrom(context),
                  margin: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0, // Add horizontal margin for consistency
                  ),
                ),
              ),
              // Comments section wrapped in SliverToBoxAdapter
              SliverToBoxAdapter(child: MemoComments(memoId: widget.memoId)),
              // Add some bottom padding within the scroll view
              const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
            ],
          ),
        );
        // --- End CustomScrollView ---
      },
      // Replace CircularProgressIndicator with CupertinoActivityIndicator
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error:
          (error, _) => Center(
            child: Text(
              'Error: $error',
              // Use Cupertino color for error text
              style: TextStyle(
                color: CupertinoColors.systemRed.resolveFrom(context),
              ),
            ),
          ),
    );
  }
} // End of _MemoDetailScreenState class
