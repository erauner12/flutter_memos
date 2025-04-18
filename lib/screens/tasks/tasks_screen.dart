import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Keep for Material in OverlayEntry
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_memos/main.dart'; // Import for rootNavigatorKeyProvider
import 'package:flutter_memos/models/server_config.dart'; // Still needed for ServerType enum in WorkbenchItemReference
import 'package:flutter_memos/models/task_filter.dart'; // Import the filter enum
import 'package:flutter_memos/models/task_item.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart';
import 'package:flutter_memos/models/workbench_item_type.dart'; // Import the unified enum
import 'package:flutter_memos/providers/settings_provider.dart'; // Import for todoistApiKeyProvider
import 'package:flutter_memos/providers/task_providers.dart';
import 'package:flutter_memos/providers/workbench_provider.dart';
import 'package:flutter_memos/screens/settings_screen.dart'; // Import SettingsScreen
import 'package:flutter_memos/screens/tasks/new_task_screen.dart';
import 'package:flutter_memos/screens/tasks/widgets/task_list_item.dart';
import 'package:flutter_memos/utils/thread_utils.dart'; // Import thread utils
import 'package:flutter_memos/utils/workbench_utils.dart'; // Import instance picker utility
import 'package:hooks_riverpod/hooks_riverpod.dart'; // Import hooks_riverpod
import 'package:uuid/uuid.dart';

// Constants for Todoist Workbench items (since there's no ServerConfig anymore)
const String _todoistWorkbenchServerId = 'global-todoist-integration';
const String _todoistWorkbenchServerName = 'Todoist';

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

  // Add task to workbench - updated to use picker
  Future<void> _addTaskToWorkbench(
    BuildContext context,
    WidgetRef ref,
    TaskItem task,
  ) async {
    final apiKey = ref.read(todoistApiKeyProvider);
    if (apiKey.isEmpty) {
      _showAlertDialog(
        context,
        'Error',
        'Cannot add task: Todoist API Key not configured in Settings > Integrations.',
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

    final reference = WorkbenchItemReference(
      id: const Uuid().v4(),
      referencedItemId: task.id,
      referencedItemType: WorkbenchItemType.task,
      serverId: _todoistWorkbenchServerId,
      serverType: ServerType.todoist,
      serverName: _todoistWorkbenchServerName,
      previewContent: task.content,
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

  // NEW: Method to handle "Chat about Task" action
  Future<void> _chatWithTask(
    BuildContext context,
    WidgetRef ref,
    String taskId,
  ) async {
    String? fetchedContent;
    Object? error;
    const serverId = _todoistWorkbenchServerId;
    try {
      fetchedContent = await getFormattedThreadContent(
        ref,
        taskId,
        WorkbenchItemType.task,
        serverId,
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
    final rootNavigatorKey = ref.read(rootNavigatorKeyProvider);
    final chatArgs = {
      'contextString': fetchedContent,
      'parentItemId': taskId,
      'parentItemType': WorkbenchItemType.task,
      'parentServerId': serverId,
    };
    rootNavigatorKey.currentState?.pushNamed('/chat', arguments: chatArgs);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> handleRefresh() async {
      final isTodoistConfigured = ref.read(todoistApiKeyProvider).isNotEmpty;
      if (isTodoistConfigured) {
        await ref.read(tasksNotifierProvider.notifier).fetchTasks();
      }
    }

    final todoistApiKey = ref.watch(todoistApiKeyProvider);
    final bool isTodoistConfigured = todoistApiKey.isNotEmpty;
    final tasksState = ref.watch(tasksNotifierProvider);
    final tasks = ref.watch(filteredTasksProviderFamily(filter));

    useEffect(
      () {
        if (isTodoistConfigured) {
          if (tasksState.tasks.isEmpty &&
              !tasksState.isLoading &&
              tasksState.error == null) {
            Future.microtask(
              () => ref.read(tasksNotifierProvider.notifier).fetchTasks(),
            );
          }
        } else {
          if (tasksState.tasks.isNotEmpty) {
            Future.microtask(
              () => ref.read(tasksNotifierProvider.notifier).clearTasks(),
            );
          }
        }
        return null;
      },
      [
        isTodoistConfigured,
        todoistApiKey,
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
        previousPageTitle: 'More',
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed:
              tasksState.isLoading || !isTodoistConfigured
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
                  !isTodoistConfigured
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
            if (!isTodoistConfigured) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Please enter your Todoist API Key in Settings > Integrations to view tasks.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: CupertinoColors.secondaryLabel),
                  ),
                ),
              );
            }
            if (tasksState.isLoading && tasks.isEmpty) {
              return const Center(child: CupertinoActivityIndicator());
            }
            if (tasksState.error != null && tasks.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error loading tasks: ${tasksState.error}\nPlease check your connection and API key in Settings > Integrations.',
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
                    emptyStateMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: CupertinoColors.secondaryLabel.resolveFrom(ctx),
                    ),
                  ),
                ),
              );
            }
            return CustomScrollView(
              slivers: [
                CupertinoSliverRefreshControl(onRefresh: handleRefresh),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (itemCtx, index) {
                      final task = tasks[index];
                      return TaskListItem(
                      key: ValueKey(task.id),
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
                                  'Are you sure you want to delete "${task.content}"? This cannot be undone.',
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
