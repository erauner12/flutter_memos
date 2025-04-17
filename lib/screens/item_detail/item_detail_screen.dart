import 'dart:async'; // For Completer

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Keep for ScaffoldMessenger, SnackBar
import 'package:flutter/services.dart';
// Add import for the provider
import 'package:flutter_memos/main.dart'; // Adjust path if main.dart is elsewhere
import 'package:flutter_memos/models/note_item.dart'; // Import NoteItem
import 'package:flutter_memos/models/workbench_item_reference.dart'; // Import workbench model
// Import note_providers instead of memo_providers
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
import 'package:flutter_memos/providers/server_config_provider.dart'; // Import server config provider
// Import settings_provider for manuallyHiddenNoteIdsProvider
import 'package:flutter_memos/providers/settings_provider.dart' as settings_p;
import 'package:flutter_memos/providers/ui_providers.dart';
// Removed import for memo_detail_providers
import 'package:flutter_memos/providers/workbench_instances_provider.dart'; // Import instances provider
import 'package:flutter_memos/providers/workbench_provider.dart'; // Import workbench provider family etc.
import 'package:flutter_memos/screens/home_screen.dart'; // Import for navigator keys and NEW providers
import 'package:flutter_memos/screens/home_tabs.dart'
    show HomeTab, SafeTabNav; // NEW IMPORT
import 'package:flutter_memos/utils/keyboard_navigation.dart';
import 'package:flutter_memos/utils/thread_utils.dart'; // Import the utility
import 'package:flutter_memos/widgets/capture_utility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart'; // Import Uuid

import 'note_comments.dart'; // Updated import
import 'note_content.dart'; // Updated import

class ItemDetailScreen extends ConsumerStatefulWidget {
  final String itemId;
  final WorkbenchItemType itemType = WorkbenchItemType.note;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen>
    with KeyboardNavigationMixin<ItemDetailScreen> {
  final FocusNode _screenFocusNode = FocusNode(
    debugLabel: 'ItemDetailScreenFocus',
  );
  late ScrollController _scrollController;
  BuildContext? _loadingDialogContext;

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
    _dismissLoadingDialog();
    super.dispose();
  }

  void _dismissLoadingDialog() {
    if (_loadingDialogContext != null) {
      try {
        final navigator = Navigator.of(_loadingDialogContext!);
        if (navigator.canPop()) {
          navigator.pop();
        }
      } catch (e) {
        if (kDebugMode) {
          print("Error dismissing loading dialog: $e");
        }
      }
      _loadingDialogContext = null;
    }
  }

  void _showLoadingDialog(String message) {
    _dismissLoadingDialog();
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        _loadingDialogContext = dialogContext;
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
    if (kDebugMode) {
      print('[ItemDetailScreen] Pull-to-refresh triggered.');
    }
    HapticFeedback.mediumImpact();
    if (!mounted) return;
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
  Future<void> _addNoteToWorkbench(NoteItem note) async {
    final activeServer = ref.read(activeServerConfigProvider);
    if (activeServer == null) {
      _showErrorSnackbar("Cannot add to workbench: No active server.");
      return;
    }

    final instancesState = ref.read(workbenchInstancesProvider);
    final instances = instancesState.instances;
    final activeInstanceId = instancesState.activeInstanceId;

    String targetInstanceId = activeInstanceId;

    if (instances.length > 1) {
      final String? chosenId = await showCupertinoModalPopup<String>(
        context: context,
        builder: (BuildContext popupContext) {
          return CupertinoActionSheet(
            title: const Text('Add Note to Workbench'),
            actions:
                instances.map((instance) {
                  return CupertinoActionSheetAction(
                    isDefaultAction: instance.id == activeInstanceId,
                    onPressed: () {
                      Navigator.pop(popupContext, instance.id);
                    },
                    child: Text(instance.name),
                  );
                }).toList(),
            cancelButton: CupertinoActionSheetAction(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(popupContext);
              },
            ),
          );
        },
      );

      if (chosenId == null) {
        return;
      }
      targetInstanceId = chosenId;
    } else if (instances.isEmpty) {
      _showErrorSnackbar(
        "Cannot add to workbench: No workbench instances found.",
      );
      return;
    }

    final preview = note.content.split('\n').first;

    final reference = WorkbenchItemReference(
      id: const Uuid().v4(), // Generate unique ID for the reference
      instanceId: targetInstanceId, // Use the chosen or default instance ID
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
      // previewComments, referencedItemUpdateTime, overallLastUpdateTime are populated later
    );

    // Read the specific notifier for the target instance and add the item
    ref
        .read(workbenchProviderFamily(targetInstanceId).notifier)
        .addItem(reference);

    // Use tryWhere pattern that safely handles no matches
    final targetInstance =
        instances
            .where((i) => i.id == targetInstanceId).firstOrNull;
    final targetInstanceName = targetInstance?.name ?? 'Workbench';

    _showSuccessSnackbar('Added note to "$targetInstanceName"');
  }
  // --- End Add to Workbench Action ---

