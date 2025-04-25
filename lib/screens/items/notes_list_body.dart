import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_memos/models/note_item.dart'; // Import NoteItem model
import 'package:flutter_memos/providers/note_providers.dart' as note_p;
import 'package:flutter_memos/providers/ui_providers.dart' as ui_providers;
import 'package:flutter_memos/screens/items/note_list_item.dart';
import 'package:flutter_memos/screens/memos/memos_empty_state.dart'; // Keep for now, rename later if needed
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotesListBody extends ConsumerStatefulWidget {
  final void Function(String noteId)? onMoveNoteToServer;
  final ScrollController scrollController;
  final List<NoteItem> notes;
  final note_p.NotesState notesState;
  final bool isInHiddenView;
  final BlinkoNoteType? type; // Add type parameter
  // Action handlers passed down
  final Future<void> Function(String noteId) onArchiveNote;
  final Future<void> Function(String noteId) onDeleteNote;
  final Future<void> Function(String noteId) onTogglePinNote;
  final Future<void> Function(String noteId) onBumpNote;
  final Future<void> Function(String noteId, DateTime? newStartDate)
  onUpdateNoteStartDate;
  final void Function() Function(String id) toggleItemVisibilityProvider;
  final void Function() Function(String id) unhideNoteProvider;

  const NotesListBody({
    super.key,
    required this.scrollController,
    required this.notes,
    required this.notesState,
    required this.isInHiddenView,
    required this.type, // Require type
    required this.onArchiveNote,
    required this.onDeleteNote,
    required this.onTogglePinNote,
    required this.onBumpNote,
    required this.onUpdateNoteStartDate,
    required this.toggleItemVisibilityProvider,
    required this.unhideNoteProvider,
    this.onMoveNoteToServer,
  });

  @override
  ConsumerState<NotesListBody> createState() => _NotesListBodyState();
}

