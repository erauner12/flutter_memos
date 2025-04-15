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
  // Keep track if initial load was triggered by constructor
  bool _initialLoadTriggered = false;

  WorkbenchNotifier(this._ref, {bool loadOnInit = true})
    : super(const WorkbenchState(isLoading: false)) {
    // Default isLoading to false
    _cloudKitService = _ref.read(cloudKitServiceProvider);
    if (loadOnInit) {
      _initialLoadTriggered = true;
      // Use unawaited only if loading on init
      unawaited(loadItems());
    }
  }

  Future<void> loadItems() async {
    // Prevent concurrent loads, especially during init vs manual refresh
    if (state.isLoading) return;

    if (!mounted) return;
    // Set loading true only if not the initial auto-load or if already loaded once
    final bool setLoading =
        !_initialLoadTriggered || state.items.isNotEmpty || state.error != null;
    if (setLoading) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      // For the very first auto-load, clear error but don't show loading indicator yet
      state = state.copyWith(clearError: true);
    }

    // Mark that a load attempt has happened
    _initialLoadTriggered = true;

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

  Future<void> addItem(WorkbenchItemReference item) async {
    if (!mounted) return;

    // --- Check for Duplicates ---
    final exists = state.items.any((existingItem) =>
        existingItem.referencedItemId == item.referencedItemId &&
        existingItem.serverId == item.serverId);

    if (exists) {
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier] Item with referencedItemId ${item.referencedItemId} on server ${item.serverId} already exists. Skipping add.',
        );
      }
      // Optionally: Show a message to the user via a different mechanism
      // (e.g., return false, throw specific exception, use a separate state field)
      // For now, just silently prevent the duplicate add.
      return;
    }
    // --- End Check for Duplicates ---


    // Optimistic Update (only if not a duplicate)
    final optimisticItems = List<WorkbenchItemReference>.from(state.items)..add(item);
    // Sort by default order (newest first) after adding
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
      // If successful, state is already correct
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
        // No need to re-sort here as we just removed the optimistically added one
        state = state.copyWith(items: revertedItems, error: e); // Keep the error state
         if (kDebugMode) {
           print('[WorkbenchNotifier] Reverted optimistic add for item: ${item.id}');
         }
      }
    }
  }

  Future<void> removeItem(String referenceId) async {
    if (!mounted) return;

    WorkbenchItemReference? originalItem;
    final optimisticItems = state.items.where((i) {
      if (i.id == referenceId) {
        originalItem = i; // Keep track of the item being removed
        return false; // Exclude the item
      }
      return true;
    }).toList();

    // Check if the item was actually found and removed
    if (originalItem == null) {
       if (kDebugMode) {
         print('[WorkbenchNotifier] Item $referenceId not found for removal.');
       }
      return; // Item wasn't in the list, nothing to do
    }

    // Add logging here
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
        // Even if CloudKit reports failure (e.g., already deleted), keep the optimistic removal
        if (kDebugMode) {
          print('[WorkbenchNotifier] CloudKit delete reported failure for $referenceId, but keeping optimistic removal.');
        }
        // Optionally, re-fetch from CloudKit here to be absolutely sure, but might be overkill
      } else {
        // If successful, state is already correct
        if (kDebugMode) {
          print('[WorkbenchNotifier] Successfully deleted item $referenceId from CloudKit.');
        }
      }
    } catch (e, s) {
      if (kDebugMode) {
        print('[WorkbenchNotifier] Error deleting item $referenceId from CloudKit: $e\n$s');
      }
      // Revert optimistic update ONLY if CloudKit deletion fails AND the item still exists locally
      // (It might have been removed by another device in the meantime)
      if (mounted && originalItem != null) {
        // Check if the item is *still* gone from the current state before reverting
        if (!state.items.any((i) => i.id == referenceId)) {
          final revertedItems = List<WorkbenchItemReference>.from(state.items)..add(originalItem!);
          // Sort by default order (newest first) after reverting
          revertedItems.sort((a, b) => b.addedTimestamp.compareTo(a.addedTimestamp));
          state = state.copyWith(items: revertedItems, error: e); // Keep the error state
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

  /// Reorders items locally based on user drag-and-drop.
  /// This change is not persisted to CloudKit.
  void reorderItems(int oldIndex, int newIndex) {
    if (!mounted) return;
    if (oldIndex < 0 || oldIndex >= state.items.length) return;
    if (newIndex < 0 || newIndex > state.items.length) {
      return; // Allow inserting at the end
    }

    final List<WorkbenchItemReference> currentItems = List.from(state.items);

    // Adjust newIndex if item is moved downwards in the list
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final WorkbenchItemReference item = currentItems.removeAt(oldIndex);
    currentItems.insert(newIndex, item);

    state = state.copyWith(items: currentItems);
    if (kDebugMode) {
      print(
        '[WorkbenchNotifier] Reordered items locally. Moved item from $oldIndex to $newIndex.',
      );
    }
  }

  /// Resets the item order to the default (newest added first).
  /// This change is not persisted to CloudKit.
  void resetOrder() {
    if (!mounted) return;

    final List<WorkbenchItemReference> currentItems = List.from(state.items);
    // Apply default sort: newest added first
    currentItems.sort((a, b) => b.addedTimestamp.compareTo(a.addedTimestamp));

    state = state.copyWith(items: currentItems);
    if (kDebugMode) {
      print('[WorkbenchNotifier] Reset item order to default (newest first).');
    }
  }

} // End of WorkbenchNotifier class

// Provider definition remains the same
final workbenchProvider = StateNotifierProvider<WorkbenchNotifier, WorkbenchState>((ref) {
  // Pass loadOnInit: true for normal operation
  final notifier = WorkbenchNotifier(ref, loadOnInit: true);
  // Initial load is now handled within the constructor if loadOnInit is true
  return notifier;
});
