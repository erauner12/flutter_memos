import 'dart:async'; // For unawaited

import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart';
import 'package:flutter_memos/providers/service_providers.dart'; // To get CloudKitService
import 'package:flutter_memos/services/cloud_kit_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class WorkbenchState {
  final List<WorkbenchItemReference> items;
  final bool isLoading;
  final Object? error;

  const WorkbenchState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  WorkbenchState copyWith({
    List<WorkbenchItemReference>? items,
    bool? isLoading,
    Object? error,
    bool clearError = false,
  }) {
    return WorkbenchState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WorkbenchState &&
        listEquals(other.items, items) &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(items), isLoading, error);
}

class WorkbenchNotifier extends StateNotifier<WorkbenchState> {
  final Ref _ref;
  late final CloudKitService _cloudKitService;
  // Remove _initialLoadTriggered flag
  // bool _initialLoadTriggered = false;

  // Remove loadOnInit parameter and automatic call
  WorkbenchNotifier(this._ref) : super(const WorkbenchState(isLoading: false)) {
    // Always start with isLoading: false
    _cloudKitService = _ref.read(cloudKitServiceProvider);
    // DO NOT call loadItems automatically here
  }

  Future<void> loadItems() async {
    // Prevent concurrent loads
    if (state.isLoading) return;
    if (!mounted) return;

    // Always set loading true when manually called
    state = state.copyWith(isLoading: true, clearError: true);

    // Remove _initialLoadTriggered logic


    try {
      final items = await _cloudKitService.getAllWorkbenchItemReferences();

      // Default sort: newest added first
      items.sort((a, b) => b.addedTimestamp.compareTo(a.addedTimestamp));

      if (mounted) {
        state = state.copyWith(items: items, isLoading: false);
        if (kDebugMode) {
          print('[WorkbenchNotifier] Loaded ${items.length} items.');
        }
      }
    } catch (e, s) {
      if (kDebugMode) {
        print('[WorkbenchNotifier] Error loading items: $e\n$s');
      }
      if (mounted) {
        state = state.copyWith(error: e, isLoading: false);
      }
    }
  }

