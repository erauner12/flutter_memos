import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/models/task_item.dart';
import 'package:flutter_memos/providers/task_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NewTaskScreen extends ConsumerStatefulWidget {
  final TaskItem? taskToEdit; // Optional: pass task for editing

  const NewTaskScreen({super.key, this.taskToEdit});

  @override
  ConsumerState<NewTaskScreen> createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends ConsumerState<NewTaskScreen> {
  final _titleController =
      TextEditingController(); // Renamed from _contentController
  final _descriptionController = TextEditingController();
  // TODO: Add controllers/state for priority, due date, labels, project etc.
  bool _isSaving = false;
  bool get _isEditing => widget.taskToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      // Use title instead of content
      _titleController.text = widget.taskToEdit!.title; // Use title
      _descriptionController.text = widget.taskToEdit!.description ?? '';
      // TODO: Initialize other fields (priority, due date, etc.)
    }
  }

  @override
  void dispose() {
    _titleController.dispose(); // Dispose renamed controller
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    if (_titleController.text.trim().isEmpty) {
      // Check title controller
      // Show error dialog or inline validation
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Title Required'), // Updated title
              content: const Text(
                'Task title cannot be empty.',
              ), // Updated message
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('OK'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      TaskItem taskData;
      if (_isEditing) {
        // Update existing task - copy existing and apply changes
        taskData = widget.taskToEdit!.copyWith(
          // Use title instead of content
          title: _titleController.text.trim(), // Use title controller
          // Wrap description in ValueGetter
          description: () => _descriptionController.text.trim().isEmpty
                           ? null
                           : _descriptionController.text.trim(),
          // TODO: Add other fields like priority, due date, labels
        );
        // Call update method (needs Task ID as String)
        final updatedTask = await ref
            .read(tasksNotifierProvider.notifier)
            // Use the String id getter from TaskItem
            .updateTask(widget.taskToEdit!.id, taskData);

         if (updatedTask != null && mounted) {
           Navigator.of(context).pop(); // Close screen on success
         } else if (mounted) {
            _showErrorDialog('Failed to update task.');
         }

      } else {
        // Create new task - construct from form fields
         taskData = TaskItem(
           // ID is int, but API assigns it, pass 0 or handle differently if needed locally before creation
          id: 0, // Temporary ID, service/API will assign the real one
           // Use title instead of content
          title: _titleController.text.trim(), // Use title controller
           description: _descriptionController.text.trim().isEmpty
                        ? null
                        : _descriptionController.text.trim(),
           // Use done instead of isCompleted
          done: false, // Use done
          priority: null, // Default priority (Vikunja might use null or 0)
           createdAt: DateTime.now(), // Temp value, API assigns real one
           // TODO: Assign other fields from form (dueDate, projectId etc.)
        );
         // Call create method
        final createdTask = await ref
            .read(tasksNotifierProvider.notifier)
            .createTask(taskData); // Assuming notifier has createTask

         if (createdTask != null && mounted) {
           Navigator.of(context).pop(); // Close screen on success
         } else if (mounted) {
           _showErrorDialog('Failed to create task.');
         }
      }


    } catch (e) {
      if (mounted) {
        _showErrorDialog('An error occurred: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showErrorDialog(String message) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('OK'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_isEditing ? 'Edit Task' : 'New Task'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isSaving ? null : _saveTask,
          child: _isSaving ? const CupertinoActivityIndicator() : const Text('Save'),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            CupertinoTextField(
              controller: _titleController, // Use title controller
              placeholder:
                  'Task title (e.g., Buy groceries)', // Updated placeholder
              style: const TextStyle(fontSize: 18),
              maxLines: null, // Allow multiple lines
              textInputAction: TextInputAction.next,
              decoration: const BoxDecoration(
                  // No border, just placeholder
                  ),
            ),
            const SizedBox(height: 16),
             CupertinoTextField(
              controller: _descriptionController,
              placeholder: 'Description (optional)',
              maxLines: 5,
              minLines: 3,
              textInputAction: TextInputAction.newline,
               decoration: BoxDecoration(
                 color: CupertinoColors.secondarySystemFill.resolveFrom(context),
                 borderRadius: BorderRadius.circular(8.0),
               ),
             ),
            // TODO: Add fields for Priority, Due Date, Labels, Project, Section
            // These will likely involve pickers or selection lists.
             const SizedBox(height: 20),
              Text(
                'More options (Priority, Due Date, Labels, etc.) coming soon!',
                textAlign: TextAlign.center,
                style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context)),
              ),
          ],
        ),
      ),
    );
  }
}