class _NotesListBodyState extends ConsumerState<NotesListBody> {

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _ensureInitialSelection(),
    );
  }

  void _ensureInitialSelection() {
    if (!mounted) return;

    final notes = widget.notes;
    final selectedId = ref.read(ui_providers.selectedItemIdProvider);

    if (notes.isNotEmpty && selectedId == null) {
      final firstNoteId = notes.first.id;
      // Check if the first note is actually visible before selecting it
      // This might be complex depending on filters; for now, select the first in the list.
      ref.read(ui_providers.selectedItemIdProvider.notifier).state = firstNoteId;
      if (kDebugMode) {
        print(
          '[NotesListBody(${widget.type})] Selected first note (ID=$firstNoteId) after initial load/refresh.',
        );
      }
    } else if (notes.isNotEmpty && selectedId != null) {
      // Ensure the currently selected ID still exists in the list
      if (!notes.any((note) => note.id == selectedId)) {
        final firstNoteId = notes.first.id;
        ref.read(ui_providers.selectedItemIdProvider.notifier).state =
            firstNoteId;
        if (kDebugMode) {
          print(
            '[NotesListBody(${widget.type})] Current selection $selectedId not found in list, selecting first note (ID=$firstNoteId).',
          );
        }
      }
    } else if (notes.isEmpty && selectedId != null) {
      // Clear selection if list becomes empty
      ref.read(ui_providers.selectedItemIdProvider.notifier).state = null;
      if (kDebugMode) {
        print(
          '[NotesListBody(${widget.type})] List is empty, clearing selection.',
        );
      }
    }
  }

  @override
  void didUpdateWidget(covariant NotesListBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-check selection if the notes list changes significantly
    if (!listEquals(
      oldWidget.notes.map((e) => e.id).toList(),
      widget.notes.map((e) => e.id).toList(),
    )) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _ensureInitialSelection(),
      );
    }
  }


  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (widget.scrollController.position.pixels >=
        widget.scrollController.position.maxScrollExtent - 200) {
      // Use the family provider with the current type
      final notifier = ref.read(
        note_p.notesNotifierFamily(widget.type).notifier,
      );
      // Use the family provider state
      if (ref.read(note_p.notesNotifierFamily(widget.type)).canLoadMore) {
        if (kDebugMode) {
          print(
            '[NotesListBody(${widget.type})] Reached near bottom, attempting to fetch more notes.',
          );
        }
        notifier.fetchMoreNotes();
      } else {
        // Optional: log if needed
        // if (kDebugMode) { print('[NotesListBody(${widget.type})] Reached near bottom, but cannot load more.'); }
      }
    }
  }

  Future<void> _onRefresh() async {
    if (kDebugMode) {
      print('[NotesListBody(${widget.type})] Pull-to-refresh triggered.');
    }
    HapticFeedback.lightImpact();

    // Use the family provider with the current type
    await ref
        .read(
          note_p.notesNotifierFamily(widget.type).notifier,
        )
        .refresh();

    HapticFeedback.mediumImpact();
    _ensureInitialSelection();
  }

  Widget _buildRefreshIndicator(
    BuildContext context,
    RefreshIndicatorMode refreshState,
    double pulledExtent,
    double refreshTriggerPullDistance,
    double refreshIndicatorExtent,
  ) {
    final double opacity = pulledExtent / refreshTriggerPullDistance;
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (refreshState == RefreshIndicatorMode.refresh ||
              refreshState == RefreshIndicatorMode.armed)
            const CupertinoActivityIndicator(radius: 14.0)
          else if (refreshState == RefreshIndicatorMode.drag)
            Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: const CupertinoActivityIndicator(radius: 14.0),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use the state and list passed via the widget constructor
    final notesState = widget.notesState;
    final visibleNotes = widget.notes;

    // Loading State
    if (notesState.isLoading && notesState.notes.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }

    // Error State
    if (notesState.error != null && notesState.notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 40,
              color: CupertinoColors.systemRed,
            ),
            const SizedBox(height: 10),
            Padding(
              // Added padding for better text wrapping
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Error loading notes for this server: ${notesState.error}',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            CupertinoButton(onPressed: _onRefresh, child: const Text('Retry')),
          ],
        ),
      );
    }

    // Empty State (or No Search Results)
    if (visibleNotes.isEmpty) {
      // Pass refresh handler to empty state
      return MemosEmptyState(onRefresh: _onRefresh);
    }

    // Data State (List View)
    return CupertinoScrollbar(
      controller: widget.scrollController,
      thumbVisibility: true,
      thickness: 6.0,
      radius: const Radius.circular(3.0),
      child: ScrollConfiguration(
        behavior: const CupertinoScrollBehavior(),
        child: CustomScrollView(
          controller: widget.scrollController,
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: _onRefresh,
              refreshIndicatorExtent: 60.0,
              refreshTriggerPullDistance: 100.0,
              builder: _buildRefreshIndicator,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final note = visibleNotes[index];
                  // Debug print removed for brevity
                  return NoteListItem(
                    key: ValueKey(
                      note.id,
                    ), // Use ValueKey for better performance
                    note: note,
                    index: index,
                    isInHiddenView: widget.isInHiddenView,
                    type: widget.type, // Pass type down
                    onMoveToServer:
                        widget.onMoveNoteToServer != null
                        ? () => widget.onMoveNoteToServer!(note.id)
                        : null,
                    // Pass down action handlers
                    onArchive: () => widget.onArchiveNote(note.id),
                    onDelete: () => widget.onDeleteNote(note.id),
                    onTogglePin: () => widget.onTogglePinNote(note.id),
                    onBump: () => widget.onBumpNote(note.id),
                    onUpdateStartDate:
                        (date) => widget.onUpdateNoteStartDate(note.id, date),
                    onToggleVisibility: widget.toggleItemVisibilityProvider(
                      note.id,
                    ),
                    onUnhide: widget.unhideNoteProvider(note.id),
                  );
                }, childCount: visibleNotes.length),
              ),
            ),
            if (notesState.isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(child: CupertinoActivityIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