  // --- addItem ---
  Future<void> addItem(WorkbenchItemReference item) async {
    if (!mounted) return;

    // Check for Duplicates
    final exists = state.items.any((existingItem) =>
        existingItem.referencedItemId == item.referencedItemId &&
        existingItem.serverId == item.serverId);

    if (exists) {
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier] Item with referencedItemId ${item.referencedItemId} on server ${item.serverId} already exists. Skipping add.',
        );
      }
      return;
    }

    // Optimistic Update
    final optimisticItems = List<WorkbenchItemReference>.from(state.items)
      ..add(item);
    optimisticItems.sort((a, b) => b.addedTimestamp.compareTo(a.addedTimestamp));
    state = state.copyWith(items: optimisticItems);
    if (kDebugMode) {
      print('[WorkbenchNotifier] Optimistically added item: ${item.id}');
    }

    try {
      final success = await _cloudKitService.saveWorkbenchItemReference(item);
      if (!success) {
        throw Exception('Failed to save item to CloudKit');
      }
      if (kDebugMode) {
         print('[WorkbenchNotifier] Successfully saved item ${item.id} to CloudKit.');
       }
    } catch (e, s) {
      if (kDebugMode) {
        print('[WorkbenchNotifier] Error saving item ${item.id}: $e\n$s');
      }
      // Revert optimistic update on failure
      if (mounted) {
        final revertedItems = state.items.where((i) => i.id != item.id).toList();
        state = state.copyWith(items: revertedItems, error: e);
         if (kDebugMode) {
           print('[WorkbenchNotifier] Reverted optimistic add for item: ${item.id}');
         }
      }
    }
  }

  // --- removeItem ---
  Future<void> removeItem(String referenceId) async {
    if (!mounted) return;

    WorkbenchItemReference? originalItem;
    final optimisticItems = state.items.where((i) {
      if (i.id == referenceId) {
            originalItem = i;
            return false;
      }
      return true;
    }).toList();

    if (originalItem == null) {
       if (kDebugMode) {
         print('[WorkbenchNotifier] Item $referenceId not found for removal.');
       }
      return;
    }

    if (kDebugMode) {
      print('[WorkbenchNotifier] Attempting to remove item with reference ID: $referenceId');
      print('[WorkbenchNotifier] Found item to remove: ${originalItem.toString()}');
    }

    // Optimistic Update
    state = state.copyWith(items: optimisticItems);
     if (kDebugMode) {
       print('[WorkbenchNotifier] Optimistically removed item: $referenceId');
     }

    try {
      final success = await _cloudKitService.deleteWorkbenchItemReference(referenceId);
      if (!success) {
        if (kDebugMode) {
          print('[WorkbenchNotifier] CloudKit delete reported failure for $referenceId, but keeping optimistic removal.');
        }
      } else {
        if (kDebugMode) {
          print('[WorkbenchNotifier] Successfully deleted item $referenceId from CloudKit.');
        }
      }
    } catch (e, s) {
      if (kDebugMode) {
        print('[WorkbenchNotifier] Error deleting item $referenceId from CloudKit: $e\n$s');
      }
      // Revert optimistic update ONLY if CloudKit deletion fails
      if (mounted && originalItem != null) {
        // Check if the item is *still* gone from the current state before reverting
        if (!state.items.any((i) => i.id == referenceId)) {
          final revertedItems = List<WorkbenchItemReference>.from(state.items)
            ..add(originalItem!);
          revertedItems.sort((a, b) => b.addedTimestamp.compareTo(a.addedTimestamp));
          state = state.copyWith(items: revertedItems, error: e);
          if (kDebugMode) {
            print('[WorkbenchNotifier] Reverted optimistic remove for item: $referenceId due to CloudKit error.');
          }
        } else {
           if (kDebugMode) {
            print('[WorkbenchNotifier] CloudKit delete failed for $referenceId, but item already removed from local state. No revert needed.');
          }
        }
      }
    }
  }

  // --- reorderItems ---
  void reorderItems(int oldIndex, int newIndex) {
    if (!mounted) return;
    if (oldIndex < 0 || oldIndex >= state.items.length) return;
    // Allow inserting at the very end (index == length)
    if (newIndex < 0 || newIndex > state.items.length) {
      return;
    }

    final List<WorkbenchItemReference> currentItems = List.from(state.items);

    // Adjust newIndex if item is moved downwards in the list before removal
    final int effectiveNewIndex =
        (oldIndex < newIndex) ? newIndex - 1 : newIndex;

    // Ensure effectiveNewIndex is within bounds after potential adjustment
    if (effectiveNewIndex < 0 || effectiveNewIndex > currentItems.length - 1) {
      // This case handles moving the single item to index 1 when length is 1,
      // or other edge cases resulting from the adjustment.
      // If moving to the end, newIndex == length, effectiveNewIndex == length - 1.
      if (newIndex == currentItems.length && oldIndex < newIndex) {
        // This is okay, it means move to the end.
      } else {
        if (kDebugMode) {
          print(
            '[WorkbenchNotifier] Invalid effectiveNewIndex $effectiveNewIndex after adjustment. old=$oldIndex, new=$newIndex, len=${currentItems.length}',
          );
        }
        return; // Avoid index out of bounds after adjustment
      }
    }


    final WorkbenchItemReference item = currentItems.removeAt(oldIndex);
    // Insert at the potentially adjusted index
    // If newIndex was length, effectiveNewIndex is length-1, insert happens correctly after removal.
    currentItems.insert(effectiveNewIndex, item);


    state = state.copyWith(items: currentItems);
    if (kDebugMode) {
      print(
        '[WorkbenchNotifier] Reordered items locally. Moved item from $oldIndex to $effectiveNewIndex (original newIndex: $newIndex).',
      );
    }
  }

  // --- resetOrder ---
  void resetOrder() {
    if (!mounted) return;

    final List<WorkbenchItemReference> currentItems = List.from(state.items);
    currentItems.sort((a, b) => b.addedTimestamp.compareTo(a.addedTimestamp));

    state = state.copyWith(items: currentItems);
    if (kDebugMode) {
      print('[WorkbenchNotifier] Reset item order to default (newest first).');
    }
  }

} // End of WorkbenchNotifier class

// Provider definition - constructor signature changed
final workbenchProvider = StateNotifierProvider<WorkbenchNotifier, WorkbenchState>((ref) {
      // Constructor no longer takes loadOnInit
      final notifier = WorkbenchNotifier(ref);
      // IMPORTANT: The application UI (e.g., WorkbenchScreen) will now need
      // to trigger the initial loadItems call if it wasn't already.
  return notifier;
});
