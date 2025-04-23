import 'dart:async'; // For unawaited
import 'dart:convert'; // For jsonEncode/Decode

import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart';
import 'package:flutter_memos/models/workbench_item_type.dart';
import 'package:flutter_memos/providers/api_providers.dart'; // Import API providers
// Import new single config providers
import 'package:flutter_memos/providers/note_server_config_provider.dart';
import 'package:flutter_memos/providers/shared_prefs_provider.dart'; // Import SharedPrefs
import 'package:flutter_memos/providers/task_server_config_provider.dart';
import 'package:flutter_memos/providers/workbench_instances_provider.dart';
import 'package:flutter_memos/services/base_api_service.dart'; // Import BaseApiService
// Removed CloudKitService import
import 'package:flutter_memos/services/note_api_service.dart';
import 'package:flutter_memos/services/task_api_service.dart';
import 'package:flutter_memos/utils/shared_prefs.dart'; // Import SharedPrefsService
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart'; // Import Uuid

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
  // Removed CloudKitService instance
  // late final CloudKitService _cloudKitService;
  late final SharedPrefsService _prefsService; // Add SharedPrefsService
  bool _prefsInitialized = false; // Track prefs initialization
  static const int _maxPreviewComments = 2;

  // Key for storing items for this instance in SharedPreferences
  String get _prefsKey => 'workbench_items_$instanceId';

  WorkbenchNotifier(this._ref, this.instanceId)
    : super(const WorkbenchState(isLoading: true)) {
    // Start loading
    // Removed CloudKitService initialization
    // _cloudKitService = _ref.read(cloudKitServiceProvider);
    _initializePrefsAndLoad();
  }

  Future<void> _initializePrefsAndLoad() async {
    try {
      _prefsService = await _ref.read(sharedPrefsServiceProvider.future);
      _prefsInitialized = true;
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] SharedPrefsService initialized.',
        );
      }
      await loadItems(); // Load items from prefs after initialization
    } catch (e, s) {
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] Error getting SharedPrefsService: $e\n$s',
        );
      }
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load preferences',
        );
      }
    }
  }

  // Load items from SharedPreferences - ensure return type is Future<void>
  Future<void> loadItems() async {
    // Check isLoading flag here as well to prevent concurrent loads
    if (state.isLoading || state.isRefreshingDetails) return;
    if (!mounted || !_prefsInitialized) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      if (kDebugMode)
        print(
          '[WorkbenchNotifier($instanceId)] loadItems: Fetching references from SharedPreferences.',
        );
      final jsonString = _prefsService.getString(_prefsKey);
      List<WorkbenchItemReference> references = [];
      if (jsonString != null) {
        final List<dynamic> decodedList = jsonDecode(jsonString);
        // Fix the call to fromJson (now only needs json map)
        references =
            decodedList
                .map(
                  (data) => WorkbenchItemReference.fromJson(
                    data as Map<String, dynamic>,
                  ),
                )
                .toList(); // This is now List<WorkbenchItemReference>
      }

      if (kDebugMode)
        print(
          '[WorkbenchNotifier($instanceId)] loadItems: Fetched ${references.length} raw references from SharedPreferences.',
        );

      // Sort initially by added timestamp or a default order if needed
      references.sort((a, b) => b.addedTimestamp.compareTo(a.addedTimestamp));

      if (mounted) {
        state = state.copyWith(items: references, isLoading: false);
        if (kDebugMode)
          print(
            '[WorkbenchNotifier($instanceId)] Loaded ${references.length} references.',
          );
        // Fetch details after loading references
        unawaited(_fetchAndPopulateDetails(references));
      }
    } catch (e, s) {
      if (kDebugMode)
        print(
          '[WorkbenchNotifier($instanceId)] Error loading references from SharedPreferences: $e\n$s',
        );
      if (mounted) state = state.copyWith(error: e, isLoading: false);
    }
  }

  // Helper to save the current state.items to SharedPreferences
  Future<bool> _saveItemsToPrefs() async {
    if (!_prefsInitialized) return false;
    try {
      final itemsToSave = state.items; // Get current items from state
      final jsonString = jsonEncode(
        itemsToSave.map((item) => item.toJson()).toList(),
      );
      // Use the correct method name from SharedPrefsService
      await _prefsService.setString(_prefsKey, jsonString);
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] Saved ${itemsToSave.length} items to SharedPreferences.',
        );
      }
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] Error saving items to SharedPreferences: $e\n$s',
        );
      }
      return false;
    }
  }


  DateTime _getCommentTimestamp(Comment comment) {
    return comment.updatedTs ?? comment.createdTs;
  }

  // Fetch details from APIs (no change needed here, it doesn't involve CloudKit)
  Future<void> _fetchAndPopulateDetails(
    List<WorkbenchItemReference> itemsToProcess,
  ) async {
    if (!mounted || itemsToProcess.isEmpty) {
      if (state.isRefreshingDetails && mounted) {
        state = state.copyWith(isRefreshingDetails: false);
      }
      return;
    }

    // Ensure we only process items belonging to *this* notifier's instanceId
    final relevantItems =
        itemsToProcess.where((item) => item.instanceId == instanceId).toList();
    if (relevantItems.isEmpty) {
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] _fetchAndPopulateDetails called but no items belong to this instance.',
        );
      }
      if (mounted && state.isRefreshingDetails) {
        state = state.copyWith(isRefreshingDetails: false);
      }
      return;
    }


    final Map<String, List<WorkbenchItemReference>> itemsByServer = {};
    for (final item in relevantItems) {
      // Use filtered list
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] _fetchAndPopulateDetails: Processing item ${item.id} for server ${item.serverId}.',
        );
      }
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
        if (kDebugMode) {
          print(
            '[WorkbenchNotifier($instanceId)] Error getting API service for server $serverId: $e\n$s',
          );
        }
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
        if (kDebugMode) {
          print(
            '[WorkbenchNotifier($instanceId)] Server config ($serverId) not found or service not configured. Skipping detail fetch for its items.',
          );
        }
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
                if (referencedItemUpdateTime.isAfter(overallLastUpdateTime)) {
                  overallLastUpdateTime = referencedItemUpdateTime;
                }
              } catch (e) {
                if (kDebugMode) {
                  print(
                    '[WorkbenchNotifier($instanceId)] Error fetching note ${itemRef.referencedItemId} on server $serverId: $e',
                  );
                }
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
                referencedItemUpdateTime = task.updatedAt ?? task.createdAt;
                updatedPreviewContent = task.title;
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
        if (kDebugMode) {
          print(
            '[WorkbenchNotifier($instanceId)] Finished fetching details for ${results.length} items belonging to this instance.',
          );
        }
        // Save the updated items (with details) to prefs
        unawaited(_saveItemsToPrefs());
      }
    }
  }


  Future<void> refreshItemDetails() async {
    if (state.isLoading || state.isRefreshingDetails) return;
    if (!mounted) return;
    final itemsForThisInstance =
        state.items.where((i) => i.instanceId == instanceId).toList();
    if (itemsForThisInstance.isEmpty) {
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] No items in this instance to refresh details for.',
        );
      }
      return;
    }
    if (mounted) {
      state = state.copyWith(isRefreshingDetails: true, clearError: true);
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] Refreshing details for ${itemsForThisInstance.length} items in this instance.',
        );
      }
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
    if (kDebugMode) {
      print(
        '[WorkbenchNotifier($instanceId)] Reset item order to default (last activity first).',
      );
    }
    // Save the reordered list to prefs
    unawaited(_saveItemsToPrefs());
  }

  Future<void> addItem(WorkbenchItemReference item) async {
    if (!mounted || !_prefsInitialized) return;
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
          existingItem.serverId == item.serverId &&
          existingItem.instanceId == instanceId, // Check instanceId too
    );
    if (isDuplicate) {
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] Item with refId ${item.referencedItemId} on server ${item.serverId} already exists in this instance. Skipping add.',
        );
      }
      return;
    }

    // Ensure the item has a unique ID if not provided
    final itemToAdd =
        item.id.isEmpty ? item.copyWith(id: const Uuid().v4()) : item;

    final newItemWithDefaults = itemToAdd.copyWith(
      overallLastUpdateTime: itemToAdd.addedTimestamp,
    );
    final newItems = [...state.items, newItemWithDefaults];
    newItems.sort(
      (a, b) => b.overallLastUpdateTime.compareTo(a.overallLastUpdateTime),
    );
    if (mounted) {
      state = state.copyWith(items: newItems, clearError: true);
      // Save to prefs after updating state
      final success = await _saveItemsToPrefs();
      if (success) {
        if (kDebugMode) {
          print(
            '[WorkbenchNotifier($instanceId)] Added item ${itemToAdd.id} successfully locally.',
          );
        }
        // Fetch details only for the newly added item
        unawaited(_fetchAndPopulateDetails([newItemWithDefaults]));
      } else {
        if (kDebugMode) {
          print(
            '[WorkbenchNotifier($instanceId)] Failed to save added item ${itemToAdd.id} to prefs.',
          );
        }
        // Optionally revert state or show error
        state = state.copyWith(
          items: state.items.where((i) => i.id != itemToAdd.id).toList(),
          error: 'Failed to save item',
        );
      }
    }
    // Removed CloudKit save logic
  }

  // Internal method to add an item locally without saving to CloudKit
  // Used when an item is moved *into* this instance.
  // Now also saves to prefs.
  Future<void> _addExistingItemLocally(WorkbenchItemReference item) async {
    if (!mounted || !_prefsInitialized) return;
    if (item.instanceId != instanceId) {
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] _addExistingItemLocally called with item ${item.id} for wrong instance ${item.instanceId}. Skipping.',
        );
      }
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
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] _addExistingItemLocally: Item ${item.id} (refId ${item.referencedItemId}) already exists. Skipping.',
        );
      }
      return;
    }

    final newItems = [...state.items, item];
    newItems.sort(
      (a, b) => b.overallLastUpdateTime.compareTo(a.overallLastUpdateTime),
    );
    state = state.copyWith(items: newItems, clearError: true);
    // Save to prefs
    final success = await _saveItemsToPrefs();
    if (success) {
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] Added existing item ${item.id} locally after move and saved to prefs.',
        );
      }
      // Fetch details for the newly added item
      unawaited(_fetchAndPopulateDetails([item]));
    } else {
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] Failed to save locally added item ${item.id} to prefs.',
        );
      }
      // Optionally revert state or show error
      state = state.copyWith(
        items: state.items.where((i) => i.id != item.id).toList(),
        error: 'Failed to save moved item',
      );
    }
  }

  Future<void> removeItem(String itemId) async {
    if (!mounted || !_prefsInitialized) return;

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
      // Save to prefs after updating state
      final success = await _saveItemsToPrefs();
      if (success) {
        if (kDebugMode) {
          print(
            '[WorkbenchNotifier($instanceId)] Removed item $itemId successfully locally.',
          );
        }
        // Check if the removed item was the last opened one for this instance
        final lastOpened =
            _ref.read(workbenchInstancesProvider).lastOpenedItemId[instanceId];
        if (lastOpened == itemId) {
          _ref
              .read(workbenchInstancesProvider.notifier)
              .setLastOpenedItem(instanceId, null);
        }
      } else {
        if (kDebugMode) {
          print(
            '[WorkbenchNotifier($instanceId)] Failed to save removed item $itemId to prefs.',
          );
        }
        // Revert state if save failed
        state = state.copyWith(
          items: originalItems,
          error: 'Failed to save item removal',
        );
      }
    }
    // Removed CloudKit delete logic
  }

  // Move item between instances (local state + prefs update)
  Future<void> moveItem({
    required String itemId,
    required String targetInstanceId,
  }) async {
    if (!mounted || !_prefsInitialized) return;
    if (targetInstanceId == instanceId) {
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] Attempted to move item $itemId to the same instance. Skipping.',
        );
      }
      return;
    }

    WorkbenchItemReference? itemToMove;
    try {
      // Ensure the item exists in *this* instance before attempting to move it
      itemToMove = state.items.firstWhere(
        (i) => i.id == itemId && i.instanceId == instanceId,
      );
    } catch (e) {
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] Item with ID $itemId not found in this instance for move operation.',
        );
      }
      if (mounted) {
        state = state.copyWith(
          error: Exception('Item to move not found in this instance.'),
        );
      }
      return;
    }

    final originalItems = List<WorkbenchItemReference>.from(state.items);
    // Optimistically remove the item from the current instance's state
    final newItems = originalItems.where((item) => item.id != itemId).toList();

    if (mounted) {
      state = state.copyWith(items: newItems, clearError: true);
      // Save the removal from this instance's prefs
      final removeSuccess = await _saveItemsToPrefs();

      if (!removeSuccess) {
        if (kDebugMode) {
          print(
            '[WorkbenchNotifier($instanceId)] Failed to save removal of item $itemId from prefs. Reverting move.',
          );
        }
        state = state.copyWith(
          items: originalItems,
          error: 'Failed to save item removal during move',
        );
        return; // Stop the move if saving removal fails
      }

      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] Optimistically removed item $itemId for move and saved to prefs.',
        );
      }

      // Create the representation of the item in the target instance
      // Generate a new UUID for the item in the target instance to avoid ID conflicts if moved back later
      final newItemForTarget = itemToMove.copyWith(
        id: const Uuid().v4(), // Assign a new unique ID
        instanceId: targetInstanceId,
        // Reset transient fields for the target instance
        previewComments: [],
        referencedItemUpdateTime: () => null,
        overallLastUpdateTime:
            itemToMove.addedTimestamp, // Reset to added time initially
      );

      // Get the notifier for the target instance
      final targetNotifier = _ref.read(
        workbenchProviderFamily(targetInstanceId).notifier,
      );
      // Add the item locally to the target notifier's state (this also saves to target prefs)
      await targetNotifier._addExistingItemLocally(newItemForTarget);

      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] Successfully processed move for item original ID $itemId to instance $targetInstanceId (new ID: ${newItemForTarget.id}). Item added locally to target.',
        );
      }

      // Check if the moved item was the last opened one for this instance
      final lastOpened =
          _ref.read(workbenchInstancesProvider).lastOpenedItemId[instanceId];
      if (lastOpened == itemId) {
        _ref
            .read(workbenchInstancesProvider.notifier)
            .setLastOpenedItem(instanceId, null);
      }
    }
    // Removed CloudKit move logic
  }

  // Reorder items within the local list and save to prefs
  Future<void> reorderItems(int oldIndex, int newIndex) async {
    if (!mounted || !_prefsInitialized) return;

    // Operate only on items belonging to this instance
    final instanceItems =
        state.items.where((i) => i.instanceId == instanceId).toList();
    // Keep track of items from other instances (shouldn't be any, but defensively)
    final otherItems =
        state.items.where((i) => i.instanceId != instanceId).toList();

    if (oldIndex < 0 || oldIndex >= instanceItems.length) return;
    // Allow newIndex to be equal to length for moving to the end
    if (newIndex < 0 || newIndex > instanceItems.length) return;

    final item = instanceItems.removeAt(oldIndex);
    // Adjust newIndex if removing item before it shifts the target position
    final effectiveNewIndex = (newIndex > oldIndex) ? newIndex - 1 : newIndex;

    // Ensure effectiveNewIndex is within bounds after removal
    if (effectiveNewIndex < 0 || effectiveNewIndex > instanceItems.length) {
      return;
    }

    instanceItems.insert(effectiveNewIndex, item);

    // Combine the reordered instance items with items from other instances
    final combinedItems = [...instanceItems, ...otherItems];

    if (mounted) {
      state = state.copyWith(items: combinedItems);
      // Save the new order to prefs
      final success = await _saveItemsToPrefs();
      if (success) {
        if (kDebugMode) {
          print(
            '[WorkbenchNotifier($instanceId)] Reordered items within instance: $oldIndex -> $effectiveNewIndex and saved to prefs.',
          );
        }
      } else {
        if (kDebugMode) {
          print(
            '[WorkbenchNotifier($instanceId)] Failed to save reordered items to prefs.',
          );
        }
        // Optionally revert or show error
        // For simplicity, we might just log the error here
        state = state.copyWith(error: 'Failed to save reordered items');
      }
    }
  }

  // Clear items only from local state and prefs for this instance
  Future<void> clearItems() async {
    if (!mounted || !_prefsInitialized) return;
    final itemsInThisInstance =
        state.items.where((i) => i.instanceId == instanceId).toList();
    if (itemsInThisInstance.isEmpty) {
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] No items in this instance to clear.',
        );
      }
      return;
    }

    final originalItems = List<WorkbenchItemReference>.from(state.items);
    // Optimistically remove items belonging to this instance from local state
    final itemsToKeep =
        state.items.where((i) => i.instanceId != instanceId).toList();

    if (mounted) {
      state = state.copyWith(items: itemsToKeep, clearError: true);
      // Attempt to clear prefs for this instance
      final success =
          await _saveItemsToPrefs(); // Saving an empty list clears it

      if (success) {
        if (kDebugMode) {
          print(
            '[WorkbenchNotifier($instanceId)] Cleared local items for this instance and updated prefs.',
          );
        }
        // Clear any previous error state if successful
        if (state.error != null) state = state.copyWith(clearError: true);
        // Clear last opened item for this instance
        _ref
            .read(workbenchInstancesProvider.notifier)
            .setLastOpenedItem(instanceId, null);
      } else {
        if (kDebugMode) {
          print(
            '[WorkbenchNotifier($instanceId)] Failed to clear items from prefs. Reverting state.',
          );
        }
        // Revert state if clearing prefs failed
        state = state.copyWith(
          items: originalItems,
          error: 'Failed to clear items from storage',
        );
      }
    }
    // Removed CloudKit deletion logic
  }
}

// --- Provider Definitions ---

final workbenchProviderFamily =
    StateNotifierProvider.family<WorkbenchNotifier, WorkbenchState, String>((
      ref,
      instanceId,
    ) {
      // Notifier now loads items itself after prefs initialization
      return WorkbenchNotifier(ref, instanceId);
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
  // isLoading now primarily depends on whether instances themselves are loading
  // or if individual workbench notifiers are still initializing/loading from prefs.
  bool isLoading = instancesState.isLoading;
  Object? error = instancesState.error;

  if (!isLoading && error == null) {
    for (final instance in instancesState.instances) {
      // Watch the individual notifier for this instance
      final instanceItemsState = ref.watch(
        workbenchProviderFamily(instance.id),
      );
      allItems.addAll(instanceItemsState.items);
      // Consider an instance loading if its notifier is loading OR refreshing details
      if (instanceItemsState.isLoading ||
          instanceItemsState.isRefreshingDetails) {
        isLoading = true;
      }
      if (error == null && instanceItemsState.error != null) {
        error = instanceItemsState.error; // Capture the first error encountered
      }
    }
  }

  // Sort the combined list only if not loading and no error occurred
  if (!isLoading && error == null) {
    // Sort by overallLastUpdateTime (which includes details fetched async)
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
