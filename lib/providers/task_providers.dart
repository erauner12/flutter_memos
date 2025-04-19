import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/task_filter.dart'; // Import the new enum
import 'package:flutter_memos/models/task_item.dart';
// Keep this if used elsewhere
// Remove Todoist service import: import 'package:flutter_memos/services/task_api_service.dart';
import 'package:flutter_memos/services/vikunja_api_service.dart'; // Import Vikunja service
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to fetch details for a single task by ID
final taskDetailProvider =
    FutureProvider.family<TaskItem, String>((
  ref,
  taskId,
) async {
  // Use the Vikunja service provider
  final vikunjaService = ref.watch(vikunjaApiServiceProvider);

  // Check if the Vikunja service is configured
  // We might need a way to access the isVikunjaConfiguredProvider state here,
  // or rely on the service's internal state/error handling.
  // For simplicity, let's assume the service throws if not configured.
  // if (!vikunjaService.isConfigured) { // Or use the provider: ref.watch(isVikunjaConfiguredProvider)
  //   throw Exception('Vikunja API not configured in Settings.');
  // }

  try {
    // The service method now handles parsing String ID to int if needed
    final task = await vikunjaService.getTask(taskId);
    return task;
  } catch (e) {
    if (kDebugMode) {
      print('Error fetching task detail for $taskId via Vikunja provider: $e');
    }
    // Rethrow a more user-friendly error or the original exception
    throw Exception('Failed to load task details for ID: $taskId. Error: $e');
  }
});

