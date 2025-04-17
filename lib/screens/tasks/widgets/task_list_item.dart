import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/models/task_item.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // Import Slidable
import 'package:intl/intl.dart'; // For date formatting

// Animation duration constant
const Duration kShortAnimation = Duration(milliseconds: 220);

/// Public widget responsible for wiring parameters.
class TaskListItem extends StatelessWidget {
  final TaskItem task;
  final Function(bool isCompleted) onToggleComplete;
  final VoidCallback onDelete;
  final VoidCallback onAddToWorkbench;
  final VoidCallback onTap;

  const TaskListItem({
    // Use ValueKey for efficient list updates
    super.key,
    required this.task,
    required this.onToggleComplete,
    required this.onDelete,
    required this.onAddToWorkbench,
    required this.onTap,
  });

  // Helper to build context menu actions
  List<Widget> _buildContextActions(BuildContext context) {
    return <Widget>[
      CupertinoContextMenuAction(
        child: Text(task.isCompleted ? 'Reopen Task' : 'Complete Task'),
        onPressed: () {
          Navigator.pop(context); // Close the menu
          onToggleComplete(!task.isCompleted);
        },
      ),
      CupertinoContextMenuAction(
        child: const Text('Add to Workbench'),
        onPressed: () {
          Navigator.pop(context);
          onAddToWorkbench();
        },
      ),
      CupertinoContextMenuAction(
        isDestructiveAction: true,
        child: const Text('Delete Task'),
        onPressed: () {
          Navigator.pop(context);
          onDelete();
        },
      ),
    ];
  }

