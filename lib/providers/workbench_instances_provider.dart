import 'dart:async';

import 'package:flutter/foundation.dart';
// Removed Material import
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
  final bool isLoading;
  final Object? error;
  final Map<String, String?> lastOpenedItemId; // key = instanceId, value = referenceId or null

  const WorkbenchInstancesState({
    this.instances = const [],
    this.isLoading = false,
    this.error,
    this.lastOpenedItemId = const {},
  });

  // Initial state before loading from cache/cloud
  factory WorkbenchInstancesState.initial() {
    return const WorkbenchInstancesState(
      isLoading: true, // Start in loading state
    );
  }

  WorkbenchInstancesState copyWith({
    List<WorkbenchInstance>? instances,
    bool? isLoading,
    Object? error,
    bool clearError = false,
    Map<String, String?>? lastOpenedItemId,
  }) {
    return WorkbenchInstancesState(
      instances: instances ?? this.instances,
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
        other.isLoading == isLoading &&
        other.error == error &&
        mapEquals(other.lastOpenedItemId, lastOpenedItemId);
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(instances),
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
    _initializePrefsAndLoad();
  }

  Future<void> _initializePrefsAndLoad() async {
    try {
      _prefsService = await _ref.read(sharedPrefsServiceProvider.future);
      _prefsInitialized = true;
      if (kDebugMode) {
        print('[WorkbenchInstancesNotifier] SharedPrefsService initialized.');
      }
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

    final cachedLastOpenedMap = _prefsService.getLastOpenedItemMap();

    if (mounted) {
      state = state.copyWith(
        lastOpenedItemId: cachedLastOpenedMap,
        isLoading: true,
        clearError: true,
      );
    }

    await loadInstances();
  }

  Future<void> loadInstances() async {
    if (!mounted) return;

    if (!_prefsInitialized) {
      if (kDebugMode) {
        print(
          '[WorkbenchInstancesNotifier] loadInstances called before prefs initialized. Waiting...',
        );
      }
      state = state.copyWith(isLoading: true);
      return;
    }

    if (!state.isLoading) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final instances = await _cloudKitService.getAllWorkbenchInstances();
      if (!mounted) return;

      if (mounted) {
        state = state.copyWith(
          instances: instances,
          isLoading: false,
        );
        if (kDebugMode) {
          print(
            '[WorkbenchInstancesNotifier] Loaded ${instances.length} instances.',
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
      if (kDebugMode) {
        print('[WorkbenchInstancesNotifier] Instance name cannot be empty.');
      }
      state = state.copyWith(error: 'Instance name cannot be empty');
      return false;
    }

    if (state.instances.any((i) => i.name.toLowerCase() == name.trim().toLowerCase())) {
      if (kDebugMode) {
        print(
          '[WorkbenchInstancesNotifier] Instance name "$name" already exists.',
        );
      }
      state = state.copyWith(error: 'An instance with this name already exists.');
      return false;
    }

    final newInstance = WorkbenchInstance(
      id: const Uuid().v4(),
      name: name.trim(),
      createdAt: DateTime.now(),
    );

    final originalState = state;
    final updatedInstances = [
      ...originalState.instances,
      newInstance,
    ];

    if (mounted) {
      state = state.copyWith(
        instances: updatedInstances,
        isLoading: false,
        clearError: true,
      );
    }

    try {
      final success = await _cloudKitService.saveWorkbenchInstance(newInstance);
      if (!success) {
        throw Exception('CloudKit save failed');
      }
      if (kDebugMode) {
        print(
          '[WorkbenchInstancesNotifier] Saved new instance ${newInstance.id}.',
        );
      }
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        print('[WorkbenchInstancesNotifier] Error saving instance: $e\n$s');
      }
      if (mounted) {
        state = originalState.copyWith(error: e);
      }
      return false;
    }
  }

  Future<bool> renameInstance(String instanceId, String newName) async {
    if (!mounted || !_prefsInitialized) return false;
    if (newName.trim().isEmpty) {
      if (kDebugMode) {
        print('[WorkbenchInstancesNotifier] Instance name cannot be empty.');
      }
      state = state.copyWith(error: 'Instance name cannot be empty');
      return false;
    }
    if (state.instances.any((i) => i.id != instanceId && i.name.toLowerCase() == newName.trim().toLowerCase())) {
      if (kDebugMode) {
        print(
          '[WorkbenchInstancesNotifier] Instance name "$newName" already exists.',
        );
      }
      state = state.copyWith(error: 'An instance with this name already exists.');
      return false;
    }

    final instanceToRename = state.instances.firstWhere(
      (i) => i.id == instanceId,
      orElse:
          () => throw Exception('Instance not found for rename: $instanceId'),
    );
    final updatedInstance = instanceToRename.copyWith(name: newName.trim());

    final originalInstances = List<WorkbenchInstance>.from(state.instances);
    final updatedList =
        originalInstances
            .map((i) => i.id == instanceId ? updatedInstance : i)
            .toList();
    if (mounted) {
      state = state.copyWith(instances: updatedList, clearError: true);
    }

    try {
      final success = await _cloudKitService.saveWorkbenchInstance(updatedInstance);
      if (!success) throw Exception('CloudKit save failed');
      if (kDebugMode) {
        print('[WorkbenchInstancesNotifier] Renamed instance $instanceId to "$newName"');
      }
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        print('[WorkbenchInstancesNotifier] Error renaming instance $instanceId: $e\n$s');
      }
      if (mounted) {
        state = state.copyWith(instances: originalInstances, error: e);
      }
      return false;
    }
  }

  Future<bool> deleteInstance(String instanceId) async {
    if (!mounted || !_prefsInitialized) return false;
    if (state.instances.length <= 1) {
      if (kDebugMode) {
        print('[WorkbenchInstancesNotifier] Cannot delete the last instance.');
      }
      state = state.copyWith(error: 'Cannot delete the last instance.');
      return false;
    }
    if (instanceId == WorkbenchInstance.defaultInstanceId) {
      if (kDebugMode) {
        print(
          '[WorkbenchInstancesNotifier] Cannot delete the default instance.',
        );
      }
      state = state.copyWith(error: 'Cannot delete the default instance.');
      return false;
    }

    final originalState = state;
    final originalInstances = List<WorkbenchInstance>.from(state.instances);
    final newInstances =
        originalInstances.where((i) => i.id != instanceId).toList();

    if (mounted) {
      state = state.copyWith(
        instances: newInstances,
        clearError: true,
      );
    }

    try {
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

      unawaited(
        _cloudKitService
            .deleteAllWorkbenchItemReferences(instanceId: instanceId)
            .then((success) {
              if (kDebugMode) {
                print(
                  '[WorkbenchInstancesNotifier] Attempted deletion of items for instance $instanceId. Success: $success',
                );
              }
            }),
      );

      _removeInstanceFromLastOpenedMap(instanceId);

      return true;
    } catch (e, s) {
      if (kDebugMode) {
        print(
          '[WorkbenchInstancesNotifier] Error during delete instance process for $instanceId: $e\n$s',
        );
      }
      if (mounted) {
        state = originalState.copyWith(error: e);
      }
      return false;
    }
  }

  // --- Last Opened Item Logic ---

  void setLastOpenedItem(String instanceId, String? referenceId) {
    if (!mounted || !_prefsInitialized) return;

    final currentMap = Map<String, String?>.from(state.lastOpenedItemId);
    if (currentMap[instanceId] == referenceId) return;

    currentMap[instanceId] = referenceId;

    if (mounted) {
      state = state.copyWith(lastOpenedItemId: currentMap);
      if (kDebugMode) {
        print(
          '[WorkbenchInstancesNotifier] Updated last opened item for instance $instanceId to $referenceId',
        );
      }
      unawaited(_prefsService.saveLastOpenedItemMap(currentMap));
    }
  }

  void _removeInstanceFromLastOpenedMap(String instanceId) {
    if (!mounted || !_prefsInitialized) return;
    final currentMap = Map<String, String?>.from(state.lastOpenedItemId);
    if (currentMap.containsKey(instanceId)) {
      currentMap.remove(instanceId);
      if (mounted) {
        state = state.copyWith(lastOpenedItemId: currentMap);
        if (kDebugMode) {
          print(
            '[WorkbenchInstancesNotifier] Removed instance $instanceId from last opened map.',
          );
        }
        unawaited(_prefsService.saveLastOpenedItemMap(currentMap));
      }
    }
  }
}

// Provider definition for instance state
final workbenchInstancesProvider =
    StateNotifierProvider<WorkbenchInstancesNotifier, WorkbenchInstancesState>((
      ref,
    ) {
      return WorkbenchInstancesNotifier(ref);
    });
