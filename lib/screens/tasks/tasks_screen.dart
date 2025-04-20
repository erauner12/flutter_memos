import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'package:flutter/material.dart'; // Keep for Material in OverlayEntry
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_memos/main.dart'; // Import for rootNavigatorKeyProvider
import 'package:flutter_memos/models/server_config.dart'; // Needed for ServerType enum
import 'package:flutter_memos/models/task_filter.dart'; // Import the filter enum
import 'package:flutter_memos/models/task_item.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart';
import 'package:flutter_memos/models/workbench_item_type.dart'; // Import the unified enum
// Removed settings_provider import (vikunjaApiKeyProvider is checked via isVikunjaConfiguredProvider)
import 'package:flutter_memos/providers/task_providers.dart';
// Import new task server config provider
import 'package:flutter_memos/providers/task_server_config_provider.dart';
import 'package:flutter_memos/providers/workbench_provider.dart';
import 'package:flutter_memos/screens/settings_screen.dart'; // Import SettingsScreen
import 'package:flutter_memos/screens/tasks/new_task_screen.dart';
import 'package:flutter_memos/screens/tasks/widgets/task_list_item.dart';
import 'package:flutter_memos/services/vikunja_api_service.dart'; // Import for isVikunjaConfiguredProvider
import 'package:flutter_memos/utils/thread_utils.dart'; // Import thread utils
import 'package:flutter_memos/utils/workbench_utils.dart'; // Import instance picker utility
import 'package:hooks_riverpod/hooks_riverpod.dart'; // Import hooks_riverpod
import 'package:uuid/uuid.dart';

// Removed Todoist constants

// Change from ConsumerStatefulWidget to HookConsumerWidget
class TasksScreen extends HookConsumerWidget {
  final TaskFilter filter; // Add filter parameter

  const TasksScreen({
    super.key,
    this.filter = TaskFilter.all, // Default to all tasks
  });

  // Track current undo toast entry
  static OverlayEntry? _currentUndoToast;

