import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Keep for Tooltip
import 'package:flutter/services.dart';
import 'package:flutter_memos/models/note_item.dart'; // Import NoteItem
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/providers/filter_providers.dart';
import 'package:flutter_memos/providers/mcp_server_config_provider.dart';
// Import note_providers instead of memo_providers
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/providers/service_providers.dart';
import 'package:flutter_memos/providers/settings_provider.dart';
import 'package:flutter_memos/providers/ui_providers.dart' as ui_providers;
// Import notes_list_body instead of memos_body
import 'package:flutter_memos/screens/items/notes_list_body.dart';
import 'package:flutter_memos/utils/keyboard_navigation.dart';
import 'package:flutter_memos/widgets/advanced_filter_panel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ItemsScreen extends ConsumerStatefulWidget { // Renamed class
  const ItemsScreen({super.key}); // Renamed constructor

  @override
  ConsumerState<ItemsScreen> createState() => _ItemsScreenState(); // Renamed class
}

class _ItemsScreenState extends ConsumerState<ItemsScreen>
    with KeyboardNavigationMixin<ItemsScreen> {
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(loadFilterPreferencesProvider);
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  CupertinoNavigationBar _buildMultiSelectNavBar(int selectedCount) {
    return CupertinoNavigationBar(
      transitionBetweenRoutes: false,
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          if (kDebugMode) {
            print('[ItemsScreen] Exit multi-select via Cancel button');
          }
          ref.read(ui_providers.toggleItemMultiSelectModeProvider)();
        },
        child: const Icon(CupertinoIcons.clear),
      ),
      middle: Text('$selectedCount Selected'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            minSize: 0,
            onPressed: selectedCount > 0
                ? () {
                      // Removed unimplemented multi-delete logic
                      if (kDebugMode) {
                        print(
                          '[ItemsScreen] Multi-delete action placeholder triggered for $selectedCount items.',
                        );
                      }
                  }
                : null,
            child: Icon(
              CupertinoIcons.delete,
              color: selectedCount > 0
                  ? CupertinoColors.destructiveRed
                  : CupertinoColors.inactiveGray,
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            minSize: 0,
            onPressed: selectedCount > 0
                ? () {
                      // Removed unimplemented multi-archive logic
                    if (kDebugMode) {
                        print(
                          '[ItemsScreen] Multi-archive action placeholder triggered for $selectedCount items.',
                        );
                    }
                  }
                : null,
            child: Icon(
              CupertinoIcons.archivebox,
              color: selectedCount > 0
                  ? CupertinoTheme.of(context).primaryColor
                  : CupertinoColors.inactiveGray,
            ),
          ),
        ],
      ),
    );
  }

  void _selectNextNote() {
    final notes = ref.read(note_providers.filteredNotesProvider);
    if (kDebugMode) {
      print(
        '[ItemsScreen _selectNextNote] Called. Filtered notes count: ${notes.length}',
      );
    }

    if (notes.isEmpty) return;

    final currentId = ref.read(ui_providers.selectedItemIdProvider);
    int currentIndex = -1;
    if (currentId != null) {
      currentIndex = notes.indexWhere((note) => note.id == currentId);
    }

    final nextIndex = getNextIndex(currentIndex, notes.length);

    if (nextIndex != -1) {
      final nextNoteId = notes[nextIndex].id;
      ref.read(ui_providers.selectedItemIdProvider.notifier).state = nextNoteId;
      if (kDebugMode) {
        print(
          '[ItemsScreen _selectNextNote] Updated selectedItemIdProvider to: $nextNoteId',
        );
      }
    }
  }

  void _selectPreviousNote() {
    final notes = ref.read(note_providers.filteredNotesProvider);
    if (kDebugMode) {
      print(
        '[ItemsScreen _selectPreviousNote] Called. Filtered notes count: ${notes.length}',
      );
    }

    if (notes.isEmpty) return;

    final currentId = ref.read(ui_providers.selectedItemIdProvider);
    int currentIndex = -1;
    if (currentId != null) {
      currentIndex = notes.indexWhere((note) => note.id == currentId);
    }

    final prevIndex = getPreviousIndex(currentIndex, notes.length);

    if (prevIndex != -1) {
      final prevNoteId = notes[prevIndex].id;
      ref.read(ui_providers.selectedItemIdProvider.notifier).state = prevNoteId;
      if (kDebugMode) {
        print(
          '[ItemsScreen _selectPreviousNote] Updated selectedItemIdProvider to: $prevNoteId',
        );
      }
    }
  }

  void _viewSelectedItem() {
    final selectedId = ref.read(ui_providers.selectedItemIdProvider);
    if (selectedId != null) {
      if (kDebugMode) {
        print('[ItemsScreen] Viewing selected item: ID $selectedId');
      }
      if (mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushNamed('/item-detail', arguments: {'itemId': selectedId});
      }
    }
  }

  void _clearSelectionOrUnfocus() {
    final selectedId = ref.read(ui_providers.selectedItemIdProvider);
    if (selectedId != null) {
      if (kDebugMode) {
        print('[ItemsScreen] Clearing selection via Escape');
      }
      ref.read(ui_providers.selectedItemIdProvider.notifier).state = null;
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (kDebugMode) {
      print(
        '[ItemsScreen _handleKeyEvent] Received key: ${event.logicalKey.keyLabel}',
      );
      print(
        '[ItemsScreen _handleKeyEvent] FocusNode has focus: ${node.hasFocus}',
      );
    }

    final result = handleKeyEvent(
      event,
      ref,
      onUp: _selectPreviousNote,
      onDown: _selectNextNote,
      onSubmit: _viewSelectedItem,
      onEscape: _clearSelectionOrUnfocus,
    );

    if (kDebugMode) {
      print(
        '[ItemsScreen _handleKeyEvent] Mixin handleKeyEvent result: $result',
      );
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    // Use providers from note_providers and renamed ui_providers
    final notesState = ref.watch(note_providers.notesNotifierProvider);
    // Use filteredNotesProvider directly now
    final visibleNotes = ref.watch(note_providers.filteredNotesProvider);
    final selectedPresetKey = ref.watch(quickFilterPresetProvider);
    final currentPresetLabel =
        quickFilterPresets[selectedPresetKey]?.label ?? 'Notes';
    // Use renamed providers from ui_providers
    final isMultiSelectMode = ref.watch(ui_providers.itemMultiSelectModeProvider);
    final selectedIds = ref.watch(ui_providers.selectedItemIdsForMultiSelectProvider);
    // Watch new providers for hidden notes
    final hiddenCount = ref.watch(note_providers.totalHiddenNoteCountProvider);
    final showHidden = ref.watch(showHiddenNotesProvider);
    final theme = CupertinoTheme.of(context);

    return CupertinoPageScaffold(
      navigationBar: isMultiSelectMode
          ? _buildMultiSelectNavBar(selectedIds.length)
          : CupertinoNavigationBar(
              transitionBetweenRoutes: false,
              leading: _buildServerSwitcherButton(),
              middle: GestureDetector(
                onTap: () {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      0.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                },
                child: Container(
                  color: CupertinoColors.transparent,
                  child: Text(currentPresetLabel),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      minSize: 0,
                      onPressed:
                          () =>
                              ref.read(
                                ui_providers.toggleItemMultiSelectModeProvider,
                              )(),
                    child: const Icon(
                      CupertinoIcons.checkmark_seal,
                    ),
                  ),
                    // Add Show/Hide Hidden Toggle Button
                    if (hiddenCount > 0)
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        minSize: 0,
                        onPressed: () {
                          ref
                              .read(showHiddenNotesProvider.notifier)
                              .update((state) => !state);
                        },
                        child: Tooltip(
                          message:
                              showHidden
                                  ? 'Hide Hidden Notes'
                                  : 'Show Hidden Notes ($hiddenCount)',
                          child: Icon(
                            showHidden
                                ? CupertinoIcons.eye_slash_fill
                                : CupertinoIcons.eye_fill,
                            color:
                                showHidden
                                    ? theme.primaryColor
                                    : CupertinoColors.secondaryLabel
                                        .resolveFrom(context),
                          ),
                        ),
                      ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      minSize: 0,
                      // FIX: Wrap the call in a lambda to match VoidCallback type
                      onPressed: () => _showAdvancedFilterPanel(context),
                    child: const Icon(CupertinoIcons.tuningfork),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    minSize: 0,
                    onPressed: () {
                      Navigator.of(
                        context,
                        rootNavigator: true,
                        ).pushNamed('/new-note');
                    },
                    child: const Icon(CupertinoIcons.add),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    minSize: 0,
                    onPressed: _showResetConfirmationDialog,
                    child: const Tooltip(
                      message: 'Reset All Cloud & Local Data',
                      child: Icon(
                        CupertinoIcons.exclamationmark_octagon,
                        color: CupertinoColors.systemRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      child: SafeArea(
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: Column(
            children: [
              if (!isMultiSelectMode)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
                  child: _buildSearchBar(),
                ),
              if (!isMultiSelectMode)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                  child: _buildQuickFilterControl(),
                ),
              // Display hidden count conditionally (for non-hidden views)
              if (!isMultiSelectMode &&
                  hiddenCount > 0 &&
                  !showHidden &&
                  selectedPresetKey != 'hidden')
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$hiddenCount hidden notes',
                      style: TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                  ),
                ),
              // Add Unhide All button when in hidden view
              if (!isMultiSelectMode && selectedPresetKey == 'hidden')
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 0,
                      onPressed: _showUnhideAllConfirmation,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.eye,
                            size: 18,
                            color: theme.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Unhide All Manually Hidden (${ref.watch(note_providers.manuallyHiddenNoteCountProvider)})',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(child: _buildNotesList(notesState, visibleNotes)),
            ],
          ),
        ),
      ),
    );
  }

  // Updated _buildQuickFilterControl with reordered segments
  Widget _buildQuickFilterControl() {
    final selectedPresetKey = ref.watch(quickFilterPresetProvider);
    final theme = CupertinoTheme.of(context);

    // Define the desired order, starting with 'today', removing 'tagged'
    const List<String> desiredOrder = [
      'today',
      'inbox',
      'all',
      'hidden',
    ];

    // Build the segments map respecting the desired order
    final Map<String, Widget> segments = {};
    for (var key in desiredOrder) {
      final preset = quickFilterPresets[key];
      // Ensure the preset exists and is not the 'custom' placeholder
      if (preset != null && preset.key != 'custom') {
        segments[preset.key] = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (preset.icon != null) Icon(preset.icon, size: 18),
              if (preset.icon != null) const SizedBox(width: 4),
              Text(preset.label),
            ],
          ),
        );
      }
    }

    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<String>(
        // Use the ordered segments map
        children: segments,
        groupValue: selectedPresetKey == 'custom' ? null : selectedPresetKey,
        thumbColor: theme.primaryColor,
        backgroundColor: CupertinoColors.secondarySystemFill.resolveFrom(context),
        onValueChanged: (String? newPresetKey) {
          if (newPresetKey != null) {
            if (kDebugMode) {
              print('[ItemsScreen] Quick filter selected: $newPresetKey');
            }
            ref.read(quickFilterPresetProvider.notifier).state = newPresetKey;
            // Clear raw filter if a preset is selected
            if (ref.read(rawCelFilterProvider).isNotEmpty) {
              ref.read(rawCelFilterProvider.notifier).state = '';
            }
            // Save the selected preset preference
            ref.read(filterPreferencesProvider)(newPresetKey);
          }
        },
      ),
    );
  }

  void _showAdvancedFilterPanel(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return AdvancedFilterPanel(onClose: () => Navigator.pop(context));
          },
        );
      },
    );
  }

  Widget _buildServerSwitcherButton() {
    final activeServer = ref.watch(activeServerConfigProvider);
    final serverName =
        activeServer?.name ?? activeServer?.serverUrl ?? 'No Server';
    final truncatedName =
        serverName.length > 15
            ? '${serverName.substring(0, 12)}...'
            : serverName;

    return CupertinoButton(
      padding: const EdgeInsets.only(left: 8.0),
      onPressed: () => _showServerSelectionSheet(context, ref),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.square_stack_3d_down_right, size: 20),
          const SizedBox(width: 4),
          Text(
            truncatedName,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
          const Icon(CupertinoIcons.chevron_down, size: 14),
        ],
      ),
    );
  }

  void _showServerSelectionSheet(BuildContext context, WidgetRef ref) {
    final multiServerState = ref.read(multiServerConfigProvider);
    final servers = multiServerState.servers;
    final activeServerId = multiServerState.activeServerId;
    final notifier = ref.read(multiServerConfigProvider.notifier);

    if (servers.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('No Servers'),
              content: const Text(
                'Please add a server configuration in Settings.',
              ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Settings'),
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushNamed('/settings');
              },
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Switch Active Server'),
        actions: servers.map((server) {
          final bool isActive = server.id == activeServerId;
          return CupertinoActionSheetAction(
            isDefaultAction: isActive,
            onPressed: () {
              if (!isActive) {
                if (kDebugMode) {
                          print(
                            '[ItemsScreen] Setting active server to: ${server.name ?? server.id}',
                          );
                }
                notifier.setActiveServer(server.id);
              }
              Navigator.pop(context);
            },
            child: Text(server.name ?? server.serverUrl),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final searchQuery = ref.watch(searchQueryProvider);
    final TextEditingController controller = TextEditingController(
      text: searchQuery,
    );
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );

    return CupertinoSearchTextField(
      controller: controller,
      placeholder: 'Search notes...',
      style: TextStyle(color: CupertinoColors.label.resolveFrom(context)),
      decoration: BoxDecoration(
        color: CupertinoColors.systemFill.resolveFrom(context),
        borderRadius: BorderRadius.circular(10.0),
      ),
      onChanged: (value) {
        ref.read(searchQueryProvider.notifier).state = value;
        final isLocalSearch = ref.read(localSearchEnabledProvider);
        if (!isLocalSearch && value.isNotEmpty) {
          ref.read(note_providers.notesNotifierProvider.notifier).refresh();
        }
      },
      onSubmitted: (value) {
        final isLocalSearch = ref.read(localSearchEnabledProvider);
        if (!isLocalSearch) {
          ref.read(note_providers.notesNotifierProvider.notifier).refresh();
        }
      },
    );
  }

  void _handleMoveNoteToServer(String noteId) {
    if (kDebugMode) {
      print(
        '[ItemsScreen] _handleMoveNoteToServer called for note ID: $noteId',
      );
    }

    final multiServerState = ref.read(multiServerConfigProvider);
    final servers = multiServerState.servers;
    final activeServerId = multiServerState.activeServerId;
    final availableTargetServers =
        servers.where((s) => s.id != activeServerId).toList();

    if (kDebugMode) {
      print(
        '[ItemsScreen] Found ${availableTargetServers.length} target servers.',
      );
    }

    if (availableTargetServers.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('No Other Servers'),
          content: const Text(
                'You need to configure at least one other server to move notes.',
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('OK'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
      return;
    }

    showCupertinoModalPopup<ServerConfig>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
            title: const Text('Move Note To...'),
        actions: availableTargetServers.map(
          (server) => CupertinoActionSheetAction(
            child: Text(server.name ?? server.serverUrl),
            onPressed: () {
              if (kDebugMode) {
                            print(
                              '[ItemsScreen] Selected target server: ${server.name ?? server.id}',
                            );
              }
              Navigator.pop(sheetContext, server);
            },
          ),
        ).toList(),
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(sheetContext),
        ),
      ),
    ).then((selectedServer) {
      if (selectedServer != null) {
        if (kDebugMode) {
          print(
            '[ItemsScreen] Calling moveNoteProvider for note $noteId to server ${selectedServer.id}',
          );
        }
        final moveParams = note_providers.MoveNoteParams(
          noteId: noteId,
          targetServer: selectedServer,
        );
        ref
            .read(note_providers.moveNoteProvider(moveParams))()
            .then((_) {
          if (kDebugMode) {
                print('[ItemsScreen] Move successful for note $noteId');
          }
          if (mounted) {
            showCupertinoDialog(
              context: context,
              builder: (ctx) => CupertinoAlertDialog(
                title: const Text('Move Successful'),
                        content: Text(
                          'Note moved to ${selectedServer.name ?? selectedServer.serverUrl}.',
                        ),
                actions: [
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    child: const Text('OK'),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            );
          }
        }).catchError((error, stackTrace) {
          if (kDebugMode) {
                print('[ItemsScreen] Move failed for note $noteId: $error');
            print(stackTrace);
          }
          if (mounted) {
            showCupertinoDialog(
              context: context,
              builder: (ctx) => CupertinoAlertDialog(
                title: const Text('Move Failed'),
                        content: Text(
                          'Could not move note. Error: ${error.toString()}',
                        ),
                actions: [
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    child: const Text('OK'),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            );
          }
        });
      } else {
        if (kDebugMode) {
          print('[ItemsScreen] No target server selected.');
        }
      }
    });
  }

  // Renamed method to reflect it builds the notes list
  // Update signature: Accept the already filtered list
  Widget _buildNotesList(
    note_providers.NotesState notesState,
    List<NoteItem> filteredNotes,
  ) {
    // Determine if we are in the hidden view
    final selectedPresetKey = ref.watch(quickFilterPresetProvider);
    final bool isInHiddenView = selectedPresetKey == 'hidden';

    return NotesListBody(
      scrollController: _scrollController,
      onMoveNoteToServer: _handleMoveNoteToServer,
      notes: filteredNotes,
      notesState: notesState,
      isInHiddenView: isInHiddenView, // Pass the flag
    );
  }

  // --- Start Unhide All Confirmation ---
  void _showUnhideAllConfirmation() {
    final manualHiddenCount = ref.read(
      note_providers.manuallyHiddenNoteCountProvider,
    );
    if (manualHiddenCount == 0) {
      // Optionally show a message if there's nothing to unhide
      return;
    }

    showCupertinoDialog<bool>(
      context: context,
      builder:
          (BuildContext dialogContext) => CupertinoAlertDialog(
            title: const Text('Unhide All Manually Hidden Notes?'),
            content: Text(
              'Are you sure you want to unhide all $manualHiddenCount manually hidden notes? Notes hidden due to future start dates will remain hidden.',
            ),
            actions: <Widget>[
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(dialogContext, false),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Unhide All'),
                onPressed: () => Navigator.pop(dialogContext, true),
              ),
            ],
          ),
    ).then((confirmed) {
      if (confirmed == true) {
        if (kDebugMode) {
          print('[ItemsScreen] Confirmed Unhide All Manually Hidden.');
        }
        ref
            .read(note_providers.unhideAllNotesProvider)()
            .then((_) {
              // Switch back to the 'today' view after unhiding
              if (mounted && ref.read(quickFilterPresetProvider) == 'hidden') {
                ref.read(quickFilterPresetProvider.notifier).state =
                    'today'; // Default back to 'today'
                ref.read(filterPreferencesProvider)('today'); // Save preference
              }
            })
            .catchError((e, s) {
              if (kDebugMode) {
                print('[ItemsScreen] Error during Unhide All: $e\n$s');
              }
              // Show error dialog if needed
            });
      }
    });
  }
  // --- End Unhide All Confirmation ---

  // --- Reset Logic ---
  void _showResetConfirmationDialog() {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (BuildContext dialogContext) => CupertinoAlertDialog(
        title: const Text('Reset All Cloud & Local Data?'),
        content: const Text(
          'WARNING: This will permanently delete ALL Memos server configurations, MCP server configurations, and saved API keys (Todoist, OpenAI, Gemini) from this device AND from your iCloud account.\n\nThis action cannot be undone and is intended for recovery purposes only.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Reset Data'),
            onPressed: () {
              Navigator.pop(dialogContext);
              _performFullReset();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _performFullReset() async {
    if (kDebugMode) {
      print('[ItemsScreen] Starting full data reset...');
    }
    if (!mounted) {
      if (kDebugMode) {
        print('[ItemsScreen] Reset aborted: Widget unmounted before starting.');
      }
      return;
    }
    final cloudKitService = ref.read(cloudKitServiceProvider);

    bool cloudSuccess = true;
    String cloudErrorMessage = '';

    try {
      if (kDebugMode) {
        print('[ItemsScreen] Deleting CloudKit ServerConfig records...');
      }
      bool deleteServersSuccess = await cloudKitService.deleteAllRecordsOfType('ServerConfig');
      if (!deleteServersSuccess) {
        cloudSuccess = false;
        cloudErrorMessage += 'Failed to delete ServerConfig records. ';
        if (kDebugMode) {
          print('[ItemsScreen] Failed CloudKit ServerConfig deletion.');
        }
      }

      if (kDebugMode) {
        print('[ItemsScreen] Deleting CloudKit McpServerConfig records...');
      }
      bool deleteMcpSuccess = await cloudKitService.deleteAllRecordsOfType('McpServerConfig');
      if (!deleteMcpSuccess) {
        cloudSuccess = false;
        cloudErrorMessage += 'Failed to delete McpServerConfig records. ';
        if (kDebugMode) {
          print('[ItemsScreen] Failed CloudKit McpServerConfig deletion.');
        }
      }

      if (kDebugMode) {
        print('[ItemsScreen] Deleting CloudKit UserSettings record...');
      }
      bool deleteSettingsSuccess = await cloudKitService.deleteUserSettingsRecord();
      if (!deleteSettingsSuccess) {
        cloudSuccess = false;
        cloudErrorMessage += 'Failed to delete UserSettings record. ';
        if (kDebugMode) {
          print('[ItemsScreen] Failed CloudKit UserSettings deletion.');
        }
      }

      if (!cloudSuccess) {
        if (kDebugMode) {
          print(
            '[ItemsScreen] CloudKit deletion finished with errors: $cloudErrorMessage',
          );
        }
      } else {
        if (kDebugMode) {
          print('[ItemsScreen] CloudKit deletion finished successfully.');
        }
      }
    } catch (e, s) {
      if (kDebugMode) {
        print(
          '[ItemsScreen] Critical error during CloudKit deletion phase: $e\n$s',
        );
      }
      cloudSuccess = false;
      cloudErrorMessage =
          'A critical error occurred during CloudKit deletion: $e';
    }

    final multiServerNotifier = ref.read(multiServerConfigProvider.notifier);
    final mcpServerNotifier = ref.read(mcpServerConfigProvider.notifier);
    final todoistNotifier = ref.read(todoistApiKeyProvider.notifier);
    final openAiKeyNotifier = ref.read(openAiApiKeyProvider.notifier);
    final openAiModelNotifier = ref.read(openAiModelIdProvider.notifier);
    final geminiNotifier = ref.read(geminiApiKeyProvider.notifier);

    try {
      if (kDebugMode) {
        print('[ItemsScreen] Resetting local notifiers and cache...');
      }
      await multiServerNotifier.resetStateAndCache();
      await mcpServerNotifier.resetStateAndCache();
      await todoistNotifier.clear();
      await openAiKeyNotifier.clear();
      await openAiModelNotifier.clear();
      await geminiNotifier.clear();
      if (kDebugMode) {
        print('[ItemsScreen] Local reset finished.');
      }
    } catch (e, s) {
      if (kDebugMode) {
        print('[ItemsScreen] Error during local notifier reset phase: $e\n$s');
      }
      if (cloudErrorMessage.isNotEmpty) {
        cloudErrorMessage += '\nAn error also occurred during local data reset.';
      } else {
        cloudErrorMessage = 'An error occurred during local data reset.';
        cloudSuccess = false;
      }
    }

    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (BuildContext finalDialogContext) => CupertinoAlertDialog(
          title: Text(cloudSuccess ? 'Reset Complete' : 'Reset Failed'),
          content: Text(
            cloudSuccess
                ? 'All cloud and local configurations have been reset. Please restart the app or navigate to Settings to reconfigure.'
                : 'The reset process encountered errors:\n$cloudErrorMessage\nPlease check your iCloud data manually via Settings > Apple ID > iCloud > Manage Account Storage, then restart the app.'
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(finalDialogContext);
                if (mounted) {
                  ref.invalidate(loadServerConfigProvider);
                  if (kDebugMode) {
                        print(
                          '[ItemsScreen] Reset complete. Invalidated loadServerConfigProvider.',
                        );
                  }
                } else {
                  if (kDebugMode) {
                        print(
                          '[ItemsScreen] Widget unmounted before invalidating loadServerConfigProvider.',
                        );
                  }
                }
              },
            ),
          ],
        ),
      );
    } else {
      if (kDebugMode) {
        print(
          '[ItemsScreen] Widget unmounted before final reset dialog could be shown.',
        );
      }
    }
  }
  // --- End Reset Logic ---
}
