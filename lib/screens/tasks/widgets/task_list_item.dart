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
  final VoidCallback onChatWithTask; // NEW: Callback for chat action
  final VoidCallback onTap;

  const TaskListItem({
    // Use ValueKey for efficient list updates
    super.key,
    required this.task,
    required this.onToggleComplete,
    required this.onDelete,
    required this.onAddToWorkbench,
    required this.onChatWithTask, // NEW: Require chat callback
    required this.onTap,
  });

  // NEW helper to show action sheet on long-press
  void _showContextMenu(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      useRootNavigator: true, // Avoids nested navigator issues
      builder:
          (popupContext) => CupertinoActionSheet(
            title: const Text('Task Actions'),
            actions: [
              CupertinoActionSheetAction(
                child: Text(task.isCompleted ? 'Reopen Task' : 'Complete Task'),
                onPressed: () {
                  Navigator.pop(popupContext);
                  onToggleComplete(!task.isCompleted);
                },
              ),
              // NEW: Chat about Task action
              CupertinoActionSheetAction(
                child: const Text('Chat about Task'),
                onPressed: () {
                  Navigator.pop(popupContext);
                  onChatWithTask(); // Call the new callback
                },
              ),
              CupertinoActionSheetAction(
                child: const Text('Add to Workbench'),
                onPressed: () {
                  Navigator.pop(popupContext);
                  onAddToWorkbench();
                },
              ),
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                child: const Text('Delete Task'),
                onPressed: () {
                  Navigator.pop(popupContext);
                  onDelete();
                },
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(popupContext),
            ),
          ),
    );
  }

  // Helper to build slidable action pane (remains unchanged)
  ActionPane _buildActionPane(BuildContext context) {
    return ActionPane(
      motion: const BehindMotion(), // Or StretchMotion, etc.
      extentRatio:
          0.75, // Adjust how far it slides (increased slightly for 4 actions)
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
        // NEW: Chat action in slide pane
        SlidableAction(
          onPressed: (_) => onChatWithTask(),
          backgroundColor: CupertinoColors.systemPurple.resolveFrom(context),
          foregroundColor: CupertinoColors.white,
          icon: CupertinoIcons.chat_bubble_2,
          label: 'Chat',
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

      // The child is now _TaskRowContent directly.
      // Long-press is handled inside _TaskRowContent via the new callback.
      child: _TaskRowContent(
        task: task,
        onTap: onTap, // Pass onTap for the main content area
        onToggleComplete: onToggleComplete, // Pass toggle for the checkbox
        onLongPress:
            () => _showContextMenu(context), // Pass long-press handler
      ),
    );
  }
}

/// Private widget handling the actual row layout.
class _TaskRowContent extends StatelessWidget {
  final TaskItem task;
  final VoidCallback onTap;
  final Function(bool isCompleted) onToggleComplete;
  final VoidCallback onLongPress; // Callback for long-press

  const _TaskRowContent({
    required this.task,
    required this.onTap,
    required this.onToggleComplete,
    required this.onLongPress, // Require the callback
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

    // Wrap the Container in a ConstrainedBox to provide finite width constraints.
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          // Set color inside BoxDecoration
          color: CupertinoColors.systemBackground.resolveFrom(context),
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
            // AND handles long-press.
            Expanded(
              child: GestureDetector(
                onTap: onTap, // Use the passed onTap callback
                onLongPress:
                    onLongPress, // Use the passed onLongPress callback
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
                    if (task.description != null &&
                        task.description!.isNotEmpty)
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
                                style: TextStyle(
                                  fontSize: 13,
                                  color: dateColor,
                                ),
                              ),
                            if (formattedDueDate.isNotEmpty &&
                                task.labels.isNotEmpty)
                              const Text(
                                '  •  ',
                                style: TextStyle(fontSize: 13),
                              ),
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