// Provider family for filtered tasks based on TaskFilter
final filteredTasksProviderFamily = Provider.family<List<TaskItem>, TaskFilter>(
  (ref, taskFilter) {
  final tasksState = ref.watch(tasksNotifierProvider);
  final allTasks = tasksState.tasks;

  // Filter based on the provided taskFilter
  List<TaskItem> filteredTasks;
  switch (taskFilter) {
    case TaskFilter.recurring:
        // TODO: Adapt for Vikunja's recurring logic (e.g., repeatAfter != null)
        // filteredTasks = allTasks.where((t) => t.isRecurring).toList();
        filteredTasks = allTasks; // Placeholder: Show all for now
      break;
    case TaskFilter.notRecurring:
        // TODO: Adapt for Vikunja's recurring logic
        // filteredTasks = allTasks.where((t) => !t.isRecurring).toList();
        filteredTasks = allTasks; // Placeholder: Show all for now
      break;
    case TaskFilter.dueToday:
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final tomorrowStart = DateTime(now.year, now.month, now.day + 1);
        filteredTasks =
            allTasks.where((t) {
              return t.dueDate != null &&
                  t.dueDate!.isAfter(
                    todayStart.subtract(const Duration(microseconds: 1)),
                  ) &&
                  t.dueDate!.isBefore(tomorrowStart);
            }).toList();
      break;
    case TaskFilter.all:
      filteredTasks = allTasks;
  }

  // Apply other filters like 'show completed'
  final showCompleted = ref.watch(showCompletedTasksProvider);
  if (!showCompleted) {
      // Use 'done' field instead of 'isCompleted'
      return filteredTasks.where((task) => !task.done).toList();
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

  // Helper to get the configured Vikunja TaskApiService or handle errors
  VikunjaApiService? _getVikunjaApiService() {
    // Use the dedicated Vikunja service provider
    final vikunjaService = _ref.read(vikunjaApiServiceProvider);
    final isConfigured = _ref.read(
      isVikunjaConfiguredProvider,
    ); // Read the state provider

    if (!isConfigured) {
      final errorMessage = 'Vikunja API not configured in Settings.';
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
    return vikunjaService; // Return the configured service instance
  }

  /// Clears tasks and resets state to initial.
  void clearTasks() {
    state = TasksState.initial();
  }

  Future<void> fetchTasks({String? filter}) async {
    final apiService = _getVikunjaApiService();
    if (apiService == null) return; // Error handled in _getVikunjaApiService

    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final tasks = await apiService.listTasks(filter: filter);
      if (!mounted) return;

      // Sort tasks (e.g., by priority descending, then maybe creation date)
      // Adjust sorting based on Vikunja priority meaning if kept
      tasks.sort((a, b) {
        // Handle null priority
        final priorityA = a.priority ?? 99; // Assign low priority if null
        final priorityB = b.priority ?? 99;
        final priorityComparison = priorityB.compareTo(
          priorityA,
        ); // Vikunja priority might be different scale
        if (priorityComparison != 0) {
          return priorityComparison;
        }
        // Fallback sort by creation date if priorities are equal
        return a.createdAt.compareTo(b.createdAt);
      });
      state = state.copyWith(isLoading: false, tasks: tasks);
    } catch (e, s) {
       if (kDebugMode) {
        print('Error fetching tasks from Vikunja: $e\n$s');
      }
       if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch tasks from Vikunja: ${e.toString()}',
        tasks: [],
      );
    }
  }

  /// Fetches a single task by its ID.
  Future<TaskItem?> fetchTaskById(String taskId) async {
    final apiService = _getVikunjaApiService();
    if (apiService == null) return null;

    try {
      final task = await apiService.getTask(
        taskId,
      ); // Service handles ID parsing
      return task;
    } catch (e, s) {
      if (kDebugMode) {
        print('Error fetching Vikunja task by ID $taskId: $e\n$s');
      }
      if (mounted) {
        state = state.copyWith(
          error: 'Failed to fetch task $taskId: ${e.toString()}',
        );
      }
      return null;
    }
  }


  Future<bool> completeTask(String id) async {
    final apiService = _getVikunjaApiService();
    if (apiService == null) return false;

    // Optimistic update using 'done' field
    final originalTasks = List<TaskItem>.from(state.tasks);
    TaskItem? originalTask;
    bool taskFound = false;
    if (mounted) {
      state = state.copyWith(
        tasks:
            state.tasks.map((task) {
              // Compare String ID from UI/state with int ID from TaskItem
              if (task.id.toString() == id) {
                taskFound = true;
                originalTask = task;
                return task.copyWith(done: true); // Use 'done'
              }
              return task;
            }).toList(),
      );
    }

    if (!taskFound) {
      print("Warning: Task $id not found in local state for completion.");
      // Optionally revert or handle differently
    }


    try {
      await apiService.completeTask(id); // Service handles ID parsing
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        print('Error completing Vikunja task $id: $e\n$s');
      }
      // Revert optimistic update on failure
      if (mounted && taskFound) {
        // Only revert if we found and modified it
        state = state.copyWith(
          tasks: originalTasks,
          error: 'Failed to complete task: ${e.toString()}',
        );
      } else if (mounted) {
        state = state.copyWith(
          error: 'Failed to complete task: ${e.toString()}',
        );
      }
      return false;
    }
  }

  Future<bool> reopenTask(String id) async {
    final apiService = _getVikunjaApiService();
    if (apiService == null) return false;

    // Optimistic update using 'done' field
    final originalTasks = List<TaskItem>.from(state.tasks);
    TaskItem? originalTask;
    bool taskFound = false;
    if (mounted) {
      state = state.copyWith(
        tasks:
            state.tasks.map((task) {
              if (task.id.toString() == id) {
                taskFound = true;
                originalTask = task;
                return task.copyWith(done: false); // Use 'done'
              }
              return task;
            }).toList(),
      );
    }

    if (!taskFound) {
      print("Warning: Task $id not found in local state for reopening.");
    }

    try {
      await apiService.reopenTask(id); // Service handles ID parsing
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        print('Error reopening Vikunja task $id: $e\n$s');
      }
      // Revert optimistic update on failure
      if (mounted && taskFound) {
        state = state.copyWith(
          tasks: originalTasks,
          error: 'Failed to reopen task: ${e.toString()}',
        );
      } else if (mounted) {
        state = state.copyWith(error: 'Failed to reopen task: ${e.toString()}');
      }
      return false;
    }
  }

  Future<bool> deleteTask(String id) async {
    final apiService = _getVikunjaApiService();
    if (apiService == null) return false;

    // Optimistic update
    final originalTasks = List<TaskItem>.from(state.tasks);
    bool taskFound = false;
    if (mounted) {
      final initialLength = state.tasks.length;
      final newTasks =
          state.tasks.where((task) => task.id.toString() != id).toList();
      if (newTasks.length < initialLength) {
        taskFound = true;
        state = state.copyWith(tasks: newTasks);
      } else {
        print("Warning: Task $id not found in local state for deletion.");
      }
    }

    try {
      await apiService.deleteTask(id); // Service handles ID parsing
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        print('Error deleting Vikunja task $id: $e\n$s');
      }
      // Revert optimistic update on failure
      if (mounted && taskFound) {
        // Only revert if we actually removed it
        state = state.copyWith(
          tasks: originalTasks,
          error: 'Failed to delete task: ${e.toString()}',
        );
      } else if (mounted) {
        state = state.copyWith(error: 'Failed to delete task: ${e.toString()}');
      }
      return false;
    }
  }

  Future<TaskItem?> createTask(TaskItem task, {int? projectId}) async {
    final apiService = _getVikunjaApiService();
    if (apiService == null) return null;

    try {
      // Pass projectId if provided
      final createdTask = await apiService.createTask(
        task,
        projectId: projectId,
      );
      if (mounted) {
        final newTasks = [...state.tasks, createdTask];
        // Re-sort based on updated logic
        newTasks.sort((a, b) {
          final priorityA = a.priority ?? 99;
          final priorityB = b.priority ?? 99;
          final priorityComparison = priorityB.compareTo(priorityA);
          if (priorityComparison != 0) return priorityComparison;
          return a.createdAt.compareTo(b.createdAt);
        });
        state = state.copyWith(tasks: newTasks, clearError: true);
      }
      return createdTask;
    } catch (e, s) {
      if (kDebugMode) {
        print('Error creating Vikunja task: $e\n$s');
      }
      if (mounted) {
        state = state.copyWith(error: 'Failed to create task: ${e.toString()}');
      }
      return null;
    }
  }

  Future<TaskItem?> updateTask(String id, TaskItem taskUpdate) async {
    final apiService = _getVikunjaApiService();
    if (apiService == null) return null;

    // Optimistic update
    final originalTasks = List<TaskItem>.from(state.tasks);
    TaskItem? originalTask;
    bool found = false;
    if (mounted) {
      state = state.copyWith(
        tasks:
            state.tasks.map((task) {
              if (task.id.toString() == id) {
                originalTask = task;
                found = true;
                // Merge updates using copyWith - ensure all relevant fields are copied
                return originalTask!.copyWith(
                  title: taskUpdate.title,
                  description:
                      () =>
                          taskUpdate
                              .description, // Use ValueGetter for nullability
                  priority: taskUpdate.priority,
                  dueDate: taskUpdate.dueDate,
                  done: taskUpdate.done, // Include 'done' if updatable here
                  projectId: taskUpdate.projectId,
                  bucketId: taskUpdate.bucketId,
                  percentDone: taskUpdate.percentDone,
                  // Add other updatable fields from Vikunja if needed
                );
              }
              return task;
            }).toList(),
      );
    }
    if (!found) {
      print("Warning: Task $id not found in local state for update.");
      // Decide how to handle - maybe fetch first or return null?
    }

    try {
      // Pass the original TaskItem with merged updates to the service
      final updatedTask = await apiService.updateTask(
        id,
        taskUpdate,
      ); // Service handles ID parsing
      if (mounted) {
        final updatedTasks =
            state.tasks.map((task) {
              if (task.id.toString() == id) {
                return updatedTask; // Replace with the task returned by the API
              }
              return task;
            }).toList();

        // Re-sort
        updatedTasks.sort((a, b) {
          final priorityA = a.priority ?? 99;
          final priorityB = b.priority ?? 99;
          final priorityComparison = priorityB.compareTo(priorityA);
          if (priorityComparison != 0) return priorityComparison;
          return a.createdAt.compareTo(b.createdAt);
        });
        state = state.copyWith(tasks: updatedTasks, clearError: true);
        return updatedTask;
      }
      return null; // Not mounted
    } catch (e, s) {
      if (kDebugMode) {
        print('Error updating Vikunja task $id: $e\n$s');
      }
      // Revert optimistic update on failure
      if (mounted && found) {
        // Only revert if we found and modified it
        state = state.copyWith(
          tasks: originalTasks,
          error: 'Failed to update task: ${e.toString()}',
        );
      } else if (mounted) {
        state = state.copyWith(error: 'Failed to update task: ${e.toString()}');
      }
      return null;
    }
  }
}

// TasksState remains the same
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
