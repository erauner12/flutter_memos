import 'dart:async';

import 'package:flutter/foundation.dart';
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
  // TODO: Add UserSettings persistence later if needed for lastOpenedItemId map

  WorkbenchInstancesNotifier(this._ref)
    : super(WorkbenchInstancesState.initial()) {
    _cloudKitService = _ref.read(cloudKitServiceProvider);
    // Read SharedPrefsService asynchronously using the correct provider
    _ref.read(sharedPrefsServiceProvider.future).then((prefs) {
      _prefsService = prefs;
      _initialize(); // Call initialization after prefs are ready
    }).catchError((e, s) {
       if (kDebugMode) {
        print('[WorkbenchInstancesNotifier] Error getting SharedPrefsService: $e\n$s');
      }
      // Handle error - perhaps set state to error state?
      if (mounted) {
        state = state.copyWith(isLoading: false, error: 'Failed to load preferences');
      }
    });
  }

  Future<void> _initialize() async {
    if (!mounted) return;

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
    }

    // 2. Load instances from CloudKit
    await loadInstances(setActiveIdFromCache: initialActiveId);

    // 3. Load last opened map from CloudKit (if implemented)
    // await _loadLastOpenedMapFromCloudKit(); // Placeholder
  }


  Future<void> loadInstances({String? setActiveIdFromCache}) async {
    if (!mounted) return;
    // Don't set isLoading if already loading (e.g., during initial _initialize)
    if (!state.isLoading) {
       state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final instances = await _cloudKitService.getAllWorkbenchInstances();
      if (!mounted) return;

      String finalActiveId = state.activeInstanceId; // Keep current/cached ID initially

      if (instances.isNotEmpty) {
        // If the cached/current active ID is no longer valid, reset to the first available instance
        if (!instances.any((i) => i.id == finalActiveId)) {
          finalActiveId = instances.first.id;
           if (kDebugMode) {
            print('[WorkbenchInstancesNotifier] Active instance ID $state.activeInstanceId not found, resetting to ${instances.first.id}');
          }
          // Persist the newly selected active ID
          unawaited(_prefsService.saveActiveInstanceId(finalActiveId));
        }
      } else {
        // This case should ideally not happen due to default instance creation in CloudKitService,
        // but handle defensively.
        finalActiveId = WorkbenchInstance.defaultInstanceId;
         if (kDebugMode) {
          print('[WorkbenchInstancesNotifier] No instances loaded, ensuring active ID is default.');
        }
      }


      if (mounted) {
        state = state.copyWith(
          instances: instances,
          activeInstanceId: finalActiveId,
          isLoading: false,
        );
         if (kDebugMode) {
          print('[WorkbenchInstancesNotifier] Loaded ${instances.length} instances. Active: $finalActiveId');
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
    if (!mounted) return false;
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
      id: const Uuid().v4(),
      name: name.trim(),
      createdAt: DateTime.now(),
    );

    // Optimistic update
    final originalInstances = List<WorkbenchInstance>.from(state.instances);
    if (mounted) {
      state = state.copyWith(
        instances: [...originalInstances, newInstance],
        isLoading: false, // Not loading, but performing action
        clearError: true,
      );
    }

    try {
      final success = await _cloudKitService.saveWorkbenchInstance(newInstance);
      if (!success) {
        throw Exception('CloudKit save failed');
      }
      if (kDebugMode) {
        print('[WorkbenchInstancesNotifier] Saved new instance ${newInstance.id}');
      }
      // No need to update state again if optimistic update succeeded
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        print('[WorkbenchInstancesNotifier] Error saving instance: $e\n$s');
      }
      // Revert optimistic update
      if (mounted) {
        state = state.copyWith(instances: originalInstances, error: e);
      }
      return false;
    }
  }

  Future<bool> renameInstance(String instanceId, String newName) async {
     if (!mounted) return false;
     if (newName.trim().isEmpty) {
       if (kDebugMode) print('[WorkbenchInstancesNotifier] Instance name cannot be empty.');
       state = state.copyWith(error: 'Instance name cannot be empty');
       return false;
    }
    // Check for duplicate names (case-insensitive), excluding the current instance being renamed
    if (state.instances.any((i) => i.id != instanceId && i.name.toLowerCase() == newName.trim().toLowerCase())) {
      if (kDebugMode) print('[WorkbenchInstancesNotifier] Instance name "$newName" already exists.');
      state = state.copyWith(error: 'An instance with this name already exists.');
      return false;
    }

    final instanceToRename = state.instances.firstWhere((i) => i.id == instanceId, orElse: () => throw Exception('Instance not found'));
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
    if (!mounted) return false;
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

    final originalInstances = List<WorkbenchInstance>.from(state.instances);
    final newInstances = originalInstances.where((i) => i.id != instanceId).toList();
    String newActiveId = state.activeInstanceId;

    // If deleting the active instance, switch to the first remaining one (or default)
    if (instanceId == state.activeInstanceId) {
      newActiveId = newInstances.isNotEmpty ? newInstances.first.id : WorkbenchInstance.defaultInstanceId;
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
      if (newActiveId != state.activeInstanceId) {
         unawaited(_prefsService.saveActiveInstanceId(newActiveId));
      }
    }

    try {
      final success = await _cloudKitService.deleteWorkbenchInstance(instanceId);
      if (!success) {
        throw Exception('CloudKit delete failed');
      }
      if (kDebugMode) {
        print('[WorkbenchInstancesNotifier] Deleted instance $instanceId');
      }
      // Also delete associated workbench items (fire-and-forget for now)
      unawaited(_cloudKitService.deleteAllWorkbenchItemReferences(instanceId: instanceId));
      // Remove from last opened map
      _removeInstanceFromLastOpenedMap(instanceId);
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        print('[WorkbenchInstancesNotifier] Error deleting instance $instanceId: $e\n$s');
      }
      // Revert optimistic update
      if (mounted) {
        // Need to potentially revert activeInstanceId as well if it was changed
        state = state.copyWith(
          instances: originalInstances,
          activeInstanceId: state.activeInstanceId, // Revert active ID too
          error: e,
        );
         // Revert cached active ID if it was changed optimistically
        if (newActiveId != state.activeInstanceId) {
           unawaited(_prefsService.saveActiveInstanceId(state.activeInstanceId));
        }
      }
      return false;
    }
  }

  Future<void> setActiveInstance(String instanceId) async {
    if (!mounted) return;
    if (state.activeInstanceId == instanceId) return; // No change needed

    // Check if the instanceId exists
    if (!state.instances.any((i) => i.id == instanceId)) {
       if (kDebugMode) print('[WorkbenchInstancesNotifier] Attempted to set active instance to non-existent ID: $instanceId');
       // Optionally set an error state or just ignore
       return;
    }

    if (mounted) {
      state = state.copyWith(activeInstanceId: instanceId, clearError: true);
       if (kDebugMode) print('[WorkbenchInstancesNotifier] Set active instance to: $instanceId');
      // Persist to cache
      await _prefsService.saveActiveInstanceId(instanceId);
      // Persist to CloudKit UserSettings (if needed, e.g., for cross-device sync)
      // await _cloudKitService.saveSetting('activeInstanceId', instanceId); // Placeholder
    }
  }

  // --- Last Opened Item Logic ---

  void setLastOpenedItem(String instanceId, String? referenceId) {
    if (!mounted) return;

    final currentMap = Map<String, String?>.from(state.lastOpenedItemId);
    if (currentMap[instanceId] == referenceId) return; // No change

    currentMap[instanceId] = referenceId;

    if (mounted) {
      state = state.copyWith(lastOpenedItemId: currentMap);
       if (kDebugMode) print('[WorkbenchInstancesNotifier] Updated last opened item for instance $instanceId to $referenceId');
      // Persist lazily to cache
      unawaited(_prefsService.saveLastOpenedItemMap(currentMap));
      // Persist lazily to CloudKit UserSettings (if implemented)
      // unawaited(_saveLastOpenedMapToCloudKit(currentMap)); // Placeholder
    }
  }

  void _removeInstanceFromLastOpenedMap(String instanceId) {
     if (!mounted) return;
     final currentMap = Map<String, String?>.from(state.lastOpenedItemId);
     if (currentMap.containsKey(instanceId)) {
       currentMap.remove(instanceId);
       if (mounted) {
         state = state.copyWith(lastOpenedItemId: currentMap);
          if (kDebugMode) print('[WorkbenchInstancesNotifier] Removed instance $instanceId from last opened map.');
         // Persist change
         unawaited(_prefsService.saveLastOpenedItemMap(currentMap));
         // unawaited(_saveLastOpenedMapToCloudKit(currentMap)); // Placeholder
       }
     }
  }

  // Placeholder for CloudKit persistence of the map
  // Future<void> _loadLastOpenedMapFromCloudKit() async { ... }
  // Future<void> _saveLastOpenedMapToCloudKit(Map<String, String?> map) async { ... }

}

// Provider definition
final workbenchInstancesProvider =
    StateNotifierProvider<WorkbenchInstancesNotifier, WorkbenchInstancesState>((ref) {
  return WorkbenchInstancesNotifier(ref);
  // Initialization logic (including async _initialize) is handled within the notifier's constructor
});
