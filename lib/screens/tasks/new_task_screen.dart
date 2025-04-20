import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/models/task_item.dart';
import 'package:flutter_memos/providers/task_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Import Vikunja models for project data
import 'package:vikunja_flutter_api/vikunja_api/lib/api.dart' as vikunja;

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

  // ADDED: State for project selection
  int? _selectedProjectId;
  List<vikunja.ModelsProject> _projects = []; // To store fetched projects
  String? _projectFetchError; // To display project fetch errors
  bool _isLoadingProjects = true; // To show loading indicator for projects
  // END ADDED

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      // Use title instead of content
      _titleController.text = widget.taskToEdit!.title; // Use title
      _descriptionController.text = widget.taskToEdit!.description ?? '';
      // Initialize selected project ID if editing
      _selectedProjectId = widget.taskToEdit!.projectId; // ADDED
      // TODO: Initialize other fields (priority, due date, etc.)
    }
    // Fetch projects when the screen initializes
    _fetchProjects(); // ADDED
  }

  // ADDED: Method to fetch projects
  Future<void> _fetchProjects() async {
    // Use mounted check
    if (!mounted) return;
    setState(() {
      _isLoadingProjects = true;
      _projectFetchError = null;
    });
    try {
      // Read the provider future directly
      final projects = await ref.read(vikunjaProjectsProvider.future);
      if (mounted) {
        setState(() {
          _projects = projects;
          _isLoadingProjects = false;
          // If not editing and there's only one project, select it by default? (Optional)
          // if (!_isEditing && projects.length == 1) {
          //   _selectedProjectId = projects.first.id;
          // }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _projectFetchError = 'Error loading projects: ${e.toString()}';
          _isLoadingProjects = false;
        });
      }
    }
  }
  // END ADDED

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
        builder:
            (ctx) => CupertinoAlertDialog(
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

    // ADDED: Validate that a project is selected
    if (_selectedProjectId == null) {
      showCupertinoDialog(
        context: context,
        builder:
            (ctx) => CupertinoAlertDialog(
              title: const Text('Project Required'),
              content: const Text('Please select a project for this task.'),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
      );
      return; // Stop saving if no project is selected
    }
    // END ADDED

    setState(() => _isSaving = true);

    try {
      TaskItem taskData;
      if (_isEditing) {
        // Update existing task - copy existing and apply changes
        taskData = widget.taskToEdit!.copyWith(
          // Use title instead of content
          title: _titleController.text.trim(), // Use title controller
          // Wrap description in ValueGetter
          description:
              () =>
                  _descriptionController.text.trim().isEmpty
                      ? null
                      : _descriptionController.text.trim(),
          // ADDED: Set the selected project ID
          projectId: _selectedProjectId,
          // TODO: Add other fields like priority, due date, labels
        );
        // Call update method (needs Task ID as String)
        // No need to pass projectId separately for update, it's in taskData
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
          description:
              _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
          // Use done instead of isCompleted
          done: false, // Use done
          priority: null, // Default priority (Vikunja might use null or 0)
          createdAt: DateTime.now(), // Temp value, API assigns real one
          // ADDED: Set the selected project ID
          projectId: _selectedProjectId,
          // TODO: Assign other fields from form (dueDate, projectId etc.)
        );
        // Call create method, passing projectId explicitly as required by notifier/service
        final createdTask = await ref
            .read(tasksNotifierProvider.notifier)
            .createTask(
              taskData,
              projectId: _selectedProjectId,
            ); // Pass projectId here

        if (createdTask != null && mounted) {
          Navigator.of(context).pop(); // Close screen on success
        } else if (mounted) {
          _showErrorDialog('Failed to create task.');
        }
      }
    } catch (e) {
      if (mounted) {
        // Improved error message display
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
      builder:
          (ctx) => CupertinoAlertDialog(
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
          child:
              _isSaving
                  ? const CupertinoActivityIndicator()
                  : const Text('Save'),
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
            const SizedBox(height: 24), // Increased spacing
            // --- ADDED: Project Selection UI ---
            _buildProjectSelector(), // Extracted to a helper method
            // --- END ADDED ---

            // TODO: Add fields for Priority, Due Date, Labels, Project, Section
            // These will likely involve pickers or selection lists.
            const SizedBox(height: 20),
            Text(
              'More options (Priority, Due Date, Labels, etc.) coming soon!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ADDED: Helper widget for project selection UI
  Widget _buildProjectSelector() {
    if (_isLoadingProjects) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_projectFetchError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          _projectFetchError!,
          style: TextStyle(
            color: CupertinoColors.systemRed.resolveFrom(context),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_projects.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'No projects found. Create a project in Vikunja first.',
          style: TextStyle(
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Find the selected project name
    final selectedProjectName =
        _selectedProjectId == null
            ? 'Select Project'
            : _projects
                .firstWhere(
                  (p) => p.id == _selectedProjectId,
                  orElse: () => vikunja.ModelsProject(title: 'Unknown Project'),
                )
                .title;

    return CupertinoListTile(
      title: const Text('Project'),
      additionalInfo: Text(selectedProjectName ?? 'Select Project'),
      trailing: const CupertinoListTileChevron(),
      onTap: _showProjectPicker, // Call method to show picker
    );

    // --- Placeholder Button Implementation (Alternative) ---
    // return CupertinoButton(
    //   child: Text(selectedProjectName ?? 'Select Project'),
    //   onPressed: _showProjectPicker, // Call method to show picker
    // );
  }

  // ADDED: Method to show the project picker (basic implementation)
  void _showProjectPicker() {
    if (_projects.isEmpty) return; // Don't show picker if no projects

    // --- Simple Action Sheet Picker ---
    showCupertinoModalPopup<void>(
      context: context,
      builder:
          (BuildContext context) => CupertinoActionSheet(
            title: const Text('Select Project'),
            actions:
                _projects.map((project) {
                  return CupertinoActionSheetAction(
                    child: Text(project.title ?? 'Untitled Project'),
                    onPressed: () {
                      setState(() {
                        _selectedProjectId = project.id;
                      });
                      Navigator.pop(context); // Close the action sheet
                    },
                  );
                }).toList(),
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
    );

    // --- TODO: Implement a more robust picker if needed (e.g., CupertinoPicker or separate screen) ---
    // Example using CupertinoPicker (might need more setup):
    // showCupertinoModalPopup<void>(
    //   context: context,
    //   builder: (BuildContext context) {
    //     int selectedIndex = _selectedProjectId == null ? 0 : _projects.indexWhere((p) => p.id == _selectedProjectId);
    //     if (selectedIndex == -1) selectedIndex = 0; // Default to first if not found
    //
    //     return Container(
    //       height: 216,
    //       padding: const EdgeInsets.only(top: 6.0),
    //       margin: EdgeInsets.only(
    //         bottom: MediaQuery.of(context).viewInsets.bottom,
    //       ),
    //       color: CupertinoColors.systemBackground.resolveFrom(context),
    //       child: SafeArea(
    //         top: false,
    //         child: CupertinoPicker(
    //           magnification: 1.22,
    //           squeeze: 1.2,
    //           useMagnifier: true,
    //           itemExtent: 32.0, // Adjust item height
    //           scrollController: FixedExtentScrollController(initialItem: selectedIndex),
    //           onSelectedItemChanged: (int index) {
    //             setState(() {
    //               _selectedProjectId = _projects[index].id;
    //             });
    //           },
    //           children: List<Widget>.generate(_projects.length, (int index) {
    //             return Center(child: Text(_projects[index].title ?? 'Untitled'));
    //           }),
    //         ),
    //       ),
    //     );
    //   },
    //   },
    // );
  }

  // END ADDED
}
