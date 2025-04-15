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

  WorkbenchNotifier(this._ref) : super(const WorkbenchState(isLoading: true)) {
    _cloudKitService = _ref.read(cloudKitServiceProvider);
    // Initial load is triggered by the provider definition
  }

  Future<void> loadItems() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _cloudKitService.getAllWorkbenchItemReferences();

      // Sort by lastOpenedTimestamp (desc, nulls last), then addedTimestamp (desc)
      items.sort((a, b) {
        final aOpened = a.lastOpenedTimestamp;
        final bOpened = b.lastOpenedTimestamp;

        if (aOpened != null && bOpened != null) {
          return bOpened.compareTo(aOpened); // Both opened, sort by opened desc
        } else if (aOpened != null) {
          return -1; // a opened, b didn't -> a comes first
        } else if (bOpened != null) {
          return 1; // b opened, a didn't -> b comes first
        } else {
          // Neither opened, sort by added desc
          return b.addedTimestamp.compareTo(a.addedTimestamp);
        }
      });

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

  /// Marks an item as opened by updating its lastOpenedTimestamp.
  Future<void> markItemOpened(String referenceId) async {
    if (!mounted) return;

    final index = state.items.indexWhere((item) => item.id == referenceId);
    if (index == -1) {
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier] markItemOpened: Item $referenceId not found in state.',
        );
      }
      return; // Item not found
    }

    final originalItem = state.items[index];
    final now = DateTime.now();

    // Avoid unnecessary updates if already opened very recently (e.g., within a second)
    if (originalItem.lastOpenedTimestamp != null &&
        now.difference(originalItem.lastOpenedTimestamp!).inSeconds < 1) {
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier] markItemOpened: Item $referenceId already marked opened recently. Skipping.',
        );
      }
      return;
    }

    final updatedItem = originalItem.copyWith(lastOpenedTimestamp: now);

    // Optimistic UI Update (update the item in the list)
    final optimisticItems = List<WorkbenchItemReference>.from(state.items);
    optimisticItems[index] = updatedItem;
    // Re-sort based on the new timestamp
    optimisticItems.sort((a, b) {
      final aOpened = a.lastOpenedTimestamp;
      final bOpened = b.lastOpenedTimestamp;
      if (aOpened != null && bOpened != null) {
        return bOpened.compareTo(aOpened);
      }
      if (aOpened != null) {
        return -1;
      }
      if (bOpened != null) {
        return 1;
      }
      return b.addedTimestamp.compareTo(a.addedTimestamp);
    });
    state = state.copyWith(items: optimisticItems);
    if (kDebugMode) {
      print(
        '[WorkbenchNotifier] Optimistically marked item $referenceId as opened.',
      );
    }

    // Persist change to CloudKit (fire and forget or await with error handling)
    try {
      final success = await _cloudKitService.updateWorkbenchItemLastOpened(
        referenceId,
      );
      if (!success) {
        throw Exception('CloudKit update failed');
      }
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier] Successfully synced lastOpenedTimestamp for $referenceId to CloudKit.',
        );
      }
    } catch (e, s) {
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier] Error syncing lastOpenedTimestamp for $referenceId: $e\n$s',
        );
      }
      // Revert optimistic update on failure
      if (mounted) {
        final revertedItems = List<WorkbenchItemReference>.from(state.items);
        final revertIndex = revertedItems.indexWhere(
          (item) => item.id == referenceId,
        );
        if (revertIndex != -1) {
          revertedItems[revertIndex] =
              originalItem; // Put the original item back
          // Re-sort again after reverting
          revertedItems.sort((a, b) {
            final aOpened = a.lastOpenedTimestamp;
            final bOpened = b.lastOpenedTimestamp;
            if (aOpened != null && bOpened != null) {
              return bOpened.compareTo(aOpened);
            }
            if (aOpened != null) {
              return -1;
            }
            if (bOpened != null) {
              return 1;
            }
            return b.addedTimestamp.compareTo(a.addedTimestamp);
          });
          state = state.copyWith(items: revertedItems, error: e);
          if (kDebugMode) {
            print(
              '[WorkbenchNotifier] Reverted optimistic mark opened for item: $referenceId',
            );
          }
        }
      }
    }
  }

} // End of WorkbenchNotifier class

// Provider definition remains the same
final workbenchProvider = StateNotifierProvider<WorkbenchNotifier, WorkbenchState>((ref) {
  final notifier = WorkbenchNotifier(ref);
  // Trigger initial load when the provider is first created/read.
  // Use unawaited to not block provider creation, errors handled internally.
  unawaited(notifier.loadItems());
  return notifier;
});
