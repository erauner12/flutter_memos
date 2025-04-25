import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/focus_instance.dart'; // Updated import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'focus_instances'; // Updated key
const _defaultInstanceId = 'default_focus_instance'; // Updated default ID

@immutable
class FocusInstancesState {
  final List<FocusInstance> instances;
  final bool isLoading;
  final String? error;

  const FocusInstancesState({
    this.instances = const [],
    this.isLoading = false,
    this.error,
  });

  FocusInstancesState copyWith({
    List<FocusInstance>? instances,
    bool? isLoading,
    String? error,
    // bool clearError = false, // Optional: flag to explicitly clear error
  }) {
    return FocusInstancesState(
      instances: instances ?? this.instances,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      // error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FocusInstancesState &&
        listEquals(other.instances, instances) &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(instances), isLoading, error);

  get lastOpenedItemId => null;

   @override
  String toString() {
    return 'FocusInstancesState(instances: ${instances.length} instances, isLoading: $isLoading, error: $error)';
  }
}


class FocusInstancesNotifier extends StateNotifier<FocusInstancesState> {
  FocusInstancesNotifier() : super(const FocusInstancesState(isLoading: true)) {
    _loadInstances();
  }

  Future<void> _loadInstances() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? instancesJson = prefs.getString(_prefsKey);
      List<FocusInstance> loadedInstances = [];

      if (instancesJson != null) {
        final List<dynamic> decodedList = jsonDecode(instancesJson);
        loadedInstances = decodedList
            .map((jsonItem) => FocusInstance.fromJson(jsonItem as Map<String, dynamic>))
            .toList();
      }

      // Ensure the default instance always exists
      if (!loadedInstances.any((inst) => inst.id == _defaultInstanceId)) {
         final defaultInstance = FocusInstance.defaultInstance();
         loadedInstances.insert(0, defaultInstance); // Add to the beginning
         await _saveInstancesToPrefs(loadedInstances); // Save immediately
      }


      state = state.copyWith(instances: loadedInstances, isLoading: false);
       if (kDebugMode) {
        print('[FocusInstancesNotifier] Loaded ${loadedInstances.length} instances.');
      }

    } catch (e, s) {
       if (kDebugMode) {
        print('[FocusInstancesNotifier] Error loading instances: $e\n$s');
      }
      state = state.copyWith(isLoading: false, error: 'Failed to load focus boards: $e');
    }
  }

  Future<void> _saveInstancesToPrefs(List<FocusInstance> instances) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> jsonList =
          instances.map((instance) => instance.toJson()).toList();
      await prefs.setString(_prefsKey, jsonEncode(jsonList));
       if (kDebugMode) {
        print('[FocusInstancesNotifier] Saved ${instances.length} instances to prefs.');
      }
    } catch (e, s) {
       if (kDebugMode) {
        print('[FocusInstancesNotifier] Error saving instances: $e\n$s');
      }
      // Optionally update state with error, though saving is background
       state = state.copyWith(error: 'Failed to save focus boards: $e');
    }
  }

  Future<bool> saveInstance(String name) async {
    state = state.copyWith(isLoading: true); // Indicate loading/processing
    try {
      final newInstance = FocusInstance(name: name.trim());
      final updatedInstances = [...state.instances, newInstance];
      await _saveInstancesToPrefs(updatedInstances);
      state = state.copyWith(instances: updatedInstances, isLoading: false);
       if (kDebugMode) {
        print('[FocusInstancesNotifier] Added new instance: ${newInstance.id} - ${newInstance.name}');
      }
      return true;
    } catch (e, s) {
       if (kDebugMode) {
        print('[FocusInstancesNotifier] Error adding instance: $e\n$s');
      }
      state = state.copyWith(isLoading: false, error: 'Failed to add focus board: $e');
      return false;
    }
  }

  Future<void> renameInstance(String instanceId, String newName) async {
     if (newName.trim().isEmpty) return; // Prevent renaming to empty string

    final instanceIndex = state.instances.indexWhere((inst) => inst.id == instanceId);
    if (instanceIndex != -1) {
      final updatedInstance = state.instances[instanceIndex].copyWith(name: newName.trim());
      final updatedList = List<FocusInstance>.from(state.instances);
      updatedList[instanceIndex] = updatedInstance;
      await _saveInstancesToPrefs(updatedList);
      state = state.copyWith(instances: updatedList);
       if (kDebugMode) {
        print('[FocusInstancesNotifier] Renamed instance $instanceId to "$newName"');
      }
    } else {
       if (kDebugMode) {
        print('[FocusInstancesNotifier] Instance $instanceId not found for renaming.');
      }
       state = state.copyWith(error: 'Focus board not found for renaming.');
    }
  }

  Future<void> deleteInstance(String instanceId) async {
    // Prevent deleting the default instance or the last instance
    if (instanceId == _defaultInstanceId || state.instances.length <= 1) {
       if (kDebugMode) {
        print('[FocusInstancesNotifier] Attempted to delete default or last instance ($instanceId). Denied.');
      }
       state = state.copyWith(error: 'Cannot delete the default or last focus board.');
      return;
    }

    final updatedInstances = state.instances.where((inst) => inst.id != instanceId).toList();
    if (updatedInstances.length < state.instances.length) {
      await _saveInstancesToPrefs(updatedInstances);
      state = state.copyWith(instances: updatedInstances);
       if (kDebugMode) {
        print('[FocusInstancesNotifier] Deleted instance $instanceId.');
      }
      // TODO: Consider deleting associated items from focusProviderFamily(instanceId)
      // This might require invalidating or directly manipulating the other provider's state.
    } else {
       if (kDebugMode) {
        print('[FocusInstancesNotifier] Instance $instanceId not found for deletion.');
      }
       state = state.copyWith(error: 'Focus board not found for deletion.');
    }
  }

  // Refresh function to reload from storage
  Future<void> refresh() async {
    await _loadInstances();
  }

  void setLastOpenedItem(String instanceId, param1) {}
}

// Updated provider name
final focusInstancesProvider =
    StateNotifierProvider<FocusInstancesNotifier, FocusInstancesState>((ref) {
  return FocusInstancesNotifier();
});

// Selector provider to get a specific instance by ID
final focusInstanceProvider = Provider.family<FocusInstance?, String>((ref, id) {
  final instances = ref.watch(focusInstancesProvider).instances;
  try {
    return instances.firstWhere((instance) => instance.id == id);
  } catch (_) {
    return null; // Return null if not found
  }
});

// Selector provider to get the list of instances (useful for pickers)
final allFocusInstancesProvider = Provider<List<FocusInstance>>((ref) {
  return ref.watch(focusInstancesProvider).instances;
});
