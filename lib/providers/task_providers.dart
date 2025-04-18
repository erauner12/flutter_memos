import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/task_filter.dart'; // Import the new enum
import 'package:flutter_memos/models/task_item.dart';
import 'package:flutter_memos/providers/api_providers.dart';
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

// NEW: Provider family for filtered tasks based on TaskFilter
final filteredTasksProviderFamily = Provider.family<
  List<TaskItem>,
  TaskFilter
>((ref, taskFilter) {
  final tasksState = ref.watch(tasksNotifierProvider);
  final allTasks = tasksState.tasks;

  // Filter based on the provided taskFilter
  List<TaskItem> filteredTasks;
  switch (taskFilter) {
    case TaskFilter.recurring:
      filteredTasks = allTasks.where((t) => t.isRecurring).toList();
      break;
    case TaskFilter.notRecurring:
      filteredTasks = allTasks.where((t) => !t.isRecurring).toList();
      break;
    case TaskFilter.dueToday:
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final tomorrowStart = DateTime(now.year, now.month, now.day + 1);
      filteredTasks =
          allTasks.where((t) {
            // Check if dueDate is not null and falls on the current calendar day
            return t.dueDate != null &&
                t.dueDate!.isAfter(
                  todayStart.subtract(const Duration(microseconds: 1)),
                ) && // >= today 00:00:00.000
                t.dueDate!.isBefore(tomorrowStart); // < tomorrow 00:00:00.000
          }).toList();
      break;
    case TaskFilter.all:
      filteredTasks = allTasks;
  }

  // Apply other filters like 'show completed'
  final showCompleted = ref.watch(showCompletedTasksProvider);
  if (!showCompleted) {
    return filteredTasks.where((task) => !task.isCompleted).toList();
  }

  return filteredTasks;
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

  // Helper to get the configured Todoist TaskApiService or handle errors
  TaskApiService? _getTaskApiService() {
    // Use the dedicated Todoist service provider
    final todoistService = _ref.read(todoistApiServiceProvider);

    if (!todoistService.isConfigured) {
      // If Todoist API key isn't set up
      final errorMessage = 'Todoist API Key not configured in Settings.';
      if (state.error != errorMessage) {
        state = TasksState.initial().copyWith(
          error: errorMessage,
          tasks: [], // Clear tasks if not configured
        );
      }
      return null;
    }

    // Clear error if we successfully get the service and previously had an error
    if (state.error != null) {
      state = state.copyWith(clearError: true);
    }
    return todoistService; // Return the configured service instance
  }

  /// Clears tasks and resets state to initial.
  void clearTasks() {
    state = TasksState.initial();
  }

  Future<void> fetchTasks({String? filter}) async {
    // Use the helper which now checks configuration, not active server
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
        error: 'Failed to fetch tasks from Todoist: ${e.toString()}',
        tasks: [],
      ); // Clear tasks on error
    }
  }

  Future<bool> completeTask(String id) async {
    final apiService = _getTaskApiService(); // Checks config
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
      await apiService.completeTask(id); // Use the service instance
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
    final apiService = _getTaskApiService(); // Checks config
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
      await apiService.reopenTask(id); // Use the service instance
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
    final apiService = _getTaskApiService(); // Checks config
    if (apiService == null) return false;

    // Optimistic update
    final originalTasks = List<TaskItem>.from(state.tasks);
    if (mounted) {
      state = state.copyWith(
        tasks: state.tasks.where((task) => task.id != id).toList(),
      );
    }

    try {
      await apiService.deleteTask(id); // Use the service instance
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

  Future<TaskItem?> createTask(TaskItem task) async {
    final apiService = _getTaskApiService(); // Checks config
    if (apiService == null) return null;

    try {
      final createdTask = await apiService.createTask(
        task,
      ); // Use the service instance
      if (mounted) {
        final newTasks = [...state.tasks, createdTask];
        newTasks.sort((a, b) {
          final priorityComparison = b.priority.compareTo(a.priority);
          if (priorityComparison != 0) return priorityComparison;
          return 0;
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
    final apiService = _getTaskApiService(); // Checks config
    if (apiService == null) return null;

    // Optimistic update
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
                // Merge updates using copyWith
                return originalTask!.copyWith(
                  content: taskUpdate.content,
                  // Wrap description in ValueGetter
                  description: () => taskUpdate.description,
                  priority: taskUpdate.priority,
                  dueDate: taskUpdate.dueDate,
                  dueString: taskUpdate.dueString,
                  labels: taskUpdate.labels,
                  // Add other updatable fields here
                );
              }
              return task;
            }).toList(),
      );
    }
    if (!found) {
      print("Warning: Task $id not found in local state for update.");
    }

    try {
      final updatedTask = await apiService.updateTask(
        id,
        taskUpdate,
      ); // Use the service instance
      if (mounted) {
        final updatedTasks =
            state.tasks.map((task) {
              if (task.id == id) {
                return updatedTask;
              }
              return task;
            }).toList();

        updatedTasks.sort((a, b) {
          final priorityComparison = b.priority.compareTo(a.priority);
          if (priorityComparison != 0) return priorityComparison;
          return 0;
        });
        state = state.copyWith(tasks: updatedTasks, clearError: true);
        return updatedTask;
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

  const TasksState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
  });

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
