import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/models/task_item.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/services/task_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to fetch details for a single task by ID
final taskDetailProvider =
    FutureProvider.family<TaskItem, String>((
  ref,
  taskId,
) async {

  // Always try to get the dedicated Todoist service for task details,
  // regardless of the *active* server in the main UI.
  // This assumes task details are only ever fetched for Todoist tasks.
  final todoistService = ref.watch(todoistApiServiceProvider);

  if (!todoistService.isConfigured) {
    throw Exception('Todoist API Key not configured in Settings.');
  }

  // Use the dedicated service instance
  try {
    final task = await todoistService.getTask(taskId);
    return task;
  } catch (e) {
    if (kDebugMode) {
      print(
        'Error fetching task detail for $taskId via dedicated provider: $e',
      );
    }
    throw Exception('Failed to load task details for ID: $taskId. Error: $e');
  }
});

// Basic provider that returns the list of tasks from the notifier.
// Filtering logic (search, status, labels) can be added here later.
final filteredTasksProvider = Provider<List<TaskItem>>((ref) {
  final tasksState = ref.watch(tasksNotifierProvider);
  // --- Add filtering logic here based on other providers ---
  // Example: final searchTerm = ref.watch(taskSearchProvider);
  // Example: final statusFilter = ref.watch(taskStatusFilterProvider);

  // Simple filtering example: Show completed tasks based on a hypothetical filter provider
  final showCompleted = ref.watch(showCompletedTasksProvider);
  if (!showCompleted) {
    return tasksState.tasks.where((task) => !task.isCompleted).toList();
  }

  // Default: return all tasks fetched
  return tasksState.tasks;
});

