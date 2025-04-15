import 'dart:async'; // For unawaited

import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/comment.dart'; // Import Comment
import 'package:flutter_memos/models/server_config.dart'; // Import ServerConfig class
import 'package:flutter_memos/models/workbench_item_reference.dart';
import 'package:flutter_memos/providers/api_providers.dart'; // Import API providers
import 'package:flutter_memos/providers/server_config_provider.dart'; // Import server config provider
import 'package:flutter_memos/providers/service_providers.dart'; // To get CloudKitService
import 'package:flutter_memos/services/base_api_service.dart'; // Import BaseApiService
import 'package:flutter_memos/services/cloud_kit_service.dart';
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
        state = state.copyWith(isRefreshingDetails: false);
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

      // Get the API service for this specific server
      // Assumption: Workbench only shows items for servers configured in multiServerConfigProvider
      // Find the server config, allowing it to be null
      final serverConfig = _ref
          .read(multiServerConfigProvider)
          .servers
          .cast<ServerConfig?>() // Cast to nullable type
          .firstWhere(
            (s) => s?.id == serverId,
            orElse: () => null, // Ensure orElse returns null
          );

      // Get the correct API service instance (assuming apiServiceProvider is NOT a family)
      // This relies on the apiServiceProvider correctly reconfiguring when activeServer changes.
      // For fetching details of non-active servers, a different approach (e.g., family provider or direct instantiation) would be needed.
      // For now, we proceed assuming the active server matches the items being processed or that the service handles overrides.
      // Let's try getting the active service and passing the override.
      final BaseApiService apiService = _ref.read(apiServiceProvider);

      for (final itemRef in serverItems) {
        detailFetchFutures.add(() async {
          try {
            Comment? latestComment;
            DateTime? noteUpdateTime;
            DateTime overallLastUpdateTime = itemRef.addedTimestamp;

            // Only fetch comments/note details for NOTE items
            if (itemRef.referencedItemType == WorkbenchItemType.note) {
              // Fetch Note Item to get its update time
              try {
                // Pass the specific server config to the API call if supported
                final note = await apiService.getNote(
                  itemRef.referencedItemId,
                  targetServerOverride: serverConfig,
                );
                noteUpdateTime = note.updateTime;
                if (noteUpdateTime.isAfter(overallLastUpdateTime)) {
                  overallLastUpdateTime = noteUpdateTime;
                }
              } catch (e) {
                if (kDebugMode)
                  print(
                    '[WorkbenchNotifier] Error fetching note ${itemRef.referencedItemId} on server $serverId: $e',
                  );
                // Continue without note update time
              }

              // Fetch comments
              try {
                // Pass the specific server config to the API call if supported
                final comments = await apiService.listNoteComments(
                  itemRef.referencedItemId,
                  targetServerOverride: serverConfig,
                );
                if (comments.isNotEmpty) {
                  // Sort comments to find the latest (by updateTime or createTime)
                  comments.sort((a, b) {
                    final timeA = a.updateTime ?? a.createTime;
                    final timeB = b.updateTime ?? b.createTime;
                    return timeB.compareTo(timeA); // Descending
                  });
                  latestComment = comments.first;
                  final commentTime =
                      latestComment.updateTime ?? latestComment.createTime;
                  final commentDateTime = DateTime.fromMillisecondsSinceEpoch(
                    commentTime,
                  );
                  if (commentDateTime.isAfter(overallLastUpdateTime)) {
                    overallLastUpdateTime = commentDateTime;
                  }
                }
              } catch (e) {
                if (kDebugMode)
                  print(
                    '[WorkbenchNotifier] Error fetching comments for note ${itemRef.referencedItemId} on server $serverId: $e',
                  );
                // Continue without comments
              }
            }
            // else: If item is a comment, overallLastUpdateTime remains addedTimestamp

            return itemRef.copyWith(
              latestComment: () => latestComment, // Use ValueGetter for null
              referencedItemUpdateTime: () => noteUpdateTime,
              overallLastUpdateTime: overallLastUpdateTime,
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
    state = state.copyWith(items: newItems, clearError: true);

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

    final itemToRemove = state.items.firstWhere(
      (item) => item.id == itemId,
      orElse: () => null, // Use orElse to return null if not found
    );

    // Optimistic update
    final originalItems = List<WorkbenchItemReference>.from(state.items);
    final newItems = originalItems.where((item) => item.id != itemId).toList();
    // No need to re-sort here as relative order is maintained
    state = state.copyWith(items: newItems, clearError: true);

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
    state = state.copyWith(items: currentItems);
    if (kDebugMode) {
      print(
        '[WorkbenchNotifier] Reordered items: $oldIndex -> $effectiveNewIndex',
      );
    }
    // Note: Reordering is local only, not persisted to CloudKit order.
    // Default sort is applied on load/refresh.
  }
} // End of WorkbenchNotifier class

// Provider definition - constructor signature changed
final workbenchProvider = StateNotifierProvider<
  WorkbenchNotifier,
  WorkbenchState
>((ref) {
  // Constructor no longer takes loadOnInit
  final notifier = WorkbenchNotifier(ref);
  // IMPORTANT: The application UI (e.g., WorkbenchScreen) will now need
  // to trigger the initial loadItems call if it wasn't already.
  // Consider calling loadItems here if it should always load on provider init.
  // notifier.loadItems(); // Uncomment if initial load is desired here
  return notifier;
});
