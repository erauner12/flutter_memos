import 'dart:async'; // For unawaited

import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart';
import 'package:flutter_memos/models/workbench_item_type.dart';
import 'package:flutter_memos/providers/api_providers.dart'; // Import API providers
// Import new single config providers
import 'package:flutter_memos/providers/note_server_config_provider.dart';
import 'package:flutter_memos/providers/service_providers.dart';
import 'package:flutter_memos/providers/task_server_config_provider.dart';
import 'package:flutter_memos/providers/workbench_instances_provider.dart';
import 'package:flutter_memos/services/base_api_service.dart'; // Import BaseApiService
import 'package:flutter_memos/services/cloud_kit_service.dart';
import 'package:flutter_memos/services/note_api_service.dart';
import 'package:flutter_memos/services/task_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class WorkbenchState {
  final List<WorkbenchItemReference> items;
  final bool isLoading;
  final Object? error;
  final bool isRefreshingDetails;

  const WorkbenchState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.isRefreshingDetails = false,
  });

  WorkbenchState copyWith({
    List<WorkbenchItemReference>? items,
    bool? isLoading,
    Object? error,
    bool clearError = false,
    bool? isRefreshingDetails,
  }) {
    return WorkbenchState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isRefreshingDetails: isRefreshingDetails ?? this.isRefreshingDetails,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkbenchState &&
        listEquals(other.items, items) &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.isRefreshingDetails == isRefreshingDetails;
  }

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(items), isLoading, error, isRefreshingDetails);
}

class WorkbenchNotifier extends StateNotifier<WorkbenchState> {
  final Ref _ref;
  final String instanceId;
  late final CloudKitService _cloudKitService;
  static const int _maxPreviewComments = 2;

  WorkbenchNotifier(this._ref, this.instanceId)
    : super(const WorkbenchState()) {
    _cloudKitService = _ref.read(cloudKitServiceProvider);
  }

