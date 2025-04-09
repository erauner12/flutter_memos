import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'package:flutter/material.dart'; // Import Material for ScaffoldMessenger
import 'package:flutter/services.dart'; // Import for HapticFeedback
import 'package:flutter_memos/providers/memo_providers.dart' as memo_providers;
import 'package:flutter_memos/providers/ui_providers.dart';
import 'package:flutter_memos/utils/keyboard_navigation.dart';
import 'package:flutter_memos/widgets/capture_utility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'memo_comments.dart';
import 'memo_content.dart';
import 'memo_detail_providers.dart';

// Provider to track loading state specifically for the "Fix Grammar" action
final _isFixingGrammarProvider = StateProvider<bool>((ref) => false);

class MemoDetailScreen extends ConsumerStatefulWidget {
  final String memoId;

  const MemoDetailScreen({super.key, required this.memoId});

  @override
  ConsumerState<MemoDetailScreen> createState() => _MemoDetailScreenState();
}

class _MemoDetailScreenState extends ConsumerState<MemoDetailScreen>
    with KeyboardNavigationMixin<MemoDetailScreen> {
  final FocusNode _screenFocusNode = FocusNode(
    debugLabel: 'MemoDetailScreenFocus',
  );
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check mounted before accessing ref or focus node
      if (mounted) {
        _screenFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _screenFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    if (kDebugMode) print('[MemoDetailScreen] Pull-to-refresh triggered.');
    HapticFeedback.mediumImpact();
    // Invalidate providers to refetch data
    // Check mounted before accessing ref
    if (!mounted) return;
    ref.invalidate(memoDetailProvider(widget.memoId));
    ref.invalidate(memoCommentsProvider(widget.memoId));
    // No need to manually await, FutureProvider handles the loading state
  }

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
        clipBehavior: Clip.none,
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

  // --- Action Sheet Logic ---
  void _showActions() {
    // Check mounted before accessing ref or context
    if (!mounted) return;
    // Read loading state for Fix Grammar
    final isFixingGrammar = ref.read(_isFixingGrammarProvider);

    showCupertinoModalPopup<void>(
      context: context, // Use the current context safely here
      builder:
          (BuildContext popupContext) => CupertinoActionSheet(
            // Use popupContext inside builder
            title: const Text('Memo Actions'),
            actions: <CupertinoActionSheetAction>[
              CupertinoActionSheetAction(
                child: const Text('Edit Memo'),
                onPressed: () {
                  Navigator.pop(
                    popupContext,
                  ); // Close the action sheet using popupContext
                  // Use rootNavigator: true for potentially pushing over the sheet
                  Navigator.of(context, rootNavigator: true)
                      .pushNamed(
                        '/edit-entity',
                        arguments: {
                          'entityType': 'memo',
                          'entityId': widget.memoId,
                        },
                      )
                      .then((_) {
                        // Check mounted before interacting with ref after await gap
                        if (!mounted) return;
                        // Refresh detail data after editing
                        ref.invalidate(memoDetailProvider(widget.memoId));
                        ref.invalidate(memoCommentsProvider(widget.memoId));
                        // Ensure memo is not hidden after edit
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
              CupertinoActionSheetAction(
                // Disable button while processing
                isDefaultAction:
                    !isFixingGrammar, // Make it default if not loading
                onPressed:
                    isFixingGrammar
                        ? () {} // Empty callback when disabled
                        : () {
                          // This lambda matches VoidCallback
                          Navigator.pop(popupContext); // Close the action sheet
                          _fixGrammar(); // Call the async function, don't await here
                        },
                child:
                    isFixingGrammar
                        ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CupertinoActivityIndicator(radius: 10),
                            SizedBox(width: 10),
                            Text('Fixing Grammar...'),
                          ],
                        )
                        : const Text('Fix Grammar (AI)'),
              ),
              // Example: Delete Action
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                child: const Text('Delete Memo'),
                onPressed: () async {
                  // Capture context before first await
                  final sheetContext = popupContext; // Use popupContext
                  Navigator.pop(sheetContext); // Close action sheet

                  // Capture context for dialog
                  final dialogContext =
                      context; // Use original context for dialog
                  final confirmed = await showCupertinoDialog<bool>(
                    context: dialogContext, // Use captured context for dialog
                    builder:
                        (context) => CupertinoAlertDialog(
                          title: const Text('Delete Memo?'),
                          content: const Text(
                            'Are you sure you want to permanently delete this memo and its comments?',
                          ),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.of(context).pop(false),
                            ),
                            CupertinoDialogAction(
                              isDestructiveAction: true,
                              child: const Text('Delete'),
                              onPressed: () => Navigator.of(context).pop(true),
                            ),
                          ],
                        ),
                  );

                  // Check mounted after await before using context or ref
                  if (confirmed == true) {
                    if (!mounted) return; // Check mounted before try block
                    try {
                      // Call delete provider
                      await ref.read(
                        memo_providers.deleteMemoProvider(widget.memoId),
                      )();
                      // Pop back to previous screen after successful deletion
                      // Check mounted *again* before this context use
                      if (!mounted) return;
                      Navigator.of(
                        context,
                      ).pop(); // Pop the detail screen itself
                    } catch (e) {
                      // Show error if deletion fails
                      // Check mounted *again* before this context use
                      if (!mounted) return;
                      _showErrorSnackbar('Failed to delete memo: $e');
                    }
                  }
                },
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(popupContext); // Use popupContext
              },
            ),
      ),
    );
  }

  // --- Fix Grammar Handler ---
  Future<void> _fixGrammar() async {
    // Check mounted before interacting with ref
    if (!mounted) return;
    // Set loading state
    ref.read(_isFixingGrammarProvider.notifier).state = true;
    HapticFeedback.mediumImpact();

    try {
      // Call the provider
      // Check mounted before interacting with ref
      if (!mounted) return;
      await ref.read(
        memo_providers.fixMemoGrammarProvider(widget.memoId).future,
      );
      // Show success message (optional)
      if (mounted) _showSuccessSnackbar('Grammar corrected successfully!');

    } catch (e) {
      // Show error message
      if (mounted) _showErrorSnackbar('Failed to fix grammar: $e');
      if (kDebugMode) print('[MemoDetailScreen] Fix Grammar Error: $e');
    } finally {
      // Reset loading state only if the widget is still mounted
      if (mounted) {
        ref.read(_isFixingGrammarProvider.notifier).state = false;
      }
    }
  }

  // --- Snackbar Helpers (using Material ScaffoldMessenger) ---
  void _showErrorSnackbar(String message) {
    // Check mounted before accessing context
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    // Check mounted before accessing context
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
  // --- End Snackbar Helpers ---

  // --- Keyboard Navigation Helpers ---
  void _selectNextComment() {
    // Check mounted before accessing ref
    if (!mounted) return;
    final commentsAsync = ref.read(memoCommentsProvider(widget.memoId));
    commentsAsync.whenData((comments) {
      if (comments.isEmpty) return;
      // Check mounted before accessing ref inside callback
      if (!mounted) return;
      final currentIndex = ref.read(selectedCommentIndexProvider);
      final nextIndex = getNextIndex(currentIndex, comments.length);
      if (nextIndex != currentIndex) {
        // Check mounted before accessing ref notifier
        if (!mounted) return;
        ref.read(selectedCommentIndexProvider.notifier).state = nextIndex;
      }
    });
  }

  void _selectPreviousComment() {
    // Check mounted before accessing ref
    if (!mounted) return;
    final commentsAsync = ref.read(memoCommentsProvider(widget.memoId));
    commentsAsync.whenData((comments) {
      if (comments.isEmpty) return;
      // Check mounted before accessing ref inside callback
      if (!mounted) return;
      final currentIndex = ref.read(selectedCommentIndexProvider);
      final prevIndex = getPreviousIndex(currentIndex, comments.length);
      if (prevIndex != currentIndex) {
        // Check mounted before accessing ref notifier
        if (!mounted) return;
        ref.read(selectedCommentIndexProvider.notifier).state = prevIndex;
      }
    });
  }
  // --- End Keyboard Navigation Helpers ---

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _screenFocusNode,
      autofocus: true,
      canRequestFocus: true,
      skipTraversal: false,
      includeSemantics: true,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        // Check mounted before accessing ref
        if (!mounted) return KeyEventResult.ignored;
        return handleKeyEvent(
          event,
          ref,
          onUp: _selectPreviousComment,
          onDown: _selectNextComment,
          onBack: () => Navigator.of(context).pop(),
          onEscape: () {
            FocusManager.instance.primaryFocus?.unfocus();
            _screenFocusNode.requestFocus();
          },
        );
      },
      child: GestureDetector(
        onTap: () => _screenFocusNode.requestFocus(),
        behavior: HitTestBehavior.translucent,
        child: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: const Text('Memo Detail'),
            transitionBetweenRoutes: false,
            // Use a button that opens the action sheet
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showActions, // Call the action sheet method
              child: const Icon(CupertinoIcons.ellipsis_vertical),
            ),
          ),
          child: Column(
            children: [
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
  // --- End Build Method ---

  // --- Build Body Helper ---
  Widget _buildBody() {
    // Check mounted before accessing ref
    if (!mounted) return const Center(child: CupertinoActivityIndicator());
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
                  // Check mounted before accessing context
                  color:
                      mounted
                          ? CupertinoColors.separator.resolveFrom(context)
                          : CupertinoColors.separator,
                  margin: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
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
              'Error loading memo: $error',
              // Check mounted before accessing context
              style: TextStyle(
                color:
                    mounted
                        ? CupertinoColors.systemRed.resolveFrom(context)
                        : CupertinoColors.systemRed,
              ),
            ),
          ),
    );
  }
  // --- End Build Body Helper ---
}
