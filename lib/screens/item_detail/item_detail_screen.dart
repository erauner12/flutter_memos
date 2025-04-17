import 'dart:async'; // For Completer

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Keep for ScaffoldMessenger, SnackBar
import 'package:flutter/services.dart';
import 'package:flutter_memos/models/note_item.dart'; // Import NoteItem
import 'package:flutter_memos/models/workbench_item_reference.dart'; // Import workbench model
// Import note_providers instead of memo_providers
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
import 'package:flutter_memos/providers/server_config_provider.dart'; // Import server config provider
// Import settings_provider for manuallyHiddenNoteIdsProvider
import 'package:flutter_memos/providers/settings_provider.dart' as settings_p;
import 'package:flutter_memos/providers/ui_providers.dart';
// Removed import for memo_detail_providers
import 'package:flutter_memos/providers/workbench_provider.dart'; // Import workbench provider
import 'package:flutter_memos/screens/home_screen.dart'; // Import for tabControllerProvider and navigator keys
import 'package:flutter_memos/utils/keyboard_navigation.dart';
import 'package:flutter_memos/utils/thread_utils.dart'; // Import the utility
import 'package:flutter_memos/widgets/capture_utility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart'; // Import Uuid

import 'note_comments.dart'; // Updated import
import 'note_content.dart'; // Updated import