// Provider for controlling task filters (Example: Show Completed toggle)
final showCompletedTasksProvider = StateProvider<bool>(
  (ref) => false,
  name: 'showCompletedTasks',
);


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
      if (state.error != 'Active server is not Todoist') {
        state = TasksState.initial().copyWith(
          error: 'Active server is not Todoist',
          tasks: [],
        ); // Clear tasks if not Todoist
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
      if (state.error != 'Active service does not support tasks') {
        state = state.copyWith(
          isLoading: false,
          error: 'Active service does not support tasks',
          tasks: [],
        ); // Clear tasks on error
      }
      return null;
    }
  }

  /// Clears tasks and sets state to initial when server switches away from Todoist
  void clearTasksForNonTodoist() {
    if (_ref.read(activeServerConfigProvider)?.serverType !=
        ServerType.todoist) {
      state = TasksState.initial();
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
      // Sort tasks (e.g., by priority descending, then maybe creation date)
      tasks.sort((a, b) {
        final priorityComparison = b.priority.compareTo(a.priority);
        if (priorityComparison != 0) {
          return priorityComparison;
        }
        // Optional secondary sort, e.g., by creation date descending
        // return b.createdAt.compareTo(a.createdAt);
        return 0; // Keep original API order if priorities are equal
      });
      state = state.copyWith(isLoading: false, tasks: tasks);
    } catch (e, s) {
       if (kDebugMode) {
         print('Error fetching tasks: $e\n$s');
       }
       // Check if still mounted before updating state
       if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        tasks: [],
      ); // Clear tasks on error
    }
  }

  Future<bool> completeTask(String id) async {
    final apiService = _getTaskApiService();
    if (apiService == null) return false;

    // Optimistic update
    final originalTasks = List<TaskItem>.from(state.tasks);
    TaskItem? originalTask;
    if (mounted) {
      state = state.copyWith(
        tasks:
            state.tasks.map((task) {
              if (task.id == id) {
                originalTask = task; // Store original for potential revert
                return task.copyWith(isCompleted: true);
              }
              return task;
            }).toList(),
      );
    }

    try {
      await apiService.completeTask(id);
      // Success, state already updated optimistically
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        print('Error completing task $id: $e\n$s');
      }
      // Revert optimistic update on failure
      if (mounted && originalTask != null) {
        state = state.copyWith(
          tasks: originalTasks, // Revert to original list
          error: 'Failed to complete task: ${e.toString()}',
        );
      }
      return false;
    }
  }

  Future<bool> reopenTask(String id) async {
    final apiService = _getTaskApiService();
    if (apiService == null) return false;

    // Optimistic update
    final originalTasks = List<TaskItem>.from(state.tasks);
    TaskItem? originalTask;
    if (mounted) {
      state = state.copyWith(
        tasks:
            state.tasks.map((task) {
              if (task.id == id) {
                originalTask = task; // Store original for potential revert
                return task.copyWith(isCompleted: false);
              }
              return task;
            }).toList(),
      );
    }

    try {
      await apiService.reopenTask(id);
      // Success, state already updated optimistically
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        print('Error reopening task $id: $e\n$s');
      }
      // Revert optimistic update on failure
      if (mounted && originalTask != null) {
        state = state.copyWith(
          tasks: originalTasks, // Revert to original list
          error: 'Failed to reopen task: ${e.toString()}',
        );
      }
      return false;
    }
  }

  Future<bool> deleteTask(String id) async {
    final apiService = _getTaskApiService();
    if (apiService == null) return false;

    // Optimistic update
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
        state = state.copyWith(
          tasks: originalTasks,
          error: 'Failed to delete task: ${e.toString()}',
        );
      }
      return false;
    }
  }

  // Add methods for createTask, updateTask
  Future<TaskItem?> createTask(TaskItem task) async {
    final apiService = _getTaskApiService();
    if (apiService == null) return null;

    // Set loading state specifically for creation? Maybe not needed if UI handles it.

    try {
      final createdTask = await apiService.createTask(task);
      // Add to local state optimistically or after success?
      // Adding after success ensures we have the correct ID from the API.
      if (mounted) {
        // Add and re-sort
        final newTasks = [...state.tasks, createdTask];
        newTasks.sort((a, b) {
          final priorityComparison = b.priority.compareTo(a.priority);
          if (priorityComparison != 0) return priorityComparison;
          return 0; // Keep original order if priorities are equal
        });
        state = state.copyWith(tasks: newTasks, clearError: true);
      }
      return createdTask;
    } catch (e, s) {
      if (kDebugMode) {
        print('Error creating task: $e\n$s');
      }
      if (mounted) {
        state = state.copyWith(error: 'Failed to create task: ${e.toString()}');
      }
      return null; // Indicate failure
    }
  }

  Future<TaskItem?> updateTask(String id, TaskItem taskUpdate) async {
    final apiService = _getTaskApiService();
    if (apiService == null) return null;

    // Optimistic update (optional, but improves perceived performance)
    final originalTasks = List<TaskItem>.from(state.tasks);
    TaskItem? originalTask;
    bool found = false;
    if (mounted) {
      state = state.copyWith(
        tasks:
            state.tasks.map((task) {
              if (task.id == id) {
                originalTask = task; // Store original for revert
                found = true;
                return taskUpdate.copyWith(id: id); // Ensure ID remains correct
              }
              return task;
            }).toList(),
      );
    }
    // If task wasn't found locally (shouldn't happen if called from UI list)
    if (!found) {
      print("Warning: Task $id not found in local state for update.");
      // Potentially revert state or fetch tasks again
    }

    try {
      // API update often returns the updated item or just confirms success
      final updatedTask = await apiService.updateTask(id, taskUpdate);
      // If API returns the updated task, replace it in the list. If not, the optimistic update stands.
      if (mounted) {
        // Re-sort after update as priority might have changed
        final currentTasks = List<TaskItem>.from(state.tasks);
        currentTasks.sort((a, b) {
          final priorityComparison = b.priority.compareTo(a.priority);
          if (priorityComparison != 0) return priorityComparison;
          return 0;
        });
        state = state.copyWith(tasks: currentTasks, clearError: true);
        return updatedTask; // Return the result from the API service
      }
      return null; // Not mounted
    } catch (e, s) {
      if (kDebugMode) {
        print('Error updating task $id: $e\n$s');
      }
      // Revert optimistic update on failure
      if (mounted && originalTask != null) {
        state = state.copyWith(
          tasks: originalTasks,
          error: 'Failed to update task: ${e.toString()}',
        );
      } else if (mounted) {
        // If optimistic update failed somehow or task wasn't found
        state = state.copyWith(error: 'Failed to update task: ${e.toString()}');
      }
      return null; // Indicate failure
    }
  }


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
