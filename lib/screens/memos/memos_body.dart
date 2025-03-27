import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_memos/providers/ui_providers.dart';
import 'package:flutter_memos/utils/keyboard_navigation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'memo_list_item.dart';
import 'memos_empty_state.dart';

class MemosBody extends ConsumerStatefulWidget {
  const MemosBody({super.key});

  @override
  ConsumerState<MemosBody> createState() => _MemosBodyState();
}

class _MemosBodyState extends ConsumerState<MemosBody>
    with KeyboardNavigationMixin<MemosBody> {

  // Focus node to manage focus state
  final FocusNode _focusNode = FocusNode(debugLabel: 'MemosBodyFocus');
  
  @override
  void initState() {
    super.initState();
    // Request focus after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Select the first memo when data is available
    final memosAsync = ref.watch(visibleMemosProvider);
    if (memosAsync is AsyncData<List<Memo>> &&
        memosAsync.value.isNotEmpty &&
        ref.read(selectedMemoIndexProvider) < 0) {
      
      // Use another post-frame callback to ensure UI is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(selectedMemoIndexProvider.notifier).state = 0;
          if (kDebugMode) {
            print('[MemosBody] Selected first memo at index 0');
          }
        }
      });
    }
  }
  
  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the providers for data changes
    final memosAsync = ref.watch(visibleMemosProvider);
    
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
        );
        
        // For integration testing, we need to manually trigger a selection
        // after key events to ensure it works
        if (result == KeyEventResult.handled &&
            (event.logicalKey == LogicalKeyboardKey.keyJ ||
             event.logicalKey == LogicalKeyboardKey.keyK)) {
          if (kDebugMode) {
            print('[MemosBody] Key event handled: ${event.logicalKey.keyLabel}');
          }
        }
        
        return result;
      },
      child: memosAsync.when(
        data: (memos) {
          // Get hidden memo IDs
          final hiddenIds = ref.watch(hiddenMemoIdsProvider);

          // Filter out hidden memos
          final visibleMemos =
              memos.where((memo) => !hiddenIds.contains(memo.id)).toList();

          if (visibleMemos.isEmpty) {
            return const MemosEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Invalidate the memosProvider to force refresh
              ref.invalidate(memosProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: visibleMemos.length,
              itemBuilder: (context, index) {
                final memo = visibleMemos[index];
                return MemoListItem(memo: memo, index: index);
              },
            ),
          );
        },
        loading: () {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        },
        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Error loading memos: ${error.toString().substring(0, math.min(error.toString().length, 100))}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }
  
  // Helper methods for keyboard navigation
  void selectNextMemo() {
    // Get the current list of visible memos
    final memosAsync = ref.read(visibleMemosProvider);
    if (memosAsync is! AsyncData<List<Memo>>) return;
    
    final memos = memosAsync.value;
    if (memos.isEmpty) return;
    
    // Get the current selection
    final currentIndex = ref.read(selectedMemoIndexProvider);
    
    // Calculate next index using helper from mixin
    final nextIndex = getNextIndex(currentIndex, memos.length);
    
    // Only update if the index actually changed, to avoid unnecessary rebuilds
    if (nextIndex != currentIndex) {
      // Update the selection
      ref.read(selectedMemoIndexProvider.notifier).state = nextIndex;
    }
  }

  void selectPreviousMemo() {
    // Get the current list of visible memos
    final memosAsync = ref.read(visibleMemosProvider);
    if (memosAsync is! AsyncData<List<Memo>>) return;
    
    final memos = memosAsync.value;
    if (memos.isEmpty) return;
    
    // Get the current selection
    final currentIndex = ref.read(selectedMemoIndexProvider);
    
    // Calculate previous index using helper from mixin
    final prevIndex = getPreviousIndex(currentIndex, memos.length);
    
    // Only update if the index actually changed, to avoid unnecessary rebuilds
    if (prevIndex != currentIndex) {
      // Update the selection
      ref.read(selectedMemoIndexProvider.notifier).state = prevIndex;
    }
  }

  void openSelectedMemo(BuildContext context) {
    // Get the current list of visible memos
    final memosAsync = ref.read(visibleMemosProvider);
    if (memosAsync is! AsyncData<List<Memo>>) return;
    
    final memos = memosAsync.value;
    final selectedIndex = ref.read(selectedMemoIndexProvider);
    
    // If we have a valid selection, navigate to that memo
    if (selectedIndex >= 0 && selectedIndex < memos.length) {
      final selectedMemo = memos[selectedIndex];
      Navigator.pushNamed(
        context,
        '/memo-detail',
        arguments: {'memoId': selectedMemo.id},
      );
    }
  }
  
  // Ensure there's always a selection when memos are available
  void ensureInitialSelection() {
    final memosAsync = ref.read(visibleMemosProvider);
    if (memosAsync is! AsyncData<List<Memo>>) return;
    
    final memos = memosAsync.value;
    if (memos.isEmpty) return;
    
    final currentIndex = ref.read(selectedMemoIndexProvider);
    if (currentIndex < 0 && memos.isNotEmpty) {
      // Initialize selection to the first memo if nothing is selected
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedMemoIndexProvider.notifier).state = 0;
      });
    }
  }
}
