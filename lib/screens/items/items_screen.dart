import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Keep for Tooltip
import 'package:flutter/services.dart';
import 'package:flutter_memos/models/note_item.dart'; // Import NoteItem
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/providers/filter_providers.dart';
// Import note_providers and use families
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
// Import new single config provider
import 'package:flutter_memos/providers/note_server_config_provider.dart';
import 'package:flutter_memos/providers/ui_providers.dart' as ui_providers;
import 'package:flutter_memos/screens/items/notes_list_body.dart';
import 'package:flutter_memos/screens/settings_screen.dart'; // Import SettingsScreen
import 'package:flutter_memos/utils/keyboard_navigation.dart';
import 'package:flutter_memos/widgets/advanced_filter_panel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ItemsScreen extends ConsumerStatefulWidget {
  // Optional key to initialize the filter preset for this screen instance
  final String? presetKey;

  // Remove serverId from constructor, add presetKey
  const ItemsScreen({super.key, this.presetKey});

  @override
  ConsumerState<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends ConsumerState<ItemsScreen>
    with KeyboardNavigationMixin<ItemsScreen> {
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  String? _effectiveServerId; // Store the serverId from the provider

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateEffectiveServerId(); // Determine serverId initially
      // Initialize filter based on presetKey if provided
      if (widget.presetKey != null &&
          quickFilterPresets.containsKey(widget.presetKey)) {
        // Check if the current preset is different before updating
        final currentPreset = ref.read(quickFilterPresetProvider);
        if (currentPreset != widget.presetKey) {
          ref.read(quickFilterPresetProvider.notifier).state =
              widget.presetKey!;
          // Optionally clear other filters when a preset is applied via constructor
          ref.read(rawCelFilterProvider.notifier).state = '';
          ref.read(searchQueryProvider.notifier).state = '';
          // Persist this initial preset if desired
          ref.read(filterPreferencesProvider)(widget.presetKey!);
          if (kDebugMode) {
            print(
              '[ItemsScreen] Initialized with presetKey: ${widget.presetKey}',
            );
          }
        }
      } else {
        // Load saved preferences if no specific preset is passed
        ref.read(loadFilterPreferencesProvider);
      }
      if (mounted) FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateEffectiveServerId(); // Update if dependencies change
  }

  void _updateEffectiveServerId() {
    // Get serverId directly from the single note provider
    final newServerId = ref.read(noteServerConfigProvider)?.id;
    if (_effectiveServerId != newServerId) {
      setState(() {
        _effectiveServerId = newServerId;
      });
      // If serverId changes, we might need to refresh data or handle state transition
      if (newServerId != null) {
        // Trigger initial fetch if needed for the new serverId
        // The provider family might handle this automatically if watched correctly
        ref.read(
          note_providers.notesNotifierProvider,
        ); // Ensure notifier is initialized
      }
    }
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
          if (kDebugMode)
            print('[ItemsScreen] Exit multi-select via Cancel button');
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
            onPressed:
                selectedCount > 0
                    ? () {
                      // TODO: Implement multi-delete using deleteNoteProvider
                      if (kDebugMode)
                        print(
                          '[ItemsScreen] Multi-delete action placeholder triggered for $selectedCount items.',
                        );
                    }
                    : null,
            child: Icon(
              CupertinoIcons.delete,
              color:
                  selectedCount > 0
                      ? CupertinoColors.destructiveRed
                      : CupertinoColors.inactiveGray,
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            minSize: 0,
            onPressed:
                selectedCount > 0
                    ? () {
                      // TODO: Implement multi-archive using archiveNoteProvider
                      if (kDebugMode)
                        print(
                          '[ItemsScreen] Multi-archive action placeholder triggered for $selectedCount items.',
                        );
                    }
                    : null,
            child: Icon(
              CupertinoIcons.archivebox,
              color:
                  selectedCount > 0
                      ? CupertinoTheme.of(context).primaryColor
                      : CupertinoColors.inactiveGray,
            ),
          ),
        ],
      ),
    );
  }

  // Helper to get the current server config
  ServerConfig? _getCurrentServerConfig() {
    return ref.read(noteServerConfigProvider);
  }

  void _selectNextNote() {
    if (_effectiveServerId == null) return;
    final notes = ref.read(
      note_providers.filteredNotesProvider,
    ); // Use non-family provider
    if (kDebugMode)
      print(
        '[ItemsScreen($_effectiveServerId) _selectNextNote] Called. Filtered notes count: ${notes.length}',
      );
    if (notes.isEmpty) return;
    final currentId = ref.read(ui_providers.selectedItemIdProvider);
    int currentIndex =
        currentId != null
            ? notes.indexWhere((note) => note.id == currentId)
            : -1;
    final nextIndex = getNextIndex(currentIndex, notes.length);
    if (nextIndex != -1) {
      final nextNoteId = notes[nextIndex].id;
      ref.read(ui_providers.selectedItemIdProvider.notifier).state = nextNoteId;
      if (kDebugMode)
        print(
          '[ItemsScreen($_effectiveServerId) _selectNextNote] Updated selectedItemIdProvider to: $nextNoteId',
        );
    }
  }

  void _selectPreviousNote() {
    if (_effectiveServerId == null) return;
    final notes = ref.read(
      note_providers.filteredNotesProvider,
    ); // Use non-family provider
    if (kDebugMode)
      print(
        '[ItemsScreen($_effectiveServerId) _selectPreviousNote] Called. Filtered notes count: ${notes.length}',
      );
    if (notes.isEmpty) return;
    final currentId = ref.read(ui_providers.selectedItemIdProvider);
    int currentIndex =
        currentId != null
            ? notes.indexWhere((note) => note.id == currentId)
            : -1;
    final prevIndex = getPreviousIndex(currentIndex, notes.length);
    if (prevIndex != -1) {
      final prevNoteId = notes[prevIndex].id;
      ref.read(ui_providers.selectedItemIdProvider.notifier).state = prevNoteId;
      if (kDebugMode)
        print(
          '[ItemsScreen($_effectiveServerId) _selectPreviousNote] Updated selectedItemIdProvider to: $prevNoteId',
        );
    }
  }

  void _viewSelectedItem() {
    if (_effectiveServerId == null) return;
    final selectedId = ref.read(ui_providers.selectedItemIdProvider);
    if (selectedId != null) {
      if (kDebugMode)
        print(
          '[ItemsScreen($_effectiveServerId)] Viewing selected item: ID $selectedId',
        );
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushNamed(
          '/item-detail',
          arguments: {
            'itemId': selectedId,
          }, // serverId no longer needed in args
        );
      }
    }
  }

  void _clearSelectionOrUnfocus() {
    final selectedId = ref.read(ui_providers.selectedItemIdProvider);
    if (selectedId != null) {
      if (kDebugMode)
        print(
          '[ItemsScreen($_effectiveServerId)] Clearing selection via Escape',
        );
      ref.read(ui_providers.selectedItemIdProvider.notifier).state = null;
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final result = handleKeyEvent(
      event,
      ref,
      onUp: _selectPreviousNote,
      onDown: _selectNextNote,
      onSubmit: _viewSelectedItem,
      onEscape: _clearSelectionOrUnfocus,
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    // Ensure serverId is available before building UI that depends on it
    if (_effectiveServerId == null) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('Notes')),
        child: Center(child: Text('No Note Server Configured')),
      );
    }
    // Use the single notesNotifierProvider
    final notesState = ref.watch(note_providers.notesNotifierProvider);
    final visibleNotes = ref.watch(note_providers.filteredNotesProvider);
    final selectedPresetKey = ref.watch(quickFilterPresetProvider);
    final isMultiSelectMode = ref.watch(ui_providers.itemMultiSelectModeProvider);
    final selectedIds = ref.watch(ui_providers.selectedItemIdsForMultiSelectProvider);
    final hiddenCount = ref.watch(note_providers.totalHiddenNoteCountProvider);
    final showHidden = ref.watch(showHiddenNotesProvider);
    final theme = CupertinoTheme.of(context);
    final currentServer = _getCurrentServerConfig(); // Get current server info

    // Handle case where server config might become null after initial check
    if (currentServer == null) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('Error')),
        child: Center(child: Text('Server configuration not found.')),
      );
    }

    // Determine the title based on the preset key or server name
    String screenTitle = currentServer.name ?? currentServer.serverUrl;
    if (widget.presetKey != null) {
      final preset = quickFilterPresets[widget.presetKey];
      if (preset != null) {
        screenTitle = preset.label; // Use preset label for title
      }
    }


    return CupertinoPageScaffold(
      navigationBar: isMultiSelectMode
          ? _buildMultiSelectNavBar(selectedIds.length)
              : CupertinoNavigationBar(
              middle: GestureDetector(
                  onTap: () {
                    if (_scrollController.hasClients)
                      _scrollController.animateTo(
                        0.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                  },
                child: Container(
                  color: CupertinoColors.transparent,
                    child: Text(
                      screenTitle, // Use dynamic title
                      overflow: TextOverflow.ellipsis,
                    ),
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
                      child: const Icon(CupertinoIcons.checkmark_seal),
                    ),
                    if (hiddenCount > 0)
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        minSize: 0,
                        onPressed:
                            () => ref
                                .read(showHiddenNotesProvider.notifier)
                                .update((state) => !state),
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
                      onPressed:
                          () => Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pushNamed('/new-note'),
                      child: const Icon(CupertinoIcons.add),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      minSize: 0,
                      child: const Icon(CupertinoIcons.settings, size: 22),
                      onPressed:
                          () => Navigator.of(context, rootNavigator: true).push(
                            CupertinoPageRoute(
                              builder:
                                  (context) => const SettingsScreen(
                                    isInitialSetup: false,
                                  ),
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
              // Only show quick filters if no specific preset was forced via constructor
              if (!isMultiSelectMode && widget.presetKey == null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                  child: _buildQuickFilterControl(),
                ),
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
                          ), // Use non-family provider
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

  Widget _buildQuickFilterControl() {
    final selectedPresetKey = ref.watch(quickFilterPresetProvider);
    final theme = CupertinoTheme.of(context);
    // Define the order and available presets for the general view
    const List<String> desiredOrder = [
      'today',
      'inbox',
      'all',
      'hidden',
    ]; // Example order
    final Map<String, Widget> segments = {};
    for (var key in desiredOrder) {
      final preset = quickFilterPresets[key];
      // Only include presets relevant for the general segmented control
      if (preset != null &&
          preset.key != 'custom' &&
          preset.key != 'cache' &&
          preset.key != 'vault') {
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
    // If no relevant presets found, don't build the control
    if (segments.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<String>(
        children: segments,
        groupValue: selectedPresetKey == 'custom' ? null : selectedPresetKey,
        thumbColor: theme.primaryColor,
        backgroundColor: CupertinoColors.secondarySystemFill.resolveFrom(
          context,
        ),
        onValueChanged: (String? newPresetKey) {
          if (newPresetKey != null) {
            if (kDebugMode)
              print(
                '[ItemsScreen($_effectiveServerId)] Quick filter selected: $newPresetKey',
              );
            ref.read(quickFilterPresetProvider.notifier).state = newPresetKey;
            if (ref.read(rawCelFilterProvider).isNotEmpty)
              ref.read(rawCelFilterProvider.notifier).state = '';
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
        return ProviderScope(
          overrides: [], // No serverId override needed here
          child: DraggableScrollableSheet(
            initialChildSize: 0.8,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder:
                (_, scrollController) =>
                    AdvancedFilterPanel(onClose: () => Navigator.pop(context)),
          ),
        );
      },
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
      onChanged:
          (value) => ref.read(searchQueryProvider.notifier).state = value,
      onSubmitted: (value) {},
    );
  }

  // Removed _handleMoveNoteToServer as moveNoteProvider was removed

  Widget _buildNotesList(
    note_providers.NotesState notesState,
    List<NoteItem> filteredNotes,
  ) {
    final selectedPresetKey = ref.watch(quickFilterPresetProvider);
    final bool isInHiddenView = selectedPresetKey == 'hidden';
    return NotesListBody(
      scrollController: _scrollController,
      // onMoveNoteToServer: _handleMoveNoteToServer, // Removed
      notes: filteredNotes,
      notesState: notesState,
      isInHiddenView: isInHiddenView,
      // serverId: _effectiveServerId!, // Removed serverId parameter
    );
  }

  void _showUnhideAllConfirmation() {
    final manualHiddenCount = ref.read(
      note_providers.manuallyHiddenNoteCountProvider,
    ); // Use non-family provider
    if (manualHiddenCount == 0) return;
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
        if (kDebugMode)
          print(
            '[ItemsScreen($_effectiveServerId)] Confirmed Unhide All Manually Hidden.',
          );
        ref
            .read(note_providers.unhideAllNotesProvider)()
            .then((_) {
              // Use non-family provider
              if (mounted && ref.read(quickFilterPresetProvider) == 'hidden') {
                // Decide where to navigate after unhiding all - maybe 'today' or 'all'
                final targetPreset = widget.presetKey ?? 'today';
                ref.read(quickFilterPresetProvider.notifier).state =
                    targetPreset;
                ref.read(filterPreferencesProvider)(targetPreset);
              }
            })
            .catchError((e, s) {
              if (kDebugMode)
                print(
                  '[ItemsScreen($_effectiveServerId)] Error during Unhide All: $e\n$s',
                );
            });
      }
    });
  }
}
