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
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] loadItems: Fetching references for this instance.',
        );
      }
      final references = await _cloudKitService.getAllWorkbenchItemReferences(
        instanceId: instanceId,
      );
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
    if (!mounted || itemsToProcess.isEmpty) {
      if (state.isRefreshingDetails && mounted) {
        state = state.copyWith(isRefreshingDetails: false);
      }
      return;
    }

    final Map<String, List<WorkbenchItemReference>> itemsByServer = {};
    for (final item in itemsToProcess) {
      if (item.instanceId != instanceId) {
        if (kDebugMode) {
          print(
            '[WorkbenchNotifier($instanceId)] _fetchAndPopulateDetails: Skipping item ${item.id} because its instanceId (${item.instanceId}) does not match.',
          );
        }
        continue;
      }
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
          .firstWhere((s) => s?.id == serverId, orElse: () => null);

      if (serverConfig == null) {
        if (kDebugMode) {
          print(
            '[WorkbenchNotifier($instanceId)] Server config not found for $serverId. Skipping detail fetch for its items.',
          );
        }
        detailFetchFutures.addAll(
          serverItems.map((item) => Future.value(item)),
        );
        continue;
      }

      final baseApiService = _ref.read(apiServiceProvider);

      bool serviceTypeMatches =
          ((serverConfig.serverType == ServerType.memos ||
                  serverConfig.serverType == ServerType.blinko) &&
              baseApiService is NoteApiService) ||
          ((serverConfig.serverType == ServerType.todoist) &&
              baseApiService is TaskApiService);

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
            return itemRef;
          }
        }());
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
    if (state.isLoading || state.isRefreshingDetails) return;
    if (!mounted) return;

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
    if (!mounted) return;

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

  Future<void> addItem(WorkbenchItemReference item) async {
    if (!mounted) return;

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
      if (!success) throw Exception('CloudKit save failed');
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

  void _addExistingItem(WorkbenchItemReference item) {
    if (!mounted) return;
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
    unawaited(_fetchAndPopulateDetails([item]));
  }

  Future<void> removeItem(String itemId) async {
    if (!mounted) return;

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
      if (!success) throw Exception('CloudKit delete failed');
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
      return;
    }

    WorkbenchItemReference? itemToMove;
    try {
      // 1. Grab the item from local state of the *source* instance
      itemToMove = state.items.firstWhere((i) => i.id == itemId);
    } catch (e) {
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] Item with ID $itemId not found for move operation.',
        );
      }
      if (mounted) {
        state = state.copyWith(error: Exception('Item to move not found.'));
      }
      return;
    }

    // 2. Remove from this (source) instance's state optimistically
    final originalItems = List<WorkbenchItemReference>.from(state.items);
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
      // 3. Convert old item to a map for re-creation
      final oldRecordFields = itemToMove.toJson();

      // 4. CloudKit delete + create using the new service method, capture the new ID
      final maybeNewCloudKitId = await _cloudKitService
          .moveWorkbenchItemReferenceByDeleteRecreate(
            recordName: itemId,
            newInstanceId: targetInstanceId,
            oldRecordFields: oldRecordFields,
          );

      // Check if the CloudKit operation failed (returned null)
      if (maybeNewCloudKitId == null) {
        throw Exception('CloudKit delete-recreate move operation failed');
      }

      // 5. Build the new item locally using the EXACT ID returned from CloudKit
      final newItemForTarget = itemToMove.copyWith(
        id: maybeNewCloudKitId,
        instanceId: targetInstanceId,
      );

      // 6. Insert new item into target instance's local state
      if (mounted) {
        final targetNotifier = _ref.read(
          workbenchProviderFamily(targetInstanceId).notifier,
        );
        targetNotifier._addExistingItem(newItemForTarget);
        
        // Immediately add the item to local state (optimistic update)
        if (kDebugMode) {
          print(
            '[WorkbenchNotifier($instanceId)] Added item to target instance. Now adding delayed refresh to handle CloudKit consistency.',
          );
        }

        // Add a delay before loading items to allow CloudKit indexing to catch up
        // This addresses the eventual consistency issue where new records
        // might not be immediately available in query results
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              targetNotifier.loadItems();
              if (kDebugMode) {
                print(
                  '[WorkbenchNotifier($instanceId)] Executed delayed loadItems() on target instance after move.',
                );
              }
            }
          });
        }

        if (kDebugMode) {
          print(
            '[WorkbenchNotifier($instanceId)] Successfully processed move for item original ID $itemId to instance $targetInstanceId (new CloudKit ID: $maybeNewCloudKitId).',
          );
        }
        // Clear last opened item if it was the one moved
        final lastOpened =
            _ref.read(workbenchInstancesProvider).lastOpenedItemId[instanceId];
        if (lastOpened == itemId) {
          _ref
              .read(workbenchInstancesProvider.notifier)
              .setLastOpenedItem(instanceId, null);
        }
      }
    } catch (e, s) {
      if (kDebugMode) {
        print(
          '[WorkbenchNotifier($instanceId)] Error moving item $itemId to $targetInstanceId: $e\n$s',
        );
      }
      // Revert local state change on failure
      if (mounted) {
        final itemsToRestore = List<WorkbenchItemReference>.from(originalItems);
        if (!itemsToRestore.any((i) => i.id == itemId)) {
          itemsToRestore.add(itemToMove);
        }
        itemsToRestore.sort(
          (a, b) => b.overallLastUpdateTime.compareTo(a.overallLastUpdateTime),
        );
        state = state.copyWith(items: itemsToRestore, error: e);
      }
    }
  }

  void reorderItems(int oldIndex, int newIndex) {
    if (!mounted) return;
    if (oldIndex < 0 || oldIndex >= state.items.length) return;
    if (newIndex < 0 || newIndex > state.items.length) return;

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
  }

  Future<void> clearItems() async {
    if (!mounted) return;
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
}

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