  void _showActions() {
    if (!mounted) return;
    final isFixingGrammar = ref.read(note_providers.isFixingGrammarProvider);
    final noteAsync = ref.read(
      note_providers.noteDetailProvider(widget.itemId),
    );
    final activeServer = ref.read(activeServerConfigProvider);
    final bool canInteractWithServer = activeServer != null;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext popupContext) {
        final List<CupertinoActionSheetAction> actions = [];

        if (canInteractWithServer) {
          actions.add(
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(popupContext);
                Navigator.of(context, rootNavigator: true)
                    .pushNamed(
                      '/edit-entity',
                      arguments: {
                        'entityType': 'note',
                        'entityId': widget.itemId,
                      },
                    )
                    .then((_) {
                      if (!mounted) return;
                      ref.invalidate(
                        note_providers.noteDetailProvider(widget.itemId),
                      );
                      ref.invalidate(
                        note_providers.noteCommentsProvider(widget.itemId),
                      );
                      ref
                          .read(
                            settings_p.manuallyHiddenNoteIdsProvider.notifier,
                          )
                          .remove(widget.itemId);
                    });
              },
              child: const Text('Edit Note'),
            ),
          );
        }

        // Add Note to Workbench Action
        if (canInteractWithServer && noteAsync is AsyncData<NoteItem>) {
          actions.add(
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(popupContext);
                _addNoteToWorkbench(noteAsync.value);
              },
              child: const Text('Add to Workbench'),
            ),
          );
        }

        if (canInteractWithServer) {
          actions.add(
            CupertinoActionSheetAction(
              isDefaultAction: !isFixingGrammar,
              onPressed: () {
                if (!isFixingGrammar) {
                  Navigator.pop(popupContext);
                  _fixGrammar();
                }
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
          );
        }

        if (canInteractWithServer) {
          actions.add(
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(popupContext);
                _copyThreadContent(
                  context,
                  ref,
                  widget.itemId,
                  widget.itemType,
                );
              },
              child: const Text('Copy Full Thread'),
            ),
          );
        }

        if (canInteractWithServer) {
          actions.add(
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(popupContext);
                _chatWithThread(context, ref, widget.itemId, widget.itemType);
              },
              child: const Text('Chat about Thread'),
            ),
          );
        }

        if (canInteractWithServer) {
          actions.add(
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.pop(popupContext);
                if (!mounted) return;
                final dialogContext = context;
                final confirmed = await showCupertinoDialog<bool>(
                  context: dialogContext,
                  builder:
                      (context) => CupertinoAlertDialog(
                        title: const Text('Delete Note?'),
                        content: const Text(
                          'Are you sure you want to permanently delete this note and its comments?',
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
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  } catch (e) {
                    if (!mounted) return;
                    _showErrorSnackbar('Failed to delete note: $e');
                  }
                }
              },
              child: const Text('Delete Note'),
            ),
          );
        }

        return CupertinoActionSheet(
          title: const Text('Note Actions'),
          actions: actions,
          cancelButton: CupertinoActionSheetAction(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.pop(popupContext);
            },
          ),
        );
      },
    );
  }

  Future<void> _fixGrammar() async {
    if (!mounted) return;
    ref.read(note_providers.isFixingGrammarProvider.notifier).state = true;
    HapticFeedback.mediumImpact();
    _showLoadingDialog('Fixing grammar...');

    try {
      await ref.read(
        note_providers.fixNoteGrammarProvider(widget.itemId).future,
      );
      if (!mounted) return;
      _dismissLoadingDialog();
      _showSuccessSnackbar('Grammar corrected successfully!');
    } catch (e) {
      if (!mounted) return;
      _dismissLoadingDialog();
      _showErrorSnackbar('Failed to fix grammar: $e');
      if (kDebugMode) print('[ItemDetailScreen] Fix Grammar Error: $e');
    } finally {
      if (mounted) {
        ref.read(note_providers.isFixingGrammarProvider.notifier).state = false;
      }
    }
  }

  Future<void> _copyThreadContent(
    BuildContext buildContext,
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

    String? fetchedContent;
    Object? fetchError;

    try {
      fetchedContent = await getFormattedThreadContent(
        ref,
        itemId,
        itemType,
        activeServerId,
      );
      await Clipboard.setData(ClipboardData(text: fetchedContent));
    } catch (e) {
      fetchError = e;
    }

    if (!mounted) return;
    _dismissLoadingDialog();

    if (fetchError != null) {
      _showErrorSnackbar('Failed to copy thread: $fetchError');
    } else {
      _showSuccessSnackbar('Thread content copied to clipboard.');
    }
  }

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
    String? fetchedContent;
    Object? fetchError;

    try {
      fetchedContent = await getFormattedThreadContent(
        ref,
        itemId,
        itemType,
        activeServerId,
      );
    } catch (e) {
      fetchError = e;
    }

    if (!mounted) return;
    _dismissLoadingDialog();

    if (fetchError != null) {
      _showErrorSnackbar('Failed to start chat: $fetchError');
      return;
    }
    if (fetchedContent == null) {
      _showErrorSnackbar(
        'Failed to start chat: Could not fetch thread content.',
      );
      return;
    }

    try {
      // Use the new providers and safeSetIndex
      final controller = ref.read(homeTabControllerProvider);
      final indexMap = ref.read(homeTabIndexMapProvider);
      controller.safeSetIndex(HomeTab.chat, indexMap, indexMap.length);

      // No need for null checks or index checks, safeSetIndex handles it.
      // Proceed directly to navigation.
      if (!mounted) return;
      _navigateToChatScreen(
        buildContext,
        fetchedContent,
        itemId,
        itemType,
        activeServerId,
      );

    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Failed to navigate to chat: $e');
      }
    }
  }

  void _navigateToChatScreen(
    BuildContext buildContext,
    String fetchedContent,
    String itemId,
    WorkbenchItemType itemType,
    String activeServerId,
  ) {
    // Navigate within the Chat tab's navigator if possible
    final chatNavigator = chatTabNavKey.currentState;
    final chatArgs = {
      'contextString': fetchedContent,
      'parentItemId': itemId,
      'parentItemType': itemType,
      'parentServerId': activeServerId,
    };

    if (chatNavigator != null) {
      // Pop to root of chat tab first to avoid stacking chat screens
      chatNavigator.popUntil((route) => route.isFirst);
      // Push the chat screen with arguments using the tab's navigator
      chatNavigator.pushNamed('/chat', arguments: chatArgs);
    } else {
      // Fallback: Use root navigator if chat tab navigator isn't available
      final rootNavigatorKey = ref.read(rootNavigatorKeyProvider);
      if (rootNavigatorKey.currentState != null) {
        rootNavigatorKey.currentState!.pushNamed('/chat', arguments: chatArgs);
      } else {
        _showErrorSnackbar('Could not access root navigator.');
        if (kDebugMode) {
          print("Error: rootNavigatorKey.currentState is null");
        }
      }
    }
  }

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

  void _selectNextComment() {
    if (!mounted) return;
    final commentsAsync = ref.read(
      note_providers.noteCommentsProvider(widget.itemId),
    );
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
    final commentsAsync = ref.read(
      note_providers.noteCommentsProvider(widget.itemId),
    );
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

  @override
  Widget build(BuildContext context) {
    final noteAsync = ref.watch(
      note_providers.noteDetailProvider(widget.itemId),
    );
    final activeServer = ref.watch(activeServerConfigProvider);
    final bool isActiveServerItem = activeServer != null;

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
            middle: const Text('Note Detail'),
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
              if (isActiveServerItem)
                CaptureUtility(
                  mode: CaptureMode.addComment,
                  memoId: widget.itemId,
                  hintText: 'Add a comment...',
                  buttonText: 'Add Comment',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (!mounted) return const Center(child: CupertinoActivityIndicator());
    final noteAsync = ref.watch(
      note_providers.noteDetailProvider(widget.itemId),
    );
    final activeServer = ref.watch(activeServerConfigProvider);
    final bool isActiveServerItem = activeServer != null;

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
                child: NoteContent(note: note, noteId: widget.itemId),
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
              SliverToBoxAdapter(child: NoteComments(noteId: widget.itemId)),
              const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
            ],
          ),
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (error, _) {
        final bool isNotFoundError = error.toString().contains('not found');
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
      },
    );
  }
}
