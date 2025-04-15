import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Keep for ScaffoldMessenger
import 'package:flutter/services.dart';
// Import note_providers instead of memo_providers
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
// Import settings_provider for manuallyHiddenNoteIdsProvider
import 'package:flutter_memos/providers/settings_provider.dart' as settings_p;
import 'package:flutter_memos/providers/ui_providers.dart';
import 'package:flutter_memos/utils/keyboard_navigation.dart';
import 'package:flutter_memos/widgets/capture_utility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'note_comments.dart'; // Updated import
import 'note_content.dart'; // Updated import
// Removed import for memo_detail_providers

class ItemDetailScreen extends ConsumerStatefulWidget { // Renamed class
  final String itemId; // Renamed from memoId to itemId

  const ItemDetailScreen({super.key, required this.itemId}); // Renamed constructor and parameter

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState(); // Renamed class
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> // Renamed class
    with KeyboardNavigationMixin<ItemDetailScreen> { // Renamed class
  final FocusNode _screenFocusNode = FocusNode(
    debugLabel: 'ItemDetailScreenFocus', // Renamed debug label
  );
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    if (kDebugMode) print('[ItemDetailScreen] Pull-to-refresh triggered.'); // Updated log identifier
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    // Use providers from note_providers
    ref.invalidate(note_providers.noteDetailProvider(widget.itemId));
    ref.invalidate(note_providers.noteCommentsProvider(widget.itemId));
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
            top: 16.0,
            child: Opacity(
              opacity:
                  (refreshState == RefreshIndicatorMode.drag) ? opacity : 1.0,
              child:
                  (refreshState == RefreshIndicatorMode.refresh ||
                          refreshState == RefreshIndicatorMode.armed)
                      ? const CupertinoActivityIndicator(radius: 14.0)
                      : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  // --- Action Sheet Logic ---
  void _showActions() {
    if (!mounted) return;
    // Use public provider from note_providers
    final isFixingGrammar = ref.read(note_providers.isFixingGrammarProvider);

    showCupertinoModalPopup<void>(
      context: context,
      builder:
          (BuildContext popupContext) => CupertinoActionSheet(
            title: const Text('Note Actions'), // Updated text
            actions: <CupertinoActionSheetAction>[
              CupertinoActionSheetAction(
                child: const Text('Edit Note'), // Updated text
                onPressed: () {
                  Navigator.pop(popupContext);
                  Navigator.of(context, rootNavigator: true)
                      .pushNamed(
                        '/edit-entity',
                        arguments: {
                          'entityType': 'note', // Specify type as 'note'
                          'entityId': widget.itemId, // Pass itemId as entityId
                        },
                      )
                      .then((_) {
                        if (!mounted) return;
                        // Use providers from note_providers
                        ref.invalidate(note_providers.noteDetailProvider(widget.itemId));
                        ref.invalidate(note_providers.noteCommentsProvider(widget.itemId));
                        // Ensure item is not hidden after edit (using correct provider and remove method)
                        ref
                            .read(
                              settings_p.manuallyHiddenNoteIdsProvider.notifier,
                            )
                            .remove(
                              widget.itemId,
                            ); // Directly remove the ID if it exists
                      });
                },
              ),
              CupertinoActionSheetAction(
                isDefaultAction: !isFixingGrammar,
                onPressed: isFixingGrammar ? () {} : () {
                          Navigator.pop(popupContext);
                          _fixGrammar();
                        },
                child: isFixingGrammar
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
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                child: const Text('Delete Note'), // Updated text
                onPressed: () async {
                  final sheetContext = popupContext;
                  Navigator.pop(sheetContext);

                  final dialogContext = context;
                  final confirmed = await showCupertinoDialog<bool>(
                    context: dialogContext,
                    builder:
                        (context) => CupertinoAlertDialog(
                          title: const Text('Delete Note?'), // Updated text
                          content: const Text(
                            'Are you sure you want to permanently delete this note and its comments?', // Updated text
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

                  if (confirmed == true) {
                    if (!mounted) return;
                    try {
                      // Use deleteNoteProvider from note_providers
                      await ref.read(
                        note_providers.deleteNoteProvider(widget.itemId),
                      )();
                      if (!mounted) return;
                      Navigator.of(context).pop();
                    } catch (e) {
                      if (!mounted) return;
                      _showErrorSnackbar('Failed to delete note: $e'); // Updated text
                    }
                  }
                },
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(popupContext);
              },
            ),
      ),
    );
  }

  // --- Fix Grammar Handler ---
  Future<void> _fixGrammar() async {
    if (!mounted) return;
    // Use public provider from note_providers
    ref.read(note_providers.isFixingGrammarProvider.notifier).state = true;
    HapticFeedback.mediumImpact();

    try {
      if (!mounted) return;
      // Use provider from note_providers
      await ref.read(
        note_providers.fixNoteGrammarProvider(widget.itemId).future,
      );
      if (mounted) _showSuccessSnackbar('Grammar corrected successfully!');

    } catch (e) {
      if (mounted) _showErrorSnackbar('Failed to fix grammar: $e');
      if (kDebugMode) print('[ItemDetailScreen] Fix Grammar Error: $e'); // Updated log identifier
    } finally {
      if (mounted) {
        // Use public provider from note_providers
        ref.read(note_providers.isFixingGrammarProvider.notifier).state = false;
      }
    }
  }

  // --- Snackbar Helpers ---
  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
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
    if (!mounted) return;
    // Use provider from note_providers
    final commentsAsync = ref.read(note_providers.noteCommentsProvider(widget.itemId));
    commentsAsync.whenData((comments) {
      if (comments.isEmpty) return;
      if (!mounted) return;
      final currentIndex = ref.read(selectedCommentIndexProvider);
      final nextIndex = getNextIndex(currentIndex, comments.length);
      if (nextIndex != currentIndex) {
        if (!mounted) return;
        ref.read(selectedCommentIndexProvider.notifier).state = nextIndex;
      }
    });
  }

  void _selectPreviousComment() {
    if (!mounted) return;
    // Use provider from note_providers
    final commentsAsync = ref.read(note_providers.noteCommentsProvider(widget.itemId));
    commentsAsync.whenData((comments) {
      if (comments.isEmpty) return;
      if (!mounted) return;
      final currentIndex = ref.read(selectedCommentIndexProvider);
      final prevIndex = getPreviousIndex(currentIndex, comments.length);
      if (prevIndex != currentIndex) {
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
            middle: const Text('Note Detail'), // Updated text
            transitionBetweenRoutes: false,
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showActions,
              child: const Icon(CupertinoIcons.ellipsis_vertical),
            ),
          ),
          child: Column(
            children: [
              Expanded(child: _buildBody()),
              CaptureUtility(
                mode: CaptureMode.addComment,
                memoId: widget.itemId, // Pass itemId as memoId
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
    if (!mounted) return const Center(child: CupertinoActivityIndicator());
    // Use provider from note_providers
    final noteAsync = ref.watch(note_providers.noteDetailProvider(widget.itemId));

    return noteAsync.when(
      data: (note) {
        return CupertinoScrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          thickness: 6.0,
          radius: const Radius.circular(3.0),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: _onRefresh,
                builder: _buildRefreshIndicator,
              ),
              SliverToBoxAdapter(
                child: NoteContent( // Use renamed widget
                  note: note,
                  noteId: widget.itemId, // Pass itemId as noteId
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  height: 0.5,
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
              SliverToBoxAdapter(child: NoteComments(noteId: widget.itemId)), // Use renamed widget and pass noteId
              const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
            ],
          ),
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error:
          (error, _) => Center(
            child: Text(
              'Error loading note: $error', // Updated text
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