  Future<void> loadItems() async {
    if (state.isLoading || state.isRefreshingDetails) return;
    if (!mounted) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      if (kDebugMode)
        print(
          '[WorkbenchNotifier($instanceId)] loadItems: Fetching references for this instance.',
        );
      final references = await _cloudKitService.getAllWorkbenchItemReferences(
        instanceId: instanceId,
      );
      if (kDebugMode)
        print(
          '[WorkbenchNotifier($instanceId)] loadItems: Fetched ${references.length} raw references from CloudKit.',
        );
      // Keep original sort order from CloudKit for now, sort later if needed
      // references.sort((a, b) => b.addedTimestamp.compareTo(a.addedTimestamp));
      if (mounted) {
        state = state.copyWith(items: references, isLoading: false);
        if (kDebugMode)
          print(
            '[WorkbenchNotifier($instanceId)] Loaded ${references.length} references.',
          );
        unawaited(_fetchAndPopulateDetails(references));
      }
    } catch (e, s) {
      if (kDebugMode)
        print(
          '[WorkbenchNotifier($instanceId)] Error loading references: $e\n$s',
        );
      if (mounted) state = state.copyWith(error: e, isLoading: false);
    }
  }

  DateTime _getCommentTimestamp(Comment comment) {
    return comment.updatedTs ?? comment.createdTs;
  }

  Future<void> _fetchAndPopulateDetails(
    List<WorkbenchItemReference> itemsToProcess,
  ) async {
    if (!mounted || itemsToProcess.isEmpty) {
      if (state.isRefreshingDetails && mounted)
        state = state.copyWith(isRefreshingDetails: false);
      return;
    }

    // Ensure we only process items belonging to *this* notifier's instanceId
    final relevantItems =
        itemsToProcess.where((item) => item.instanceId == instanceId).toList();
    if (relevantItems.isEmpty) {
      if (kDebugMode)
        print(
          '[WorkbenchNotifier($instanceId)] _fetchAndPopulateDetails called but no items belong to this instance.',
        );
      if (mounted && state.isRefreshingDetails)
        state = state.copyWith(isRefreshingDetails: false);
      return;
    }


    final Map<String, List<WorkbenchItemReference>> itemsByServer = {};
    for (final item in relevantItems) {
      // Use filtered list
      if (kDebugMode)
        print(
          '[WorkbenchNotifier($instanceId)] _fetchAndPopulateDetails: Processing item ${item.id} for server ${item.serverId}.',
        );
      (itemsByServer[item.serverId] ??= []).add(item);
    }

    final List<Future<WorkbenchItemReference>> detailFetchFutures = [];
    final noteConfig = _ref.read(noteServerConfigProvider); // Read once
    final taskConfig = _ref.read(taskServerConfigProvider); // Read once

    for (final serverEntry in itemsByServer.entries) {
      final serverId = serverEntry.key;
      final serverItems = serverEntry.value;

      // Determine which config (note or task) matches this serverId
      ServerConfig? serverConfig;
      BaseApiService? apiService; // Use BaseApiService initially

      try {
        if (noteConfig?.id == serverId) {
          serverConfig = noteConfig;
          apiService = _ref.read(noteApiServiceProvider); // Sync read is fine
        } else if (taskConfig?.id == serverId) {
          serverConfig = taskConfig;
          // Await the future for the task service
          apiService = await _ref.read(taskApiServiceProvider.future);
        }
      } catch (e, s) {
        if (kDebugMode)
          print(
            '[WorkbenchNotifier($instanceId)] Error getting API service for server $serverId: $e\n$s',
          );
        // Add items without details if service fails to load
        detailFetchFutures.addAll(
          serverItems.map((item) => Future.value(item)),
        );
        continue; // Skip to next server
      }


      if (serverConfig == null ||
          apiService == null ||
          apiService is DummyNoteApiService ||
          apiService is DummyTaskApiService) {
        if (kDebugMode)
          print(
            '[WorkbenchNotifier($instanceId)] Server config ($serverId) not found or service not configured. Skipping detail fetch for its items.',
          );
        detailFetchFutures.addAll(
          serverItems.map((item) => Future.value(item)),
        ); // Add items without details
        continue;
      }

      // Cast the service based on the item type we expect to fetch
      final NoteApiService? noteApiService =
          apiService is NoteApiService ? apiService : null;
      final TaskApiService? taskApiService =
          apiService is TaskApiService ? apiService : null;

      for (final itemRef in serverItems) {
        detailFetchFutures.add(() async {
          try {
            List<Comment> fetchedComments = [];
            DateTime? latestCommentTimestamp;
            DateTime? referencedItemUpdateTime;
            String? updatedPreviewContent = itemRef.previewContent;
            DateTime overallLastUpdateTime = itemRef.addedTimestamp;

            if (itemRef.referencedItemType == WorkbenchItemType.note &&
                noteApiService != null) {
              try {
                final note = await noteApiService.getNote(
                  itemRef.referencedItemId,
                );
                referencedItemUpdateTime = note.updateTime;
                updatedPreviewContent = note.content;
                if (referencedItemUpdateTime.isAfter(overallLastUpdateTime))
                  overallLastUpdateTime = referencedItemUpdateTime;
              } catch (e) {
                if (kDebugMode)
                  print(
                    '[WorkbenchNotifier($instanceId)] Error fetching note ${itemRef.referencedItemId} on server $serverId: $e',
                  );
              }
              try {
                fetchedComments = await noteApiService.listNoteComments(
                  itemRef.referencedItemId,
                );
              } catch (e) {
                if (kDebugMode)
                  print(
                    '[WorkbenchNotifier($instanceId)] Error fetching comments for note ${itemRef.referencedItemId} on server $serverId: $e',
                  );
              }
            } else if (itemRef.referencedItemType == WorkbenchItemType.task &&
                taskApiService != null) {
              try {
                final task = await taskApiService.getTask(
                  itemRef.referencedItemId,
                );
                referencedItemUpdateTime = task.updatedAt ?? task.createdAt;
                updatedPreviewContent = task.title;
                if (referencedItemUpdateTime.isAfter(overallLastUpdateTime))
                  overallLastUpdateTime = referencedItemUpdateTime;
                try {
                  fetchedComments = await taskApiService.listComments(
                    itemRef.referencedItemId,
                  );
                } catch (e) {
                  if (kDebugMode)
                    print(
                      '[WorkbenchNotifier($instanceId)] Error fetching comments for task ${itemRef.referencedItemId} on server $serverId: $e',
                    );
                }
              } catch (e) {
                if (kDebugMode)
                  print(
                    '[WorkbenchNotifier($instanceId)] Error fetching task ${itemRef.referencedItemId} on server $serverId: $e',
                  );
              }
            }

            List<Comment> previewComments = [];
            if (fetchedComments.isNotEmpty) {
              fetchedComments.sort(
                (a, b) =>
                    _getCommentTimestamp(b).compareTo(_getCommentTimestamp(a)),
              );
              latestCommentTimestamp = _getCommentTimestamp(
                fetchedComments.first,
              );
              if (latestCommentTimestamp.isAfter(overallLastUpdateTime))
                overallLastUpdateTime = latestCommentTimestamp;
              previewComments =
                  fetchedComments.take(_maxPreviewComments).toList();
            }

            return itemRef.copyWith(
              previewComments: previewComments,
              referencedItemUpdateTime: () => referencedItemUpdateTime,
              overallLastUpdateTime: overallLastUpdateTime,
              previewContent: updatedPreviewContent,
            );
          } catch (e) {
            if (kDebugMode)
              print(
                '[WorkbenchNotifier($instanceId)] Error processing item ${itemRef.id} (refId: ${itemRef.referencedItemId}) on server $serverId: $e',
              );
            return itemRef; // Return original item on error
          }
        }());
      }
    }

    final List<WorkbenchItemReference> results = await Future.wait(
      detailFetchFutures,
    );

    if (mounted) {
      // Get current items *only for this instance*
      final currentItemsMap = {
        for (var item in state.items.where((i) => i.instanceId == instanceId))
          item.id: item,
      };
      // Update the map with new results (which should also belong to this instance)
      for (final updatedItem in results) {
        if (updatedItem.instanceId == instanceId) {
          currentItemsMap[updatedItem.id] = updatedItem;
        } else if (kDebugMode) {
          print(
            '[WorkbenchNotifier($instanceId)] WARNING: Received updated item ${updatedItem.id} belonging to wrong instance ${updatedItem.instanceId} during detail fetch.',
          );
        }
      }
      // Get items from *other* instances that might be in the state (shouldn't happen ideally)
      final otherInstanceItems =
          state.items.where((i) => i.instanceId != instanceId).toList();

      // Combine this instance's updated items with any others
      final finalItems = [...currentItemsMap.values, ...otherInstanceItems];

      // Sort based on the desired criteria (e.g., overallLastUpdateTime)
      finalItems.sort(
        (a, b) => b.overallLastUpdateTime.compareTo(a.overallLastUpdateTime),
      );

      if (mounted) {
        state = state.copyWith(
          items: finalItems,
          isRefreshingDetails: false,
          isLoading:
              false, // Ensure loading is set to false after details are fetched
        );
        if (kDebugMode)
          print(
            '[WorkbenchNotifier($instanceId)] Finished fetching details for ${results.length} items belonging to this instance.',
          );
      }
    }
  }


  Future<void> refreshItemDetails() async {
    if (state.isLoading || state.isRefreshingDetails) return;
    if (!mounted) return;
    final itemsForThisInstance =
        state.items.where((i) => i.instanceId == instanceId).toList();
    if (itemsForThisInstance.isEmpty) {
      if (kDebugMode)
        print(
          '[WorkbenchNotifier($instanceId)] No items in this instance to refresh details for.',
        );
      return;
    }
    if (mounted) {
      state = state.copyWith(isRefreshingDetails: true, clearError: true);
      if (kDebugMode)
        print(
          '[WorkbenchNotifier($instanceId)] Refreshing details for ${itemsForThisInstance.length} items in this instance.',
        );
      // Pass only the items belonging to this instance
      await _fetchAndPopulateDetails(itemsForThisInstance);
    }
  }

  void resetOrder() {
    if (!mounted) return;
    final List<WorkbenchItemReference> currentItems = List.from(state.items);
    // Only sort items belonging to this instance? Or all items? Let's sort all for now.
    currentItems.sort(
      (a, b) => b.overallLastUpdateTime.compareTo(a.overallLastUpdateTime),
    );
    state = state.copyWith(items: currentItems);
    if (kDebugMode)
      print(
        '[WorkbenchNotifier($instanceId)] Reset item order to default (last activity first).',
      );
  }

  Future<void> addItem(WorkbenchItemReference item) async {
    if (!mounted) return;
    if (item.instanceId != instanceId) {
      if (kDebugMode)
        print(
          '[WorkbenchNotifier($instanceId)] Attempted to add item ${item.id} belonging to instance ${item.instanceId}. Skipping.',
        );
      return;
    }
    final isDuplicate = state.items.any(
      (existingItem) =>
          existingItem.referencedItemId == item.referencedItemId &&
          existingItem.serverId == item.serverId &&
          existingItem.instanceId == instanceId, // Check instanceId too
    );
    if (isDuplicate) {
      if (kDebugMode)
        print(
          '[WorkbenchNotifier($instanceId)] Item with refId ${item.referencedItemId} on server ${item.serverId} already exists in this instance. Skipping add.',
        );
      return;
    }

    final originalItems = List<WorkbenchItemReference>.from(state.items);
    final newItemWithDefaults = item.copyWith(
      overallLastUpdateTime: item.addedTimestamp,
    );
    final newItems = [...originalItems, newItemWithDefaults];
    newItems.sort(
      (a, b) => b.overallLastUpdateTime.compareTo(a.overallLastUpdateTime),
    );
    if (mounted) state = state.copyWith(items: newItems, clearError: true);

    try {
      final success = await _cloudKitService.saveWorkbenchItemReference(item);
      if (!success) throw Exception('CloudKit save failed');
      if (kDebugMode)
        print(
          '[WorkbenchNotifier($instanceId)] Added item ${item.id} successfully.',
        );
      // Find the added item in the *current* state to fetch details
      final addedItemInState = state.items.firstWhere(
        (i) => i.id == item.id,
        orElse: () => newItemWithDefaults, // Fallback just in case
      );
      // Fetch details only for the newly added item
      unawaited(_fetchAndPopulateDetails([addedItemInState]));
    } catch (e, s) {
      if (kDebugMode)
        print(
          '[WorkbenchNotifier($instanceId)] Error adding item ${item.id}: $e\n$s',
        );
      if (mounted) {
        // Restore original state on error
        originalItems.sort(
          (a, b) => b.overallLastUpdateTime.compareTo(a.overallLastUpdateTime),
        );
        state = state.copyWith(items: originalItems, error: e);
      }
    }
  }

  // Internal method to add an item locally without saving to CloudKit
  // Used when an item is moved *into* this instance.
  void _addExistingItemLocally(WorkbenchItemReference item) {
    if (!mounted) return;
    if (item.instanceId != instanceId) {
      if (kDebugMode)
        print(
          '[WorkbenchNotifier($instanceId)] _addExistingItemLocally called with item ${item.id} for wrong instance ${item.instanceId}. Skipping.',
        );
      return;
    }
    final isDuplicate = state.items.any(
      (existingItem) =>
          existingItem.id == item.id || // Check by new ID
          (existingItem.referencedItemId == item.referencedItemId &&
              existingItem.serverId == item.serverId &&
              existingItem.instanceId == instanceId), // Check content
    );
    if (isDuplicate) {
      if (kDebugMode)
        print(
          '[WorkbenchNotifier($instanceId)] _addExistingItemLocally: Item ${item.id} (refId ${item.referencedItemId}) already exists. Skipping.',
        );
      return;
    }

    final newItems = [...state.items, item];
    newItems.sort(
      (a, b) => b.overallLastUpdateTime.compareTo(a.overallLastUpdateTime),
    );
    state = state.copyWith(items: newItems, clearError: true);
    if (kDebugMode)
      print(
        '[WorkbenchNotifier($instanceId)] Added existing item ${item.id} locally after move.',
      );
    // Fetch details for the newly added item
    unawaited(_fetchAndPopulateDetails([item]));
  }

  Future<void> removeItem(String itemId) async {
    if (!mounted) return;
    try {} catch (e) {
      if (kDebugMode)
        print(
          '[WorkbenchNotifier($instanceId)] Item with ID $itemId not found in this instance. Skipping remove.',
        );
      return;
    }


    final originalItems = List<WorkbenchItemReference>.from(state.items);
    final newItems = originalItems.where((item) => item.id != itemId).toList();
    if (mounted) state = state.copyWith(items: newItems, clearError: true);

    try {
      final success = await _cloudKitService.deleteWorkbenchItemReference(
        itemId,
      );
      if (!success) throw Exception('CloudKit delete failed');
      if (kDebugMode)
        print(
          '[WorkbenchNotifier($instanceId)] Removed item $itemId successfully.',
        );
      // Check if the removed item was the last opened one for this instance
      final lastOpened =
          _ref.read(workbenchInstancesProvider).lastOpenedItemId[instanceId];
      if (lastOpened == itemId) {
        _ref
          .read(workbenchInstancesProvider.notifier)
          .setLastOpenedItem(instanceId, null);
      }

    } catch (e, s) {
      if (kDebugMode)
        print(
          '[WorkbenchNotifier($instanceId)] Error removing item $itemId: $e\n$s',
        );
      if (mounted) {
        // Restore original state on error
        originalItems.sort(
          (a, b) => b.overallLastUpdateTime.compareTo(a.overallLastUpdateTime),
        );
        state = state.copyWith(items: originalItems, error: e);
      }
    }
  }

  Future<void> moveItem({
    required String itemId,
    required String targetInstanceId,
  }) async {
    if (!mounted) return;
    if (targetInstanceId == instanceId) {
      if (kDebugMode)
        print(
          '[WorkbenchNotifier($instanceId)] Attempted to move item $itemId to the same instance. Skipping.',
        );
      return;
    }

    WorkbenchItemReference? itemToMove;
    try {
      // Ensure the item exists in *this* instance before attempting to move it
      itemToMove = state.items.firstWhere(
        (i) => i.id == itemId && i.instanceId == instanceId,
      );
    } catch (e) {
      if (kDebugMode)
        print(
          '[WorkbenchNotifier($instanceId)] Item with ID $itemId not found in this instance for move operation.',
        );
      if (mounted)
        state = state.copyWith(
          error: Exception('Item to move not found in this instance.'),
        );
      return;
    }

    final originalItems = List<WorkbenchItemReference>.from(state.items);
    // Optimistically remove the item from the current instance's state
    final newItems = originalItems.where((item) => item.id != itemId).toList();
    if (mounted) {
      state = state.copyWith(items: newItems, clearError: true);
      if (kDebugMode)
        print(
          '[WorkbenchNotifier($instanceId)] Optimistically removed item $itemId for move.',
        );
    }

    try {
      final oldRecordFields = itemToMove.toJson();
      // Perform the move in CloudKit (delete old, create new with targetInstanceId)
      final maybeNewCloudKitId = await _cloudKitService
          .moveWorkbenchItemReferenceByDeleteRecreate(
            recordName: itemId, // The ID of the record to delete
            newInstanceId: targetInstanceId,
            oldRecordFields:
                oldRecordFields, // Pass existing fields for recreation
          );

      if (maybeNewCloudKitId == null)
        throw Exception('CloudKit delete-recreate move operation failed');

      // Create the representation of the item in the target instance
      final newItemForTarget = itemToMove.copyWith(
        id: maybeNewCloudKitId, // Use the new ID returned by CloudKit
        instanceId: targetInstanceId,
        // Reset transient fields for the target instance
        previewComments: [],
        referencedItemUpdateTime: () => null,
        overallLastUpdateTime:
            itemToMove.addedTimestamp, // Reset to added time initially
      );

      if (mounted) {
        // Get the notifier for the target instance
        final targetNotifier = _ref.read(
          workbenchProviderFamily(targetInstanceId).notifier,
        );
        // Add the item locally to the target notifier's state
        targetNotifier._addExistingItemLocally(newItemForTarget);

        if (kDebugMode)
          print(
            '[WorkbenchNotifier($instanceId)] Successfully processed move for item original ID $itemId to instance $targetInstanceId (new CloudKit ID: $maybeNewCloudKitId). Item added locally to target.',
          );

        // Check if the moved item was the last opened one for this instance
        final lastOpened =
            _ref.read(workbenchInstancesProvider).lastOpenedItemId[instanceId];
        if (lastOpened == itemId) {
          _ref
              .read(workbenchInstancesProvider.notifier)
              .setLastOpenedItem(instanceId, null);
        }
      }
    } catch (e, s) {
      if (kDebugMode)
        print(
          '[WorkbenchNotifier($instanceId)] Error moving item $itemId to $targetInstanceId: $e\n$s',
        );
      if (mounted) {
        // Revert: Add the item back to the current instance's state if the move failed
        final itemsToRestore = List<WorkbenchItemReference>.from(originalItems);
        // Ensure sorting is reapplied if needed
        itemsToRestore.sort(
          (a, b) => b.overallLastUpdateTime.compareTo(a.overallLastUpdateTime),
        );
        state = state.copyWith(items: itemsToRestore, error: e);
        if (kDebugMode)
          print(
            '[WorkbenchNotifier($instanceId)] Reverted state after failed move for item $itemId.',
          );
      }
    }
  }

  void reorderItems(int oldIndex, int newIndex) {
    if (!mounted) return;

    // Operate only on items belonging to this instance
    final instanceItems =
        state.items.where((i) => i.instanceId == instanceId).toList();
    final otherItems =
        state.items.where((i) => i.instanceId != instanceId).toList();

    if (oldIndex < 0 || oldIndex >= instanceItems.length) return;
    // Allow newIndex to be equal to length for moving to the end
    if (newIndex < 0 || newIndex > instanceItems.length) return;

    final item = instanceItems.removeAt(oldIndex);
    // Adjust newIndex if removing item before it shifts the target position
    final effectiveNewIndex = (newIndex > oldIndex) ? newIndex - 1 : newIndex;

    // Ensure effectiveNewIndex is within bounds after removal
    if (effectiveNewIndex < 0 || effectiveNewIndex > instanceItems.length)
      return;

    instanceItems.insert(effectiveNewIndex, item);

    // Combine the reordered instance items with items from other instances
    final combinedItems = [...instanceItems, ...otherItems];
    // Optional: Re-sort the combined list if needed, or maintain separation
    // For now, just update the state with the combined list
    if (mounted) {
      state = state.copyWith(items: combinedItems);
      if (kDebugMode)
        print(
          '[WorkbenchNotifier($instanceId)] Reordered items within instance: $oldIndex -> $effectiveNewIndex',
        );
      // TODO: Persist the new order (e.g., update sortOrder field and save)
    }
  }

  Future<void> clearItems() async {
    if (!mounted) return;
    final itemsInThisInstance =
        state.items.where((i) => i.instanceId == instanceId).toList();
    if (itemsInThisInstance.isEmpty) {
      if (kDebugMode)
        print(
          '[WorkbenchNotifier($instanceId)] No items in this instance to clear.',
        );
      return;
    }

    final originalItems = List<WorkbenchItemReference>.from(state.items);
    // Optimistically remove items belonging to this instance from local state
    final itemsToKeep =
        state.items.where((i) => i.instanceId != instanceId).toList();
    if (mounted) {
      state = state.copyWith(items: itemsToKeep, clearError: true);
      if (kDebugMode)
        print(
          '[WorkbenchNotifier($instanceId)] Cleared local items for this instance optimistically.',
        );
    }

    Object? firstError;
    bool success = false;

    try {
      // Call CloudKit to delete all items *for this specific instance*
      success = await _cloudKitService.deleteAllWorkbenchItemReferences(
        instanceId: instanceId,
      );
      if (!success) {
        firstError = Exception(
          'CloudKit deleteAllWorkbenchItemReferences failed for instance $instanceId',
        );
        if (kDebugMode)
          print('[WorkbenchNotifier($instanceId)] ${firstError.toString()}');
      }
    } catch (e, s) {
      firstError = e;
      if (kDebugMode)
        print(
          '[WorkbenchNotifier($instanceId)] Error clearing items from CloudKit for this instance: $e\n$s',
        );
      success = false;
    }

    if (!success && mounted) {
      // Revert state if CloudKit deletion failed
      originalItems.sort(
        (a, b) => b.overallLastUpdateTime.compareTo(a.overallLastUpdateTime),
      );
      state = state.copyWith(
        items: originalItems,
        error:
            firstError ??
            Exception('Failed to clear items from CloudKit for this instance'),
      );
      if (kDebugMode)
        print(
          '[WorkbenchNotifier($instanceId)] Reverted state due to CloudKit clear failure. ${itemsInThisInstance.length} items restored for this instance.',
        );
    } else if (mounted) {
      if (kDebugMode)
        print(
          '[WorkbenchNotifier($instanceId)] All items successfully cleared from CloudKit for this instance.',
        );
      // Clear any previous error state if successful
      if (state.error != null) state = state.copyWith(clearError: true);
      // Clear last opened item for this instance
      _ref
          .read(workbenchInstancesProvider.notifier)
          .setLastOpenedItem(instanceId, null);
    }
  }
}