class ItemDetailScreen extends ConsumerStatefulWidget { // Renamed class
  final String itemId; // Renamed from memoId to itemId
  // Assume note for now, could be passed if screen becomes generic
  final WorkbenchItemType itemType = WorkbenchItemType.note;

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
  BuildContext?
  _loadingDialogContext; // To store the context of the loading dialog

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
    _dismissLoadingDialog(); // Ensure dialog is dismissed
    super.dispose();
  }

  // Helper to dismiss loading dialog safely
  void _dismissLoadingDialog() {
    if (_loadingDialogContext != null) {
      try {
        if (Navigator.of(_loadingDialogContext!).canPop()) {
          Navigator.of(_loadingDialogContext!).pop();
        }
      } catch (_) {
        // Ignore errors if context is already invalid or cannot pop
      }
      _loadingDialogContext = null;
    }
  }

  // Helper to show loading dialog safely
  void _showLoadingDialog(String message) {
    // Dismiss any existing dialog first
    _dismissLoadingDialog();
    if (!mounted) return;
    showCupertinoDialog(
      context: context, // Use the screen's main context
      barrierDismissible: false,
      builder: (dialogContext) {
        _loadingDialogContext = dialogContext; // Store the dialog's context
        return CupertinoAlertDialog(
          content: Row(
            children: [
              const CupertinoActivityIndicator(),
              const SizedBox(width: 15),
              Text(message),
            ],
          ),
        );
      },
    );
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

  // --- Add to Workbench Action ---
  void _addNoteToWorkbench(NoteItem note) {
    final activeServer = ref.read(activeServerConfigProvider);
    if (activeServer == null) {
      _showErrorSnackbar("Cannot add to workbench: No active server.");
      return;
    }

    final preview =
        note.content.split('\n').first; // Simple preview (first line)

    final reference = WorkbenchItemReference(
      id: const Uuid().v4(), // Generate unique ID for the reference
      referencedItemId: note.id,
      referencedItemType: WorkbenchItemType.note,
      serverId: activeServer.id,
      serverType: activeServer.serverType,
      serverName: activeServer.name,
      previewContent:
          preview.length > 100
              ? '${preview.substring(0, 97)}...'
              : preview, // Limit preview length
      addedTimestamp: DateTime.now(),
      // parentNoteId is null for notes
    );

    ref.read(workbenchProvider.notifier).addItem(reference);
    _showSuccessSnackbar('Added note to Workbench');
  }
  // --- End Add to Workbench Action ---


  // --- Action Sheet Logic ---
  void _showActions() {
    if (!mounted) return;
    final isFixingGrammar = ref.read(note_providers.isFixingGrammarProvider);
    final noteAsync = ref.read(
      note_providers.noteDetailProvider(widget.itemId),
    );
    final activeServer = ref.read(activeServerConfigProvider);
    // Item detail screen assumes the item is on the active server
    final bool canInteractWithServer = activeServer != null;

    showCupertinoModalPopup<void>(
      context: context,
      builder:
          (BuildContext popupContext) => CupertinoActionSheet(
            title: const Text('Note Actions'), // Updated text
            actions: <CupertinoActionSheetAction>[
              CupertinoActionSheetAction(
                // Pass the function directly if canInteract, otherwise null
                onPressed:
                    !canInteractWithServer
                        ? null
                        : () {
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
                        ref.invalidate(note_providers.noteDetailProvider(widget.itemId));
                                ref.invalidate(
                                  note_providers.noteCommentsProvider(
                                    widget.itemId,
                                  ),
                                );
                        ref
                                    .read(
                                      settings_p
                                          .manuallyHiddenNoteIdsProvider
                                          .notifier,
                                    )
                                    .remove(widget.itemId);
                      });
                },
                child: const Text('Edit Note'),
              ),
              // Add Note to Workbench Action
              if (noteAsync is AsyncData<NoteItem>)
                CupertinoActionSheetAction(
                  onPressed:
                      !canInteractWithServer
                          ? null
                          : () {
                            Navigator.pop(popupContext);
                            _addNoteToWorkbench(noteAsync.value);
                          },
                  child: const Text('Add to Workbench'),
                ),
              // Fix Grammar Action
              CupertinoActionSheetAction(
                isDefaultAction: !isFixingGrammar,
                onPressed:
                    (isFixingGrammar || !canInteractWithServer)
                        ? null
                        : () {
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
              // Copy Full Thread Action
              CupertinoActionSheetAction(
                onPressed:
                    !canInteractWithServer
                        ? null
                        : () {
                          Navigator.pop(popupContext);
                          _copyThreadContent(
                            context,
                            ref,
                            widget.itemId,
                            widget.itemType, // Use widget's itemType
                          );
                        },
                child: const Text('Copy Full Thread'),
              ),
              // --- Chat about Thread Action ---
              CupertinoActionSheetAction(
                onPressed:
                    !canInteractWithServer
                        ? null
                        : () {
                  Navigator.pop(popupContext); // Close the sheet first
                          _chatWithThread(
                            context,
                    ref,
                    widget.itemId,
                            widget.itemType, // Use widget's itemType
                  );
                },
                child: const Text('Chat about Thread'),
              ),
              // --- End Chat about Thread Action ---
              // Delete Note Action
              CupertinoActionSheetAction(
                isDestructiveAction: true, // Updated text
                onPressed:
                    !canInteractWithServer
                        ? null
                        : () async {
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
                      await ref.read(
                        note_providers.deleteNoteProvider(widget.itemId),
                      )();
                      if (!mounted) return;
                              // Check if we can pop the current screen
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                    } catch (e) {
                      if (!mounted) return;
                      _showErrorSnackbar('Failed to delete note: $e'); // Updated text
                    }
                  }
                },
                child: const Text('Delete Note'),
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
    ref.read(note_providers.isFixingGrammarProvider.notifier).state = true;
    HapticFeedback.mediumImpact();
    _showLoadingDialog('Fixing grammar...'); // Show loading

    try {
      if (!mounted) return;
      await ref.read(
        note_providers.fixNoteGrammarProvider(widget.itemId).future,
      );
      _dismissLoadingDialog(); // Dismiss loading
      if (mounted) _showSuccessSnackbar('Grammar corrected successfully!');

    } catch (e) {
      _dismissLoadingDialog(); // Dismiss loading on error
      if (mounted) _showErrorSnackbar('Failed to fix grammar: $e');
      if (kDebugMode) print('[ItemDetailScreen] Fix Grammar Error: $e');
    } finally {
      if (mounted) {
        ref.read(note_providers.isFixingGrammarProvider.notifier).state = false;
      }
    }
  }

  // --- Copy Thread Content Helper ---
  Future<void> _copyThreadContent(
    BuildContext buildContext, // Use the main screen's context
    WidgetRef ref,
    String itemId,
    WorkbenchItemType itemType,
  ) async {
    final activeServerId = ref.read(activeServerConfigProvider)?.id;
    if (activeServerId == null) {
      _showErrorSnackbar('Cannot copy thread: No active server.');
      return;
    }

    _showLoadingDialog('Fetching thread...');

    try {
      // Assuming the item detail screen always shows an item from the active server
      final content = await getFormattedThreadContent(
        ref,
        itemId,
        itemType,
        activeServerId,
      );
      await Clipboard.setData(ClipboardData(text: content));

      _dismissLoadingDialog();
      if (mounted) {
        _showSuccessSnackbar('Thread content copied to clipboard.');
      }
    } catch (e) {
      _dismissLoadingDialog();
      if (mounted) {
        _showErrorSnackbar('Failed to copy thread: $e');
      }
    }
  }
  // --- End Copy Thread Content Helper ---

  // --- Chat With Thread Helper ---
  Future<void> _chatWithThread(
    BuildContext buildContext,
    WidgetRef ref,
    String itemId,
    WorkbenchItemType itemType,
  ) async {
    final activeServer = ref.read(activeServerConfigProvider);
    if (activeServer == null) {
      _showErrorSnackbar('Cannot start chat: No active server.');
      return;
    }
    final activeServerId = activeServer.id;

    _showLoadingDialog('Fetching thread for chat...');

    try {
      // Fetch the thread content
      final content = await getFormattedThreadContent(
        ref,
        itemId,
        itemType,
        activeServerId,
      );

      _dismissLoadingDialog(); // Dismiss before navigation

      if (!mounted) return;

      // 1. Switch Tab
      final tabController = ref.read(tabControllerProvider);
      if (tabController == null || tabController.index == 3) {
        // Already on chat tab or controller not found, proceed directly
        _navigateToChatScreen(
          buildContext,
          content,
          itemId,
          itemType,
          activeServerId,
        );
      } else {
        tabController.index = 3; // Switch to Chat tab (index 3)
        // Add a short delay to allow tab switch animation before navigating
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          _navigateToChatScreen(
            buildContext,
            content,
            itemId,
            itemType,
            activeServerId,
          );
        }
      }
    } catch (e) {
      _dismissLoadingDialog();
      if (mounted) {
        _showErrorSnackbar('Failed to start chat: $e');
      }
    }
  }

  // Helper to perform the actual navigation to chat screen
  void _navigateToChatScreen(
    BuildContext buildContext,
    String fetchedContent,
    String itemId,
    WorkbenchItemType itemType,
    String activeServerId,
  ) {
    // Use the specific navigator key for the Chat tab
    final chatNavigator = chatTabNavKey.currentState;
    if (chatNavigator != null) {
      // Pop to root of chat tab first to avoid stacking chat screens
      chatNavigator.popUntil((route) => route.isFirst);
      // Push the chat screen with arguments
      chatNavigator.pushNamed(
        '/chat', // Route defined in HomeScreen for the chat tab
        arguments: {
          'contextString': fetchedContent,
          'parentItemId': itemId,
          'parentItemType': itemType,
          'parentServerId': activeServerId,
        },
      );
    } else {
      // Fallback or error handling if navigator key is null
      _showErrorSnackbar('Could not navigate to chat tab.');
      if (kDebugMode) {
        print("Error: chatTabNavKey.currentState is null");
      }
    }
  }
  // --- End Chat With Thread Helper ---


  // --- Snackbar Helpers ---
  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  // --- End Snackbar Helpers ---

  // --- Keyboard Navigation Helpers ---
  void _selectNextComment() {
    if (!mounted) return;
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
    // Check if the item still exists or if the server is active
    final noteAsync = ref.watch(
      note_providers.noteDetailProvider(widget.itemId),
    );
    final activeServer = ref.watch(activeServerConfigProvider);
    // Assuming the detail screen implies the item is on the active server.
    // If the server changes while viewing, this might become invalid.
    final bool isActiveServerItem = activeServer != null;

    // Handle cases where the note is deleted or server becomes inactive while viewing
    if (noteAsync is AsyncError && isActiveServerItem) {
      // If error is specifically 'not found' or similar after a delete action
      // Maybe pop automatically? Or show a specific message.
      // For now, show generic error.
    } else if (!isActiveServerItem) {
      // If server switched away, show an overlay or disable actions?
      // For now, actions are disabled in _showActions based on canInteractWithServer
    }


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
              // Only show comment input if on active server
              if (isActiveServerItem)
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
    final noteAsync = ref.watch(note_providers.noteDetailProvider(widget.itemId));
    final activeServer = ref.watch(activeServerConfigProvider);
    final bool isActiveServerItem =
        activeServer != null; // Simplified check for body

    if (!isActiveServerItem) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'The server for this item is no longer active. Please switch servers to interact.',
            textAlign: TextAlign.center,
            style: TextStyle(color: CupertinoColors.secondaryLabel),
          ),
        ),
      );
    }

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
                  color: CupertinoColors.separator.resolveFrom(context),
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
      error: (error, _) {
        // Check if error indicates item not found (e.g., after deletion)
        // This depends on the specific error thrown by the API service
        bool isNotFoundError = error.toString().contains(
          'not found',
        ); // Example check

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              isNotFoundError
                  ? 'Note not found. It may have been deleted.'
                  : 'Error loading note: $error',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CupertinoColors.systemRed.resolveFrom(context),
              ),
            ),
          ),
        );
      }
    );
  }
  // --- End Build Body Helper ---
}
