import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/task_filter.dart'; // Import the new enum
import 'package:flutter_memos/models/task_item.dart';
// Import Vikunja service and API provider
import 'package:flutter_memos/providers/api_providers.dart'; // Import taskApiServiceProvider
// Import new single config provider
import 'package:flutter_memos/providers/task_server_config_provider.dart';
import 'package:flutter_memos/services/task_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to fetch details for a single task by ID
final taskDetailProvider = FutureProvider.family<TaskItem, String>((
  ref,
  taskId,
) async {
  // Use the Task API service provider - WATCH the FutureProvider
  final taskApiServiceAsyncValue = ref.watch(taskApiServiceProvider);

  // Handle the AsyncValue states
  return taskApiServiceAsyncValue.when(
    data: (taskApiService) async {
      if (taskApiService is DummyTaskApiService) {
        throw Exception('Task API not configured in Settings.');
      }
      try {
        final task = await taskApiService.getTask(taskId);
        return task;
      } catch (e) {
        if (kDebugMode) print('Error fetching task detail for $taskId: $e');
        throw Exception(
          'Failed to load task details for ID: $taskId. Error: $e',
        );
      }
    },
    loading:
        () =>
            throw Exception(
              'Task API service is loading...',
            ), // Or return a loading state indicator if preferred
    error:
        (err, stack) => throw Exception('Error loading Task API service: $err'),
  );
});

// Provider family for filtered tasks based on TaskFilter
final filteredTasksProviderFamily = Provider.family<List<TaskItem>, TaskFilter>(
  (ref, taskFilter) {
  final tasksState = ref.watch(tasksNotifierProvider);
  final allTasks = tasksState.tasks;

  List<TaskItem> filteredTasks;
  switch (taskFilter) {
    case TaskFilter.recurring:
        filteredTasks =
            allTasks
                .where((t) => t.recurringInterval != null)
                .toList(); // Example Vikunja logic
      break;
    case TaskFilter.notRecurring:
        filteredTasks =
            allTasks
                .where((t) => t.recurringInterval == null)
                .toList(); // Example Vikunja logic
      break;
    case TaskFilter.dueToday:
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final tomorrowStart = DateTime(now.year, now.month, now.day + 1);
        filteredTasks =
            allTasks
                .where(
                  (t) =>
                      t.dueDate != null &&
                      t.dueDate!.isAfter(
                        todayStart.subtract(const Duration(microseconds: 1)),
                      ) &&
                      t.dueDate!.isBefore(tomorrowStart),
                )
                .toList();
      break;
    case TaskFilter.all:
      filteredTasks = allTasks;
  }

  final showCompleted = ref.watch(showCompletedTasksProvider);
    if (!showCompleted) {
      return filteredTasks.where((task) => !task.done).toList();
  }

  return filteredTasks;
});


// Provider for controlling task filters
final showCompletedTasksProvider = StateProvider<bool>(
  (ref) => false,
  name: 'showCompletedTasks',
);


final tasksNotifierProvider = StateNotifierProvider<TasksNotifier, TasksState>((
  ref,
) {
  final notifier = TasksNotifier(ref);
  return notifier;
});

class TasksNotifier extends StateNotifier<TasksState> {
  final Ref _ref;

  TasksNotifier(this._ref) : super(TasksState.initial());

  // Helper to get the configured TaskApiService or handle errors
  Future<TaskApiService?> _getTaskApiService() async {
    final taskConfig = _ref.read(taskServerConfigProvider);
    if (taskConfig == null) {
      if (state.error != 'No Task server configured.') {
        state = TasksState.initial().copyWith(
          error: 'No Task server configured.',
          tasks: [],
        );
      }
      return null;
    }
    // Use the dedicated provider which handles configuration
    // Await the future from the FutureProvider
    try {
      final taskService = await _ref.read(taskApiServiceProvider.future);
      if (taskService is DummyTaskApiService) {
        if (state.error != 'Task API service is not configured.') {
          state = TasksState.initial().copyWith(
            error: 'Task API service is not configured.',
            tasks: [],
          );
        }
        return null;
      }
      // Clear error if service is valid
      if (state.error != null) {
        state = state.copyWith(clearError: true);
      }
      return taskService;
    } catch (e, s) {
      if (kDebugMode) print('Error getting Task API service: $e\n$s');
      if (mounted) {
        state = TasksState.initial().copyWith(
          error: 'Failed to initialize Task API service: $e',
          tasks: [],
        );
      }
      return null;
    }
  }

