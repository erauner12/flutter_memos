import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_memos/providers/ui_providers.dart';
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

class _MemoDetailScreenState extends ConsumerState<MemoDetailScreen> {
  @override
  void initState() {
    super.initState();
    
    // Register a global key handler for keyboard events
    RawKeyboard.instance.addListener(_handleGlobalKeyEvent);
  }
  
  @override
  void dispose() {
    // Clean up the keyboard listener
    RawKeyboard.instance.removeListener(_handleGlobalKeyEvent);
    super.dispose();
  }
  
  // Global key event handler
  void _handleGlobalKeyEvent(RawKeyEvent event) {
    if (!mounted) return;
    
    // Only process key down events
    if (event is! RawKeyDownEvent) return;
    
    // Handle keyboard shortcuts
    if (event.logicalKey == LogicalKeyboardKey.keyJ ||
        (event.logicalKey == LogicalKeyboardKey.arrowDown &&
         event.isShiftPressed)) {
      _selectNextComment(ref);
    }
    else if (event.logicalKey == LogicalKeyboardKey.keyK ||
             (event.logicalKey == LogicalKeyboardKey.arrowUp &&
              event.isShiftPressed)) {
      _selectPreviousComment(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      canRequestFocus: true,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent) {
          // Handle Command+Left Arrow to go back
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
              HardwareKeyboard.instance.isMetaPressed) {
            Navigator.of(context).pop();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Memo Detail'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/edit-memo',
                  arguments: {'memoId': widget.memoId},
                ).then((_) {
                  // Refresh data when returning from edit screen
                  ref.invalidate(memoDetailProvider(widget.memoId));
                  ref.invalidate(memoCommentsProvider(widget.memoId));
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
    );
  }

  // Helper methods for keyboard navigation
  void _selectNextComment(WidgetRef ref) {
    // Get the current list of comments
    final commentsAsync = ref.read(memoCommentsProvider(widget.memoId));
    
    commentsAsync.whenData((comments) {
      if (comments.isEmpty) return;
      
      // Get the current selection and calculate next index
      final currentIndex = ref.read(selectedCommentIndexProvider);
      final nextIndex =
          currentIndex < 0 ? 0 : (currentIndex + 1) % comments.length;
      
      // Update the selection
      ref.read(selectedCommentIndexProvider.notifier).state = nextIndex;
      
      // Optional: Scroll to the selected comment
      // This would require keeping scroll controller references or using global keys
    });
  }

  void _selectPreviousComment(WidgetRef ref) {
    // Get the current list of comments
    final commentsAsync = ref.read(memoCommentsProvider(widget.memoId));
    
    commentsAsync.whenData((comments) {
      if (comments.isEmpty) return;
      
      // Get the current selection and calculate previous index with wraparound
      final currentIndex = ref.read(selectedCommentIndexProvider);
      final prevIndex =
          currentIndex < 0
              ? comments.length -
                  1 // If nothing selected, select the last item
              : (currentIndex - 1 + comments.length) % comments.length;
      
      // Update the selection
      ref.read(selectedCommentIndexProvider.notifier).state = prevIndex;
      
      // Optional: Scroll to the selected comment
      // This would require keeping scroll controller references or using global keys
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
