import 'dart:async'; // For unawaited

import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/comment.dart'; // Import Comment
import 'package:flutter_memos/models/server_config.dart'; // Import ServerConfig class
import 'package:flutter_memos/models/workbench_item_reference.dart';
import 'package:flutter_memos/providers/api_providers.dart'; // Import API providers
import 'package:flutter_memos/providers/server_config_provider.dart'; // Import server config provider
import 'package:flutter_memos/providers/service_providers.dart'; // To get CloudKitService
import 'package:flutter_memos/services/cloud_kit_service.dart';
import 'package:flutter_memos/services/note_api_service.dart';
import 'package:flutter_memos/services/task_api_service.dart'; // Import TaskApiService
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class WorkbenchState {
  final List<WorkbenchItemReference> items;
  final bool isLoading; // Loading references from CloudKit
  final Object? error;
  final bool isRefreshingDetails; // Loading details (comments, note updates)

  const WorkbenchState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.isRefreshingDetails = false, // Default to false
  });

  WorkbenchState copyWith({
    List<WorkbenchItemReference>? items,
    bool? isLoading,
    Object? error,
    bool clearError = false,
    bool? isRefreshingDetails, // Add parameter
  }) {
    return WorkbenchState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isRefreshingDetails:
          isRefreshingDetails ?? this.isRefreshingDetails, // Assign value
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WorkbenchState &&
        listEquals(other.items, items) &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.isRefreshingDetails == isRefreshingDetails; // Compare new flag
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(items),
    isLoading,
    error,
    isRefreshingDetails, // Include new flag in hash
  );
}

class WorkbenchNotifier extends StateNotifier<WorkbenchState> {
  final Ref _ref; // Keep ref
  late final CloudKitService _cloudKitService;

  // Constructor takes Ref, initial state is not loading
  WorkbenchNotifier(this._ref) : super(const WorkbenchState()) {
    _cloudKitService = _ref.read(cloudKitServiceProvider);
    // DO NOT call loadItems automatically here
  }

