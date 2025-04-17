import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_memos/models/server_config.dart'; // Still needed for ServerType enum in WorkbenchItemReference
import 'package:flutter_memos/models/task_item.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart';
// Removed server_config_provider import (MultiServerConfigNotifier)
import 'package:flutter_memos/providers/settings_provider.dart'; // Import for todoistApiKeyProvider
import 'package:flutter_memos/providers/task_providers.dart';
import 'package:flutter_memos/providers/workbench_provider.dart';
import 'package:flutter_memos/screens/settings_screen.dart'; // Import SettingsScreen
import 'package:flutter_memos/screens/tasks/new_task_screen.dart';
import 'package:flutter_memos/screens/tasks/widgets/task_list_item.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart'; // Import hooks_riverpod
import 'package:uuid/uuid.dart';

// Constants for Todoist Workbench items (since there's no ServerConfig anymore)
const String _todoistWorkbenchServerId = 'global-todoist-integration';
const String _todoistWorkbenchServerName = 'Todoist';

// Change from ConsumerStatefulWidget to HookConsumerWidget
class TasksScreen extends HookConsumerWidget {
  const TasksScreen({super.key});

  // Helper to show simple alert dialogs (needs context)
  void _showAlertDialog(BuildContext context, String title, String message) {
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

  // Add task to workbench - no longer needs ServerConfig parameter
  void _addTaskToWorkbench(BuildContext context, WidgetRef ref, TaskItem task) {
    // Check if the Todoist API key is configured
    final apiKey = ref.read(todoistApiKeyProvider);
    if (apiKey.isEmpty) {
      _showAlertDialog(
        context, // Pass context
        'Error',
        'Cannot add task: Todoist API Key not configured in Settings > Integrations.', // Update message
      );
      return;
    }

    final reference = WorkbenchItemReference(
      id: const Uuid().v4(),
      referencedItemId: task.id,
      referencedItemType: WorkbenchItemType.task,
      serverId: _todoistWorkbenchServerId, // Use constant ID
      serverType: ServerType.todoist, // Use Todoist type from enum
      serverName: _todoistWorkbenchServerName, // Use constant Name
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
      // Check if Todoist API key is configured
      final isTodoistConfigured = ref.read(todoistApiKeyProvider).isNotEmpty;
      if (isTodoistConfigured) {
        await ref.read(tasksNotifierProvider.notifier).fetchTasks();
      }
    }

    // Watch necessary providers
    // Watch the API key provider to determine if Todoist is configured
    final todoistApiKey = ref.watch(todoistApiKeyProvider);
    final bool isTodoistConfigured = todoistApiKey.isNotEmpty;

    final tasksState = ref.watch(tasksNotifierProvider);
    final tasks = ref.watch(filteredTasksProvider); // Watch the filtered list

    // Use useEffect to fetch tasks when Todoist becomes configured or on initial load
    useEffect(
      () {
        if (isTodoistConfigured) {
          // Fetch if configured, tasks are empty, not loading, and no error
          if (tasksState.tasks.isEmpty &&
              !tasksState.isLoading &&
              tasksState.error == null) {
            Future.microtask(
              () => ref.read(tasksNotifierProvider.notifier).fetchTasks(),
            );
          }
        } else {
          // If Todoist is *not* configured (API key removed/empty)
          // If tasks are currently loaded, clear them
          if (tasksState.tasks.isNotEmpty) {
            Future.microtask(
              () => ref.read(tasksNotifierProvider.notifier).clearTasks(),
            );
          }
        }
        return null; // No cleanup needed
      },
      // Depend on configuration status, API key, loading state, error state, and task list emptiness
      [
        isTodoistConfigured,
        todoistApiKey, // Add dependency on the key itself
        tasksState.isLoading,
        tasksState.error,
        tasksState.tasks.isEmpty,
      ],
    );

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Tasks'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          // Enable refresh only if configured and not loading
          onPressed:
              tasksState.isLoading || !isTodoistConfigured
                  ? null
                  : handleRefresh,
          child: const Icon(CupertinoIcons.refresh),
        ),
        trailing: Row(
          // Wrap existing and new button in a Row
          mainAxisSize: MainAxisSize.min,
          children: [
            // Existing Add Button
            CupertinoButton(
              padding: EdgeInsets.zero,
              // Enable add only if configured
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
            const SizedBox(width: 8), // Add spacing
            // New Settings Button
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.settings, size: 22), // Gear icon
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder:
                        (context) =>
                            const SettingsScreen(isInitialSetup: false),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Builder(
          builder: (context) {
            // Show placeholder if Todoist API key is not configured
            if (!isTodoistConfigured) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Please enter your Todoist API Key in Settings > Integrations to view tasks.', // Updated message
                    textAlign: TextAlign.center,
                    style: TextStyle(color: CupertinoColors.secondaryLabel),
                  ),
                ),
              );
            }

            // Loading indicator
            if (tasksState.isLoading && tasks.isEmpty) {
              return const Center(child: CupertinoActivityIndicator());
            }

            // Error display
            if (tasksState.error != null && tasks.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error loading tasks: ${tasksState.error}\nPlease check your connection and API key in Settings > Integrations.', // Updated guidance
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: CupertinoColors.systemRed),
                  ),
                ),
              );
            }

            // Empty state (configured but no tasks)
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

            // Task list
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

                        if (!success && context.mounted) {
                          _showAlertDialog(
                            context,
                            'Error',
                            'Failed to update task status.',
                          );
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
                        // Pass context, ref, task - no server config needed
                        _addTaskToWorkbench(context, ref, task);
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
