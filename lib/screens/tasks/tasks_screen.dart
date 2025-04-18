import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_memos/main.dart'; // Import for rootNavigatorKeyProvider
import 'package:flutter_memos/models/server_config.dart'; // Still needed for ServerType enum in WorkbenchItemReference
import 'package:flutter_memos/models/task_item.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart';
// Removed server_config_provider import (MultiServerConfigNotifier)
import 'package:flutter_memos/providers/settings_provider.dart'; // Import for todoistApiKeyProvider
import 'package:flutter_memos/providers/task_providers.dart';
import 'package:flutter_memos/providers/workbench_instances_provider.dart'; // &lt;-- ADD THIS
import 'package:flutter_memos/providers/workbench_provider.dart';
import 'package:flutter_memos/screens/settings_screen.dart'; // Import SettingsScreen
import 'package:flutter_memos/screens/tasks/new_task_screen.dart';
import 'package:flutter_memos/screens/tasks/widgets/task_list_item.dart';
import 'package:flutter_memos/utils/thread_utils.dart'; // Import thread utils
import 'package:hooks_riverpod/hooks_riverpod.dart'; // Import hooks_riverpod
import 'package:uuid/uuid.dart';

// Constants for Todoist Workbench items (since there's no ServerConfig anymore)
const String _todoistWorkbenchServerId = 'global-todoist-integration';
const String _todoistWorkbenchServerName = 'Todoist';

// Change from ConsumerStatefulWidget to HookConsumerWidget
class TasksScreen extends HookConsumerWidget {
  const TasksScreen({super.key});

  // Track current undo toast entry
  static OverlayEntry? _currentUndoToast;

  // Helper to show simple alert dialogs (needs context)
  void _showAlertDialog(BuildContext context, String title, String message) {
    // Ensure dialog is shown safely if context is still valid
    if (!context.mounted) return;
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

    // Fetch the active instance ID
    final instanceId = ref.read(
      workbenchInstancesProvider.select((s) => s.activeInstanceId),
    );

    final reference = WorkbenchItemReference(
      id: const Uuid().v4(),
      referencedItemId: task.id,
      referencedItemType: WorkbenchItemType.task,
      serverId: _todoistWorkbenchServerId, // Use constant ID
      serverType: ServerType.todoist, // Use Todoist type from enum
      serverName: _todoistWorkbenchServerName, // Use constant Name
      previewContent: task.content,
      addedTimestamp: DateTime.now(),
      instanceId: instanceId, // &lt;-- PASS instanceId
    );

    // FIX: Use activeWorkbenchNotifierProvider
    unawaited(ref.read(activeWorkbenchNotifierProvider).addItem(reference));
    _showAlertDialog(
      context, // Pass context
      'Success',
      'Task "${task.content}" added to Workbench.',
    );
  }

  // Show an "Undo" toast when completing or reopening a task
  void _showUndoToast(
    BuildContext context,
    WidgetRef ref,
    TaskItem task,
    bool newCompletedState,
  ) {
    // Remove any existing toast first
    _currentUndoToast?.remove();

    // Ensure context is valid before creating overlay
    if (!context.mounted) return;

    // Create a new overlay entry
    final overlayState = Overlay.of(context);
    final toast = OverlayEntry(
      builder:
          (context) => Positioned(
            left: 16.0,
            bottom: 32.0,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: CupertinoPopupSurface(
                  isSurfacePainted: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          newCompletedState
                              ? CupertinoIcons.check_mark_circled_solid
                              : CupertinoIcons
                                  .arrow_counterclockwise_circle_fill,
                          color:
                              newCompletedState
                                  ? CupertinoColors.systemGreen.resolveFrom(
                                    context,
                                  )
                                  : CupertinoColors.systemBlue.resolveFrom(
                                    context,
                                  ),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 180,
                          child: Text(
                            task.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          minSize: 28,
                          child: const Text(
                            'Undo',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onPressed: () {
                            // Remove the toast first
                            _currentUndoToast?.remove();
                            _currentUndoToast = null;

                            // Call appropriate method based on current state
                            if (newCompletedState) {
                              ref
                                  .read(tasksNotifierProvider.notifier)
                                  .reopenTask(task.id);
                            } else {
                              ref
                                  .read(tasksNotifierProvider.notifier)
                                  .completeTask(task.id);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
    );

    // Show the toast
    _currentUndoToast = toast;
    overlayState.insert(toast);

    // Set timer to remove after 5 seconds
    Timer(const Duration(seconds: 5), () {
      if (_currentUndoToast == toast) {
        toast.remove();
        _currentUndoToast = null;
      }
    });
  }

  // NEW: Method to handle "Chat about Task" action
  Future<void> _chatWithTask(
    BuildContext context,
    WidgetRef ref,
    String taskId,
  ) async {
    // Optional: Show loading indicator (e.g., using a state variable or dialog)
    // For simplicity, we'll just show errors if they occur.

    String? fetchedContent;
    Object? error;
    const serverId = _todoistWorkbenchServerId; // Use the constant ID

    try {
      // Call the utility function to get the formatted thread content
      fetchedContent = await getFormattedThreadContent(
        ref,
        taskId,
        WorkbenchItemType.task, // Specify the type
        serverId,
      );
    } catch (e) {
      error = e;
      debugPrint("Error fetching task thread: $e");
    }

    // Optional: Dismiss loading indicator

    // Check for errors or null content
    if (!context.mounted)
      return; // Check context before showing dialog/navigating
    if (error != null || fetchedContent == null) {
      _showAlertDialog(
        context,
        'Error',
        'Unable to fetch Task thread: ${error ?? 'Unknown error'}',
      );
      return;
    }

    // Navigate to chat screen with context
    final rootNavigatorKey = ref.read(rootNavigatorKeyProvider);
    final chatArgs = {
      'contextString': fetchedContent,
      'parentItemId': taskId,
      'parentItemType': WorkbenchItemType.task, // Pass the correct type
      'parentServerId': serverId,
    };

    // Push the chat route using the root navigator
    rootNavigatorKey.currentState?.pushNamed('/chat', arguments: chatArgs);
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
                    'No tasks found.\nPull down to refresh or add a new task.', // Corrected newline
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
                      key: ValueKey(task.id), // Ensure key is here
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

                        if (success) {
                          // Show undo toast upon successful operation
                          _showUndoToast(context, ref, task, isCompleted);
                        } else if (context.mounted) {
                          _showAlertDialog(
                            context,
                            'Error',
                            'Failed to update task status.',
                          );
                          await handleRefresh();
                          }
                      },
                        onDelete: () async {
                        final confirmed = await showCupertinoDialog<bool>(
                          // await the result
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
                        ); // Added await

                        if (confirmed == true) {
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
                      // NEW: Pass the chat handler
                      onChatWithTask: () {
                        _chatWithTask(context, ref, task.id);
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
