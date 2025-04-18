import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Keep for Tooltip
import 'package:flutter/services.dart';
import 'package:flutter_memos/models/note_item.dart'; // Import NoteItem
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/providers/filter_providers.dart';
// Import note_providers and use families
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/providers/ui_providers.dart' as ui_providers;
import 'package:flutter_memos/screens/items/notes_list_body.dart';
import 'package:flutter_memos/screens/settings_screen.dart'; // Import SettingsScreen
import 'package:flutter_memos/utils/keyboard_navigation.dart';
import 'package:flutter_memos/widgets/advanced_filter_panel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ItemsScreen extends ConsumerStatefulWidget {
  final String serverId; // Add serverId parameter

  const ItemsScreen({
    super.key,
    required this.serverId, // Make serverId required
  });

  @override
  ConsumerState<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends ConsumerState<ItemsScreen>
    with KeyboardNavigationMixin<ItemsScreen> {
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load filter preferences (this seems independent of server)
      ref.read(loadFilterPreferencesProvider);
      // Initial fetch is handled by the provider family upon first watch
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
            print(
              '[ItemsScreen(${widget.serverId})] Exit multi-select via Cancel button',
            );
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
                      // TODO: Implement multi-delete using deleteNoteProviderFamily
                      if (kDebugMode) {
                        print(
                          '[ItemsScreen(${widget.serverId})] Multi-delete action placeholder triggered for $selectedCount items.',
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
                      // TODO: Implement multi-archive using archiveNoteProviderFamily
                    if (kDebugMode) {
                        print(
                          '[ItemsScreen(${widget.serverId})] Multi-archive action placeholder triggered for $selectedCount items.',
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

  // Helper to get the current server config based on widget.serverId
  ServerConfig? _getCurrentServerConfig() {
    final servers = ref.read(multiServerConfigProvider).servers;
    try {
      return servers.firstWhere((s) => s.id == widget.serverId);
    } catch (e) {
      return null; // Server not found
    }
  }

  void _selectNextNote() {
    // Use the provider family with the current serverId
    final notes = ref.read(
      note_providers.filteredNotesProviderFamily(widget.serverId),
    );
    if (kDebugMode) {
      // print('[ItemsScreen(${widget.serverId}) _selectNextNote] Called. Filtered notes count: ${notes.length}');
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
        // print('[ItemsScreen(${widget.serverId}) _selectNextNote] Updated selectedItemIdProvider to: $nextNoteId');
      }
    }
  }

  void _selectPreviousNote() {
    // Use the provider family with the current serverId
    final notes = ref.read(
      note_providers.filteredNotesProviderFamily(widget.serverId),
    );
    if (kDebugMode) {
      // print('[ItemsScreen(${widget.serverId}) _selectPreviousNote] Called. Filtered notes count: ${notes.length}');
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
        // print('[ItemsScreen(${widget.serverId}) _selectPreviousNote] Updated selectedItemIdProvider to: $prevNoteId');
      }
    }
  }

  void _viewSelectedItem() {
    final selectedId = ref.read(ui_providers.selectedItemIdProvider);
    if (selectedId != null) {
      if (kDebugMode) {
        print(
          '[ItemsScreen(${widget.serverId})] Viewing selected item: ID $selectedId',
        );
      }
      if (mounted) {
        // Pass serverId to detail screen
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushNamed(
          '/item-detail',
          arguments: {
            'itemId': selectedId,
            'serverId': widget.serverId, // Pass serverId
          },
        );
      }
    }
  }

  void _clearSelectionOrUnfocus() {
    final selectedId = ref.read(ui_providers.selectedItemIdProvider);
    if (selectedId != null) {
      if (kDebugMode) {
        print(
          '[ItemsScreen(${widget.serverId})] Clearing selection via Escape',
        );
      }
      ref.read(ui_providers.selectedItemIdProvider.notifier).state = null;
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // if (kDebugMode) {
    //   print('[ItemsScreen(${widget.serverId}) _handleKeyEvent] Received key: ${event.logicalKey.keyLabel}');
    //   print('[ItemsScreen(${widget.serverId}) _handleKeyEvent] FocusNode has focus: ${node.hasFocus}');
    // }

    final result = handleKeyEvent(
      event,
      ref,
      onUp: _selectPreviousNote,
      onDown: _selectNextNote,
      onSubmit: _viewSelectedItem,
      onEscape: _clearSelectionOrUnfocus,
    );

    // if (kDebugMode) {
    //   print('[ItemsScreen(${widget.serverId}) _handleKeyEvent] Mixin handleKeyEvent result: $result');
    // }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    // Use provider families with widget.serverId
    final notesState = ref.watch(
      note_providers.notesNotifierProviderFamily(widget.serverId),
    );
    final visibleNotes = ref.watch(
      note_providers.filteredNotesProviderFamily(widget.serverId),
    );
    final selectedPresetKey = ref.watch(quickFilterPresetProvider);
    final currentPresetLabel =
        quickFilterPresets[selectedPresetKey]?.label ??
        'Notes'; // Changed default label
    final isMultiSelectMode = ref.watch(ui_providers.itemMultiSelectModeProvider);
    final selectedIds = ref.watch(ui_providers.selectedItemIdsForMultiSelectProvider);
    final hiddenCount = ref.watch(
      note_providers.totalHiddenNoteCountProviderFamily(widget.serverId),
    );
    final showHidden = ref.watch(showHiddenNotesProvider);
    final theme = CupertinoTheme.of(context);
    final currentServer =
        _getCurrentServerConfig(); // Get current server info for title

    // Handle case where server config might be missing (e.g., deleted while screen is open)
    if (currentServer == null) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('Error'),
          previousPageTitle: 'Servers', // Allow navigating back
        ),
        child: Center(child: Text('Server configuration not found.')),
      );
    }


    return CupertinoPageScaffold(
      navigationBar: isMultiSelectMode
          ? _buildMultiSelectNavBar(selectedIds.length)
          : CupertinoNavigationBar(
                // REMOVED leading: _buildServerSwitcherButton(),
                // Use previousPageTitle for automatic back button text (points back to Hub)
                previousPageTitle: 'Servers',
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
                    // Show server name in title, fallback to preset label
                    child: Text(
                      currentServer.name ?? // Use non-null currentServer
                          currentServer.serverUrl,
                      overflow: TextOverflow.ellipsis,
                    ),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                    // Existing buttons (Multi-select, Hidden toggle, Filter, Add)
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
                      onPressed: () => _showAdvancedFilterPanel(context),
                    child: const Icon(CupertinoIcons.tuningfork),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    minSize: 0,
                    onPressed: () {
                        // Pass serverId to new note screen
                      Navigator.of(
                        context,
                        rootNavigator: true,
                        ).pushNamed(
                          '/new-note',
                          arguments: {'serverId': widget.serverId},
                        );
                    },
                    child: const Icon(CupertinoIcons.add),
                  ),
                    // REMOVED Reset Button
                    // New Settings Button (might be redundant if Hub has it)
                  CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                      ), // Adjust padding as needed
                    minSize: 0,
                      child: const Icon(
                        CupertinoIcons.settings,
                        size: 22,
                      ), // Gear icon
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).push(
                          // Use root navigator
                          CupertinoPageRoute(
                            builder:
                                (context) =>
                                    const SettingsScreen(isInitialSetup: false),
                          ),
                        );
                      },
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
                            'Unhide All Manually Hidden (${ref.watch(note_providers.manuallyHiddenNoteCountProviderFamily(widget.serverId))})', // Use family
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
              print(
                '[ItemsScreen(${widget.serverId})] Quick filter selected: $newPresetKey',
              );
            }
            ref.read(quickFilterPresetProvider.notifier).state = newPresetKey;
            // Clear raw filter if a preset is selected
            if (ref.read(rawCelFilterProvider).isNotEmpty) {
              ref.read(rawCelFilterProvider.notifier).state = '';
            }
            // Save the selected preset preference
            ref.read(filterPreferencesProvider)(newPresetKey);
            // Refresh is handled by the provider listening to quickFilterPresetProvider
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
        // Pass serverId to the panel if it needs it for filtering options
        return ProviderScope(
          overrides: [
            // Example: Override a provider within the panel if needed
            // currentServerIdProvider.overrideWithValue(widget.serverId),
          ],
          child: DraggableScrollableSheet(
            initialChildSize: 0.8,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, scrollController) {
              return AdvancedFilterPanel(onClose: () => Navigator.pop(context));
            },
          ),
        );
      },
    );
  }

  // REMOVED _buildServerSwitcherButton()
  // REMOVED _showServerSelectionSheet()

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
        // Refresh is handled by the provider listening to searchQueryProvider
      },
      onSubmitted: (value) {
        // Refresh is handled by the provider listening to searchQueryProvider
      },
    );
  }

  void _handleMoveNoteToServer(String noteId) {
    if (kDebugMode) {
      print(
        '[ItemsScreen(${widget.serverId})] _handleMoveNoteToServer called for note ID: $noteId from server: ${widget.serverId}',
      );
    }

    final multiServerState = ref.read(multiServerConfigProvider);
    final servers = multiServerState.servers;
    // Use widget.serverId as the source server
    final availableTargetServers =
        servers.where((s) => s.id != widget.serverId).toList();

    if (kDebugMode) {
      print(
        '[ItemsScreen(${widget.serverId})] Found ${availableTargetServers.length} target servers.',
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
                              '[ItemsScreen(${widget.serverId})] Selected target server: ${server.name ?? server.id}',
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
            '[ItemsScreen(${widget.serverId})] Calling moveNoteProvider for note $noteId from ${widget.serverId} to server ${selectedServer.id}',
          );
        }
        // Pass sourceServerId to MoveNoteParams
        final moveParams = note_providers.MoveNoteParams(
          noteId: noteId,
          sourceServerId: widget.serverId, // Pass source server ID
          targetServer: selectedServer,
        );
        // Call the moveNoteProvider family
        ref
            .read(note_providers.moveNoteProvider(moveParams))()
            .then((_) {
          if (kDebugMode) {
                print(
                  '[ItemsScreen(${widget.serverId})] Move successful for note $noteId',
                );
          }
          if (mounted) {
                // Maybe pop back to hub after successful move? Or just show success.
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
                print(
                  '[ItemsScreen(${widget.serverId})] Move failed for note $noteId: $error',
                );
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
          print('[ItemsScreen(${widget.serverId})] No target server selected.');
        }
      }
    });
  }

  // Renamed method to reflect it builds the notes list
  // Update signature: Accept the already filtered list
  Widget _buildNotesList(
    note_providers.NotesState notesState, // This state is now server-specific
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
      serverId: widget.serverId, // Pass serverId
    );
  }

  // --- Start Unhide All Confirmation ---
  void _showUnhideAllConfirmation() {
    final manualHiddenCount = ref.read(
      note_providers.manuallyHiddenNoteCountProviderFamily(
        widget.serverId,
      ), // Use family
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
              'Are you sure you want to unhide all $manualHiddenCount manually hidden notes on this server? Notes hidden due to future start dates will remain hidden.',
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
          print(
            '[ItemsScreen(${widget.serverId})] Confirmed Unhide All Manually Hidden.',
          );
        }
        // Use the provider family instance
        ref
            .read(
              note_providers.unhideAllNotesProviderFamily(widget.serverId),
            )()
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
                print(
                  '[ItemsScreen(${widget.serverId})] Error during Unhide All: $e\n$s',
                );
              }
              // Show error dialog if needed
            });
      }
    });
  }
  // --- End Unhide All Confirmation ---

  // --- REMOVED Reset Logic ---
}
