import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/models/task_item.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/services/task_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to fetch details for a single task by ID
final taskDetailProvider =
    FutureProvider.family<TaskItem, String>((ref, taskId) async {
  // Get the API service
  // Note: This assumes the active server is Todoist when this provider is used.
  // A more robust solution might involve checking the server type or using
  // a dedicated provider that *always* returns the configured Todoist service.
  final apiService = ref.watch(apiServiceProvider);

  if (apiService is TaskApiService) {
    try {
      final task = await apiService.getTask(taskId);
      return task;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching task detail for $taskId: $e');
      }
      throw Exception('Failed to load task details for ID: $taskId. Error: $e');
    }
  } else {
    throw Exception('Active service does not support fetching task details.');
  }
});
// Basic provider that returns the list of tasks from the notifier.
// Filtering logic (search, status, labels) can be added here later.
final filteredTasksProvider = Provider<List<TaskItem>>((ref) {
  final tasksState = ref.watch(tasksNotifierProvider);
  // --- Add filtering logic here based on other providers ---
  // Example: final searchTerm = ref.watch(taskSearchProvider);
  // Example: final statusFilter = ref.watch(taskStatusFilterProvider);
  // return tasksState.tasks.where((task) => matchesFilters).toList();
  return tasksState.tasks;
});
final tasksNotifierProvider =
    StateNotifierProvider<TasksNotifier, TasksState>((ref) {
  final notifier = TasksNotifier(ref);
  // Optionally trigger initial fetch if desired, or let UI trigger it
  // notifier.fetchTasks();
  return notifier;
});
class TasksNotifier extends StateNotifier<TasksState> {
  final Ref _ref;

  TasksNotifier(this._ref) : super(TasksState.initial());

  // Helper to get the TaskApiService or handle errors
  TaskApiService? _getTaskApiService() {
    final activeServerType = _ref.read(activeServerConfigProvider)?.serverType;
    if (activeServerType != ServerType.todoist) {
      // Only set error if the current state doesn't already reflect this
      if (state.error != 'Active server is not Todoist' || state.tasks.isNotEmpty) {
         state = TasksState.initial().copyWith(error: 'Active server is not Todoist');
      }
      return null;
    }

    final apiService = _ref.read(apiServiceProvider);
    if (apiService is TaskApiService) {
      // Clear error if we successfully get the service and previously had an error
      if (state.error != null) {
        state = state.copyWith(clearError: true);
      }
      return apiService;
    } else {
       // Only set error if the current state doesn't already reflect this
      if (state.error != 'Active service does not support tasks' || state.tasks.isNotEmpty) {
        state = state.copyWith(isLoading: false, error: 'Active service does not support tasks', tasks: []);
      }
      return null;
    }
  }

  Future<void> fetchTasks({String? filter}) async {
    final apiService = _getTaskApiService();
    if (apiService == null) return; // Error handled in _getTaskApiService

    // Prevent concurrent fetches
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true); // Clear previous errors on new fetch
    try {
      final tasks = await apiService.listTasks(filter: filter);
      // Check if still mounted before updating state
      if (!mounted) return;
      state = state.copyWith(isLoading: false, tasks: tasks);
    } catch (e, s) {
       if (kDebugMode) {
         print('Error fetching tasks: $e\n$s');
       }
       // Check if still mounted before updating state
       if (!mounted) return;
       state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> completeTask(String id) async {
    final apiService = _getTaskApiService();
    if (apiService == null) return false;

    try {
      await apiService.completeTask(id);
      // Update local state
      if (mounted) {
        state = state.copyWith(
          tasks: state.tasks.map((task) {
            if (task.id == id) {
              return task.copyWith(isCompleted: true);
            }
            return task;
          }).toList(),
        );
      }
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        print('Error completing task $id: $e\n$s');
      }
      // Optionally set state.error here or let caller handle UI feedback
      return false;
    }
  }

  Future<bool> reopenTask(String id) async {
    final apiService = _getTaskApiService();
    if (apiService == null) return false;

    try {
      await apiService.reopenTask(id);
      // Update local state
      if (mounted) {
        state = state.copyWith(
          tasks: state.tasks.map((task) {
            if (task.id == id) {
              return task.copyWith(isCompleted: false);
            }
            return task;
          }).toList(),
        );
      }
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        print('Error reopening task $id: $e\n$s');
      }
      return false;
    }
  }

  Future<bool> deleteTask(String id) async {
    final apiService = _getTaskApiService();
    if (apiService == null) return false;

    // Optimistic update (optional, but improves perceived performance)
    final originalTasks = List<TaskItem>.from(state.tasks);
    if (mounted) {
      state = state.copyWith(
        tasks: state.tasks.where((task) => task.id != id).toList(),
      );
    }

    try {
      await apiService.deleteTask(id);
      // Success, state already updated optimistically
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        print('Error deleting task $id: $e\n$s');
      }
      // Revert optimistic update on failure
      if (mounted) {
        state = state.copyWith(tasks: originalTasks, error: e.toString());
      }
      return false;
    }
  }

  // Add methods for createTask, updateTask later if needed directly in notifier
}

@immutable
class TasksState {
  final List<TaskItem> tasks;
  final bool isLoading;
  final String? error;
  // Add pagination fields later if needed

  const TasksState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
  });

  // Initial state
  factory TasksState.initial() => const TasksState();

  TasksState copyWith({
    List<TaskItem>? tasks,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TasksState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TasksState &&
        listEquals(other.tasks, tasks) &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(tasks),
        isLoading,
        error,
      );
}
