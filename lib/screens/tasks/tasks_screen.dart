import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart'; // Add import for hooks
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/models/task_item.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/providers/task_providers.dart';
import 'package:flutter_memos/providers/workbench_provider.dart';
import 'package:flutter_memos/screens/tasks/new_task_screen.dart'; // Import New Task Screen
import 'package:flutter_memos/screens/tasks/widgets/task_list_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart'; // Import Uuid

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  @override
  void initState() {
    super.initState();
    // Initial fetch can still be triggered here if needed,
    // but the effect in build might be sufficient and safer.
    // We'll rely on the effect in build for the initial fetch.
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _triggerFetchTasks(); // Keep this if you want an immediate fetch attempt on first load
    // });
  }

  // Helper to safely trigger fetchTasks (can be kept for refresh logic)
  void _triggerFetchTasks() {
    // Check mounted state and server type before fetching
    if (mounted && ref.read(activeServerConfigProvider)?.serverType == ServerType.todoist) {
      ref.read(tasksNotifierProvider.notifier).fetchTasks();
    }
  }

  // Define the refresh handler
  Future<void> _handleRefresh() async {
    // Check if Todoist is active before attempting refresh
    if (ref.read(activeServerConfigProvider)?.serverType ==
        ServerType.todoist) {
      // Trigger the fetchTasks method from the notifier
      // The Future returned by fetchTasks will be awaited by the RefreshIndicator
      await ref.read(tasksNotifierProvider.notifier).fetchTasks();
    }
    // If not Todoist, the refresh indicator will simply stop without fetching.
  }

  // Helper to show simple alert dialogs
  void _showAlertDialog(String title, String message) {
    if (!mounted) return;
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

  void _addTaskToWorkbench(TaskItem task) {
    final serverConfig = ref.read(activeServerConfigProvider);
    if (serverConfig == null || serverConfig.serverType != ServerType.todoist) {
      _showAlertDialog(
        'Error',
        'Cannot add task: Active server is not Todoist.',
      );
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
    _showAlertDialog('Success', 'Task "${task.content}" added to Workbench.');
  }

  @override
  Widget build(BuildContext context) {
    // Watch necessary providers
    final activeServer = ref.watch(activeServerConfigProvider);
    final tasksState = ref.watch(tasksNotifierProvider);
    final tasks = ref.watch(filteredTasksProvider); // Watch the filtered list
    final bool isTodoistActive = activeServer?.serverType == ServerType.todoist;

    // Use useEffect to handle side effects like fetching data based on state changes
    useEffect(
      () {
        // Check if the widget is still mounted before proceeding
        if (!mounted) return null;

        if (isTodoistActive) {
          // Fetch only if Todoist is active, tasks are empty, not loading, and no error
          // This prevents fetching on every rebuild.
          if (tasksState.tasks.isEmpty &&
              !tasksState.isLoading &&
              tasksState.error == null) {
            Future.microtask(
              () => ref.read(tasksNotifierProvider.notifier).fetchTasks(),
            );
          }
        } else {
          // If not Todoist active and tasks are currently loaded, clear them
          if (tasksState.tasks.isNotEmpty) {
            Future.microtask(
              () =>
                  ref
                      .read(tasksNotifierProvider.notifier)
                      .clearTasksForNonTodoist(),
            );
          }
        }
        // Return null as there's no cleanup function needed for this effect.
        // Dependencies: run this effect when isTodoistActive changes, or when loading/error state resets.
        return null;
      },
      [
        isTodoistActive,
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
          // Disable refresh if not Todoist or already loading
          onPressed:
              tasksState.isLoading || !isTodoistActive ? null : _handleRefresh,
          child: const Icon(CupertinoIcons.refresh),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          // Disable add button if not Todoist active
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
                child: Padding(
                  // Add padding for better spacing
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Select a Todoist server in Settings to view tasks.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: CupertinoColors.secondaryLabel),
                  ),
                ),
              );
            }

            // Show loading indicator ONLY if loading AND tasks list is empty
            if (tasksState.isLoading && tasks.isEmpty) {
              return const Center(child: CupertinoActivityIndicator());
            }

            // Show error message ONLY if error exists AND tasks list is empty
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

            // Show "No tasks" message ONLY if not loading, no error, and tasks list is empty
            if (tasks.isEmpty &&
                !tasksState.isLoading &&
                tasksState.error == null) {
              return Center(
                child: Padding(
                  // Add padding
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

            // Display the list (or potentially loading indicator on top if refreshing)
            // Use CustomScrollView for pull-to-refresh
            return CustomScrollView(
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh: _handleRefresh, // Now defined
                ),
                // Show list even if loading is true (for pull-to-refresh indicator)
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
                          // Consider refreshing list after reopen if sort order might change
                          // _handleRefresh(); // Or just rely on optimistic update
                        }

                        if (!success && mounted) {
                            _showAlertDialog('Error', 'Failed to update task status.');
                            // Optionally trigger a refresh to ensure state consistency
                          _handleRefresh(); // Now defined
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
                            _showAlertDialog('Error', 'Failed to delete task.');
                                // Refresh on error to potentially correct state
                            _handleRefresh(); // Now defined
                              } else if (success && mounted) {
                            // Optional: Show confirmation, but might be annoying
                            // _showAlertDialog(
                            //   'Deleted',
                            //   'Task "${task.content}" deleted.',
                            // );
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
