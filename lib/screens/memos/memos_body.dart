import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_memos/providers/ui_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'memo_list_item.dart';
import 'memos_empty_state.dart';

class MemosBody extends ConsumerWidget {
  const MemosBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the providers for data changes
    final memosAsync = ref.watch(visibleMemosProvider);
    
    return Focus(
      autofocus: true, // Allow focusing without requiring user clicks
      canRequestFocus: true,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent) {
          // Handle J/K navigation
          if (event.logicalKey == LogicalKeyboardKey.keyJ ||
              (event.logicalKey == LogicalKeyboardKey.arrowDown &&
                  HardwareKeyboard.instance.isShiftPressed)) {
            _selectNextMemo(ref);
            return KeyEventResult.handled;
          }
          // Handle K for previous item
          else if (event.logicalKey == LogicalKeyboardKey.keyK ||
              (event.logicalKey == LogicalKeyboardKey.arrowUp &&
                  HardwareKeyboard.instance.isShiftPressed)) {
            _selectPreviousMemo(ref);
            return KeyEventResult.handled;
          }
          // Handle Command+Right Arrow to open selected memo
          else if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
                   HardwareKeyboard.instance.isMetaPressed) {
            _openSelectedMemo(ref, context);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored; // Let other keys pass through
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
  void _selectNextMemo(WidgetRef ref) {
    // Get the current list of visible memos
    final memosAsync = ref.read(visibleMemosProvider);
    if (memosAsync is! AsyncData<List<Memo>>) return;
    
    final memos = memosAsync.value;
    if (memos.isEmpty) return;
    
    // Get the current selection and calculate next index
    final currentIndex = ref.read(selectedMemoIndexProvider);
    final nextIndex = currentIndex < 0 ? 0 : (currentIndex + 1) % memos.length;
    
    // Update the selection
    ref.read(selectedMemoIndexProvider.notifier).state = nextIndex;
  }

  void _selectPreviousMemo(WidgetRef ref) {
    // Get the current list of visible memos
    final memosAsync = ref.read(visibleMemosProvider);
    if (memosAsync is! AsyncData<List<Memo>>) return;
    
    final memos = memosAsync.value;
    if (memos.isEmpty) return;
    
    // Get the current selection and calculate previous index with wraparound
    final currentIndex = ref.read(selectedMemoIndexProvider);
    final prevIndex = currentIndex < 0
        ? memos.length - 1  // If nothing selected, select the last item
        : (currentIndex - 1 + memos.length) % memos.length;
    
    // Update the selection
    ref.read(selectedMemoIndexProvider.notifier).state = prevIndex;
  }

  void _openSelectedMemo(WidgetRef ref, BuildContext context) {
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
}
