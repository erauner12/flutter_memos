import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/models/task_item.dart';
import 'package:intl/intl.dart'; // For date formatting

class TaskListItem extends StatelessWidget {
  final TaskItem task;
  final Function(bool isCompleted) onToggleComplete;
  final VoidCallback onDelete;
  final VoidCallback onAddToWorkbench;
  final VoidCallback onTap;

  const TaskListItem({
    super.key,
    required this.task,
    required this.onToggleComplete,
    required this.onDelete,
    required this.onAddToWorkbench,
    required this.onTap,
  });

  // Helper to get priority color
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

  // Helper to format due date
  String _formatDueDate(DateTime? dueDate) {
    if (dueDate == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (taskDate == today) {
      // Check if time is included (simple check: non-zero time components)
      if (dueDate.hour != 0 || dueDate.minute != 0 || dueDate.second != 0) {
        return 'Today ${DateFormat.jm().format(dueDate.toLocal())}'; // Include time
      }
      return 'Today';
    } else if (taskDate == tomorrow) {
       if (dueDate.hour != 0 || dueDate.minute != 0 || dueDate.second != 0) {
        return 'Tomorrow ${DateFormat.jm().format(dueDate.toLocal())}'; // Include time
      }
      return 'Tomorrow';
    } else if (taskDate == yesterday) {
      return 'Yesterday'; // Time usually less relevant for past dates
    } else if (differenceInDays(taskDate, today) < 7 && taskDate.isAfter(now)) {
        // Within the next week
       if (dueDate.hour != 0 || dueDate.minute != 0 || dueDate.second != 0) {
         return '${DateFormat('EEE').format(dueDate)} ${DateFormat.jm().format(dueDate.toLocal())}'; // Day + Time
       }
       return DateFormat('EEEE').format(dueDate); // Full day name
    } else {
      // Default format for other dates
      final format = (dueDate.year == now.year) ? DateFormat('MMM d') : DateFormat('MMM d, yyyy');
       if (dueDate.hour != 0 || dueDate.minute != 0 || dueDate.second != 0) {
         return '${format.format(dueDate)} ${DateFormat.jm().format(dueDate.toLocal())}'; // Date + Time
       }
      return format.format(dueDate);
    }
  }

  // Helper to calculate difference in days ignoring time
  int differenceInDays(DateTime date1, DateTime date2) {
    final d1 = DateTime(date1.year, date1.month, date1.day);
    final d2 = DateTime(date2.year, date2.month, date2.day);
    return d1.difference(d2).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final Color priorityColor = _getPriorityColor(task.priority, context);
    final String formattedDueDate = _formatDueDate(task.dueDate);
    final bool isOverdue = task.dueDate != null &&
        !task.isCompleted &&
        task.dueDate!.isBefore(DateTime.now());

    final Color dateColor = isOverdue
        ? CupertinoColors.systemRed.resolveFrom(context)
        : CupertinoColors.secondaryLabel.resolveFrom(context);

    return CupertinoContextMenu(
      actions: <Widget>[
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
      ],
      child: GestureDetector(
        onTap: onTap, // Use the passed onTap callback
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: CupertinoColors.separator.resolveFrom(context),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox / Priority indicator
              Padding(
                padding: const EdgeInsets.only(top: 1.0, right: 12.0),
                child: GestureDetector(
                  onTap: () => onToggleComplete(!task.isCompleted),
                  child: Icon(
                    task.isCompleted
                        ? CupertinoIcons.check_mark_circled_solid
                        : CupertinoIcons.circle,
                    color: task.isCompleted
                        ? CupertinoColors.systemGreen.resolveFrom(context)
                        : priorityColor,
                    size: 24.0,
                  ),
                ),
              ),
              // Task Content, Due Date, Labels
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.content,
                      maxLines: 3, // Allow more lines for content
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16.5,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: task.isCompleted
                            ? CupertinoColors.secondaryLabel.resolveFrom(context)
                            : CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                    // Description Snippet (if available)
                    if (task.description != null && task.description!.isNotEmpty)
                      Padding(
                         padding: const EdgeInsets.only(top: 4.0),
                         child: Text(
                            task.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                      ),
                    // Due Date and Labels row
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
                            if (formattedDueDate.isNotEmpty && task.labels.isNotEmpty)
                              const Text('  •  ', style: TextStyle(fontSize: 13)), // Separator
                            // Display Labels (limited number)
                            if (task.labels.isNotEmpty)
                              Expanded(
                                child: Text(
                                  task.labels.map((l) => '@$l').join(' '),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