  // Helper to build slidable action pane
  ActionPane _buildActionPane(BuildContext context) {
    return ActionPane(
      motion: const BehindMotion(), // Or StretchMotion, etc.
      extentRatio: 0.6, // Adjust how far it slides
      children: [
        SlidableAction(
          onPressed: (_) => onToggleComplete(!task.isCompleted),
          backgroundColor:
              task.isCompleted
                  ? CupertinoColors.systemBlue.resolveFrom(context)
                  : CupertinoColors.systemGreen.resolveFrom(context),
          foregroundColor: CupertinoColors.white,
          icon:
              task.isCompleted
                  ? CupertinoIcons.arrow_uturn_left
                  : CupertinoIcons.check_mark,
          label: task.isCompleted ? 'Reopen' : 'Complete',
        ),
        SlidableAction(
          onPressed: (_) => onAddToWorkbench(),
          backgroundColor: CupertinoColors.systemGrey.resolveFrom(context),
          foregroundColor: CupertinoColors.white,
          icon: CupertinoIcons.add,
          label: 'Workbench',
        ),
        SlidableAction(
          onPressed: (_) => onDelete(),
          backgroundColor: CupertinoColors.systemRed.resolveFrom(context),
          foregroundColor: CupertinoColors.white,
          icon: CupertinoIcons.delete,
          label: 'Delete',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Slidable (swipe actions) stays outside.
    return Slidable(
      key: ValueKey(task.id), // Essential for list animations
      endActionPane: _buildActionPane(
        context,
      ), // Actions revealed on swipe left
      closeOnScroll: true, // Default, good practice

      child: CupertinoContextMenu(
        actions: _buildContextActions(context),

        // 1. Provide a previewBuilder that gives the preview finite constraints
        //    using the _TaskContextPreview helper.
        previewBuilder:
            (context, animation, child) => _TaskContextPreview(child: child!),

        // 2. The regular child for the in-list representation.
        //    No ConstrainedBox needed here anymore.
        child: _TaskRowContent(
          task: task,
          onTap: onTap, // Pass onTap for the main content area
          onToggleComplete: onToggleComplete, // Pass toggle for the checkbox
        ),
      ),
    );
  }
}

/// Private widget handling the actual row layout.
class _TaskRowContent extends StatelessWidget {
  final TaskItem task;
  final VoidCallback onTap;
  final Function(bool isCompleted) onToggleComplete;

  const _TaskRowContent({
    required this.task,
    required this.onTap,
    required this.onToggleComplete,
    // No key needed here as it's managed by the parent Slidable
  });

  // Helper to get priority color (moved from TaskListItem)
  Color _getPriorityColor(int priority, BuildContext context) {
    switch (priority) {
      case 4: // P1 (Urgent)
        return CupertinoColors.systemRed.resolveFrom(context);
      case 3: // P2
        return CupertinoColors.systemOrange.resolveFrom(context);
      case 2: // P3
        return CupertinoColors.systemBlue.resolveFrom(context);
      case 1: // P4 (Normal)
      default:
        return CupertinoColors.secondaryLabel.resolveFrom(context);
    }
  }

  // Helper to format due date (moved from TaskListItem)
  String _formatDueDate(DateTime? dueDate) {
    if (dueDate == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (taskDate == today) {
      if (dueDate.hour != 0 || dueDate.minute != 0 || dueDate.second != 0) {
        return 'Today ${DateFormat.jm().format(dueDate.toLocal())}';
      }
      return 'Today';
    } else if (taskDate == tomorrow) {
       if (dueDate.hour != 0 || dueDate.minute != 0 || dueDate.second != 0) {
        return 'Tomorrow ${DateFormat.jm().format(dueDate.toLocal())}';
      }
      return 'Tomorrow';
    } else if (taskDate == yesterday) {
      return 'Yesterday';
    } else if (differenceInDays(taskDate, today) < 7 && taskDate.isAfter(now)) {
       if (dueDate.hour != 0 || dueDate.minute != 0 || dueDate.second != 0) {
        return '${DateFormat('EEE').format(dueDate)} ${DateFormat.jm().format(dueDate.toLocal())}';
       }
      return DateFormat('EEEE').format(dueDate);
    } else {
      final format = (dueDate.year == now.year) ? DateFormat('MMM d') : DateFormat('MMM d, yyyy');
       if (dueDate.hour != 0 || dueDate.minute != 0 || dueDate.second != 0) {
        return '${format.format(dueDate)} ${DateFormat.jm().format(dueDate.toLocal())}';
       }
      return format.format(dueDate);
    }
  }

  // Helper to calculate difference in days ignoring time (moved from TaskListItem)
  int differenceInDays(DateTime date1, DateTime date2) {
    final d1 = DateTime(date1.year, date1.month, date1.day);
    final d2 = DateTime(date2.year, date2.month, date2.day);
    return d1.difference(d2).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final Color priorityColor = _getPriorityColor(task.priority, context);
    // Allow type inference to make this non-nullable String, fixing the lint.
    final formattedDueDate = _formatDueDate(task.dueDate);
    final bool isOverdue = task.dueDate != null &&
        !task.isCompleted &&
        task.dueDate!.isBefore(DateTime.now());

    final Color dateColor = isOverdue
        ? CupertinoColors.systemRed.resolveFrom(context)
        : CupertinoColors.secondaryLabel.resolveFrom(context);

    // The Container provides padding and the bottom border
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(
          context,
        ), // Ensure background for context menu preview AND regular display
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // GestureDetector now wraps only the tappable content area,
          // allowing the outer CupertinoContextMenu to handle long-press.
          Expanded(
            child: GestureDetector(
              onTap: onTap, // Use the passed onTap callback
              behavior:
                  HitTestBehavior
                      .opaque, // Ensure it captures taps within bounds
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16.5,
                      decoration:
                          task.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                      color:
                          task.isCompleted
                              ? CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              )
                              : CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                  if (task.description != null && task.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        task.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.tertiaryLabel.resolveFrom(
                            context,
                          ),
                          decoration:
                              task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                        ),
                      ),
                    ),
                  if (formattedDueDate.isNotEmpty || task.labels.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Row(
                        children: [
                          if (formattedDueDate.isNotEmpty)
                            Icon(
                              CupertinoIcons.calendar,
                              size: 14,
                              color: dateColor,
                            ),
                          if (formattedDueDate.isNotEmpty)
                            const SizedBox(width: 4),
                          if (formattedDueDate.isNotEmpty)
                            Text(
                              formattedDueDate,
                              style: TextStyle(fontSize: 13, color: dateColor),
                            ),
                          if (formattedDueDate.isNotEmpty &&
                              task.labels.isNotEmpty)
                            const Text('  •  ', style: TextStyle(fontSize: 13)),
                          if (task.labels.isNotEmpty)
                            Expanded(
                              child: Text(
                                task.labels.map((l) => '@$l').join(' '),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12.0),

          // Trailing checkbox remains outside the main content GestureDetector
          _TrailingCheckbox(
            task: task,
            priorityColor: priorityColor,
            onToggle: onToggleComplete, // Use the passed callback
          ),
        ],
      ),
    );
  }
}

/// Animated checkbox widget (remains unchanged).
class _TrailingCheckbox extends StatelessWidget {
  final TaskItem task;
  final Color priorityColor;
  final Function(bool) onToggle;

  const _TrailingCheckbox({
    required this.task,
    required this.priorityColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44.0,
      height: 44.0,
      child: Center(
        child: GestureDetector(
          onTap: () => onToggle(!task.isCompleted),
          child: AnimatedSwitcher(
            duration: kShortAnimation,
            child: Icon(
              task.isCompleted
                  ? CupertinoIcons.check_mark_circled_solid
                  : CupertinoIcons.circle,
              key: ValueKey<bool>(task.isCompleted),
              color:
                  task.isCompleted
                      ? CupertinoColors.systemGreen.resolveFrom(context)
                      : priorityColor,
              size: 24.0,
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper widget to provide finite constraints and background for the context menu preview.
class _TaskContextPreview extends StatelessWidget {
  final Widget child;
  const _TaskContextPreview({required this.child});

  @override
  Widget build(BuildContext context) {
    // Constrain the width to the device width, leave height unbounded (intrinsic height).
    // Use Container for background and optional corner radius.
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Container(
        // Do not set color directly when using decoration.
        // color: CupertinoColors.systemBackground.resolveFrom(context), // REMOVED
        clipBehavior: Clip.hardEdge, // Use Clip enum from dart:ui
        decoration: BoxDecoration(
          // Set color inside BoxDecoration.
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }
}
