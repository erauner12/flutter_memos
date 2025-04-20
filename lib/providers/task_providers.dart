import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/server_config.dart'; // Import ServerConfig
import 'package:flutter_memos/models/task_filter.dart'; // Import the new enum
import 'package:flutter_memos/models/task_item.dart';
import 'package:flutter_memos/providers/server_config_provider.dart'; // Import server config provider
import 'package:flutter_memos/providers/settings_provider.dart'; // Import settings for API key
import 'package:flutter_memos/services/auth_strategy.dart'; // Import for BearerTokenAuthStrategy
// Import Vikunja service
import 'package:flutter_memos/services/vikunja_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to fetch details for a single task by ID
final taskDetailProvider =
    FutureProvider.family<TaskItem, String>((
  ref,
  taskId,
) async {
  // Use the Vikunja service provider
  final vikunjaService = ref.watch(vikunjaApiServiceProvider);
  // Check configuration status via the dedicated provider
  final isConfigured = ref.watch(isVikunjaConfiguredProvider);

  if (!isConfigured) {
    throw Exception('Vikunja API not configured in Settings.');
  }

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
        // For now, just return all tasks as a placeholder
        filteredTasks = allTasks;
      break;
    case TaskFilter.notRecurring:
        // TODO: Adapt for Vikunja's recurring logic
        // For now, just return all tasks as a placeholder
        filteredTasks = allTasks;
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
  // This now also handles configuration based on active server and API key.
  Future<VikunjaApiService?> _getAndConfigureVikunjaApiService() async {
    final activeServer = _ref.read(activeServerConfigProvider);
    final vikunjaApiKey = _ref.read(vikunjaApiKeyProvider);
    final vikunjaService = _ref.read(vikunjaApiServiceProvider);
    final isConfiguredNotifier = _ref.read(
      isVikunjaConfiguredProvider.notifier,
    );

    // Check if the active server is Vikunja
    if (activeServer == null || activeServer.serverType != ServerType.vikunja) {
      const errorMessage = 'Active server is not a Vikunja server.';
      if (state.error != errorMessage) {
        state = TasksState.initial().copyWith(error: errorMessage, tasks: []);
      }
      isConfiguredNotifier.state = false; // Mark as not configured
      return null;
    }

    // Check if API key is present
    if (vikunjaApiKey.isEmpty) {
      const errorMessage =
          'Vikunja API Key not configured in Settings > Integrations.';
      if (state.error != errorMessage) {
        state = TasksState.initial().copyWith(error: errorMessage, tasks: []);
      }
      isConfiguredNotifier.state = false; // Mark as not configured
      return null;
    }

    // Try to configure the service
    try {
      await vikunjaService.configureService(
        baseUrl: activeServer.serverUrl,
        authStrategy: BearerTokenAuthStrategy(vikunjaApiKey),
      );

      // Verify configuration status after attempting configuration
      if (vikunjaService.isConfigured) {
        if (state.error != null) {
          state = state.copyWith(clearError: true); // Clear previous errors
        }
        isConfiguredNotifier.state = true; // Mark as configured
        return vikunjaService; // Return the configured service instance
      } else {
        // Configuration attempt failed (e.g., invalid URL format)
        const errorMessage =
            'Failed to configure Vikunja service. Check URL/Key.';
        if (state.error != errorMessage) {
          state = TasksState.initial().copyWith(error: errorMessage, tasks: []);
        }
        isConfiguredNotifier.state = false;
        return null;
      }
    } catch (e) {
      final errorMessage = 'Error configuring Vikunja service: $e';
      if (state.error != errorMessage) {
        state = TasksState.initial().copyWith(error: errorMessage, tasks: []);
      }
      isConfiguredNotifier.state = false;
      return null;
    }
  }

  /// Clears tasks and resets state to initial.
  void clearTasks() {
    state = TasksState.initial();
    // Also mark as unconfigured when clearing tasks explicitly
    _ref.read(isVikunjaConfiguredProvider.notifier).state = false;
  }

  Future<void> fetchTasks({String? filter}) async {
    final apiService =
        await _getAndConfigureVikunjaApiService(); // Use the configuring helper
    if (apiService == null) return; // Error handled in helper

    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Pass the active server override, although configureService already set it
      final tasks = await apiService.listTasks(
        filter: filter,
        targetServerOverride: _ref.read(activeServerConfigProvider),
      );
      if (!mounted) return;

      // Sort tasks (e.g., by priority descending, then maybe creation date)
      // Adjust sorting based on Vikunja priority meaning if kept
      tasks.sort((a, b) {
        // Handle null priority
        final priorityA =
            a.priority ?? 0; // Vikunja: 0=None, 1=Lowest..5=Highest
        final priorityB = b.priority ?? 0;
        // Higher priority value comes first
        final priorityComparison = priorityB.compareTo(priorityA);
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
      // Mark as unconfigured on fetch error? Maybe too aggressive.
      // _ref.read(isVikunjaConfiguredProvider.notifier).state = false;
    }
  }

  /// Fetches a single task by its ID.
  Future<TaskItem?> fetchTaskById(String taskId) async {
    final apiService = await _getAndConfigureVikunjaApiService();
    if (apiService == null) return null;

    try {
      final task = await apiService.getTask(
        taskId,
        targetServerOverride: _ref.read(activeServerConfigProvider),
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
    final apiService = await _getAndConfigureVikunjaApiService();
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
              if (task.id == id) {
                // Use String id getter for comparison
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
      await apiService.completeTask(
        id,
        targetServerOverride: _ref.read(activeServerConfigProvider),
      ); // Service handles ID parsing
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
    final apiService = await _getAndConfigureVikunjaApiService();
    if (apiService == null) return false;

    // Optimistic update using 'done' field
    final originalTasks = List<TaskItem>.from(state.tasks);
    TaskItem? originalTask;
    bool taskFound = false;
    if (mounted) {
      state = state.copyWith(
        tasks:
            state.tasks.map((task) {
              if (task.id == id) {
                // Use String id getter for comparison
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
      await apiService.reopenTask(
        id,
        targetServerOverride: _ref.read(activeServerConfigProvider),
      ); // Service handles ID parsing
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
    final apiService = await _getAndConfigureVikunjaApiService();
    if (apiService == null) return false;

    // Optimistic update
    final originalTasks = List<TaskItem>.from(state.tasks);
    bool taskFound = false;
    if (mounted) {
      final initialLength = state.tasks.length;
      final newTasks =
          state.tasks
              .where((task) => task.id != id)
              .toList(); // Use String id getter
      if (newTasks.length < initialLength) {
        taskFound = true;
        state = state.copyWith(tasks: newTasks);
      } else {
        print("Warning: Task $id not found in local state for deletion.");
      }
    }

    try {
      await apiService.deleteTask(
        id,
        targetServerOverride: _ref.read(activeServerConfigProvider),
      ); // Service handles ID parsing
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
    final apiService = await _getAndConfigureVikunjaApiService();
    if (apiService == null) return null;

    try {
      // Pass projectId if provided, and active server override
      final createdTask = await apiService.createTask(
        task,
        projectId: projectId,
        targetServerOverride: _ref.read(activeServerConfigProvider),
      );
      if (mounted) {
        final newTasks = [...state.tasks, createdTask];
        // Re-sort based on updated logic
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
    final apiService = await _getAndConfigureVikunjaApiService();
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
                // Use String id getter
                originalTask = task;
                found = true;
                // Merge updates using copyWith - ensure all relevant fields are copied
                // Note: copyWith uses int id internally, but we match by String id
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
        targetServerOverride: _ref.read(activeServerConfigProvider),
      ); // Service handles ID parsing
      if (mounted) {
        final updatedTasks =
            state.tasks.map((task) {
              if (task.id == id) {
                // Use String id getter
                return updatedTask; // Replace with the task returned by the API
              }
              return task;
            }).toList();

        // Re-sort
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
