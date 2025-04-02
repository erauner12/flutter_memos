import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_memos/providers/ui_providers.dart';
import 'package:flutter_memos/utils/keyboard_navigation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'memo_list_item.dart';
import 'memos_empty_state.dart';

class MemosBody extends ConsumerStatefulWidget {
  // Changed to ConsumerStatefulWidget
  const MemosBody({super.key});

  @override
  ConsumerState<MemosBody> createState() => _MemosBodyState();
}

class _MemosBodyState extends ConsumerState<MemosBody>
    with KeyboardNavigationMixin<MemosBody> {

  // Focus node to manage focus state
  final FocusNode _focusNode = FocusNode(debugLabel: 'MemosBodyFocus');
  final ScrollController _scrollController =
      ScrollController(); // Add ScrollController

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll); // Add listener for pagination
    // Request focus after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Check if mounted before accessing context/focus
        FocusScope.of(context).requestFocus(_focusNode);
        // Initial selection logic might need adjustment based on the new state
        _ensureInitialSelection();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This might still be useful, but ensure it uses the new provider structure
    // Consider moving selection logic entirely to initState or build if simpler
    // _ensureInitialSelection(); // Re-evaluate if needed here
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll); // Remove listener
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Listener for scroll events to trigger loading more memos
  void _onScroll() {
    // Check if near bottom and can load more
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      // Threshold
      // Read the notifier *without* watching to avoid rebuilds on state change here
      final notifier = ref.read(memosNotifierProvider.notifier);
      // Call fetchMoreMemos - the notifier handles the logic internally
      // (checks isLoadingMore, hasReachedEnd, etc.)
      notifier.fetchMoreMemos();
    }
  }

  // Helper to ensure a selection exists when the list is first loaded or refreshed
  void _ensureInitialSelection() {
    // Use the new provider for visible memos
    final visibleMemos = ref.read(visibleMemosListProvider);
    final currentSelection = ref.read(selectedMemoIndexProvider);

    if (visibleMemos.isNotEmpty && currentSelection < 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(selectedMemoIndexProvider.notifier).state = 0;
          if (kDebugMode) {
            print(
              '[MemosBody] Selected first memo at index 0 after initial load/refresh.',
            );
          }
        }
      });
    } else if (visibleMemos.isEmpty && currentSelection != -1) {
      // Reset selection if list becomes empty
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(selectedMemoIndexProvider.notifier).state = -1;
        }
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    // Watch the providers for data changes
    // final memosAsync = ref.watch(visibleMemosProvider); // Old way
    final memosState = ref.watch(memosNotifierProvider); // Watch the full state
    final visibleMemos = ref.watch(
      visibleMemosListProvider,
    ); // Watch the filtered list

    // Ensure selection is updated when the list changes
    // Calling this in build ensures it runs whenever the visible list updates
    _ensureInitialSelection();

    return Focus(
      focusNode: _focusNode,
      autofocus: true, // Allow focusing without requiring user clicks
      canRequestFocus: true,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        // Use the shared keyboard navigation handler
        final result = handleKeyEvent(
          event,
          ref,
          onUp: () => selectPreviousMemo(),
          onDown: () => selectNextMemo(),
          onForward: () => openSelectedMemo(context),
          onEscape: () {
            // Clear any text input focus and return focus to the list
            FocusManager.instance.primaryFocus?.unfocus();
            _focusNode.requestFocus();
          },
        );

        // For integration testing, we need to manually trigger a selection
        // after key events to ensure it works
        if (result == KeyEventResult.handled &&
            (event.logicalKey == LogicalKeyboardKey.keyJ ||
                event.logicalKey == LogicalKeyboardKey.keyK ||
                event.logicalKey ==
                    LogicalKeyboardKey.arrowUp || // Also handle arrow keys
                event.logicalKey == LogicalKeyboardKey.arrowDown)) {
          if (kDebugMode) {
            print('[MemosBody] Key event handled: ${event.logicalKey.keyLabel}');
          }
        }

        return result;
      },
      // --- Build UI based on MemosState ---
      child: Builder(
        // Use Builder to handle different states cleanly
        builder: (context) {
          // 1. Initial Loading State
          if (memosState.isLoading && memosState.memos.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          // 2. Error State (only show if not loading more)
          if (memosState.error != null && !memosState.isLoadingMore) {
            return RefreshIndicator(
              onRefresh: () async {
                if (kDebugMode) {
                  print('[MemosBody] Refresh triggered (error state)');
                }
                // Use the notifier's refresh method
                await ref.read(memosNotifierProvider.notifier).refresh();
              },
              child: LayoutBuilder(
                // Use LayoutBuilder for constraints
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    // Make it scrollable for refresh
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            'Error loading memos: ${memosState.error.toString().substring(0, math.min(memosState.error.toString().length, 100))}\nPull down to retry.',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ); // End of SingleChildScrollView
                }, // End of LayoutBuilder builder
              ), // End of LayoutBuilder
            ); // End of RefreshIndicator
          }

          // 3. Empty State (after initial load, no errors, no memos)
          if (!memosState.isLoading && visibleMemos.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                if (kDebugMode) {
                  print('[MemosBody] Refresh triggered (empty state)');
                }
                // Use the notifier's refresh method
                await ref.read(memosNotifierProvider.notifier).refresh();
              },
              child: LayoutBuilder( // Use LayoutBuilder to ensure ListView constraints
                builder: (context, constraints) {
                  return SingleChildScrollView( // Make it scrollable for refresh
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child:
                          const MemosEmptyState(), // Show the empty state widget
                    ),
                  );
                }
              ),
            );
          }

          // 4. Data State (Memos available)
          return RefreshIndicator(
            onRefresh: () async {
              if (kDebugMode) {
                print('[MemosBody] Refresh triggered');
              }
              // Use the notifier's refresh method
              await ref.read(memosNotifierProvider.notifier).refresh();
            },
            child: ListView.builder(
              controller: _scrollController, // Assign the scroll controller
              // Ensure the ListView is always scrollable to allow pull-to-refresh
              // even if the content fits on the screen.
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              // Add 1 to item count if loading more for the indicator
              itemCount:
                  visibleMemos.length + (memosState.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                // Check if it's the loading indicator item at the end
                if (index == visibleMemos.length && memosState.isLoadingMore) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                // Otherwise, it's a memo item (check bounds just in case)
                if (index < visibleMemos.length) {
                  final memo = visibleMemos[index];
                  // Pass the index within the visibleMemos list
                  return MemoListItem(memo: memo, index: index);
                }

                // Should not happen, but return an empty box as fallback
                return const SizedBox.shrink();
              },
            ),
          );
        },
      ), // End of Builder
    ); // End of Focus
  } // End of build method