// --- Provider Definitions ---

final workbenchProviderFamily =
    StateNotifierProvider.family<WorkbenchNotifier, WorkbenchState, String>((
      ref,
      instanceId,
    ) {
      final notifier = WorkbenchNotifier(ref, instanceId);
      notifier.loadItems(); // Initial load
      return notifier;
    });


// --- Combined State for All Items ---

@immutable
class WorkbenchCombinedState {
  final List<WorkbenchItemReference> items;
  final bool isLoading;
  final Object? error;

  const WorkbenchCombinedState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkbenchCombinedState &&
        listEquals(other.items, items) &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(items), isLoading, error);
}

// Provider to get all items from all instances, handling loading/error states
final allWorkbenchItemsProvider = Provider<WorkbenchCombinedState>((ref) {
  final instancesState = ref.watch(workbenchInstancesProvider);
  final List<WorkbenchItemReference> allItems = [];
  bool isLoading =
      instancesState.isLoading; // Start with instance loading state
  Object? error = instancesState.error;

  if (!isLoading && error == null) {
    for (final instance in instancesState.instances) {
      final instanceItemsState = ref.watch(
        workbenchProviderFamily(instance.id),
      );
      allItems.addAll(instanceItemsState.items);
      if (instanceItemsState.isLoading ||
          instanceItemsState.isRefreshingDetails) {
        isLoading =
            true; // If any instance is loading/refreshing, overall state is loading
      }
      if (error == null && instanceItemsState.error != null) {
        error = instanceItemsState.error; // Capture the first error encountered
      }
    }
  }

  // Sort the combined list only if not loading and no error occurred during instance fetch
  if (!isLoading && error == null) {
    allItems.sort(
      (a, b) => b.overallLastUpdateTime.compareTo(a.overallLastUpdateTime),
    );
  }

  return WorkbenchCombinedState(
    items: allItems,
    isLoading: isLoading,
    error: error,
  );
});
