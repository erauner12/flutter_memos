import 'dart:async';
import 'dart:convert'; // Import dart:convert

import 'package:flutter/foundation.dart';
// Removed Material import
import 'package:flutter_memos/models/workbench_instance.dart';
import 'package:flutter_memos/providers/shared_prefs_provider.dart';
// Removed CloudKitService import
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
    // Start with a default instance if none are loaded
    return WorkbenchInstancesState(
      instances: [
        // Call the factory constructor correctly
        WorkbenchInstance.defaultInstance(),
      ], // Ensure default exists initially
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
  // Removed CloudKitService instance
  // late final CloudKitService _cloudKitService;
  late final SharedPrefsService _prefsService;
  bool _prefsInitialized = false; // Track if prefs are loaded

  // Key for storing instances in SharedPreferences
  static const String _instancesPrefsKey = 'workbench_instances_list';

  WorkbenchInstancesNotifier(this._ref)
    : super(WorkbenchInstancesState.initial()) {
    // Removed CloudKitService initialization
    // _cloudKitService = _ref.read(cloudKitServiceProvider);
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
      // Load instances from prefs first before setting state
      final loadedInstances = await _loadInstancesFromPrefs();
      state = state.copyWith(
        instances:
            loadedInstances.isNotEmpty
                ? loadedInstances
                : [
                  // Call the factory constructor correctly
                  WorkbenchInstance.defaultInstance(),
                ], // Ensure default if empty
        lastOpenedItemId: cachedLastOpenedMap,
        isLoading: false, // Loading from prefs is complete
        clearError: true,
      );
      if (kDebugMode) {
        print(
          '[WorkbenchInstancesNotifier] Initialized with ${state.instances.length} instances from Prefs.',
        );
      }
    }

    // Removed call to loadInstances (which previously loaded from CloudKit)
    // await loadInstances();
  }

  // Renamed loadInstances to loadInstancesFromPrefs
  // Ensure correct return type Future<List<WorkbenchInstance>>
  Future<List<WorkbenchInstance>> _loadInstancesFromPrefs() async {
    if (!_prefsInitialized) return []; // Cannot load if prefs not ready

    try {
      // Use the correct method name from SharedPrefsService
      final jsonString = _prefsService.getString(_instancesPrefsKey);
      if (jsonString != null) {
        // Use jsonDecode from dart:convert
        final List<dynamic> decodedList = jsonDecode(jsonString);
        final instances =
            decodedList
                .map(
                  // Call fromJson correctly (now only needs json map)
                  (data) =>
                      WorkbenchInstance.fromJson(data as Map<String, dynamic>),
                )
                .toList();
        // Ensure the default instance is always present
        if (!instances.any(
          (i) => i.id == WorkbenchInstance.defaultInstanceId,
        )) {
          // Call the factory constructor correctly
          instances.insert(0, WorkbenchInstance.defaultInstance());
        }
        return instances; // Correct return type
      } else {
        // If nothing in prefs, return just the default
        // Call the factory constructor correctly
        return [WorkbenchInstance.defaultInstance()];
      }
    } catch (e, s) {
      if (kDebugMode) {
        print(
          '[WorkbenchInstancesNotifier] Error loading instances from Prefs: $e\n$s',
        );
      }
      // Fallback to default on error
      // Call the factory constructor correctly
      return [WorkbenchInstance.defaultInstance()];
    }
  }

  // Helper to save instances to SharedPreferences
  Future<bool> _saveInstancesToPrefs(List<WorkbenchInstance> instances) async {
    if (!_prefsInitialized) return false;
    try {
      // Use jsonEncode from dart:convert
      final jsonString = jsonEncode(instances.map((i) => i.toJson()).toList());
      // Use the correct method name from SharedPrefsService
      await _prefsService.setString(_instancesPrefsKey, jsonString);
      if (kDebugMode) {
        print(
          '[WorkbenchInstancesNotifier] Saved ${instances.length} instances to Prefs.',
        );
      }
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        print(
          '[WorkbenchInstancesNotifier] Error saving instances to Prefs: $e\n$s',
        );
      }
      return false;
    }
  }

  // Removed original loadInstances method (which loaded from CloudKit)

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

    final updatedInstances = [
      ...state.instances,
      newInstance,
    ];

    if (mounted) {
      state = state.copyWith(
        instances: updatedInstances,
        isLoading: false,
        clearError: true,
      );
      // Save updated list to prefs
      final success = await _saveInstancesToPrefs(updatedInstances);
      if (kDebugMode) {
        print(
          '[WorkbenchInstancesNotifier] Saved new instance ${newInstance.id} locally.',
        );
      }
      return success;
    }
    return false; // Not mounted
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

    WorkbenchInstance? instanceToRename;
    try {
      instanceToRename = state.instances.firstWhere((i) => i.id == instanceId);
    } catch (e) {
      if (kDebugMode) {
        print(
          '[WorkbenchInstancesNotifier] Instance not found for rename: $instanceId',
        );
      }
      state = state.copyWith(error: 'Instance not found for rename');
      return false;
    }

    final updatedInstance = instanceToRename.copyWith(name: newName.trim());

    final updatedList =
        state.instances
            .map((i) => i.id == instanceId ? updatedInstance : i)
            .toList();
    if (mounted) {
      state = state.copyWith(instances: updatedList, clearError: true);
      // Save updated list to prefs
      final success = await _saveInstancesToPrefs(updatedList);
      if (kDebugMode) {
        print(
          '[WorkbenchInstancesNotifier] Renamed instance $instanceId to "$newName" locally.',
        );
      }
      return success;
    }
    return false; // Not mounted
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

    final newInstances =
        state.instances.where((i) => i.id != instanceId).toList();

    if (mounted) {
      state = state.copyWith(
        instances: newInstances,
        clearError: true,
      );
      // Save updated list to prefs
      final success = await _saveInstancesToPrefs(newInstances);
      if (success) {
        _removeInstanceFromLastOpenedMap(instanceId);
        if (kDebugMode) {
          print(
            '[WorkbenchInstancesNotifier] Deleted instance $instanceId locally.',
          );
        }
        // Also remove the associated items from prefs
        await _prefsService.remove('workbench_items_$instanceId');
        if (kDebugMode) {
          print(
            '[WorkbenchInstancesNotifier] Removed items for deleted instance $instanceId from Prefs.',
          );
        }

      } else {
        // Revert state if save failed
        state = state.copyWith(
          instances: state.instances,
        ); // Revert to previous list
        state = state.copyWith(error: 'Failed to save instance deletion');
        return false;
      }
      // Removed CloudKit deletion logic
      return true;
    }
    return false; // Not mounted
  }

  // --- Last Opened Item Logic (Uses SharedPrefsService, no change needed here) ---

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
