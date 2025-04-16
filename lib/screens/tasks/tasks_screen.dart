import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/models/task_item.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/providers/task_providers.dart';
import 'package:flutter_memos/providers/workbench_provider.dart';
import 'package:flutter_memos/screens/tasks/new_task_screen.dart';
import 'package:flutter_memos/screens/tasks/widgets/task_list_item.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart'; // Import hooks_riverpod
import 'package:uuid/uuid.dart';

// Change from ConsumerStatefulWidget to HookConsumerWidget
class TasksScreen extends HookConsumerWidget {
  const TasksScreen({super.key});

  // Remove createState method

  // Move helper methods inside or make them static/top-level if they don't need context/ref directly
  // Helper to show simple alert dialogs (needs context)
  void _showAlertDialog(BuildContext context, String title, String message) {
    // No need for mounted check here as it's called within build context scope
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  // Add task to workbench (needs ref and context)
  // Modify signature to accept the specific todoistServer config
  void _addTaskToWorkbench(
    BuildContext context,
    WidgetRef ref,
    TaskItem task,
    ServerConfig? todoistServer,
  ) {
    // Check if the passed server config exists
    if (todoistServer == null) {
      _showAlertDialog(
        context, // Pass context
        'Error',
        'Cannot add task: Todoist is not configured in Settings.', // Update message
      );
      return;
    }

    final reference = WorkbenchItemReference(
      id: const Uuid().v4(),
      referencedItemId: task.id,
      referencedItemType: WorkbenchItemType.task,
      serverId:
          todoistServer
              .id, // Use the ID from the specific Todoist server config
      serverType: ServerType.todoist, // It's always Todoist here now
      serverName:
          todoistServer
              .name, // Use the name from the specific Todoist server config
      previewContent: task.content,
      addedTimestamp: DateTime.now(),
    );

    unawaited(ref.read(workbenchProvider.notifier).addItem(reference));
    _showAlertDialog(
      context, // Pass context
      'Success',
      'Task "${task.content}" added to Workbench.',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Define the refresh handler directly within build or as a local function
    Future<void> handleRefresh() async {
      // Check if configured, not active
      final isTodoistConfigured = ref.read(todoistServerConfigProvider) != null;
      if (isTodoistConfigured) {
        await ref.read(tasksNotifierProvider.notifier).fetchTasks();
      }
    }

    // Watch necessary providers
    // Watch the new provider instead of activeServerConfigProvider for Todoist check
    final todoistServer = ref.watch(todoistServerConfigProvider);
    final bool isTodoistConfigured =
        todoistServer != null; // Check if a Todoist config exists
    final tasksState = ref.watch(tasksNotifierProvider);
    final tasks = ref.watch(filteredTasksProvider); // Watch the filtered list

    // Use useEffect here - now it's correctly inside a HookConsumerWidget's build method
    useEffect(
      () {
        // No need for mounted check inside useEffect's setup function

        // Use the new flag
        if (isTodoistConfigured) {
          // Fetch only if Todoist is configured, tasks are empty, not loading, and no error
          if (tasksState.tasks.isEmpty &&
              !tasksState.isLoading &&
              tasksState.error == null) {
            // Use Future.microtask to schedule the fetch after the current build cycle
            Future.microtask(
              () => ref.read(tasksNotifierProvider.notifier).fetchTasks(),
            );
          }
        } else {
          // If Todoist is *not* configured
          // If tasks are currently loaded, clear them using the new method
          if (tasksState.tasks.isNotEmpty) {
            Future.microtask(
              () =>
                  ref
                      .read(tasksNotifierProvider.notifier)
                      .clearTasks(), // Call the new clearTasks method
            );
          }
        }
        // Return null as there's no cleanup function needed for this effect.
        return null;
      },
      // Update dependency array (ensure tasksState.tasks.isNotEmpty is included if needed, or rely on tasksState object)
      [
        isTodoistConfigured,
        tasksState.isLoading,
        tasksState.error,
        tasksState.tasks.isEmpty, // Keep this dependency
        // tasksState.tasks.isNotEmpty, // Alternatively, watch the whole tasksState object
      ],
    );

    // --- Rest of the build method from _TasksScreenState ---
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Tasks'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          // Use the new flag for enabling/disabling
          onPressed:
              tasksState.isLoading || !isTodoistConfigured
                  ? null
                  : handleRefresh,
          child: const Icon(CupertinoIcons.refresh),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          // Use the new flag for enabling/disabling
          onPressed:
              !isTodoistConfigured
                  ? null
                  : () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (context) => const NewTaskScreen(),
                      ),
                    );
                  },
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(
        child: Builder(
          builder: (context) {
            // Use the new flag and update the message
            if (!isTodoistConfigured) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Please configure the Todoist integration in Settings to view tasks.', // New message
                    textAlign: TextAlign.center,
                    style: TextStyle(color: CupertinoColors.secondaryLabel),
                  ),
                ),
              );
            }

            // Rest of the builder logic remains the same...
            if (tasksState.isLoading && tasks.isEmpty) {
              return const Center(child: CupertinoActivityIndicator());
            }

            if (tasksState.error != null && tasks.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error loading tasks: ${tasksState.error}\nPlease check your connection and API key in Settings.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: CupertinoColors.systemRed),
                  ),
                ),
              );
            }

            if (tasks.isEmpty &&
                !tasksState.isLoading &&
                tasksState.error == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No tasks found.\nPull down to refresh or add a new task.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                ),
              );
            }

            return CustomScrollView(
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh: handleRefresh, // Use the local handler
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = tasks[index];
                      return TaskListItem(
                        task: task,
                        onToggleComplete: (isCompleted) async {
                          bool success;
                          if (isCompleted) {
                          success = await ref
                              .read(tasksNotifierProvider.notifier)
                              .completeTask(task.id);
                          } else {
                          success = await ref
                              .read(tasksNotifierProvider.notifier)
                              .reopenTask(task.id);
                        }

                        // Check context.mounted before showing dialog
                        if (!success && context.mounted) {
                          _showAlertDialog(
                            context,
                            'Error',
                            'Failed to update task status.',
                          );
                          // Optionally trigger a refresh
                          await handleRefresh();
                          }
                      },
                        onDelete: () async {
                        final confirmed =
                            await showCupertinoDialog<bool>(
                              context: context,
                              builder:
                                  (dialogContext) => CupertinoAlertDialog(
                                    title: const Text('Delete Task?'),
                                    content: Text(
                                      'Are you sure you want to delete "${task.content}"? This cannot be undone.',
                                    ),
                                    actions: [
                                      CupertinoDialogAction(
                                        child: const Text('Cancel'),
                                        onPressed:
                                            () => Navigator.pop(
                                              dialogContext,
                                              false,
                                            ),
                                      ),
                                      CupertinoDialogAction(
                                        isDestructiveAction: true,
                                        child: const Text('Delete'),
                                        onPressed:
                                            () => Navigator.pop(
                                              dialogContext,
                                              true,
                                            ),
                                      ),
                                    ],
                                  ),
                            ) ??
                            false;

                        if (confirmed) {
                          final success = await ref
                              .read(tasksNotifierProvider.notifier)
                              .deleteTask(task.id);
                          // Check context.mounted before showing dialog
                          if (!success && context.mounted) {
                            _showAlertDialog(
                              context,
                              'Error',
                              'Failed to delete task.',
                            );
                            await handleRefresh();
                          }
                        }
                        },
                        onAddToWorkbench: () {
                        // Pass context, ref, task, and the specific todoistServer config
                        _addTaskToWorkbench(
                          context,
                          ref,
                          task,
                          todoistServer, // Pass the watched todoistServer object
                        );
                        },
                      onTap: () {
                        Navigator.of(context).push(
                            CupertinoPageRoute(
                            builder:
                                (context) => NewTaskScreen(taskToEdit: task),
                            ),
                          );
                        },
                      );
                    },
                    childCount: tasks.length,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
