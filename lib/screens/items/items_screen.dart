import 'dart:async';

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
  // Flag to control internal navigation bar visibility
  final bool showNavigationBar;

  // Remove presetKey, add showNavigationBar
  const ItemsScreen({super.key, this.showNavigationBar = true});

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

      // Removed logic that set quickFilterPresetProvider based on widget.presetKey

      // Load saved preferences (will default to 'today' if invalid preset was saved)
      ref.read(loadFilterPreferencesProvider);

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
        // Ensure the active notifier (potentially overridden) is initialized/refreshed
        ref.read(
          note_providers.notesNotifierProvider,
        );
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
    // This remains unchanged as multi-select is independent of cache/vault logic
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
    // Use the active notes provider (could be generic, cache, or vault)
    final notes = ref.read(
      note_providers.filteredNotesProvider,
    );
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
    // Use the active notes provider
    final notes = ref.read(
      note_providers.filteredNotesProvider,
    );
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
        // Use rootNavigator: true to ensure the root route handler is used
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
      // Only show nav bar if requested by the widget parameter
      final navBar =
          widget.showNavigationBar
              ? const CupertinoNavigationBar(middle: Text('Notes'))
              : null;
      return CupertinoPageScaffold(
        navigationBar: navBar,
        child: const Center(child: Text('No Note Server Configured')),
      );
    }
    // Use the active notesNotifierProvider (could be generic or overridden)
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
      final navBar =
          widget.showNavigationBar
              ? const CupertinoNavigationBar(middle: Text('Error'))
              : null;
      return CupertinoPageScaffold(
        navigationBar: navBar,
        child: const Center(child: Text('Server configuration not found.')),
      );
    }

    // Determine the title based on the preset key or server name
    // This title is only used if widget.showNavigationBar is true
    String screenTitle;
    // Removed checks for widget.presetKey == 'cache'/'vault'
    final preset = quickFilterPresets[selectedPresetKey];
    if (preset != null) {
      screenTitle = preset.label;
    } else {
      // Fallback to server name/URL if preset not found or is a tag etc.
      screenTitle = currentServer.name ?? currentServer.serverUrl;
    }

    // Build the navigation bar only if requested
    final navBar =
        !widget.showNavigationBar
            ? null
            : isMultiSelectMode
            ? _buildMultiSelectNavBar(selectedIds.length)
            : CupertinoNavigationBar(
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
                                  : CupertinoColors.secondaryLabel.resolveFrom(
                                    context,
                                  ),
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
                          // Use rootNavigator: true for named route
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
                          // Use rootNavigator: true for page route
                          () => Navigator.of(context, rootNavigator: true).push(
                          CupertinoPageRoute(
                            builder:
                                (context) =>
                                    const SettingsScreen(isInitialSetup: false),
                          ),
                        ),
                    ),
                ],
              ),
            );

    // Determine if quick filters should be shown
    // Show if nav bar is shown AND it's not multi-select mode AND no type is forced
    final bool showQuickFilters =
        widget.showNavigationBar &&
        !isMultiSelectMode &&
        notesState.forcedBlinkoType == null;

    return CupertinoPageScaffold(
      navigationBar: navBar, // Use the conditionally built navBar
      child: SafeArea(
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: Column(
            children: [
              // Show search bar if nav bar is shown and not multi-select
              if (widget.showNavigationBar && !isMultiSelectMode)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
                  child: _buildSearchBar(),
                ),
              // Show quick filters conditionally
              if (showQuickFilters)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                  child: _buildQuickFilterControl(),
                ),
              // Show hidden count info only if nav bar is shown and relevant
              if (widget.showNavigationBar &&
                  !isMultiSelectMode &&
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
              // Show unhide all button only if nav bar is shown and relevant
              if (widget.showNavigationBar &&
                  !isMultiSelectMode &&
                  selectedPresetKey == 'hidden')
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

  Widget _buildQuickFilterControl() {
    final selectedPresetKey = ref.watch(quickFilterPresetProvider);
    final theme = CupertinoTheme.of(context);
    // Define the order and available presets for the general view
    // Excluded 'cache' and 'vault'
    const List<String> desiredOrder = [
      'today',
      'inbox',
      'all',
      'hidden',
    ];
    final Map<String, Widget> segments = {};
    for (var key in desiredOrder) {
      final preset = quickFilterPresets[key];
      // Only include presets relevant for the general segmented control
      if (preset != null && preset.key != 'custom') {
        // Removed cache/vault check
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
            // Refresh the active notes provider
            ref.read(note_providers.notesNotifierProvider.notifier).refresh();
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
        // No ProviderScope override needed here as it uses the default providers
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder:
              (_, scrollController) =>
                  AdvancedFilterPanel(onClose: () => Navigator.pop(context)),
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
    // Debounced search trigger
    Timer? debounce;
    return CupertinoSearchTextField(
      controller: controller,
      placeholder: 'Search notes...',
      style: TextStyle(color: CupertinoColors.label.resolveFrom(context)),
      decoration: BoxDecoration(
        color: CupertinoColors.systemFill.resolveFrom(context),
        borderRadius: BorderRadius.circular(10.0),
      ),
      onChanged: (value) {
        if (debounce?.isActive ?? false) debounce?.cancel();
        debounce = Timer(const Duration(milliseconds: 300), () {
          if (mounted) {
            ref.read(searchQueryProvider.notifier).state = value;
            // Refresh the active notes provider when search changes
            ref.read(note_providers.notesNotifierProvider.notifier).refresh();
          }
        });
      },
      onSubmitted: (value) {
        if (debounce?.isActive ?? false) debounce?.cancel();
        ref.read(searchQueryProvider.notifier).state = value;
        // Refresh immediately on submit
        ref.read(note_providers.notesNotifierProvider.notifier).refresh();
      },
    );
  }

  // Removed _handleMoveNoteToServer as moveNoteProvider was removed

  Widget _buildNotesList(
    note_providers.NotesState notesState,
    List<NoteItem> filteredNotes,
  ) {
    final selectedPresetKey = ref.watch(quickFilterPresetProvider);
    // isInHiddenView is only relevant if the generic provider is active
    final bool isInHiddenView =
        notesState.forcedBlinkoType == null && selectedPresetKey == 'hidden';
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
    // Use the active notes provider
    final manualHiddenCount = ref.read(
      note_providers.manuallyHiddenNoteCountProvider,
    );
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
        // Use the active notes provider's unhide action
        ref
            .read(note_providers.unhideAllNotesProvider)()
            .then((_) {
              // If currently in hidden view (only possible for generic provider), switch back
              if (mounted && ref.read(quickFilterPresetProvider) == 'hidden') {
                final targetPreset = 'today'; // Default back to today
                ref.read(quickFilterPresetProvider.notifier).state =
                    targetPreset;
                ref.read(filterPreferencesProvider)(targetPreset);
                // Refresh is handled by unhideAllNotesProvider
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