  Future<void> loadItems() async {
    // Prevent concurrent loads/refreshes
    if (state.isLoading || state.isRefreshingDetails) return;
    if (!mounted) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final references = await _cloudKitService.getAllWorkbenchItemReferences();

      // Initial sort by added timestamp descending
      references.sort((a, b) => b.addedTimestamp.compareTo(a.addedTimestamp));

      if (mounted) {
        // Update state with references, stop initial loading indicator
        state = state.copyWith(items: references, isLoading: false);
        if (kDebugMode) {
          print('[WorkbenchNotifier] Loaded ${references.length} references.');
        }
        // Trigger detail fetching asynchronously without blocking UI or showing loading indicator
        unawaited(_fetchAndPopulateDetails(references));
      }
    } catch (e, s) {
      if (kDebugMode) {
        print('[WorkbenchNotifier] Error loading references: $e\n$s');
      }
      if (mounted) {
        state = state.copyWith(error: e, isLoading: false);
      }
    }
  }

  // Add this new private method inside WorkbenchNotifier class
  Future<void> _fetchAndPopulateDetails(
    List<WorkbenchItemReference> itemsToProcess,
  ) async {
    if (!mounted || itemsToProcess.isEmpty) {
      // If called by refresh, ensure refreshing flag is turned off
      if (state.isRefreshingDetails) {
        if (mounted) {
          state = state.copyWith(isRefreshingDetails: false);
        }
      }
      return;
    }

    // Use a map to group items by server ID
    final Map<String, List<WorkbenchItemReference>> itemsByServer = {};
    for (final item in itemsToProcess) {
      (itemsByServer[item.serverId] ??= []).add(item);
    }

    final List<Future<WorkbenchItemReference>> detailFetchFutures = [];

    // Process items server by server
    for (final serverEntry in itemsByServer.entries) {
      final serverId = serverEntry.key;
      final serverItems = serverEntry.value;

      // Get the server config for this specific server
      final serverConfig = _ref
          .read(multiServerConfigProvider)
          .servers
          .cast<ServerConfig?>()
          .firstWhere(
            (s) => s?.id == serverId,
            orElse: () => null,
          );

      if (serverConfig == null) {
        if (kDebugMode)
          print(
            '[WorkbenchNotifier] Server config not found for $serverId. Skipping detail fetch for its items.',
          );
        continue; // Skip if server config doesn't exist anymore
      }

      // Get the appropriate API service for this server type
      // We might need to instantiate a temporary service if it's not the active one.
      // For simplicity now, we'll assume the active service provider correctly reflects
      // the necessary type IF the server matches the active one, or fetch fails gracefully.
      // A better approach might involve a family provider for services.
      final baseApiService = _ref.read(
        apiServiceProvider,
      ); // This reflects the ACTIVE server's service

      // Check if the ACTIVE service matches the type needed for the CURRENTLY PROCESSED server's items
      bool serviceTypeMatches =
          (serverConfig.serverType == ServerType.memos ||
                  serverConfig.serverType == ServerType.blinko) &&
              baseApiService is NoteApiService ||
          (serverConfig.serverType == ServerType.todoist) &&
              baseApiService is TaskApiService;

      // If the active service doesn't match the server type, we can't fetch details easily right now.
      // We'll log a warning and skip detail fetching for these items.
      // TODO: Implement fetching details from non-active servers (e.g., using a service provider family or temporary instantiation).
      if (serverConfig.id != _ref.read(activeServerConfigProvider)?.id) {
        if (kDebugMode)
          print(
            '[WorkbenchNotifier] Skipping detail fetch for items on non-active server $serverId (${serverConfig.serverType.name}).',
          );
        // Add original items to futures list so they aren't lost
        detailFetchFutures.addAll(
          serverItems.map((item) => Future.value(item)),
        );
        continue; // Skip fetching for this server group
      }
      // If the active server *is* the one we're processing, ensure the service type is correct.
      if (!serviceTypeMatches) {
        if (kDebugMode)
          print(
            '[WorkbenchNotifier] Active API service type (${baseApiService.runtimeType}) does not match required type for server $serverId (${serverConfig.serverType.name}). Skipping detail fetch.',
          );
        detailFetchFutures.addAll(
          serverItems.map((item) => Future.value(item)),
        );
        continue;
      }

      // Cast the active service to the correct type based on the serverConfig
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
            Comment? latestComment;
            DateTime? referencedItemUpdateTime;
            String? updatedPreviewContent =
                itemRef.previewContent; // Keep original unless updated
            DateTime overallLastUpdateTime = itemRef.addedTimestamp;

            if (itemRef.referencedItemType == WorkbenchItemType.note &&
                noteApiService != null) {
              // Fetch Note Item details
              try {
                // Note: Using active service, assuming serverConfig matches active server
                final note = await noteApiService.getNote(
                  itemRef.referencedItemId,
                );
                referencedItemUpdateTime = note.updateTime;
                updatedPreviewContent =
                    note.content; // Update preview from latest note content
                if (referencedItemUpdateTime.isAfter(overallLastUpdateTime)) {
                  overallLastUpdateTime = referencedItemUpdateTime;
                }
              } catch (e) {
                if (kDebugMode)
                  print(
                    '[WorkbenchNotifier] Error fetching note ${itemRef.referencedItemId} on server $serverId: $e',
                  );
              }

              // Fetch comments for Note
              try {
                // Note: Using active service, assuming serverConfig matches active server
                final comments = await noteApiService.listNoteComments(
                  itemRef.referencedItemId,
                );
                if (comments.isNotEmpty) {
                  comments.sort(
                    (a, b) => (b.updatedTs ?? b.createdTs).compareTo(
                      a.updatedTs ?? a.createdTs,
                    ),
                  );
                  latestComment = comments.first;
                  final DateTime commentTime =
                      latestComment.updatedTs ?? latestComment.createdTs;
                  if (commentTime.isAfter(overallLastUpdateTime)) {
                    overallLastUpdateTime = commentTime;
                  }
                }
              } catch (e) {
                if (kDebugMode)
                  print(
                    '[WorkbenchNotifier] Error fetching comments for note ${itemRef.referencedItemId} on server $serverId: $e',
                  );
              }
            } else if (itemRef.referencedItemType == WorkbenchItemType.task &&
                taskApiService != null) {
              // Fetch Task Item details
              try {
                // Note: Using active service, assuming serverConfig matches active server
                final task = await taskApiService.getTask(
                  itemRef.referencedItemId,
                );
                // Use task creation or a hypothetical update time if available
                // Todoist API v2 task object has 'created_at', but not obviously 'updated_at'. Use createdAt for now.
                referencedItemUpdateTime = task.createdAt;
                updatedPreviewContent =
                    task.content; // Update preview from latest task content
                // Determine overall last update time (e.g., creation time, maybe due date?)
                DateTime taskActivityTime = task.createdAt;
                // Consider due date as activity? Maybe not, stick to creation/modification.
                // if (task.dueDate != null && task.dueDate!.isAfter(taskActivityTime)) {
                //   taskActivityTime = task.dueDate!;
                // }
                if (taskActivityTime.isAfter(overallLastUpdateTime)) {
                  overallLastUpdateTime = taskActivityTime;
                }
                // Fetch comments for Task
                try {
                  final comments = await taskApiService.listComments(
                    itemRef.referencedItemId,
                  );
                  if (comments.isNotEmpty) {
                    comments.sort(
                      (a, b) => (b.updatedTs ?? b.createdTs).compareTo(
                        a.updatedTs ?? a.createdTs,
                      ),
                    );
                    latestComment = comments.first;
                    final DateTime commentTime =
                        latestComment.updatedTs ?? latestComment.createdTs;
                    if (commentTime.isAfter(overallLastUpdateTime)) {
                      overallLastUpdateTime = commentTime;
                    }
                  }
                } catch (e) {
                  if (kDebugMode)
                    print(
                      '[WorkbenchNotifier] Error fetching comments for task ${itemRef.referencedItemId} on server $serverId: $e',
                    );
                }
              } catch (e) {
                if (kDebugMode)
                  print(
                    '[WorkbenchNotifier] Error fetching task ${itemRef.referencedItemId} on server $serverId: $e',
                  );
              }
            }
            // else: If item is a comment, overallLastUpdateTime remains addedTimestamp for now

            return itemRef.copyWith(
              latestComment: () => latestComment, // Use ValueGetter for null
              referencedItemUpdateTime: () => referencedItemUpdateTime,
              overallLastUpdateTime: overallLastUpdateTime,
              previewContent: updatedPreviewContent, // Update preview content
            );
          } catch (e) {
            if (kDebugMode)
              print(
                '[WorkbenchNotifier] Error processing item ${itemRef.id} on server $serverId: $e',
              );
            return itemRef; // Return original item on error for this specific item
          }
        }()); // Immediately invoke the async closure
      }
    }

    // Wait for all detail fetching futures to complete
    final List<WorkbenchItemReference> results = await Future.wait(
      detailFetchFutures,
    );

    if (mounted) {
      // Create a map of the current items for efficient update
      final currentItemsMap = {for (var item in state.items) item.id: item};
      // Update the map with the new results (potentially partially populated if errors occurred)
      for (final updatedItem in results) {
        currentItemsMap[updatedItem.id] = updatedItem;
      }
      // Convert back to list and sort by the final overallLastUpdateTime
      final finalItems = currentItemsMap.values.toList();
      finalItems.sort(
        (a, b) => b.overallLastUpdateTime.compareTo(a.overallLastUpdateTime),
      );

      // Check mounted again before final state update
      if (mounted) {
        state = state.copyWith(
          items: finalItems,
          isRefreshingDetails: false, // Ensure this is reset
          isLoading: false, // Ensure this is reset if called from loadItems
        );
        if (kDebugMode) {
          print(
            '[WorkbenchNotifier] Finished fetching details for ${results.length} items.',
          );
        }
      }
    }
  }

  // Add this new public method inside WorkbenchNotifier class
  Future<void> refreshItemDetails() async {
    // Prevent concurrent loads/refreshes
    if (state.isLoading || state.isRefreshingDetails) return;
    if (!mounted) return;

    // Check if there are items to refresh
    if (state.items.isEmpty) {
      if (kDebugMode)
        print('[WorkbenchNotifier] No items to refresh details for.');
      return;
    }

    if (mounted) {
      state = state.copyWith(isRefreshingDetails: true, clearError: true);
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier] Refreshing details for ${state.items.length} items.',
        );
      }
      // Call the detail fetching logic with the current items
      // State update (including isRefreshingDetails = false) happens inside _fetchAndPopulateDetails
      await _fetchAndPopulateDetails(List.from(state.items)); // Pass a copy
    }
  }

  // --- resetOrder ---
  void resetOrder() {
    if (!mounted) return;

    final List<WorkbenchItemReference> currentItems = List.from(state.items);
    // Sort by the calculated overallLastUpdateTime descending (newest activity first)
    currentItems.sort(
      (a, b) => b.overallLastUpdateTime.compareTo(a.overallLastUpdateTime),
    );

    state = state.copyWith(items: currentItems);
    if (kDebugMode) {
      print(
        '[WorkbenchNotifier] Reset item order to default (last activity first).',
      );
    }
  }

  // --- addItem ---
  Future<void> addItem(WorkbenchItemReference item) async {
    if (!mounted) return;

    // Check for duplicates based on referencedItemId and serverId
    final isDuplicate = state.items.any(
      (existingItem) =>
          existingItem.referencedItemId == item.referencedItemId &&
          existingItem.serverId == item.serverId,
    );

    if (isDuplicate) {
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier] Item with refId ${item.referencedItemId} on server ${item.serverId} already exists. Skipping add.',
        );
      }
      // Optionally show a message to the user
      return;
    }

    // Optimistic update
    final originalItems = List<WorkbenchItemReference>.from(state.items);
    final newItems = [...originalItems, item];
    // Sort immediately after adding based on current logic (overallLastUpdateTime)
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
        print('[WorkbenchNotifier] Added item ${item.id} successfully.');
      }
      // Fetch details for the newly added item asynchronously
      unawaited(_fetchAndPopulateDetails([item]));
    } catch (e, s) {
      if (kDebugMode) {
        print('[WorkbenchNotifier] Error adding item ${item.id}: $e\n$s');
      }
      // Revert optimistic update on failure
      if (mounted) {
        // Re-sort the original list to maintain consistency
        originalItems.sort(
          (a, b) => b.overallLastUpdateTime.compareTo(a.overallLastUpdateTime),
        );
        state = state.copyWith(items: originalItems, error: e);
      }
    }
  }

  // --- removeItem ---
  Future<void> removeItem(String itemId) async {
    if (!mounted) return;

    // Check if the item exists before proceeding
    final itemExists = state.items.any((item) => item.id == itemId);

    if (!itemExists) {
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier] Item with ID $itemId not found. Skipping remove.',
        );
      }
      return; // Item not found, do nothing
    }

    // Optimistic update
    final originalItems = List<WorkbenchItemReference>.from(state.items);
    final newItems = originalItems.where((item) => item.id != itemId).toList();
    // No need to re-sort here as relative order is maintained
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
        print('[WorkbenchNotifier] Removed item $itemId successfully.');
      }
    } catch (e, s) {
      if (kDebugMode) {
        print('[WorkbenchNotifier] Error removing item $itemId: $e\n$s');
      }
      // Revert optimistic update on failure
      if (mounted) {
        // Re-sort the original list to ensure correct order before setting state
        originalItems.sort(
          (a, b) => b.overallLastUpdateTime.compareTo(a.overallLastUpdateTime),
        );
        state = state.copyWith(items: originalItems, error: e);
      }
    }
  }

  // --- reorderItems ---
  void reorderItems(int oldIndex, int newIndex) {
    if (!mounted) return;
    if (oldIndex < 0 || oldIndex >= state.items.length) return;
    if (newIndex < 0 || newIndex > state.items.length)
      return; // Allow newIndex == length

    final currentItems = List<WorkbenchItemReference>.from(state.items);
    final item = currentItems.removeAt(oldIndex);

    // Adjust newIndex if item was moved downwards
    final effectiveNewIndex = (newIndex > oldIndex) ? newIndex - 1 : newIndex;

    // Ensure effectiveNewIndex is within bounds after removal
    if (effectiveNewIndex < 0 || effectiveNewIndex > currentItems.length)
      return;

    currentItems.insert(effectiveNewIndex, item);
    if (mounted) {
      state = state.copyWith(items: currentItems);
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier] Reordered items: $oldIndex -> $effectiveNewIndex',
        );
      }
    }
    // Note: Reordering is local only, not persisted to CloudKit order.
    // Default sort is applied on load/refresh.
  }

  // --- clearItems ---
  Future<void> clearItems() async {
    if (!mounted) return;
    if (state.items.isEmpty) {
      if (kDebugMode) print('[WorkbenchNotifier] No items to clear.');
      return;
    }

    final originalItems = List<WorkbenchItemReference>.from(state.items);
    // Optimistic update: Clear local state immediately
    if (mounted) {
      state = state.copyWith(items: [], clearError: true);
      if (kDebugMode)
        print('[WorkbenchNotifier] Cleared local items optimistically.');
    }

    List<String> failedToDeleteIds = [];
    Object? firstError;

    // Attempt to delete all items from CloudKit
    for (final item in originalItems) {
      try {
        final success = await _cloudKitService.deleteWorkbenchItemReference(
          item.id,
        );
        if (!success) {
          failedToDeleteIds.add(item.id);
          if (kDebugMode)
            print(
              '[WorkbenchNotifier] Failed to delete item ${item.id} from CloudKit.',
            );
        }
      } catch (e, s) {
        failedToDeleteIds.add(item.id);
        firstError ??= e; // Store the first error encountered
        if (kDebugMode)
          print(
            '[WorkbenchNotifier] Error deleting item ${item.id} from CloudKit: $e\n$s',
          );
      }
    }

    // If any deletions failed, revert the state to show the items that couldn't be deleted
    if (failedToDeleteIds.isNotEmpty && mounted) {
      final remainingItems =
          originalItems
              .where((item) => failedToDeleteIds.contains(item.id))
              .toList();
      // Re-sort the remaining items
      remainingItems.sort(
        (a, b) => b.overallLastUpdateTime.compareTo(a.overallLastUpdateTime),
      );
      state = state.copyWith(
        items: remainingItems,
        error:
            firstError ??
            Exception('Failed to delete some items from CloudKit'),
      );
      if (kDebugMode)
        print(
          '[WorkbenchNotifier] Reverted state due to CloudKit deletion failures. ${remainingItems.length} items remain.',
        );
    } else if (mounted) {
      // If all deletions succeeded or no failures occurred and still mounted
      if (kDebugMode)
        print(
          '[WorkbenchNotifier] All items successfully cleared from CloudKit.',
        );
      // State is already cleared optimistically, ensure error is null if successful
      if (state.error != null) {
        state = state.copyWith(clearError: true);
      }
    }
  }

} // End of WorkbenchNotifier class

// Provider definition - constructor signature changed
final workbenchProvider =
    StateNotifierProvider<WorkbenchNotifier, WorkbenchState>((ref) {
  final notifier = WorkbenchNotifier(ref);
      // Load items when the provider is first created/read.
      // This replaces the need for the UI to trigger the initial load.
      notifier.loadItems();
  return notifier;
});