  // Helper to show simple alert dialogs (needs context)
  void _showAlertDialog(BuildContext context, String title, String message) {
    if (!context.mounted) return;
    showCupertinoDialog(
      context: context,
      builder:
          (ctx) => CupertinoAlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('OK'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
    );
  }

  // Add task to workbench - updated to use active Vikunja server
  Future<void> _addTaskToWorkbench(
    BuildContext context,
    WidgetRef ref,
    TaskItem task,
  ) async {
    // Check if Vikunja is configured
    final isConfigured = ref.read(isVikunjaConfiguredProvider);
    // Use the new taskServerConfigProvider
    final taskServer = ref.read(taskServerConfigProvider);

    if (!isConfigured ||
        taskServer == null ||
        taskServer.serverType != ServerType.vikunja) {
      _showAlertDialog(
        context,
        'Error',
        'Cannot add task: Vikunja is not configured or the task server is not Vikunja. Check Settings.',
      );
      return;
    }

    final selectedInstance = await showWorkbenchInstancePicker(
      context,
      ref,
      title: 'Add Task To Workbench',
    );
    if (selectedInstance == null) {
      return;
    }

    final targetInstanceId = selectedInstance.id;
    final targetInstanceName = selectedInstance.name;

    // Use active Vikunja server details
    final reference = WorkbenchItemReference(
      id: const Uuid().v4(),
      referencedItemId: task.id, // Vikunja task ID (String)
      referencedItemType: WorkbenchItemType.task,
      serverId: taskServer.id, // Vikunja server ID from config
      serverType: ServerType.vikunja, // Explicitly Vikunja
      serverName:
          taskServer.name ?? taskServer.serverUrl, // Vikunja server name
      previewContent: task.title, // Use Vikunja title
      addedTimestamp: DateTime.now(),
      instanceId: targetInstanceId,
    );

    unawaited(
      ref
          .read(workbenchProviderFamily(targetInstanceId).notifier)
          .addItem(reference),
    );

    final previewText = reference.previewContent;
    final safePreview =
        previewText == null
            ? 'Task'
            : '${previewText.substring(0, min(30, previewText.length))}${previewText.length > 30 ? '...' : ''}';
    final dialogContent =
        'Added "$safePreview" to Workbench "$targetInstanceName"';

    _showAlertDialog(
      context,
      'Success',
      dialogContent,
    );
  }

  // Show an "Undo" toast when completing or reopening a task
  void _showUndoToast(
    BuildContext context,
    WidgetRef ref,
    TaskItem task,
    bool newCompletedState,
  ) {
    _currentUndoToast?.remove();
    if (!context.mounted) return;

    final overlayState = Overlay.of(context);
    final toast = OverlayEntry(
      builder:
          (ctx) => Positioned(
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
                                  ? CupertinoColors.systemGreen.resolveFrom(ctx)
                                  : CupertinoColors.systemBlue.resolveFrom(ctx),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 180,
                          child: Text(
                            task.title, // Use Vikunja title
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
                            _currentUndoToast?.remove();
                            _currentUndoToast = null;
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

    _currentUndoToast = toast;
    overlayState.insert(toast);

    Timer(const Duration(seconds: 5), () {
      if (_currentUndoToast == toast) {
        toast.remove();
        _currentUndoToast = null;
      }
    });
  }

  // NEW: Method to handle "Chat about Task" action - updated for Vikunja
  Future<void> _chatWithTask(
    BuildContext context,
    WidgetRef ref,
    String taskId,
  ) async {
    // Use the new taskServerConfigProvider
    final taskServer = ref.read(taskServerConfigProvider);
    if (taskServer == null || taskServer.serverType != ServerType.vikunja) {
      _showAlertDialog(
        context,
        'Error',
        'Task server must be Vikunja to chat about tasks.',
      );
      return;
    }
    final serverId = taskServer.id; // Use Vikunja server ID

    String? fetchedContent;
    Object? error;
    try {
      fetchedContent = await getFormattedThreadContent(
        ref,
        taskId,
        WorkbenchItemType.task,
        serverId, // Pass Vikunja server ID
      );
    } catch (e) {
      error = e;
      debugPrint("Error fetching task thread: $e");
    }
    if (!context.mounted) return;
    if (error != null || fetchedContent == null) {
      _showAlertDialog(
        context,
        'Error',
        'Unable to fetch Task thread: ${error ?? 'Unknown error'}',
      );
      return;
    }
    final rootNavigatorKey = ref.read(
      rootNavigatorKeyProvider,
    ); // Use imported provider
    final chatArgs = {
      'contextString': fetchedContent,
      'parentItemId': taskId,
      'parentItemType': WorkbenchItemType.task,
      'parentServerId': serverId, // Pass Vikunja server ID
    };
    rootNavigatorKey.currentState?.pushNamed('/chat', arguments: chatArgs);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch Vikunja configuration status
    final isVikunjaConfigured = ref.watch(isVikunjaConfiguredProvider);

    Future<void> handleRefresh() async {
      if (isVikunjaConfigured) {
        // Fetch tasks using the notifier (which handles configuration internally)
        await ref.read(tasksNotifierProvider.notifier).fetchTasks();
      } else {
        // Optionally show a message or do nothing if not configured
        if (kDebugMode) {
          print("[TasksScreen] Refresh skipped: Vikunja not configured.");
        }
      }
    }

    final tasksState = ref.watch(tasksNotifierProvider);
    // Watch the filtered tasks based on the current filter
    final tasks = ref.watch(filteredTasksProviderFamily(filter));

    // Effect to fetch tasks when the screen loads or configuration changes
    useEffect(
      () {
        // Use a post frame callback to ensure providers are ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (isVikunjaConfigured) {
            // Fetch only if configured, tasks are empty, not loading, and no error
            if (tasksState.tasks.isEmpty &&
                !tasksState.isLoading &&
                tasksState.error == null) {
              // Use Future.microtask to avoid triggering build during build
              Future.microtask(
                () => ref.read(tasksNotifierProvider.notifier).fetchTasks(),
              );
            }
          } else {
            // If not configured, ensure tasks are cleared
            if (tasksState.tasks.isNotEmpty ||
                tasksState.error != null ||
                tasksState.isLoading) {
              Future.microtask(
                () => ref.read(tasksNotifierProvider.notifier).clearTasks(),
              );
            }
          }
        });
        // Return null for cleanup function
        return null;
      },
      // Dependencies: configuration status, loading state, error state, task list emptiness
      [
        isVikunjaConfigured,
        tasksState.isLoading,
        tasksState.error,
        tasksState.tasks.isEmpty,
      ],
    );

    final screenTitle = filter.title;
    final emptyStateMessage = filter.emptyStateMessage;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(screenTitle),
        // previousPageTitle: 'More', // Removed 'More' screen concept
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed:
              tasksState.isLoading || !isVikunjaConfigured
                  ? null
                  : handleRefresh,
          child: const Icon(CupertinoIcons.refresh),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed:
                  !isVikunjaConfigured
                  ? null
                  : () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (ctx) => const NewTaskScreen(),
                          ),
                        );
                      },
              child: const Icon(CupertinoIcons.add),
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.settings, size: 22),
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder:
                        (ctx) => const SettingsScreen(isInitialSetup: false),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Builder(
          builder: (ctx) {
            // 1. Check if Vikunja is configured
            if (!isVikunjaConfigured) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Vikunja integration not configured.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Please ensure a Vikunja server is added and set as the Task Server, and enter your Vikunja API Key in:', // Updated text
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            ctx,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      CupertinoButton(
                        child: const Text('Settings > Integrations'),
                        onPressed: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder:
                                  (ctx) => const SettingsScreen(
                                    isInitialSetup: false,
                                  ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }

            // 2. Handle loading state
            if (tasksState.isLoading && tasks.isEmpty) {
              return const Center(child: CupertinoActivityIndicator());
            }

            // 3. Handle error state
            if (tasksState.error != null && tasks.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.exclamationmark_triangle,
                        size: 40,
                        color: CupertinoColors.systemRed,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Error loading tasks: ${tasksState.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: CupertinoColors.systemRed,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Please check your connection, Vikunja server status, and API key in Settings.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            ctx,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      CupertinoButton(
                        onPressed: handleRefresh,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // 4. Handle empty state (configured, no error, no tasks)
            if (tasks.isEmpty &&
                !tasksState.isLoading &&
                tasksState.error == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    emptyStateMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: CupertinoColors.secondaryLabel.resolveFrom(ctx),
                    ),
                  ),
                ),
              );
            }

            // 5. Display task list
            return CustomScrollView(
              slivers: [
                CupertinoSliverRefreshControl(onRefresh: handleRefresh),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (itemCtx, index) {
                      final task = tasks[index];
                      return TaskListItem(
                      key: ValueKey(task.id), // Use Vikunja task ID
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
                          _showUndoToast(itemCtx, ref, task, isCompleted);
                        } else if (itemCtx.mounted) {
                          _showAlertDialog(
                            itemCtx,
                            'Error',
                            'Failed to update task status.',
                          );
                          await handleRefresh();
                          }
                      },
                        onDelete: () async {
                        final confirmed = await showCupertinoDialog<bool>(
                          context: itemCtx,
                          builder:
                              (dialogCtx) => CupertinoAlertDialog(
                                title: const Text('Delete Task?'),
                                content: Text(
                                  'Are you sure you want to delete "${task.title}"? This cannot be undone.', // Use title
                                ),
                                actions: [
                                  CupertinoDialogAction(
                                    child: const Text('Cancel'),
                                    onPressed:
                                        () => Navigator.pop(dialogCtx, false),
                                  ),
                                  CupertinoDialogAction(
                                    isDestructiveAction: true,
                                    child: const Text('Delete'),
                                    onPressed:
                                        () => Navigator.pop(dialogCtx, true),
                                  ),
                                ],
                              ),
                        );
                        if (confirmed == true) {
                          final success = await ref
                              .read(tasksNotifierProvider.notifier)
                              .deleteTask(task.id);
                          if (!success && itemCtx.mounted) {
                            _showAlertDialog(
                              itemCtx,
                              'Error',
                              'Failed to delete task.',
                            );
                            await handleRefresh();
                          }
                        }
                        },
                        onAddToWorkbench: () {
                        _addTaskToWorkbench(itemCtx, ref, task);
                      },
                      onChatWithTask: () {
                        _chatWithTask(itemCtx, ref, task.id);
                      },
                      onTap: () {
                        Navigator.of(itemCtx).push(
                          CupertinoPageRoute(
                            builder: (ctx2) => NewTaskScreen(taskToEdit: task),
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
