import 'dart:async'; // For Completer

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Keep for ScaffoldMessenger, SnackBar
import 'package:flutter/services.dart';
import 'package:flutter_memos/models/note_item.dart'; // Import NoteItem
import 'package:flutter_memos/models/workbench_item_reference.dart'; // Import workbench model
import 'package:flutter_memos/models/workbench_item_type.dart'; // Import the unified enum
import 'package:flutter_memos/providers/focus_provider.dart'; // Correct import: workbench -> focus
// Add import for the provider
import 'package:flutter_memos/providers/navigation_providers.dart';
// Import note_providers and use non-family providers
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
// Import new single config provider
import 'package:flutter_memos/providers/note_server_config_provider.dart';
// Import settings_provider for manuallyHiddenNoteIdsProvider
import 'package:flutter_memos/providers/settings_provider.dart' as settings_p;
import 'package:flutter_memos/providers/ui_providers.dart';
import 'package:flutter_memos/utils/focus_utils.dart'; // Correct import: workbench -> focus
import 'package:flutter_memos/utils/keyboard_navigation.dart';
import 'package:flutter_memos/utils/thread_utils.dart'; // Import the utility
import 'package:flutter_memos/widgets/capture_utility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart'; // Import Uuid

import 'note_comments.dart'; // Updated import
import 'note_content.dart'; // Updated import

class ItemDetailScreen extends ConsumerStatefulWidget {
  final String itemId;
  // serverId is no longer needed, context comes from noteServerConfigProvider
  // final String? serverId;
  final WorkbenchItemType itemType =
      WorkbenchItemType.note; // Assuming this screen is only for notes now

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
  String? _effectiveServerId; // Store the serverId from the provider

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateEffectiveServerId(); // Determine serverId initially
      if (mounted) {
        _screenFocusNode.requestFocus();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateEffectiveServerId(); // Update if dependencies change (like noteServerConfigProvider)
  }

