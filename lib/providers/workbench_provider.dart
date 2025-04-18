import 'dart:async'; // For unawaited

import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart';
import 'package:flutter_memos/models/workbench_item_type.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/providers/service_providers.dart';
import 'package:flutter_memos/providers/workbench_instances_provider.dart';
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
      isRefreshingDetails:
          isRefreshingDetails ?? this.isRefreshingDetails,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is WorkbenchState &&
        listEquals(other.items, items) &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.isRefreshingDetails == isRefreshingDetails;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(items), isLoading, error, isRefreshingDetails);
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
    if (state.isLoading || state.isRefreshingDetails) {
      return;
    }
    if (!mounted) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Add logging before fetching
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] loadItems: Fetching references for this instance.',
        );
      }
      final references = await _cloudKitService.getAllWorkbenchItemReferences(
        instanceId: instanceId,
      );
      // Add logging after fetching, before sorting/processing
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] loadItems: Fetched ${references.length} raw references from CloudKit.',
        );
      }
      references.sort((a, b) => b.addedTimestamp.compareTo(a.addedTimestamp));
      if (mounted) {
        state = state.copyWith(items: references, isLoading: false);
        if (kDebugMode) {
          print(
            '[WorkbenchNotifier($instanceId)] Loaded ${references.length} references.',
          );
        }
        unawaited(_fetchAndPopulateDetails(references));
      }
    } catch (e, s) {
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] Error loading references: $e\n$s',
        );
      }
      if (mounted) {
        state = state.copyWith(error: e, isLoading: false);
      }
    }
  }

  DateTime _getCommentTimestamp(Comment comment) {
    return comment.updatedTs ?? comment.createdTs;
  }

  Future<void> _fetchAndPopulateDetails(
    List<WorkbenchItemReference> itemsToProcess,
  ) async {
    // Add instanceId to log messages
    if (!mounted || itemsToProcess.isEmpty) {
      if (state.isRefreshingDetails) {
        if (mounted) {
          state = state.copyWith(isRefreshingDetails: false);
        }
      }
      return;
    }

    final Map<String, List<WorkbenchItemReference>> itemsByServer = {};
    for (final item in itemsToProcess) {
      if (item.instanceId != instanceId) {
        // Add logging for skipped items
        if (kDebugMode) {
          print(
            '[WorkbenchNotifier($instanceId)] _fetchAndPopulateDetails: Skipping item ${item.id} because its instanceId (${item.instanceId}) does not match.',
          );
        }
        continue; // Skip items not belonging to this instance
      }
      // Add logging for items being processed
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] _fetchAndPopulateDetails: Processing item ${item.id} for server ${item.serverId}.',
        );
      }
      (itemsByServer[item.serverId] ??= []).add(item);
    }

    if (itemsByServer.isEmpty && itemsToProcess.isNotEmpty) {
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] _fetchAndPopulateDetails called with items not belonging to this instance.',
        );
      }
      if (mounted && state.isRefreshingDetails) {
        state = state.copyWith(isRefreshingDetails: false);
      }
      return;
    }

    final List<Future<WorkbenchItemReference>> detailFetchFutures = [];

    for (final serverEntry in itemsByServer.entries) {
      final serverId = serverEntry.key;
      final serverItems = serverEntry.value;

      final serverConfig = _ref
          .read(multiServerConfigProvider)
          .servers
          .cast<ServerConfig?>()
          .firstWhere(
            (s) => s?.id == serverId,
            orElse: () => null,
          );

      if (serverConfig == null) {
        if (kDebugMode) {
          print(
            '[WorkbenchNotifier($instanceId)] Server config not found for $serverId. Skipping detail fetch for its items.',
          );
        }
        detailFetchFutures.addAll(
          serverItems.map((item) => Future.value(item)),
        );
        continue; // Skip if server config doesn't exist anymore
      }

      final baseApiService = _ref.read(apiServiceProvider);

      bool serviceTypeMatches =
          ((serverConfig.serverType == ServerType.memos ||
                  serverConfig.serverType == ServerType.blinko) &&
              baseApiService is NoteApiService) ||
          ((serverConfig.serverType == ServerType.todoist) &&
              baseApiService is TaskApiService);

      if (serverConfig.id != _ref.read(activeServerConfigProvider)?.id) {
        if (kDebugMode) {
          print(
            '[WorkbenchNotifier($instanceId)] Skipping detail fetch for items on non-active server $serverId (${serverConfig.serverType.name}).',
          );
        }
        detailFetchFutures.addAll(
          serverItems.map((item) => Future.value(item)),
        );
        continue; // Skip fetching for this server group
      }

      if (!serviceTypeMatches) {
        if (kDebugMode) {
          print(
            '[WorkbenchNotifier($instanceId)] Active API service type (${baseApiService.runtimeType}) does not match required type for server $serverId (${serverConfig.serverType.name}). Skipping detail fetch.',
          );
        }
        detailFetchFutures.addAll(
          serverItems.map((item) => Future.value(item)),
        );
        continue;
      }

      final NoteApiService? noteApiService =
          baseApiService is NoteApiService &&
                  (serverConfig.serverType == ServerType.memos ||
                      serverConfig.serverType == ServerType.blinko)
              ? baseApiService
              : null;
      final TaskApiService? taskApiService =
          baseApiService is TaskApiService &&
                  serverConfig.serverType == ServerType.todoist
              ? baseApiService
              : null;

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
                if (referencedItemUpdateTime.isAfter(overallLastUpdateTime)) {
                  overallLastUpdateTime = referencedItemUpdateTime;
                }
              } catch (e) {
                if (kDebugMode) {
                  print(
                    '[WorkbenchNotifier($instanceId)] Error fetching note ${itemRef.referencedItemId} on server $serverId: $e',
                  );
                }
                // Keep original preview/times if fetch fails
              }

              try {
                fetchedComments = await noteApiService.listNoteComments(
                  itemRef.referencedItemId,
                );
              } catch (e) {
                if (kDebugMode) {
                  print(
                    '[WorkbenchNotifier($instanceId)] Error fetching comments for note ${itemRef.referencedItemId} on server $serverId: $e',
                  );
                }
              }
            } else if (itemRef.referencedItemType == WorkbenchItemType.task &&
                taskApiService != null) {
              try {
                final task = await taskApiService.getTask(
                  itemRef.referencedItemId,
                );
                referencedItemUpdateTime = task.createdAt;
                updatedPreviewContent = task.content;
                if (referencedItemUpdateTime.isAfter(overallLastUpdateTime)) {
                  overallLastUpdateTime = referencedItemUpdateTime;
                }

                try {
                  fetchedComments = await taskApiService.listComments(
                    itemRef.referencedItemId,
                  );
                } catch (e) {
                  if (kDebugMode) {
                    print(
                      '[WorkbenchNotifier($instanceId)] Error fetching comments for task ${itemRef.referencedItemId} on server $serverId: $e',
                    );
                  }
                }
              } catch (e) {
                if (kDebugMode) {
                  print(
                    '[WorkbenchNotifier($instanceId)] Error fetching task ${itemRef.referencedItemId} on server $serverId: $e',
                  );
                }
                // Keep original preview/times if fetch fails
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
              if (latestCommentTimestamp.isAfter(overallLastUpdateTime)) {
                overallLastUpdateTime = latestCommentTimestamp;
              }
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
            if (kDebugMode) {
              print(
                '[WorkbenchNotifier($instanceId)] Error processing item ${itemRef.id} (refId: ${itemRef.referencedItemId}) on server $serverId: $e',
              );
            }
            return itemRef; // Return original item on error for this specific item
          }
        }()); // Immediately invoke the async closure
      }
    }

    final List<WorkbenchItemReference> results = await Future.wait(
      detailFetchFutures,
    );

    if (mounted) {
      final currentItemsMap = {for (var item in state.items) item.id: item};
      for (final updatedItem in results) {
        if (updatedItem.instanceId == instanceId) {
          currentItemsMap[updatedItem.id] = updatedItem;
        }
      }
      final finalItems = currentItemsMap.values.toList();
      finalItems.sort(
        (a, b) => b.overallLastUpdateTime.compareTo(a.overallLastUpdateTime),
      );

      if (mounted) {
        state = state.copyWith(
          items: finalItems,
          isRefreshingDetails: false,
          isLoading: false,
        );
        if (kDebugMode) {
          print(
            '[WorkbenchNotifier($instanceId)] Finished fetching details for ${results.length} items.',
          );
        }
      }
    }
  }

  Future<void> refreshItemDetails() async {
    if (state.isLoading || state.isRefreshingDetails) {
      return;
    }
    if (!mounted) {
      return;
    }

    // Check if there are items to refresh
    if (state.items.isEmpty) {
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] No items to refresh details for.',
        );
      }
      return;
    }

    if (mounted) {
      state = state.copyWith(isRefreshingDetails: true, clearError: true);
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] Refreshing details for ${state.items.length} items.',
        );
      }
      await _fetchAndPopulateDetails(List.from(state.items));
    }
  }

  void resetOrder() {
    if (!mounted) {
      return;
    }

    final List<WorkbenchItemReference> currentItems = List.from(state.items);
    currentItems.sort(
      (a, b) => b.overallLastUpdateTime.compareTo(a.overallLastUpdateTime),
    );

    state = state.copyWith(items: currentItems);
    if (kDebugMode) {
      print(
        '[WorkbenchNotifier($instanceId)] Reset item order to default (last activity first).',
      );
    }
  }

  /// Adds an item to the workbench, including saving to CloudKit.
  /// Checks for duplicates based on referencedItemId and serverId within the instance.
  Future<void> addItem(WorkbenchItemReference item) async {
    if (!mounted) {
      return;
    }

    // Ensure the item being added belongs to this notifier's instance
    if (item.instanceId != instanceId) {
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] Attempted to add item ${item.id} belonging to instance ${item.instanceId}. Skipping.',
        );
      }
      return;
    }

    final isDuplicate = state.items.any(
      (existingItem) =>
          existingItem.referencedItemId == item.referencedItemId &&
          existingItem.serverId == item.serverId,
    );

    if (isDuplicate) {
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] Item with refId ${item.referencedItemId} on server ${item.serverId} already exists in this instance. Skipping add.',
        );
      }
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
    if (mounted) {
      state = state.copyWith(items: newItems, clearError: true);
    }

    try {
      final success = await _cloudKitService.saveWorkbenchItemReference(item);
      if (!success) {
        throw Exception('CloudKit save failed');
      }
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] Added item ${item.id} successfully.',
        );
      }
      final addedItemInState = state.items.firstWhere(
        (i) => i.id == item.id,
        orElse: () => newItemWithDefaults,
      );
      unawaited(_fetchAndPopulateDetails([addedItemInState]));
    } catch (e, s) {
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] Error adding item ${item.id}: $e\n$s',
        );
      }
      if (mounted) {
        originalItems.sort(
          (a, b) => b.overallLastUpdateTime.compareTo(a.overallLastUpdateTime),
        );
        state = state.copyWith(items: originalItems, error: e);
      }
    }
  }

  /// Private helper to add an existing item reference to the local state
  /// *without* saving to CloudKit and *without* duplicate checks.
  /// Used internally by `moveItem`.
  void _addExistingItem(WorkbenchItemReference item) {
    if (!mounted) return;
    // Ensure item belongs to this instance before adding
    if (item.instanceId != instanceId) {
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] _addExistingItem called with item ${item.id} for wrong instance ${item.instanceId}. Skipping.',
        );
      }
      return;
    }

    final newItems = [...state.items, item];
    newItems.sort(
      (a, b) => b.overallLastUpdateTime.compareTo(a.overallLastUpdateTime),
    );
    state = state.copyWith(items: newItems, clearError: true);
    if (kDebugMode) {
      print(
        '[WorkbenchNotifier($instanceId)] Added existing item ${item.id} locally.',
      );
    }
    // Fetch details for the newly added item
    unawaited(_fetchAndPopulateDetails([item]));
  }


  Future<void> removeItem(String itemId) async {
    if (!mounted) {
      return;
    }

    // Check if the item exists in the current state before optimistic update
    final itemExists = state.items.any((item) => item.id == itemId);
    if (!itemExists) {
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] Item with ID $itemId not found in this instance. Skipping remove.',
        );
      }
      return;
    }

    final originalItems = List<WorkbenchItemReference>.from(state.items);
    final newItems = originalItems.where((item) => item.id != itemId).toList();
    if (mounted) {
      state = state.copyWith(items: newItems, clearError: true);
    }

    try {
      final success = await _cloudKitService.deleteWorkbenchItemReference(
        itemId,
      );
      if (!success) {
        throw Exception('CloudKit delete failed');
      }
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] Removed item $itemId successfully.',
        );
      }
      _ref
          .read(workbenchInstancesProvider.notifier)
          .setLastOpenedItem(instanceId, null);
    } catch (e, s) {
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] Error removing item $itemId: $e\n$s',
        );
      }
      if (mounted) {
        originalItems.sort(
          (a, b) => b.overallLastUpdateTime.compareTo(a.overallLastUpdateTime),
        );
        state = state.copyWith(items: originalItems, error: e);
      }
    }
  }

  /// Moves an item from this workbench instance to another.
  Future<void> moveItem({
    required String itemId,
    required String targetInstanceId,
  }) async {
    if (!mounted) return;
    if (targetInstanceId == instanceId) {
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] Attempted to move item $itemId to the same instance. Skipping.',
        );
      }
      return; // Cannot move to the same instance
    }

    // 1. Find the item in the current state
    WorkbenchItemReference? itemToMove;
    try {
      itemToMove = state.items.firstWhere((i) => i.id == itemId);
    } catch (e) {
      // Item not found in current state
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] Item with ID $itemId not found for move operation.',
        );
      }
      state = state.copyWith(error: Exception('Item to move not found.'));
      return;
    }

    // Store original state for potential rollback
    final originalItems = List<WorkbenchItemReference>.from(state.items);

    // 2. Optimistic UI update: Remove from current notifier's list
    final newItems = originalItems.where((item) => item.id != itemId).toList();
    if (mounted) {
      state = state.copyWith(items: newItems, clearError: true);
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] Optimistically removed item $itemId for move.',
        );
      }
    }

    try {
      // 3. Call CloudKit service to update the instanceId
      final success = await _cloudKitService.moveWorkbenchItemReference(
        recordName: itemId,
        newInstanceId: targetInstanceId,
      );

      if (!success) {
        throw Exception('CloudKit move operation failed');
      }

      // 4. On success: Push a copy to the destination notifier
      if (mounted) {
        final movedItemCopy = itemToMove.copyWith(instanceId: targetInstanceId);
        // Use the private helper on the target notifier
        _ref
            .read(workbenchProviderFamily(targetInstanceId).notifier)
            ._addExistingItem(movedItemCopy);

        if (kDebugMode) {
          print(
            '[WorkbenchNotifier($instanceId)] Successfully moved item $itemId to instance $targetInstanceId.',
          );
        }
        // Clear last opened if it was the moved item
        final lastOpened =
            _ref.read(workbenchInstancesProvider).lastOpenedItemId[instanceId];
        if (lastOpened == itemId) {
          _ref
              .read(workbenchInstancesProvider.notifier)
              .setLastOpenedItem(instanceId, null);
        }
      }
    } catch (e, s) {
      // 5. On error: Revert local list and surface error
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] Error moving item $itemId to $targetInstanceId: $e\n$s',
        );
      }
      if (mounted) {
        // Re-sort original items before reverting state
        originalItems.sort(
          (a, b) => b.overallLastUpdateTime.compareTo(a.overallLastUpdateTime),
        );
        state = state.copyWith(items: originalItems, error: e);
      }
    }
  }

  void reorderItems(int oldIndex, int newIndex) {
    if (!mounted) {
      return;
    }
    if (oldIndex < 0 || oldIndex >= state.items.length) {
      return;
    }
    if (newIndex < 0 || newIndex > state.items.length) {
      return;
    } // Allow newIndex == length

    final currentItems = List<WorkbenchItemReference>.from(state.items);
    final item = currentItems.removeAt(oldIndex);

    final effectiveNewIndex = (newIndex > oldIndex) ? newIndex - 1 : newIndex;

    if (effectiveNewIndex < 0 || effectiveNewIndex > currentItems.length) {
      return;
    }

    currentItems.insert(effectiveNewIndex, item);
    if (mounted) {
      state = state.copyWith(items: currentItems);
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] Reordered items: $oldIndex -> $effectiveNewIndex',
        );
      }
    }
    // Note: Reordering is local only, not persisted.
  }

  Future<void> clearItems() async {
    if (!mounted) {
      return;
    }
    if (state.items.isEmpty) {
      if (kDebugMode) {
        print('[WorkbenchNotifier($instanceId)] No items to clear.');
      }
      return;
    }

    final originalItems = List<WorkbenchItemReference>.from(state.items);
    if (mounted) {
      state = state.copyWith(items: [], clearError: true);
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] Cleared local items optimistically.',
        );
      }
    }

    Object? firstError;
    bool success = false;

    try {
      success = await _cloudKitService.deleteAllWorkbenchItemReferences(
        instanceId: instanceId,
      );
      if (!success) {
        firstError = Exception(
          'CloudKit deleteAllWorkbenchItemReferences failed for instance $instanceId',
        );
        if (kDebugMode) {
          print('[WorkbenchNotifier($instanceId)] ${firstError.toString()}');
        }
      }
    } catch (e, s) {
      firstError = e;
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] Error clearing items from CloudKit: $e\n$s',
        );
      }
      success = false;
    }

    if (!success && mounted) {
      originalItems.sort(
        (a, b) => b.overallLastUpdateTime.compareTo(a.overallLastUpdateTime),
      );
      state = state.copyWith(
        items: originalItems,
        error: firstError ?? Exception('Failed to clear items from CloudKit'),
      );
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] Reverted state due to CloudKit clear failure. ${originalItems.length} items remain.',
        );
      }
    } else if (mounted) {
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] All items successfully cleared from CloudKit for this instance.',
        );
      }
      if (state.error != null) {
        state = state.copyWith(clearError: true);
      }
      _ref
          .read(workbenchInstancesProvider.notifier)
          .setLastOpenedItem(instanceId, null);
    }
  }
} // End of WorkbenchNotifier class

// --- Provider Definitions ---

final workbenchProviderFamily =
    StateNotifierProvider.family<WorkbenchNotifier, WorkbenchState, String>((
      ref,
      instanceId,
    ) {
      final notifier = WorkbenchNotifier(ref, instanceId);
      notifier.loadItems();
  return notifier;
});

final activeWorkbenchProvider = Provider<WorkbenchState>((ref) {
  final activeInstanceId = ref.watch(
    workbenchInstancesProvider.select((s) => s.activeInstanceId),
  );
  // Ensure family provider is watched correctly
  return ref.watch(workbenchProviderFamily(activeInstanceId));
});

final activeWorkbenchNotifierProvider = Provider<WorkbenchNotifier>((ref) {
  final activeInstanceId = ref.watch(
    workbenchInstancesProvider.select((s) => s.activeInstanceId),
  );
  // Ensure family provider notifier is watched correctly
  return ref.watch(workbenchProviderFamily(activeInstanceId).notifier);
});