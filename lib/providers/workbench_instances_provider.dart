import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Import Material for TabController
import 'package:flutter_memos/models/workbench_instance.dart';
import 'package:flutter_memos/providers/service_providers.dart'; // Import service providers
import 'package:flutter_memos/providers/shared_prefs_provider.dart';
import 'package:flutter_memos/services/cloud_kit_service.dart';
import 'package:flutter_memos/utils/shared_prefs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

@immutable
class WorkbenchInstancesState {
  final List<WorkbenchInstance> instances;
  final String activeInstanceId; // Always non-null after initial load
  final bool isLoading;
  final Object? error;
  final Map<String, String?> lastOpenedItemId; // key = instanceId, value = referenceId or null

  const WorkbenchInstancesState({
    this.instances = const [],
    required this.activeInstanceId,
    this.isLoading = false,
    this.error,
    this.lastOpenedItemId = const {},
  });

  // Initial state before loading from cache/cloud
  factory WorkbenchInstancesState.initial() {
    // Use default instance ID temporarily until loaded
    return const WorkbenchInstancesState(
      activeInstanceId: WorkbenchInstance.defaultInstanceId,
      isLoading: true, // Start in loading state
    );
  }

  WorkbenchInstancesState copyWith({
    List<WorkbenchInstance>? instances,
    String? activeInstanceId,
    bool? isLoading,
    Object? error,
    bool clearError = false,
    Map<String, String?>? lastOpenedItemId,
  }) {
    return WorkbenchInstancesState(
      instances: instances ?? this.instances,
      activeInstanceId: activeInstanceId ?? this.activeInstanceId,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      lastOpenedItemId: lastOpenedItemId ?? this.lastOpenedItemId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WorkbenchInstancesState &&
        listEquals(other.instances, instances) &&
        other.activeInstanceId == activeInstanceId &&
        other.isLoading == isLoading &&
        other.error == error &&
        mapEquals(other.lastOpenedItemId, lastOpenedItemId);
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(instances),
        activeInstanceId,
        isLoading,
        error,
        Object.hashAll(lastOpenedItemId.entries),
      );
}

class WorkbenchInstancesNotifier extends StateNotifier<WorkbenchInstancesState> {
  final Ref _ref;
  late final CloudKitService _cloudKitService;
  late final SharedPrefsService _prefsService;
  bool _prefsInitialized = false; // Track if prefs are loaded

  WorkbenchInstancesNotifier(this._ref)
    : super(WorkbenchInstancesState.initial()) {
    _cloudKitService = _ref.read(cloudKitServiceProvider);
    // Read SharedPrefsService asynchronously
    _initializePrefsAndLoad();
  }