  void _updateEffectiveServerId() {
    // Get serverId directly from the single note provider
    final newServerId = ref.read(noteServerConfigProvider)?.id;
    if (_effectiveServerId != newServerId) {
      setState(() {
        _effectiveServerId = newServerId;
      });
      // Invalidate providers that depend on serverId when it changes
      if (newServerId != null) {
        ref.invalidate(note_providers.noteDetailProvider(widget.itemId));
        ref.invalidate(note_providers.noteCommentsProvider(widget.itemId));
      }
    }
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
    if (_effectiveServerId == null) {
      return;
    } // Don't refresh if no server
    if (kDebugMode) {
      print(
        '[ItemDetailScreen($_effectiveServerId)] Pull-to-refresh triggered.',
      );
    }
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    // Use non-family providers with itemId
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

  // --- Add to Focus Board Action --- Updated name
  Future<void> _addNoteToFocusBoard(NoteItem note) async {
    // Updated name
    if (_effectiveServerId == null) {
      _showErrorSnackbar(
        "Cannot add to focus board: Server context missing.",
      ); // Updated text
      return;
    }
    // Get the config from the provider
    final serverConfig = ref.read(noteServerConfigProvider);

    if (serverConfig == null) {
      _showErrorSnackbar(
        "Cannot add to focus board: Note server config not found.", // Updated text
      );
      return;
    }

    final selectedInstance = await showFocusInstancePicker(
      // Use focus picker
      context,
      ref,
      title: 'Add Note To Focus Board', // Updated text
    );
    if (selectedInstance == null) return;

    final targetInstanceId = selectedInstance.id;
    final targetInstanceName = selectedInstance.name;
    final preview = note.content.split('\n').first;

    final reference = WorkbenchItemReference(
      // Keep generic name or rename
      id: const Uuid().v4(),
      instanceId: targetInstanceId,
      referencedItemId: note.id,
      referencedItemType: WorkbenchItemType.note,
      serverId: serverConfig.id,
      serverType: serverConfig.serverType,
      serverName: serverConfig.name,
      previewContent:
          preview.length > 100 ? '${preview.substring(0, 97)}...' : preview,
      addedTimestamp: DateTime.now(),
      parentNoteId: null,
    );

    ref
        .read(
          focusProviderFamily(targetInstanceId).notifier,
        ) // Use focus provider family
        .addItem(reference);
    _showSuccessSnackbar('Added note to "$targetInstanceName"');
  }
  // --- End Add to Focus Board Action ---

  void _showActions() {
    if (!mounted || _effectiveServerId == null) return;
    final isFixingGrammar = ref.read(note_providers.isFixingGrammarProvider);
    final noteAsync = ref.read(
      note_providers.noteDetailProvider(widget.itemId),
    ); // Use non-family provider
    final bool canInteractWithServer = _effectiveServerId != null;

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
                      }, // serverId no longer needed
                    )
                    .then((_) {
                      if (!mounted || _effectiveServerId == null) return;
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

        if (canInteractWithServer && noteAsync is AsyncData<NoteItem>) {
          actions.add(
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(popupContext);
                _addNoteToFocusBoard(noteAsync.value); // Updated method call
              },
              child: const Text('Add to Focus Board'), // Updated text
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
                if (!mounted || _effectiveServerId == null) return;
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
                  if (!mounted || _effectiveServerId == null) return;
                  try {
                    await ref.read(
                      note_providers.deleteNoteProvider(widget.itemId),
                    )(); // Use non-family provider
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
            onPressed: () => Navigator.pop(popupContext),
          ),
        );
      },
    );
  }

  Future<void> _fixGrammar() async {
    if (!mounted || _effectiveServerId == null) return;
    ref.read(note_providers.isFixingGrammarProvider.notifier).state = true;
    HapticFeedback.mediumImpact();
    _showLoadingDialog('Fixing grammar...');

    try {
      await ref.read(
        note_providers.fixNoteGrammarProvider(widget.itemId).future,
      ); // Use non-family provider
      if (!mounted) return;
      _dismissLoadingDialog();
      _showSuccessSnackbar('Grammar corrected successfully!');
    } catch (e) {
      if (!mounted) return;
      _dismissLoadingDialog();
      _showErrorSnackbar('Failed to fix grammar: $e');
      if (kDebugMode) {
        print('[ItemDetailScreen($_effectiveServerId)] Fix Grammar Error: $e');
      }
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
    if (_effectiveServerId == null) {
      _showErrorSnackbar('Cannot copy thread: Server context missing.');
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
        _effectiveServerId!,
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
    if (_effectiveServerId == null) {
      _showErrorSnackbar('Cannot start chat: Server context missing.');
      return;
    }
    _showLoadingDialog('Fetching thread for chat...');
    String? fetchedContent;
    Object? fetchError;
    try {
      fetchedContent = await getFormattedThreadContent(
        ref,
        itemId,
        itemType,
        _effectiveServerId!,
      );
    } catch (e) {
      fetchError = e;
    }

    // Check mounted *after* await
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
      // Check mounted again before navigation
      if (!mounted) return;
      _navigateToChatScreen(
        buildContext,
        fetchedContent,
        itemId,
        itemType,
        _effectiveServerId!,
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
    String serverId,
  ) {
    final chatArgs = {
      'contextString': fetchedContent,
      'parentItemId': itemId,
      'parentItemType': itemType,
      'parentServerId': serverId,
    };
    // Read the provider (now imported from navigation_providers.dart)
    final rootNavigatorKey = ref.read(
      rootNavigatorKeyProvider,
    ); // Use imported provider
    if (rootNavigatorKey.currentState != null) {
      // TODO: Update route name if chat is replaced by studio
      rootNavigatorKey.currentState!.pushNamed('/chat', arguments: chatArgs);
    } else {
      _showErrorSnackbar('Could not access root navigator.');
      if (kDebugMode) {
        print("Error: rootNavigatorKey.currentState is null");
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
    if (!mounted || _effectiveServerId == null) return;
    final commentsAsync = ref.read(
      note_providers.noteCommentsProvider(widget.itemId),
    ); // Use non-family provider
    commentsAsync.whenData((comments) {
      if (comments.isEmpty || !mounted) return;
      final currentIndex = ref.read(selectedCommentIndexProvider);
      final nextIndex = getNextIndex(currentIndex, comments.length);
      if (nextIndex != currentIndex && mounted) {
        ref.read(selectedCommentIndexProvider.notifier).state = nextIndex;
      }
    });
  }

  void _selectPreviousComment() {
    if (!mounted || _effectiveServerId == null) return;
    final commentsAsync = ref.read(
      note_providers.noteCommentsProvider(widget.itemId),
    ); // Use non-family provider
    commentsAsync.whenData((comments) {
      if (comments.isEmpty || !mounted) return;
      final currentIndex = ref.read(selectedCommentIndexProvider);
      final prevIndex = getPreviousIndex(currentIndex, comments.length);
      if (prevIndex != currentIndex && mounted) {
        ref.read(selectedCommentIndexProvider.notifier).state = prevIndex;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_effectiveServerId == null) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('Loading...')),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    // Watch the detail provider to trigger rebuilds when data changes
    ref.watch(
      note_providers.noteDetailProvider(widget.itemId),
    ); // Use non-family provider
    final bool canInteractWithServer = _effectiveServerId != null;

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
              if (canInteractWithServer)
                CaptureUtility(
                  key: CaptureUtility.captureUtilityKey,
                  mode: CaptureMode.addComment,
                  memoId: widget.itemId,
                  hintText: 'Add a comment...',
                  buttonText: 'Add Comment',
                  // serverId removed, CaptureUtility gets it from provider
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (!mounted || _effectiveServerId == null) {
      return const Center(child: CupertinoActivityIndicator());
    }
    final noteAsync = ref.watch(
      note_providers.noteDetailProvider(widget.itemId),
    ); // Use non-family provider

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
                child: NoteContent(
                  note: note,
                  noteId: widget.itemId,
                  serverId: '',
                  // serverId: _effectiveServerId!, // No longer needed by NoteContent
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
              SliverToBoxAdapter(
                child: NoteComments(
                  noteId: widget.itemId,
                  serverId:
                      _effectiveServerId!, // NoteComments still needs serverId
                ),
              ),
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