// Helper methods for keyboard navigation remain unchanged below
  // Helper methods for keyboard navigation
  void selectNextMemo() {
    // Get the current list of visible memos using the new provider
    // final memosAsync = ref.read(visibleMemosProvider); // Old way
    // if (memosAsync is! AsyncData<List<Memo>>) return; // Old check
    // final memos = memosAsync.value; // Old way
    final memos = ref.read(visibleMemosListProvider); // New way

    if (memos.isEmpty) return;

    // Get the current selection
    final currentIndex = ref.read(selectedMemoIndexProvider);

    // Calculate next index using helper from mixin
    final nextIndex = getNextIndex(currentIndex, memos.length);

    // Only update if the index actually changed, to avoid unnecessary rebuilds
    if (nextIndex != currentIndex) {
      // Update the selection
      ref.read(selectedMemoIndexProvider.notifier).state = nextIndex;
      if (kDebugMode) {
        print('[MemosBody] Selected next memo at index $nextIndex');
      }
    }
  }

  void selectPreviousMemo() {
    // Get the current list of visible memos using the new provider
    // final memosAsync = ref.read(visibleMemosProvider); // Old way
    // if (memosAsync is! AsyncData<List<Memo>>) return; // Old check
    // final memos = memosAsync.value; // Old way
    final memos = ref.read(visibleMemosListProvider); // New way

    if (memos.isEmpty) return;

    // Get the current selection
    final currentIndex = ref.read(selectedMemoIndexProvider);

    // Calculate previous index using helper from mixin
    final prevIndex = getPreviousIndex(currentIndex, memos.length);

    // Only update if the index actually changed, to avoid unnecessary rebuilds
    if (prevIndex != currentIndex) {
      // Update the selection
      ref.read(selectedMemoIndexProvider.notifier).state = prevIndex;
      if (kDebugMode) {
        print('[MemosBody] Selected previous memo at index $prevIndex');
      }
    }
  }

  void openSelectedMemo(BuildContext context) {
    // Get the current list of visible memos using the new provider
    // final memosAsync = ref.read(visibleMemosProvider); // Old way
    // if (memosAsync is! AsyncData<List<Memo>>) return; // Old check
    // final memos = memosAsync.value; // Old way
    final memos = ref.read(visibleMemosListProvider); // New way
    final selectedIndex = ref.read(selectedMemoIndexProvider);

    // If we have a valid selection, navigate to that memo
    if (selectedIndex >= 0 && selectedIndex < memos.length) {
      final selectedMemo = memos[selectedIndex];
      if (kDebugMode) {
        print(
          '[MemosBody] Opening memo detail for index $selectedIndex, ID: ${selectedMemo.id}',
        );
      }
      Navigator.pushNamed(
        context,
        '/memo-detail',
        arguments: {'memoId': selectedMemo.id},
      );
    } else if (kDebugMode) {
      print(
        '[MemosBody] Cannot open memo detail: Invalid index $selectedIndex for list length ${memos.length}',
      );
    }
  }
}