  Future<void> _initializePrefsAndLoad() async {
    try {
      _prefsService = await _ref.read(sharedPrefsServiceProvider.future);
      _prefsInitialized = true;
      if (kDebugMode) {
        print('[WorkbenchInstancesNotifier] SharedPrefsService initialized.');
      }
      // Now that prefs are ready, proceed with initialization
      await _initialize();
    } catch (e, s) {
       if (kDebugMode) {
        print(
          '[WorkbenchInstancesNotifier] Error getting SharedPrefsService: $e\n$s',
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


  Future<void> _initialize() async {
    if (!mounted || !_prefsInitialized) return;

    // 1. Load cached active instance ID and last opened map
    final cachedActiveId = _prefsService.getActiveInstanceId();
    final cachedLastOpenedMap = _prefsService.getLastOpenedItemMap();

    // Use cached ID if available, otherwise keep default temporarily
    final initialActiveId = cachedActiveId ?? WorkbenchInstance.defaultInstanceId;

    if (mounted) {
      state = state.copyWith(
        activeInstanceId: initialActiveId,
        lastOpenedItemId: cachedLastOpenedMap,
        isLoading: true, // Still loading from CloudKit
        clearError: true,
      );
      if (kDebugMode) {
        print(
          '[WorkbenchInstancesNotifier] Initializing with cached activeId: $initialActiveId',
        );
      }
    }

    // 2. Load instances from CloudKit
    // Pass the initialActiveId to potentially use it if CloudKit load is slow/fails initially
    await loadInstances(setActiveIdFromPrefs: initialActiveId);

    // 3. Load last opened map from CloudKit (if implemented)
    // await _loadLastOpenedMapFromCloudKit(); // Placeholder
  }


  Future<void> loadInstances({String? setActiveIdFromPrefs}) async {
    if (!mounted) return;
    // Ensure prefs are loaded before proceeding, especially for the active ID logic
    if (!_prefsInitialized) {
      if (kDebugMode)
        print(
          '[WorkbenchInstancesNotifier] loadInstances called before prefs initialized. Waiting...',
        );
      state = state.copyWith(isLoading: true, error: 'Preferences not ready');
      return;
    }

    // Don't set isLoading if already loading (e.g., during initial _initialize)
    if (!state.isLoading) {
       state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final instances = await _cloudKitService.getAllWorkbenchInstances();
      if (!mounted) return;

      // Determine the active ID to use:
      // Start with the current state's active ID (which might be from prefs or previous state).
      String currentActiveIdInState = state.activeInstanceId;
      String finalActiveId = currentActiveIdInState;

      if (instances.isNotEmpty) {
        // Check if the current active ID (from state) is valid within the newly loaded list.
        bool isActiveIdValid = instances.any((i) => i.id == finalActiveId);

        if (!isActiveIdValid) {
          // The current active ID is NOT valid.
          // Action: Reset to the first available instance AND persist this correction.
          finalActiveId = instances.first.id;
          if (kDebugMode) {
            print(
              '[WorkbenchInstancesNotifier] Active instance ID $currentActiveIdInState not found in loaded list. Resetting to first available: ${instances.first.id} and persisting.',
            );
          }
          await _prefsService.saveActiveInstanceId(finalActiveId);
        }
        else if (kDebugMode) {
          print(
            '[WorkbenchInstancesNotifier] Current active instance ID $currentActiveIdInState is valid in loaded list.',
          );
        }

      } else {
        // No instances loaded (even default failed?). This is an error/edge case.
        // Fallback to the default ID and ensure it's saved.
        finalActiveId = WorkbenchInstance.defaultInstanceId;
         if (kDebugMode) {
          print(
            '[WorkbenchInstancesNotifier] No instances loaded (error?). Ensuring active ID is default and persisting.',
          );
        }
        await _prefsService.saveActiveInstanceId(finalActiveId);
      }


      if (mounted) {
        state = state.copyWith(
          instances: instances,
          activeInstanceId: finalActiveId, // Use the validated/corrected ID
          isLoading: false,
        );
         if (kDebugMode) {
          print(
            '[WorkbenchInstancesNotifier] Loaded ${instances.length} instances. Final Active: $finalActiveId',
          );
        }
      }
    } catch (e, s) {
      if (kDebugMode) {
        print('[WorkbenchInstancesNotifier] Error loading instances: $e\n$s');
      }
      if (mounted) {
        state = state.copyWith(error: e, isLoading: false);
      }
    }
  }


  Future<bool> saveInstance(String name) async {
    if (!mounted || !_prefsInitialized) return false;
    if (name.trim().isEmpty) {
       if (kDebugMode) print('[WorkbenchInstancesNotifier] Instance name cannot be empty.');
       state = state.copyWith(error: 'Instance name cannot be empty');
       return false;
    }
     // Check for duplicate names (case-insensitive)
    if (state.instances.any((i) => i.name.toLowerCase() == name.trim().toLowerCase())) {
      if (kDebugMode) print('[WorkbenchInstancesNotifier] Instance name "$name" already exists.');
      state = state.copyWith(error: 'An instance with this name already exists.');
      return false;
    }


    final newInstance = WorkbenchInstance(
      id: const Uuid().v4(), // Client-generated UUID
      name: name.trim(),
      createdAt: DateTime.now(),
    );

    final originalState = state;
    // Optimistic update: Add new instance and make it active
    if (mounted) {
      state = state.copyWith(
        instances: [...originalState.instances, newInstance],
        activeInstanceId: newInstance.id, // Set new instance as active
        isLoading: false,
        clearError: true,
      );
      // Persist the new active ID optimistically
      unawaited(_prefsService.saveActiveInstanceId(newInstance.id));
    }

    try {
      final success = await _cloudKitService.saveWorkbenchInstance(newInstance);
      if (!success) {
        throw Exception('CloudKit save failed');
      }
      if (kDebugMode) {
        print('[WorkbenchInstancesNotifier] Saved new instance ${newInstance.id}');
      }
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        print('[WorkbenchInstancesNotifier] Error saving instance: $e\n$s');
      }
      // Revert optimistic update
      if (mounted) {
        state = originalState.copyWith(error: e); // Revert state
        // Revert cached active ID
        unawaited(
          _prefsService.saveActiveInstanceId(originalState.activeInstanceId),
        );
      }
      return false;
    }
  }

  Future<bool> renameInstance(String instanceId, String newName) async {
    if (!mounted || !_prefsInitialized) return false;
     if (newName.trim().isEmpty) {
       if (kDebugMode) print('[WorkbenchInstancesNotifier] Instance name cannot be empty.');
       state = state.copyWith(error: 'Instance name cannot be empty');
       return false;
    }
    // Check for duplicate names (case-insensitive), excluding the current instance
    if (state.instances.any((i) => i.id != instanceId && i.name.toLowerCase() == newName.trim().toLowerCase())) {
      if (kDebugMode) print('[WorkbenchInstancesNotifier] Instance name "$newName" already exists.');
      state = state.copyWith(error: 'An instance with this name already exists.');
      return false;
    }

    final instanceToRename = state.instances.firstWhere(
      (i) => i.id == instanceId,
      orElse:
          () => throw Exception('Instance not found for rename: $instanceId'),
    );
    final updatedInstance = instanceToRename.copyWith(name: newName.trim());

    // Optimistic update
    final originalInstances = List<WorkbenchInstance>.from(state.instances);
    final updatedList = originalInstances.map((i) => i.id == instanceId ? updatedInstance : i).toList();
    if (mounted) {
      state = state.copyWith(instances: updatedList, clearError: true);
    }

     try {
      final success = await _cloudKitService.saveWorkbenchInstance(updatedInstance);
      if (!success) {
        throw Exception('CloudKit save failed');
      }
      if (kDebugMode) {
        print('[WorkbenchInstancesNotifier] Renamed instance $instanceId to "$newName"');
      }
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        print('[WorkbenchInstancesNotifier] Error renaming instance $instanceId: $e\n$s');
      }
      // Revert optimistic update
      if (mounted) {
        state = state.copyWith(instances: originalInstances, error: e);
      }
      return false;
    }
  }


  Future<bool> deleteInstance(String instanceId) async {
    if (!mounted || !_prefsInitialized) return false;
    // Prevent deleting the last instance or the default instance
    if (state.instances.length <= 1) {
       if (kDebugMode) print('[WorkbenchInstancesNotifier] Cannot delete the last instance.');
       state = state.copyWith(error: 'Cannot delete the last instance.');
       return false;
    }
     if (instanceId == WorkbenchInstance.defaultInstanceId) {
       if (kDebugMode) print('[WorkbenchInstancesNotifier] Cannot delete the default instance.');
       state = state.copyWith(error: 'Cannot delete the default instance.');
       return false;
    }

    final originalState = state;
    final originalInstances = List<WorkbenchInstance>.from(state.instances);
    final newInstances = originalInstances.where((i) => i.id != instanceId).toList();
    String newActiveId = state.activeInstanceId;
    String originalActiveId = state.activeInstanceId;

    // If deleting the active instance, switch to the first remaining one
    if (instanceId == state.activeInstanceId) {
      // newInstances cannot be empty here due to the check above
      newActiveId = newInstances.first.id;
       if (kDebugMode) print('[WorkbenchInstancesNotifier] Deleting active instance, switching active to $newActiveId');
    }

    // Optimistic update
    if (mounted) {
      state = state.copyWith(
        instances: newInstances,
        activeInstanceId: newActiveId,
        clearError: true,
      );
      // Update cache immediately if active ID changed
      if (newActiveId != originalActiveId) {
         unawaited(_prefsService.saveActiveInstanceId(newActiveId));
      }
    }

    try {
      // Delete the instance record itself
      final deleteInstanceSuccess = await _cloudKitService
          .deleteWorkbenchInstance(instanceId);
      if (!deleteInstanceSuccess) {
        if (kDebugMode) {
          print(
            '[WorkbenchInstancesNotifier] CloudKit delete failed for instance $instanceId, but proceeding to delete items.',
          );
        }
      } else if (kDebugMode) {
        print(
          '[WorkbenchInstancesNotifier] Deleted instance $instanceId from CloudKit.',
        );
      }

      // Also delete associated workbench items (fire-and-forget)
      unawaited(
        _cloudKitService
            .deleteAllWorkbenchItemReferences(instanceId: instanceId)
            .then((success) {
              if (kDebugMode)
                print(
                  '[WorkbenchInstancesNotifier] Attempted deletion of items for instance $instanceId. Success: $success',
                );
            }),
      );

      // Remove from last opened map locally and persist
      _removeInstanceFromLastOpenedMap(instanceId);

      return true; // Return true even if instance delete failed but item delete was attempted

    } catch (e, s) {
      if (kDebugMode) {
        print(
          '[WorkbenchInstancesNotifier] Error during delete instance process for $instanceId: $e\n$s',
        );
      }
      // Revert optimistic UI update fully on error
      if (mounted) {
        state = originalState.copyWith(error: e);
         // Revert cached active ID if it was changed optimistically
        if (newActiveId != originalActiveId) {
          unawaited(_prefsService.saveActiveInstanceId(originalActiveId));
        }
      }
      return false;
    }
  }

  Future<void> setActiveInstance(String instanceId) async {
    if (!mounted || !_prefsInitialized) return;
    if (state.activeInstanceId == instanceId) return; // No change needed

    // Check if the instanceId exists in the current list
    if (!state.instances.any((i) => i.id == instanceId)) {
      if (kDebugMode)
        print(
          '[WorkbenchInstancesNotifier] Attempted to set active instance to non-existent ID in current list: $instanceId',
        );
      return; // Don't set an invalid ID
    }

    if (mounted) {
      state = state.copyWith(activeInstanceId: instanceId, clearError: true);
       if (kDebugMode) print('[WorkbenchInstancesNotifier] Set active instance to: $instanceId');
      // Persist to cache
      await _prefsService.saveActiveInstanceId(instanceId);
      // Persist to CloudKit UserSettings (if needed)
      // await _cloudKitService.saveSetting('activeInstanceId', instanceId);
    }
  }

  // --- Last Opened Item Logic ---

  void setLastOpenedItem(String instanceId, String? referenceId) {
    if (!mounted || !_prefsInitialized) return;

    final currentMap = Map<String, String?>.from(state.lastOpenedItemId);
    if (currentMap[instanceId] == referenceId) return; // No change

    currentMap[instanceId] = referenceId;

    if (mounted) {
      state = state.copyWith(lastOpenedItemId: currentMap);
       if (kDebugMode) print('[WorkbenchInstancesNotifier] Updated last opened item for instance $instanceId to $referenceId');
      // Persist lazily to cache
      unawaited(_prefsService.saveLastOpenedItemMap(currentMap));
      // Persist lazily to CloudKit UserSettings (if implemented)
      // unawaited(_saveLastOpenedMapToCloudKit(currentMap));
    }
  }

  void _removeInstanceFromLastOpenedMap(String instanceId) {
    if (!mounted || !_prefsInitialized) return;
     final currentMap = Map<String, String?>.from(state.lastOpenedItemId);
     if (currentMap.containsKey(instanceId)) {
       currentMap.remove(instanceId);
       if (mounted) {
         state = state.copyWith(lastOpenedItemId: currentMap);
          if (kDebugMode) print('[WorkbenchInstancesNotifier] Removed instance $instanceId from last opened map.');
         // Persist change
         unawaited(_prefsService.saveLastOpenedItemMap(currentMap));
        // unawaited(_saveLastOpenedMapToCloudKit(currentMap));
       }
     }
  }

  // Placeholder for CloudKit persistence of the map
  // Future<void> _loadLastOpenedMapFromCloudKit() async { ... }
  // Future<void> _saveLastOpenedMapToCloudKit(Map<String, String?> map) async { ... }

}

// Provider definition for instance state
final workbenchInstancesProvider =
    StateNotifierProvider<WorkbenchInstancesNotifier, WorkbenchInstancesState>((
      ref,
    ) {
  return WorkbenchInstancesNotifier(ref);
});

// --- New Provider for TabController ---
// This provider holds the *current* TabController instance.
// It will be overridden by the WorkbenchTabControllerHolder.
final workbenchTabControllerProvider = Provider.autoDispose<TabController>((
  ref,
) {
  // This default implementation should ideally never be reached if the
  // holder correctly overrides it before the UI tries to watch it.
  // Throwing an error helps catch setup issues.
  throw UnimplementedError(
    'workbenchTabControllerProvider must be overridden by WorkbenchTabControllerHolder',
  );
});
