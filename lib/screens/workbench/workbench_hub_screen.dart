import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/models/workbench_instance.dart';
import 'package:flutter_memos/providers/workbench_instances_provider.dart';
import 'package:flutter_memos/screens/workbench/widgets/workbench_instance_tile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkbenchHubScreen extends ConsumerStatefulWidget {
  const WorkbenchHubScreen({super.key});

  @override
  ConsumerState<WorkbenchHubScreen> createState() => _WorkbenchHubScreenState();
}

class _WorkbenchHubScreenState extends ConsumerState<WorkbenchHubScreen> {
  final TextEditingController _instanceNameController = TextEditingController();

  @override
  void dispose() {
    _instanceNameController.dispose();
    super.dispose();
  }

  void _showAddInstanceDialog() {
    _instanceNameController.clear();
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('New Workbench'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: CupertinoTextField(
            controller: _instanceNameController,
            placeholder: 'Instance Name (e.g., Work, Project X)',
            autofocus: true,
            onSubmitted: (_) => _createInstance(),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Create'),
            onPressed: () => _createInstance(),
          ),
        ],
      ),
    );
  }

  void _createInstance() {
    final name = _instanceNameController.text.trim();
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    }
    if (name.isNotEmpty) {
      ref.read(workbenchInstancesProvider.notifier).saveInstance(name).then((success) {
        if (success) {
          // Optionally navigate to the new instance immediately
          // final newState = ref.read(workbenchInstancesProvider);
          // final newInstanceId = newState.instances.firstWhere((i) => i.name == name).id;
          // Navigator.of(context).pushNamed('/workbench/$newInstanceId');
        }
      });
    }
  }

  void _showRenameInstanceDialog(WorkbenchInstance instance) {
    _instanceNameController.text = instance.name;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Rename Workbench'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: CupertinoTextField(
            controller: _instanceNameController,
            placeholder: 'New Instance Name',
            autofocus: true,
            onSubmitted: (_) => _renameInstance(instance.id),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Rename'),
            onPressed: () => _renameInstance(instance.id),
          ),
        ],
      ),
    );
  }

  void _renameInstance(String instanceId) {
    final newName = _instanceNameController.text.trim();
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    }
    if (newName.isNotEmpty) {
      ref
          .read(workbenchInstancesProvider.notifier)
          .renameInstance(instanceId, newName);
    }
  }

  void _showDeleteConfirmationDialog(WorkbenchInstance instance) {
    final instancesState = ref.read(workbenchInstancesProvider);
    if (instancesState.instances.length <= 1 || instance.isSystemDefault) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Cannot Delete'),
          content: Text(
            instance.isSystemDefault
                ? 'The default "${instance.name}" instance cannot be deleted.'
                : 'Cannot delete the last remaining instance.',
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Delete "${instance.name}"?'),
        content: const Text(
          'Are you sure? All items within this workbench will also be permanently deleted.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.pop(context); // Close confirmation
              }
              ref
                  .read(workbenchInstancesProvider.notifier)
                  .deleteInstance(instance.id);
            },
          ),
        ],
      ),
    );
  }

  void _showInstanceActions(WorkbenchInstance instance) {
    final instancesState = ref.read(workbenchInstancesProvider);
    final bool canDelete =
        instancesState.instances.length > 1 && !instance.isSystemDefault;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Actions for "${instance.name}"'),
        actions: [
          CupertinoActionSheetAction(
            child: const Text('Rename'),
            onPressed: () {
              Navigator.pop(context); // Close action sheet
              _showRenameInstanceDialog(instance);
            },
          ),
          if (canDelete)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              child: const Text('Delete'),
              onPressed: () {
                Navigator.pop(context); // Close action sheet first
                _showDeleteConfirmationDialog(instance); // Show confirmation dialog
              },
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final instancesState = ref.watch(workbenchInstancesProvider);
    final instances = instancesState.instances;
    final isLoading = instancesState.isLoading;
    final error = instancesState.error;

    // Sort instances: default first, then by creation date or name
    final sortedInstances = [...instances]..sort((a, b) {
        if (a.isSystemDefault) return -1;
        if (b.isSystemDefault) return 1;
        return a.createdAt.compareTo(b.createdAt); // Or sort by name: a.name.compareTo(b.name)
      });

    final separator = Container(
      height: 1,
      color: CupertinoColors.separator.resolveFrom(context),
      margin: const EdgeInsets.only(left: 56), // Indent separator past icon
    );

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Workbenches"),
        // No back button needed on the hub screen
        automaticallyImplyLeading: false,
        // Trailing actions can be added here if needed (e.g., Edit button)
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // --- Loading/Error States ---
            if (isLoading && instances.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CupertinoActivityIndicator()),
              ),
            if (error != null && instances.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.exclamationmark_triangle,
                        size: 40,
                        color: CupertinoColors.systemRed,
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Error loading Workbenches: $error',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: CupertinoColors.secondaryLabel.resolveFrom(context),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      CupertinoButton(
                        child: const Text('Retry'),
                        onPressed: () => ref.read(workbenchInstancesProvider.notifier).loadInstances(),
                      ),
                    ],
                  ),
                ),
              ),

            // --- Instance List ---
            if (instances.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final instance = sortedInstances[index];
                      final isLast = index == sortedInstances.length - 1;

                      Widget tile = WorkbenchInstanceTile(
                        instance: instance,
                        onTap: () {
                          // Navigate to the detail screen using the nested navigator
                          Navigator.of(context).pushNamed('/workbench/${instance.id}');
                        },
                        onLongPress: () => _showInstanceActions(instance),
                      );

                      if (!isLast) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [tile, separator],
                        );
                      } else {
                        return tile; // No separator after the last item
                      }
                    },
                    childCount: sortedInstances.length,
                  ),
                ),
              ),

            // --- Add New Instance Button ---
             SliverPadding(
               padding: const EdgeInsets.only(top: 10.0, bottom: 20.0), // Add padding
               sliver: SliverToBoxAdapter(
                 child: Container(
                   color: CupertinoTheme.of(context).barBackgroundColor,
                   child: CupertinoButton(
                     padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                     onPressed: _showAddInstanceDialog,
                     child: Row(
                       children: [
                         const Icon(
                           CupertinoIcons.add_circled,
                           color: CupertinoColors.systemGreen,
                           size: 24,
                         ),
                         const SizedBox(width: 16),
                         Expanded(
                           child: Text(
                             'New Workbench',
                             style: CupertinoTheme.of(context).textTheme.textStyle,
                           ),
                         ),
                       ],
                     ),
                   ),
                 ),
               ),
             ),
          ],
        ),
      ),
    );
  }
}
