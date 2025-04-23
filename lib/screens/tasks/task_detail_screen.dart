import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Keep for ScaffoldMessenger, SnackBar
import 'package:flutter/services.dart';
import 'package:flutter_memos/models/task_item.dart';
import 'package:flutter_memos/providers/task_comment_providers.dart'; // Import task comment providers
import 'package:flutter_memos/providers/task_providers.dart'; // Import task providers
import 'package:flutter_memos/providers/task_server_config_provider.dart'; // To check config
import 'package:flutter_memos/screens/tasks/new_task_screen.dart';
import 'package:flutter_memos/screens/tasks/widgets/task_comment_form.dart';
import 'package:flutter_memos/screens/tasks/widgets/task_comments.dart';
import 'package:flutter_memos/screens/tasks/widgets/task_content.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final FocusNode _screenFocusNode = FocusNode(debugLabel: 'TaskDetailScreenFocus');
  // ADD: FocusNode for the comment form
  final FocusNode _commentFocusNode = FocusNode(
    debugLabel: 'TaskCommentFormFocus',
  );
  late ScrollController _scrollController;
  String? _effectiveServerId; // Store the serverId from the provider

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateEffectiveServerId(); // Determine serverId initially
      if (mounted) {
        _screenFocusNode.requestFocus();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateEffectiveServerId(); // Update if dependencies change
  }

  void _updateEffectiveServerId() {
    final newServerId = ref.read(taskServerConfigProvider)?.id;
    if (_effectiveServerId != newServerId) {
      setState(() {
        _effectiveServerId = newServerId;
      });
      // Invalidate providers that depend on serverId when it changes
      if (newServerId != null) {
        ref.invalidate(taskDetailProvider(widget.taskId));
        ref.invalidate(taskCommentsProvider(widget.taskId));
      }
    }
  }

  @override
  void dispose() {
    _screenFocusNode.dispose();
    _scrollController.dispose();
    // ADD: Dispose the comment focus node
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    if (_effectiveServerId == null) return; // Don't refresh if no server
    if (kDebugMode) print('[TaskDetailScreen($_effectiveServerId)] Pull-to-refresh triggered.');
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    // Invalidate task detail and comments providers
    ref.invalidate(taskDetailProvider(widget.taskId));
    ref.invalidate(taskCommentsProvider(widget.taskId));
    // Use await to wait for the refresh to complete if needed, or just trigger invalidation
    // await ref.read(taskDetailProvider(widget.taskId).future); // Example if waiting
  }

  Widget _buildRefreshIndicator(
    BuildContext context,
    RefreshIndicatorMode refreshState,
    double pulledExtent,
    double refreshTriggerPullDistance,
    double refreshIndicatorExtent,
  ) {
    final double opacity = (pulledExtent / refreshTriggerPullDistance).clamp(0.0, 1.0);
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            top: 16.0,
            child: Opacity(
              opacity: (refreshState == RefreshIndicatorMode.drag) ? opacity : 1.0,
              child: (refreshState == RefreshIndicatorMode.refresh || refreshState == RefreshIndicatorMode.armed)
                  ? const CupertinoActivityIndicator(radius: 14.0)
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  void _showActions(TaskItem task) {
    if (!mounted || _effectiveServerId == null) return;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext popupContext) {
        return CupertinoActionSheet(
          title: const Text('Task Actions'),
          actions: <CupertinoActionSheetAction>[
            CupertinoActionSheetAction(
              child: const Text('Edit Task'),
              onPressed: () {
                Navigator.pop(popupContext);
                // MODIFY: Use push with CupertinoPageRoute instead of pushNamed
                Navigator.of(context)
                    .push(
                      CupertinoPageRoute(
                        builder: (ctx) => NewTaskScreen(taskToEdit: task),
                      ),
                ).then((_) {
                   // Refresh data after editing
                   ref.invalidate(taskDetailProvider(widget.taskId));
                   ref.invalidate(taskCommentsProvider(widget.taskId));
                });
              },
            ),
            // Add other actions like:
            // - Add to Workbench
            // - Copy Task Details
            // - Chat about Task (if implemented)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              child: const Text('Delete Task'),
              onPressed: () async {
                Navigator.pop(popupContext);
                final confirmed = await showCupertinoDialog<bool>(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: const Text('Delete Task?'),
                    content: const Text('Are you sure you want to delete this task and its comments? This cannot be undone.'),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.pop(context, false),
                      ),
                      CupertinoDialogAction(
                        isDestructiveAction: true,
                        child: const Text('Delete'),
                        onPressed: () => Navigator.pop(context, true),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  try {
                    await ref.read(tasksNotifierProvider.notifier).deleteTask(widget.taskId);
                    if (mounted && Navigator.of(context).canPop()) {
                      Navigator.of(context).pop(); // Go back after deletion
                    }
                  } catch (e) {
                     if (mounted) _showErrorSnackbar('Failed to delete task: $e');
                  }
                }
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(popupContext),
          ),
        );
      },
    );
  }

   void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_effectiveServerId == null) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('Loading...')),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    // Watch the task detail provider
    final taskAsync = ref.watch(taskDetailProvider(widget.taskId));

    return Focus(
      focusNode: _screenFocusNode,
      autofocus: true,
      child: GestureDetector(
         onTap: () => _screenFocusNode.requestFocus(), // Request focus on tap anywhere
         behavior: HitTestBehavior.translucent,
        child: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: const Text('Task Detail'),
            transitionBetweenRoutes: false, // Keep consistent with ItemDetailScreen
            // MODIFY: Add a Row for multiple trailing buttons
            trailing: taskAsync.when(
              data:
                  (task) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ADD: Button to focus comment field
                      CupertinoButton(
                        padding: const EdgeInsets.only(
                          left: 8.0,
                        ), // Add padding if needed
                        onPressed: () => _commentFocusNode.requestFocus(),
                        child: const Icon(CupertinoIcons.chat_bubble_text),
                      ),
                      // Existing actions button
                      CupertinoButton(
                        padding: const EdgeInsets.only(
                          left: 8.0,
                        ), // Adjust padding
                        onPressed: () => _showActions(task),
                        child: const Icon(CupertinoIcons.ellipsis_vertical),
                      ),
                    ],
              ),
              loading: () => const CupertinoActivityIndicator(radius: 10),
              error: (_, __) => const SizedBox.shrink(), // No actions if error
            ),
          ),
          child: Column(
            children: [
              Expanded(child: _buildBody(taskAsync)),
              // Pass the focus node to the comment form
              TaskCommentForm(
                taskId: widget.taskId,
                focusNode: _commentFocusNode, // ADD: Pass focus node
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AsyncValue<TaskItem> taskAsync) {
    if (!mounted || _effectiveServerId == null) {
      return const Center(child: CupertinoActivityIndicator());
    }

    return taskAsync.when(
      data: (task) {
        return CupertinoScrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: _onRefresh,
                builder: _buildRefreshIndicator,
              ),
              // Task Content Section
              SliverToBoxAdapter(
                child: TaskContent(task: task, taskId: widget.taskId),
              ),
              // Separator
              SliverToBoxAdapter(
                child: Container(
                  height: 0.5,
                  color: CupertinoColors.separator.resolveFrom(context),
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                ),
              ),
              // Task Comments Section
              SliverToBoxAdapter(
                child: TaskComments(taskId: widget.taskId),
              ),
              // Padding at the bottom before the comment form
              const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
            ],
          ),
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (error, _) {
        final bool isNotFoundError = error.toString().contains('not found');
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              isNotFoundError ? 'Task not found. It may have been deleted.' : 'Error loading task: $error',
              textAlign: TextAlign.center,
              style: TextStyle(color: CupertinoColors.systemRed.resolveFrom(context)),
            ),
          ),
        );
      },
    );
  }
}
