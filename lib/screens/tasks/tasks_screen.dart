import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/models/task_item.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/providers/task_providers.dart';
import 'package:flutter_memos/providers/workbench_provider.dart';
import 'package:flutter_memos/screens/tasks/new_task_screen.dart'; // Import New Task Screen
import 'package:flutter_memos/screens/tasks/widgets/task_list_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch tasks when the screen is initialized if the active server is Todoist
    // Use addPostFrameCallback to ensure ref is accessible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerFetchTasks();
      // Listen for active server changes to refetch if Todoist becomes active
      ref.listen(activeServerConfigProvider, (previous, next) {
        if (next?.serverType == ServerType.todoist) {
           Future.microtask(() => _triggerFetchTasks()); // Use microtask for safety
        } else {
          // Clear tasks if server switches away from Todoist
           Future.microtask(() => ref.read(tasksNotifierProvider.notifier).clearTasksForNonTodoist());
        }
      });
    });
  }

  // Helper to safely trigger fetchTasks
  void _triggerFetchTasks() {
    // Check mounted state and server type before fetching
    if (mounted && ref.read(activeServerConfigProvider)?.serverType == ServerType.todoist) {
      ref.read(tasksNotifierProvider.notifier).fetchTasks();
    }
  }


  Future<void> _handleRefresh() async {
    // Check if the active server is Todoist before refreshing
    final activeServer = ref.read(activeServerConfigProvider);
    if (activeServer?.serverType == ServerType.todoist) {
      await ref.read(tasksNotifierProvider.notifier).fetchTasks();
    } else {
      // Optionally show a message or just do nothing
      print(
        "Refresh skipped: Active server is not Todoist.",
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final snackBar = CupertinoSnackBar(
      content: Text(
        message,
        style: TextStyle(
          color: isError ? CupertinoColors.destructiveRed : null,
        ),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _addTaskToWorkbench(TaskItem task) {
    final serverConfig = ref.read(activeServerConfigProvider);
    if (serverConfig == null || serverConfig.serverType != ServerType.todoist) {
      _showSnackBar('Cannot add task: Active server is not Todoist.', isError: true);
      return;
    }

    final reference = WorkbenchItemReference(
      id: const Uuid().v4(),
      referencedItemId: task.id,
      referencedItemType: WorkbenchItemType.task,
      serverId: serverConfig.id,
      serverType: serverConfig.serverType,
      serverName: serverConfig.name,
      previewContent: task.content,
      addedTimestamp: DateTime.now(),
      // parentNoteId is not applicable for tasks
    );

    unawaited(ref.read(workbenchProvider.notifier).addItem(reference));
    _showSnackBar('Task "${task.content}" added to Workbench.');
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(tasksNotifierProvider);
    final tasks = ref.watch(filteredTasksProvider); // Watch the filtered list
    final activeServer = ref.watch(activeServerConfigProvider);
    final bool isTodoistActive = activeServer?.serverType == ServerType.todoist;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Tasks'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed:
              tasksState.isLoading || !isTodoistActive ? null : _handleRefresh,
          child: const Icon(CupertinoIcons.refresh),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: !isTodoistActive ? null : () {
            // Navigate to a New Task Screen
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (context) => const NewTaskScreen(),
                // Consider fullscreenDialog: true
              ),
            );
          },
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(
        child: Builder( // Use Builder to get context for ScaffoldMessenger
          builder: (context) {
            if (!isTodoistActive) {
              return const Center(
                child: Text(
                  'Select a Todoist server in Settings to view tasks.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: CupertinoColors.secondaryLabel),
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
                    'Error loading tasks: ${tasksState.error}\nPlease check your connection and API key in Settings.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: CupertinoColors.systemRed),
                  ),
                ),
              );
            }

            if (tasks.isEmpty && !tasksState.isLoading) {
              return Center(
                child: Text(
                  'No tasks found.\nPull down to refresh or add a new task.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              );
            }

            // Use CustomScrollView for pull-to-refresh
            return CustomScrollView(
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh: _handleRefresh,
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
                            success = await ref.read(tasksNotifierProvider.notifier).completeTask(task.id);
                          } else {
                            success = await ref.read(tasksNotifierProvider.notifier).reopenTask(task.id);
                          }
                          if (!success && mounted) {
                            _showSnackBar('Failed to update task status.', isError: true);
                            // Optionally trigger a refresh to ensure state consistency
                            _handleRefresh();
                          }
                        },
                        onDelete: () async {
                           final confirmed = await showCupertinoDialog<bool>(
                              context: context,
                              builder: (dialogContext) => CupertinoAlertDialog(
                                title: const Text('Delete Task?'),
                                content: Text('Are you sure you want to delete "${task.content}"? This cannot be undone.'),
                                actions: [
                                  CupertinoDialogAction(
                                    child: const Text('Cancel'),
                                    onPressed: () => Navigator.pop(dialogContext, false),
                                  ),
                                  CupertinoDialogAction(
                                    isDestructiveAction: true,
                                    child: const Text('Delete'),
                                    onPressed: () => Navigator.pop(dialogContext, true),
                                  ),
                                ],
                              ),
                            ) ?? false; // Default to false if dialog dismissed

                            if (confirmed) {
                              final success = await ref.read(tasksNotifierProvider.notifier).deleteTask(task.id);
                              if (!success && mounted) {
                                _showSnackBar('Failed to delete task.', isError: true);
                                // Refresh on error to potentially correct state
                                _handleRefresh();
                              } else if (success && mounted) {
                                _showSnackBar('Task "${task.content}" deleted.');
                              }
                            }
                        },
                        onAddToWorkbench: () {
                           _addTaskToWorkbench(task);
                        },
                        onTap: () {
                           // Navigate to edit screen (passing task id or task object)
                           Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) => NewTaskScreen(taskToEdit: task), // Pass task for editing
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
          }
        ),
      ),
    );
  }
}
