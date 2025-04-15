import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
// Import note_providers instead of memo_providers
import 'package:flutter_memos/models/note_item.dart'; // Import NoteItem model
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
import 'package:flutter_memos/providers/ui_providers.dart' as ui_providers;
// Import note_list_item instead of memo_list_item
import 'package:flutter_memos/screens/items/note_list_item.dart';
import 'package:flutter_memos/screens/memos/memos_empty_state.dart'; // Keep for now, rename later if needed
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotesListBody extends ConsumerStatefulWidget { // Renamed class
  // Renamed callback parameter
  final void Function(String noteId)? onMoveNoteToServer; // Renamed from onMoveMemoToServer
  final ScrollController scrollController;
  // Add parameters to receive notes list and state directly
  final List<NoteItem> notes;
  final note_providers.NotesState notesState;


  const NotesListBody({ // Renamed constructor
    super.key,
    required this.scrollController,
    required this.notes, // Make notes required
    required this.notesState, // Make notesState required
    this.onMoveNoteToServer, // Renamed parameter
  });

  @override
  ConsumerState<NotesListBody> createState() => _NotesListBodyState(); // Renamed class
}

class _NotesListBodyState extends ConsumerState<NotesListBody> { // Renamed class

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

    // Use providers from note_providers and renamed ui_providers
    // Use the notes list passed via the widget constructor
    final notes = widget.notes;
    // Use ui_providers.selectedItemIdProvider
    final selectedId = ref.read(ui_providers.selectedItemIdProvider);

    if (notes.isNotEmpty && selectedId == null) {
      final firstNoteId = notes.first.id; // Renamed variable
      // Use ui_providers.selectedItemIdProvider
      ref.read(ui_providers.selectedItemIdProvider.notifier).state = firstNoteId;
      if (kDebugMode) {
        print(
          '[NotesListBody] Selected first note (ID=$firstNoteId) after initial load/refresh.', // Updated log identifier
        );
      }
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
      // Use provider from note_providers
      final notifier = ref.read(note_providers.notesNotifierProvider.notifier);
      // Use provider from note_providers
      if (ref.read(note_providers.notesNotifierProvider).canLoadMore) {
        if (kDebugMode) {
          print(
            '[NotesListBody] Reached near bottom, attempting to fetch more notes.', // Updated log identifier
          );
        }
        notifier.fetchMoreNotes(); // Use renamed method
      } else {
        // Optional: log if needed
        // if (kDebugMode) { print('[NotesListBody] Reached near bottom, but cannot load more.'); }
      }
    }
  }

  Future<void> _onRefresh() async {
    if (kDebugMode) {
      print('[NotesListBody] Pull-to-refresh triggered.'); // Updated log identifier
    }
    HapticFeedback.lightImpact();

    // Use provider from note_providers
    await ref.read(note_providers.notesNotifierProvider.notifier).refresh();

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
    // Use providers from note_providers
    // Use the state and list passed via the widget constructor
    final notesState = widget.notesState;
    final visibleNotes = widget.notes; // Use the passed list
    // final hasSearchResults = ref.watch(note_providers.hasSearchResultsProvider); // TODO: do we need this?

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
            Text(
              'Error: ${notesState.error}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            CupertinoButton(onPressed: _onRefresh, child: const Text('Retry')),
          ],
        ),
      );
    }

    // Empty State (or No Search Results)
    if (visibleNotes.isEmpty) {
      return MemosEmptyState(onRefresh: _onRefresh); // Keep using MemosEmptyState for now
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
                  if (kDebugMode) {
                    if (widget.onMoveNoteToServer != null) { // Use renamed callback
                      print(
                        '[NotesListBody] Building NoteListItem for ${note.id}, passing onMoveNoteToServer callback.', // Updated log identifier
                      );
                    }
                  }
                  return NoteListItem( // Use renamed widget
                    key: ValueKey(note.id),
                    note: note, // Pass NoteItem as note prop
                    index: index,
                    onMoveToServer: widget.onMoveNoteToServer != null // Use renamed callback
                        ? () => widget.onMoveNoteToServer!(note.id)
                        : null,
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