  void clearTasks() {
    state = TasksState.initial();
    // Mark as unconfigured when clearing tasks explicitly? Maybe not needed if taskApiServiceProvider handles it.
    // _ref.read(isVikunjaConfiguredProvider.notifier).state = false;
  }

  Future<void> fetchTasks({String? filter}) async {
    final apiService = await _getTaskApiService();
    if (apiService == null) return; // Error handled in helper

    if (state.isLoading) return;
    if (!mounted) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // targetServerOverride is no longer needed as the provider handles the config
      final tasks = await apiService.listTasks(filter: filter);
      if (!mounted) return;

      tasks.sort((a, b) {
        final priorityA = a.priority ?? 0;
        final priorityB = b.priority ?? 0;
        final priorityComparison = priorityB.compareTo(priorityA);
        if (priorityComparison != 0) return priorityComparison;
        return a.createdAt.compareTo(b.createdAt);
      });
      state = state.copyWith(isLoading: false, tasks: tasks);
    } catch (e, s) {
      if (kDebugMode) print('Error fetching tasks: $e\n$s');
       if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch tasks: ${e.toString()}',
        tasks: [],
      );
    }
  }

  Future<TaskItem?> fetchTaskById(String taskId) async {
    final apiService = await _getTaskApiService();
    if (apiService == null) return null;

    try {
      final task = await apiService.getTask(taskId);
      return task;
    } catch (e, s) {
      if (kDebugMode) print('Error fetching task by ID $taskId: $e\n$s');
      if (mounted) {
        state = state.copyWith(
          error: 'Failed to fetch task $taskId: ${e.toString()}',
        );
      }
      return null;
    }
  }


  Future<bool> completeTask(String id) async {
    final apiService = await _getTaskApiService();
    if (apiService == null) return false;

    final originalTasks = List<TaskItem>.from(state.tasks);
    bool taskFound = false;
    if (mounted) {
      state = state.copyWith(
        tasks:
            state.tasks.map((task) {
              if (task.id == id) {
                taskFound = true;
                return task.copyWith(done: true);
              }
              return task;
            }).toList(),
      );
    }
    if (!taskFound)
      print("Warning: Task $id not found in local state for completion.");

    try {
      await apiService.completeTask(id);
      return true;
    } catch (e, s) {
      if (kDebugMode) print('Error completing task $id: $e\n$s');
      if (mounted && taskFound)
        state = state.copyWith(
          tasks: originalTasks,
          error: 'Failed to complete task: ${e.toString()}',
        );
      else if (mounted)
        state = state.copyWith(
          error: 'Failed to complete task: ${e.toString()}',
        );
      return false;
    }
  }

  Future<bool> reopenTask(String id) async {
    final apiService = await _getTaskApiService();
    if (apiService == null) return false;

    final originalTasks = List<TaskItem>.from(state.tasks);
    bool taskFound = false;
    if (mounted) {
      state = state.copyWith(
        tasks:
            state.tasks.map((task) {
              if (task.id == id) {
                taskFound = true;
                return task.copyWith(done: false);
              }
              return task;
            }).toList(),
      );
    }
    if (!taskFound)
      print("Warning: Task $id not found in local state for reopening.");

    try {
      await apiService.reopenTask(id);
      return true;
    } catch (e, s) {
      if (kDebugMode) print('Error reopening task $id: $e\n$s');
      if (mounted && taskFound)
        state = state.copyWith(
          tasks: originalTasks,
          error: 'Failed to reopen task: ${e.toString()}',
        );
      else if (mounted)
        state = state.copyWith(error: 'Failed to reopen task: ${e.toString()}');
      return false;
    }
  }

  Future<bool> deleteTask(String id) async {
    final apiService = await _getTaskApiService();
    if (apiService == null) return false;

    final originalTasks = List<TaskItem>.from(state.tasks);
    bool taskFound = false;
    if (mounted) {
      final initialLength = state.tasks.length;
      final newTasks = state.tasks.where((task) => task.id != id).toList();
      if (newTasks.length < initialLength) {
        taskFound = true;
        state = state.copyWith(tasks: newTasks);
      } else
        print("Warning: Task $id not found in local state for deletion.");
    }

    try {
      await apiService.deleteTask(id);
      return true;
    } catch (e, s) {
      if (kDebugMode) print('Error deleting task $id: $e\n$s');
      if (mounted && taskFound)
        state = state.copyWith(
          tasks: originalTasks,
          error: 'Failed to delete task: ${e.toString()}',
        );
      else if (mounted)
        state = state.copyWith(error: 'Failed to delete task: ${e.toString()}');
      return false;
    }
  }

  Future<TaskItem?> createTask(TaskItem task, {int? projectId}) async {
    final apiService = await _getTaskApiService();
    if (apiService == null) return null;

    try {
      final createdTask = await apiService.createTask(
        task,
        projectId: projectId,
      );
      if (mounted) {
        final newTasks = [...state.tasks, createdTask];
        newTasks.sort((a, b) {
          final priorityA = a.priority ?? 0;
          final priorityB = b.priority ?? 0;
          final priorityComparison = priorityB.compareTo(priorityA);
          if (priorityComparison != 0) return priorityComparison;
          return a.createdAt.compareTo(b.createdAt);
        });
        state = state.copyWith(tasks: newTasks, clearError: true);
      }
      return createdTask;
    } catch (e, s) {
      if (kDebugMode) print('Error creating task: $e\n$s');
      if (mounted)
        state = state.copyWith(error: 'Failed to create task: ${e.toString()}');
      return null;
    }
  }

  Future<TaskItem?> updateTask(String id, TaskItem taskUpdate) async {
    final apiService = await _getTaskApiService();
    if (apiService == null) return null;

    final originalTasks = List<TaskItem>.from(state.tasks);
    TaskItem? originalTask;
    bool found = false;
    if (mounted) {
      state = state.copyWith(
        tasks:
            state.tasks.map((task) {
              if (task.id == id) {
                originalTask = task;
                found = true;
                // Use the existing task's data and apply updates
                return task.copyWith(
                  title: taskUpdate.title,
                  description:
                      () => taskUpdate.description, // Use lambda for nullable
                  priority: taskUpdate.priority,
                  dueDate: taskUpdate.dueDate,
                  done: taskUpdate.done,
                  projectId: taskUpdate.projectId,
                  bucketId: taskUpdate.bucketId,
                  percentDone: taskUpdate.percentDone,
                );
              }
              return task;
            }).toList(),
      );
    }
    if (!found) print("Warning: Task $id not found in local state for update.");

    try {
      // Pass the updated task object (derived from taskUpdate) to the API
      final taskToSend = state.tasks.firstWhere((t) => t.id == id);
      final updatedTask = await apiService.updateTask(id, taskToSend);
      if (mounted) {
        final updatedTasks =
            state.tasks
                .map((task) => task.id == id ? updatedTask : task)
                .toList();
        updatedTasks.sort((a, b) {
          final priorityA = a.priority ?? 0;
          final priorityB = b.priority ?? 0;
          final priorityComparison = priorityB.compareTo(priorityA);
          if (priorityComparison != 0) return priorityComparison;
          return a.createdAt.compareTo(b.createdAt);
        });
        state = state.copyWith(tasks: updatedTasks, clearError: true);
        return updatedTask;
      }
      return null; // Should not happen if mounted check passes
    } catch (e, s) {
      if (kDebugMode) print('Error updating task $id: $e\n$s');
      if (mounted && found)
        state = state.copyWith(
          tasks: originalTasks,
          error: 'Failed to update task: ${e.toString()}',
        );
      else if (mounted)
        state = state.copyWith(error: 'Failed to update task: ${e.toString()}');
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
  int get hashCode => Object.hash(Object.hashAll(tasks), isLoading, error);
}
