import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Keep for Tooltip
import 'package:flutter/services.dart';
import 'package:flutter_memos/models/note_item.dart'; // Import NoteItem
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/providers/filter_providers.dart';
// Import note_providers families
import 'package:flutter_memos/providers/note_providers.dart' as note_p;
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
  // Type parameter to determine which notes to show (null for generic)
  final BlinkoNoteType? type;

  const ItemsScreen({
    super.key,
    this.showNavigationBar = true,
    this.type, // Add type parameter
  });

  @override
  ConsumerState<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends ConsumerState<ItemsScreen>
    with KeyboardNavigationMixin<ItemsScreen> {
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  // Removed _effectiveServerId, server config is fetched directly when needed

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load saved preferences only for the generic view
      if (widget.type == null) {
        ref.read(loadFilterPreferencesProvider);
      } else {
        // For Cache/Vault, maybe reset filters or set a default?
        // For now, let's assume they inherit global filters unless explicitly set otherwise.
      }

      // Initial fetch is handled by the notesNotifierFamily provider itself
      // Ensure the correct family instance is watched/read early if needed.
      ref.read(note_p.notesNotifierFamily(widget.type));

      if (mounted) FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Helper to get the current server config (remains useful)
  ServerConfig? _getCurrentServerConfig() {
    return ref.read(noteServerConfigProvider);
  }

  // --- Action Handlers (Now include optimistic updates) ---

  Future<void> _handleArchiveNote(String noteId) async {
    final notifier = ref.read(note_p.notesNotifierFamily(widget.type).notifier);
    final currentSelectedId = ref.read(ui_providers.selectedItemIdProvider);
    final notesBeforeAction = ref.read(note_p.filteredNotesFamily(widget.type));
    String? nextSelectedId = currentSelectedId;

    // Determine next selection before optimistic update
    if (currentSelectedId == noteId && notesBeforeAction.isNotEmpty) {
      final actionIndex = notesBeforeAction.indexWhere((n) => n.id == noteId);
      if (actionIndex != -1) {
        if (notesBeforeAction.length == 1) {
          nextSelectedId = null;
        } else if (actionIndex < notesBeforeAction.length - 1) {
          nextSelectedId = notesBeforeAction[actionIndex + 1].id;
        } else {
          nextSelectedId = notesBeforeAction[actionIndex - 1].id;
        }
      } else {
        nextSelectedId = null;
      }
    }

    // Optimistic UI update
    notifier.archiveNoteOptimistically(noteId);
    ref.read(ui_providers.selectedItemIdProvider.notifier).state = nextSelectedId;

    // API Call
    try {
      // Use the API provider which returns a callable function
      await ref.read(note_p.archiveNoteApiProvider(noteId))();
      // Success: UI already updated
    } catch (e) {
      if (kDebugMode) print('[ItemsScreen] Error archiving note $noteId: $e');
      // Revert or refresh on error
      notifier.refresh();
      // Optionally show error message
    }
  }

  Future<void> _handleDeleteNote(String noteId) async {
    final notifier = ref.read(note_p.notesNotifierFamily(widget.type).notifier);
    final currentSelectedId = ref.read(ui_providers.selectedItemIdProvider);
    final notesBeforeAction = ref.read(note_p.filteredNotesFamily(widget.type));
    String? nextSelectedId = currentSelectedId;

    // Determine next selection
    if (currentSelectedId == noteId && notesBeforeAction.isNotEmpty) {
       final actionIndex = notesBeforeAction.indexWhere((n) => n.id == noteId);
       if (actionIndex != -1) {
         if (notesBeforeAction.length == 1) {
           nextSelectedId = null;
         } else if (actionIndex < notesBeforeAction.length - 1) {
           nextSelectedId = notesBeforeAction[actionIndex + 1].id;
         } else {
           nextSelectedId = notesBeforeAction[actionIndex - 1].id;
         }
       } else {
         nextSelectedId = null;
       }
     }

    // Optimistic UI update
    notifier.removeNoteOptimistically(noteId);
    ref.read(ui_providers.selectedItemIdProvider.notifier).state = nextSelectedId;

    // API Call
    try {
      // Use the API provider which returns a callable function
      await ref.read(note_p.deleteNoteApiProvider(noteId))();
      // Success: UI already updated
    } catch (e) {
      if (kDebugMode) print('[ItemsScreen] Error deleting note $noteId: $e');
      // Revert or refresh on error
      notifier.refresh();
      // Optionally show error message
    }
  }

  Future<void> _handleTogglePinNote(String noteId) async {
     final notifier = ref.read(note_p.notesNotifierFamily(widget.type).notifier);

     // Optimistic UI update
     notifier.togglePinOptimistically(noteId);

     // API Call
     try {
       // Use the API provider which returns a callable function
       await ref.read(note_p.togglePinNoteApiProvider(noteId))();
       // Success: UI already updated
     } catch (e) {
       if (kDebugMode) print('[ItemsScreen] Error toggling pin for note $noteId: $e');
       // Revert or refresh on error
       notifier.refresh();
       // Optionally show error message
     }
   }

   Future<void> _handleBumpNote(String noteId) async {
      final notifier = ref.read(note_p.notesNotifierFamily(widget.type).notifier);

      // Optimistic UI update
      notifier.bumpNoteOptimistically(noteId);

      // API Call
      try {
        // Use the API provider which returns a callable function
        await ref.read(note_p.bumpNoteApiProvider(noteId))();
        // Success: UI already updated
      } catch (e) {
        if (kDebugMode) print('[ItemsScreen] Error bumping note $noteId: $e');
        // Revert or refresh on error
        notifier.refresh();
        // Optionally show error message
      }
    }

    Future<void> _handleUpdateNoteStartDate(String noteId, DateTime? newStartDate) async {
       final notifier = ref.read(note_p.notesNotifierFamily(widget.type).notifier);
       final originalNote = notifier.state.notes.firstWhere((n) => n.id == noteId, orElse: () => throw Exception("Note not found")); // Need original for revert

       // Optimistic UI update
       notifier.updateNoteStartDateOptimistically(noteId, newStartDate);

       // API Call (using the generic update provider)
       try {
         final updatedNoteData = originalNote.copyWith(startDate: newStartDate); // Prepare data for API
         // Use the API provider which returns a callable function
         await ref.read(note_p.updateNoteApiProvider(noteId))(updatedNoteData);
         // Success: UI already updated
       } catch (e) {
         if (kDebugMode) print('[ItemsScreen] Error updating start date for note $noteId: $e');
         // Revert UI on error
         notifier.updateNoteOptimistically(originalNote); // Revert to original state
         // Optionally show error message
       }
     }

  // --- Multi-Select Navigation Bar ---
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
            onPressed: selectedCount > 0 ? () async {
              final selectedIdsList = ref.read(ui_providers.selectedItemIdsForMultiSelectProvider).toList();
              if (kDebugMode) print('[ItemsScreen] Multi-delete action triggered for $selectedCount items.');
              // Show confirmation dialog
              final confirmed = await showCupertinoDialog<bool>(
                context: context,
                builder: (context) => CupertinoAlertDialog(
                  title: Text('Delete $selectedCount Notes?'),
                  content: const Text('Are you sure you want to permanently delete the selected notes?'),
                  actions: [
                    CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(context, false)),
                    CupertinoDialogAction(isDestructiveAction: true, child: const Text('Delete'), onPressed: () => Navigator.pop(context, true)),
                  ],
                ),
              );
              if (confirmed == true && mounted) {
                final notifier = ref.read(note_p.notesNotifierFamily(widget.type).notifier);
                // Optimistic removal
                for (final id in selectedIdsList) {
                  notifier.removeNoteOptimistically(id);
                }
                // Use the re-added clearMultiSelectProvider
                ref.read(ui_providers.clearMultiSelectProvider)(); // Clear selection UI
                ref.read(ui_providers.toggleItemMultiSelectModeProvider)(); // Exit multi-select mode

                // Perform API calls
                List<String> failedDeletes = [];
                for (final id in selectedIdsList) {
                  try {
                    // Use the API provider which returns a callable function
                    await ref.read(note_p.deleteNoteApiProvider(id))();
                  } catch (e) {
                    failedDeletes.add(id);
                    if (kDebugMode) print('[ItemsScreen] Failed to multi-delete note $id: $e');
                  }
                }
                if (failedDeletes.isNotEmpty) {
                  notifier.refresh(); // Refresh list if some deletes failed
                  // Show error message
                }
              }
            } : null,
            child: Icon(
              CupertinoIcons.delete,
              color: selectedCount > 0 ? CupertinoColors.destructiveRed : CupertinoColors.inactiveGray,
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            minSize: 0,
            onPressed: selectedCount > 0 ? () async {
              final selectedIdsList = ref.read(ui_providers.selectedItemIdsForMultiSelectProvider).toList();
              if (kDebugMode) print('[ItemsScreen] Multi-archive action triggered for $selectedCount items.');
              // No confirmation needed for archive? Or add one similar to delete.
              if (mounted) {
                 final notifier = ref.read(note_p.notesNotifierFamily(widget.type).notifier);
                 // Optimistic removal
                 for (final id in selectedIdsList) {
                   notifier.archiveNoteOptimistically(id);
                 }
                 // Use the re-added clearMultiSelectProvider
                 ref.read(ui_providers.clearMultiSelectProvider)(); // Clear selection UI
                 ref.read(ui_providers.toggleItemMultiSelectModeProvider)(); // Exit multi-select mode

                 // Perform API calls
                 List<String> failedArchives = [];
                 for (final id in selectedIdsList) {
                   try {
                     // Use the API provider which returns a callable function
                     await ref.read(note_p.archiveNoteApiProvider(id))();
                   } catch (e) {
                     failedArchives.add(id);
                     if (kDebugMode) print('[ItemsScreen] Failed to multi-archive note $id: $e');
                   }
                 }
                 if (failedArchives.isNotEmpty) {
                   notifier.refresh(); // Refresh list if some archives failed
                   // Show error message
                 }
               }
            } : null,
            child: Icon(
              CupertinoIcons.archivebox,
              color: selectedCount > 0 ? CupertinoTheme.of(context).primaryColor : CupertinoColors.inactiveGray,
            ),
          ),
        ],
      ),
    );
  }

  // --- Keyboard Navigation ---

  void _selectNextNote() {
    // Use the family provider with the current type
    final notes = ref.read(note_p.filteredNotesFamily(widget.type));
    if (kDebugMode) print('[ItemsScreen(${widget.type})] _selectNextNote Called. Filtered notes count: ${notes.length}');
    if (notes.isEmpty) return;
    final currentId = ref.read(ui_providers.selectedItemIdProvider);
    int currentIndex = currentId != null ? notes.indexWhere((note) => note.id == currentId) : -1;
    final nextIndex = getNextIndex(currentIndex, notes.length);
    if (nextIndex != -1) {
      final nextNoteId = notes[nextIndex].id;
      ref.read(ui_providers.selectedItemIdProvider.notifier).state = nextNoteId;
      if (kDebugMode) print('[ItemsScreen(${widget.type})] _selectNextNote Updated selectedItemIdProvider to: $nextNoteId');
    }
  }

  void _selectPreviousNote() {
    // Use the family provider with the current type
    final notes = ref.read(note_p.filteredNotesFamily(widget.type));
    if (kDebugMode) print('[ItemsScreen(${widget.type})] _selectPreviousNote Called. Filtered notes count: ${notes.length}');
    if (notes.isEmpty) return;
    final currentId = ref.read(ui_providers.selectedItemIdProvider);
    int currentIndex = currentId != null ? notes.indexWhere((note) => note.id == currentId) : -1;
    final prevIndex = getPreviousIndex(currentIndex, notes.length);
    if (prevIndex != -1) {
      final prevNoteId = notes[prevIndex].id;
      ref.read(ui_providers.selectedItemIdProvider.notifier).state = prevNoteId;
      if (kDebugMode) print('[ItemsScreen(${widget.type})] _selectPreviousNote Updated selectedItemIdProvider to: $prevNoteId');
    }
  }

  void _viewSelectedItem() {
    final selectedId = ref.read(ui_providers.selectedItemIdProvider);
    if (selectedId != null) {
      if (kDebugMode) print('[ItemsScreen(${widget.type})] Viewing selected item: ID $selectedId');
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushNamed(
          '/item-detail',
          arguments: {'itemId': selectedId}, // Pass only itemId
        );
      }
    }
  }

  void _clearSelectionOrUnfocus() {
    final selectedId = ref.read(ui_providers.selectedItemIdProvider);
    if (selectedId != null) {
      if (kDebugMode) print('[ItemsScreen(${widget.type})] Clearing selection via Escape');
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
    final currentServer = _getCurrentServerConfig();
    // Handle case where server config might be null
    if (currentServer == null) {
      final navBar = widget.showNavigationBar ? const CupertinoNavigationBar(middle: Text('Error')) : null;
      return CupertinoPageScaffold(
        navigationBar: navBar,
        child: const Center(child: Text('Server configuration not found.')),
      );
    }

    // Watch the specific family instances needed for this screen type
    final notesState = ref.watch(note_p.notesNotifierFamily(widget.type));
    final visibleNotes = ref.watch(note_p.filteredNotesFamily(widget.type));
    final selectedPresetKey = ref.watch(quickFilterPresetProvider); // Still needed for title/logic in generic view
    final isMultiSelectMode = ref.watch(ui_providers.itemMultiSelectModeProvider);
    final selectedIds = ref.watch(ui_providers.selectedItemIdsForMultiSelectProvider);
    // Use hidden count family
    final hiddenCount = ref.watch(note_p.totalHiddenNoteCountFamily(widget.type));
    final showHidden = ref.watch(showHiddenNotesProvider);
    final theme = CupertinoTheme.of(context);

    // Determine the title based on type or preset key
    String screenTitle;
    if (widget.type == BlinkoNoteType.cache) {
      screenTitle = 'Cache';
    } else if (widget.type == BlinkoNoteType.vault) {
      screenTitle = 'Vault';
    } else { // Generic view (type == null)
      final preset = quickFilterPresets[selectedPresetKey];
      if (preset != null) {
        screenTitle = preset.label;
      } else {
        screenTitle = currentServer.name ?? currentServer.serverUrl; // Fallback
      }
    }

    // Build the navigation bar only if requested
    final navBar = !widget.showNavigationBar ? null : isMultiSelectMode
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
                child: Text(screenTitle, overflow: TextOverflow.ellipsis),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  minSize: 0,
                  onPressed: () => ref.read(ui_providers.toggleItemMultiSelectModeProvider)(),
                  child: const Icon(CupertinoIcons.checkmark_seal),
                ),
                if (hiddenCount > 0)
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    minSize: 0,
                    onPressed: () => ref.read(showHiddenNotesProvider.notifier).update((state) => !state),
                    child: Tooltip(
                      message: showHidden ? 'Hide Hidden Notes' : 'Show Hidden Notes ($hiddenCount)',
                      child: Icon(
                        showHidden ? CupertinoIcons.eye_slash_fill : CupertinoIcons.eye_fill,
                        color: showHidden ? theme.primaryColor : CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ),
                // Show advanced filter only in generic view? Or always? Let's keep it always for now.
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  minSize: 0,
                  onPressed: () => _showAdvancedFilterPanel(context),
                  child: const Icon(CupertinoIcons.tuningfork),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  minSize: 0,
                  onPressed: () => Navigator.of(context, rootNavigator: true).pushNamed(
                    '/new-note',
                    // Pass the current type so the new note screen knows default type
                    arguments: {'blinkoType': widget.type},
                  ),
                  child: const Icon(CupertinoIcons.add),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  minSize: 0,
                  child: const Icon(CupertinoIcons.settings, size: 22),
                  onPressed: () => Navigator.of(context, rootNavigator: true).push(
                    CupertinoPageRoute(
                      builder: (context) => const SettingsScreen(isInitialSetup: false),
                    ),
                  ),
                ),
              ],
            ),
          );

    // Show quick filters only if nav bar is shown, not multi-select, AND it's the generic view
    final bool showQuickFilters = widget.showNavigationBar && !isMultiSelectMode && widget.type == null;

    return CupertinoPageScaffold(
      navigationBar: navBar,
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
              // Show quick filters conditionally (only for generic view)
              if (showQuickFilters)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                  child: _buildQuickFilterControl(),
                ),
              // Show hidden count info only if nav bar is shown, relevant, and in generic view
              if (widget.showNavigationBar && !isMultiSelectMode && widget.type == null && hiddenCount > 0 && !showHidden && selectedPresetKey != 'hidden')
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$hiddenCount hidden notes',
                      style: TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ),
                ),
              // Show unhide all button only if nav bar is shown, relevant, and in generic hidden view
              if (widget.showNavigationBar && !isMultiSelectMode && widget.type == null && selectedPresetKey == 'hidden')
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
                          Icon(CupertinoIcons.eye, size: 18, color: theme.primaryColor),
                          const SizedBox(width: 4),
                          // Use the family for manually hidden count
                          Text(
                            'Unhide All Manually Hidden (${ref.watch(note_p.manuallyHiddenNoteCountFamily(widget.type))})',
                            style: TextStyle(fontSize: 14, color: theme.primaryColor),
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
    // This control is only shown for the generic view (widget.type == null)
    final selectedPresetKey = ref.watch(quickFilterPresetProvider);
    final theme = CupertinoTheme.of(context);
    const List<String> desiredOrder = ['today', 'inbox', 'all', 'hidden']; // Exclude cache/vault
    final Map<String, Widget> segments = {};
    for (var key in desiredOrder) {
      final preset = quickFilterPresets[key];
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
    if (segments.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<String>(
        children: segments,
        groupValue: selectedPresetKey == 'custom' ? null : selectedPresetKey,
        thumbColor: theme.primaryColor,
        backgroundColor: CupertinoColors.secondarySystemFill.resolveFrom(context),
        onValueChanged: (String? newPresetKey) {
          if (newPresetKey != null) {
            if (kDebugMode) print('[ItemsScreen(generic)] Quick filter selected: $newPresetKey');
            ref.read(quickFilterPresetProvider.notifier).state = newPresetKey;
            if (ref.read(rawCelFilterProvider).isNotEmpty) ref.read(rawCelFilterProvider.notifier).state = '';
            ref.read(filterPreferencesProvider)(newPresetKey);
            // Refresh the generic notes provider instance
            ref.read(note_p.notesNotifierFamily(null).notifier).refresh();
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
        // Pass the current type to the filter panel if it needs to adjust behavior?
        // For now, assume filters apply globally or the panel reads the context itself.
        return DraggableScrollableSheet(
          initialChildSize: 0.8, minChildSize: 0.4, maxChildSize: 0.9, expand: false,
          builder: (_, scrollController) => AdvancedFilterPanel(onClose: () => Navigator.pop(context)),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    final searchQuery = ref.watch(searchQueryProvider);
    final TextEditingController controller = TextEditingController(text: searchQuery);
    controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
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
            // Refresh the specific notes provider instance for this screen's type
            ref.read(note_p.notesNotifierFamily(widget.type).notifier).refresh();
          }
        });
      },
      onSubmitted: (value) {
        if (debounce?.isActive ?? false) debounce?.cancel();
        ref.read(searchQueryProvider.notifier).state = value;
        // Refresh immediately on submit
        ref.read(note_p.notesNotifierFamily(widget.type).notifier).refresh();
      },
    );
  }

  Widget _buildNotesList(
    note_p.NotesState notesState,
    List<NoteItem> filteredNotes,
  ) {
    final selectedPresetKey = ref.watch(quickFilterPresetProvider);
    // isInHiddenView is only relevant for the generic view
    final bool isInHiddenView = widget.type == null && selectedPresetKey == 'hidden';

    return NotesListBody(
      scrollController: _scrollController,
      notes: filteredNotes,
      notesState: notesState,
      isInHiddenView: isInHiddenView,
      type: widget.type, // Pass type down
      // Pass down action handlers
      onArchiveNote: _handleArchiveNote,
      onDeleteNote: _handleDeleteNote,
      onTogglePinNote: _handleTogglePinNote,
      onBumpNote: _handleBumpNote,
      onUpdateNoteStartDate: _handleUpdateNoteStartDate,
      // Pass down toggle visibility provider with context
      toggleItemVisibilityProvider: (id) => ref.read(note_p.toggleItemVisibilityProvider((id: id, type: widget.type))),
      unhideNoteProvider: (id) => ref.read(note_p.unhideNoteProvider(id)),
    );
  }

  void _showUnhideAllConfirmation() {
    // Use the family provider for the count
    final manualHiddenCount = ref.read(note_p.manuallyHiddenNoteCountFamily(widget.type));
    if (manualHiddenCount == 0) return;

    showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => CupertinoAlertDialog(
        title: const Text('Unhide All Manually Hidden Notes?'),
        content: Text('Are you sure you want to unhide all $manualHiddenCount manually hidden notes? Notes hidden due to future start dates will remain hidden.'),
        actions: <Widget>[
          CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(dialogContext, false)),
          CupertinoDialogAction(isDefaultAction: true, child: const Text('Unhide All'), onPressed: () => Navigator.pop(dialogContext, true)),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        if (kDebugMode) print('[ItemsScreen(${widget.type})] Confirmed Unhide All Manually Hidden.');
        // Call the unhide all provider (which invalidates the family)
        ref.read(note_p.unhideAllNotesProvider)().then((_) {
          // If currently in hidden view (only possible for generic type), switch back
          if (mounted && widget.type == null && ref.read(quickFilterPresetProvider) == 'hidden') {
            final targetPreset = 'today'; // Default back to today
            ref.read(quickFilterPresetProvider.notifier).state = targetPreset;
            ref.read(filterPreferencesProvider)(targetPreset);
            // Refresh is handled by unhideAllNotesProvider invalidating the family
          }
        }).catchError((e, s) {
          if (kDebugMode) print('[ItemsScreen(${widget.type})] Error during Unhide All: $e\n$s');
          // Optionally show error
        });
      }
    });
  }
}