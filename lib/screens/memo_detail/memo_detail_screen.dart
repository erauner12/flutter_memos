import 'package:flutter/material.dart';
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

  const MemoDetailScreen({
    super.key,
    required this.memoId,
  });

  @override
  ConsumerState<MemoDetailScreen> createState() => _MemoDetailScreenState();
}

class _MemoDetailScreenState extends ConsumerState<MemoDetailScreen>
    with KeyboardNavigationMixin<MemoDetailScreen> {
  // Create a focus node to manage focus for the entire screen
  final FocusNode _screenFocusNode = FocusNode(
    debugLabel: 'MemoDetailScreenFocus',
  );

  @override
  void initState() {
    super.initState();
    // Request focus after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _screenFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _screenFocusNode.dispose();
    super.dispose();
  }

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
        child: Scaffold(
        appBar: AppBar(
          title: const Text('Memo Detail'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                    '/edit-entity', // Use the generic route
                    arguments: {
                      'entityType': 'memo',
                      'entityId': widget.memoId,
                    }, // Specify type and ID
                ).then((_) {
                    // Refresh all data when returning from edit screen
                    // Invalidate the providers to force refresh
                  ref.invalidate(memoDetailProvider(widget.memoId));
                  ref.invalidate(memoCommentsProvider(widget.memoId));
                  
                    // Refresh memos list
                    ref
                        .read(memo_providers.memosNotifierProvider.notifier)
                        .refresh();

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
          ],
        ),
        // Use a Column for vertical layout - this ensures proper bottom alignment
        body: Column(
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
        return SingleChildScrollView(
          child: Column(
            children: [
              // Memo content section
              MemoContent(memo: memo, memoId: widget.memoId),

              // Divider between content and comments
              const Divider(),

              // Comments section
              MemoComments(memoId: widget.memoId),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, _) => Center(
            child: Text(
              'Error: $error',
              style: const TextStyle(color: Colors.red),
            ),
      ),
    );
  }
}
