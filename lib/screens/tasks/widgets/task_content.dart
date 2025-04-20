import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/models/task_item.dart';
import 'package:flutter_memos/utils/url_helper.dart'; // For link tapping
import 'package:flutter_riverpod/flutter_riverpod.dart'; // For potential future provider use
import 'package:intl/intl.dart';

class TaskContent extends ConsumerWidget {
  final TaskItem task;
  final String taskId; // Keep for context if needed

  const TaskContent({
    super.key,
    required this.task,
    required this.taskId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = CupertinoTheme.of(context);
    final dateFormat = DateFormat.yMd().add_jm(); // Example format

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task Title
          Text(
            task.title,
            style: theme.textTheme.navLargeTitleTextStyle.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12.0),

          // Task Description (Markdown)
          if (task.description != null && task.description!.isNotEmpty)
            MarkdownBody(
              data: task.description!,
              selectable: true,
              styleSheet: MarkdownStyleSheet.fromCupertinoTheme(theme).copyWith(
                p: theme.textTheme.textStyle.copyWith(fontSize: 15, height: 1.4),
                a: theme.textTheme.textStyle.copyWith(
                  color: theme.primaryColor,
                  decoration: TextDecoration.underline,
                ),
                // Add other styles as needed (code blocks, lists, etc.)
              ),
              onTapLink: (text, href, title) async {
                if (href != null) {
                  UrlHelper.launchUrl(href, context: context, ref: ref);
                }
              },
            )
          else
            Text(
              'No description provided.',
              style: theme.textTheme.textStyle.copyWith(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontStyle: FontStyle.italic,
              ),
            ),
          const SizedBox(height: 16.0),

          // Metadata Section (Due Date, Priority, etc.)
          _buildMetadataRow(
            context,
            icon: CupertinoIcons.calendar,
            label: 'Due Date',
            value: task.dueDate != null ? dateFormat.format(task.dueDate!) : 'Not set',
          ),
          const SizedBox(height: 8.0),
          _buildMetadataRow(
            context,
            icon: CupertinoIcons.flag,
            label: 'Priority',
            value: task.priority != null ? 'Priority ${task.priority}' : 'Not set', // Adjust display as needed
          ),
           const SizedBox(height: 8.0),
          _buildMetadataRow(
            context,
            icon: CupertinoIcons.percent,
            label: 'Progress',
            value: task.percentDone != null ? '${task.percentDone}%' : 'Not set',
          ),
          // Add more metadata rows as needed (Project, Bucket, Created/Updated)
          const SizedBox(height: 8.0),
           _buildMetadataRow(
            context,
            icon: CupertinoIcons.time,
            label: 'Created',
            value: dateFormat.format(task.createdAt),
          ),
           if (task.updatedAt != null) ...[
             const SizedBox(height: 8.0),
             _buildMetadataRow(
              context,
              icon: CupertinoIcons.pencil_ellipsis_rectangle,
              label: 'Updated',
              value: dateFormat.format(task.updatedAt!),
            ),
           ]
        ],
      ),
    );
  }

  Widget _buildMetadataRow(BuildContext context, {required IconData icon, required String label, required String value}) {
     final theme = CupertinoTheme.of(context);
     return Row(
       children: [
         Icon(icon, size: 18, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
         const SizedBox(width: 8.0),
         Text(
           '$label:',
           style: theme.textTheme.textStyle.copyWith(
             fontWeight: FontWeight.w600,
             color: CupertinoColors.secondaryLabel.resolveFrom(context),
             fontSize: 14,
           ),
         ),
         const SizedBox(width: 8.0),
         Expanded(
           child: Text(
             value,
             style: theme.textTheme.textStyle.copyWith(fontSize: 14),
             overflow: TextOverflow.ellipsis,
           ),
         ),
       ],
     );
  }
}
