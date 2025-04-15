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
      // Sort by added timestamp, newest first
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

    // Optimistic Update
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

    // Optimistic Update
    state = state.copyWith(items: optimisticItems);
     if (kDebugMode) {
       print('[WorkbenchNotifier] Optimistically removed item: $referenceId');
     }

    try {
      final success = await _cloudKitService.deleteWorkbenchItemReference(referenceId);
      if (!success) {
        throw Exception('Failed to delete item from CloudKit');
      }
      // If successful, state is already correct
       if (kDebugMode) {
         print('[WorkbenchNotifier] Successfully deleted item $referenceId from CloudKit.');
       }
    } catch (e, s) {
      if (kDebugMode) {
        print('[WorkbenchNotifier] Error deleting item $referenceId: $e\n$s');
      }
      // Revert optimistic update on failure
      if (mounted && originalItem != null) {
        final revertedItems = List<WorkbenchItemReference>.from(state.items)..add(originalItem!);
        revertedItems.sort((a, b) => b.addedTimestamp.compareTo(a.addedTimestamp));
        state = state.copyWith(items: revertedItems, error: e); // Keep the error state
         if (kDebugMode) {
           print('[WorkbenchNotifier] Reverted optimistic remove for item: $referenceId');
         }
      }
    }
  }
}

// Provider definition
final workbenchProvider = StateNotifierProvider<WorkbenchNotifier, WorkbenchState>((ref) {
  final notifier = WorkbenchNotifier(ref);
  // Trigger initial load when the provider is first created/read.
  // Use unawaited to not block provider creation, errors handled internally.
  unawaited(notifier.loadItems());
  return notifier;
});
