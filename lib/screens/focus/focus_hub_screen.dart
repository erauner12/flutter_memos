import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/models/focus_instance.dart'; // Correct import
import 'package:flutter_memos/providers/focus_instances_provider.dart'; // Correct import
import 'package:flutter_memos/screens/focus/widgets/focus_instance_tile.dart'; // Correct import path
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/focus_provider.dart'; // Correct import

// Renamed from WorkbenchHubScreen
class FocusHubScreen extends ConsumerStatefulWidget {
  const FocusHubScreen({super.key});

  @override
  ConsumerState<FocusHubScreen> createState() => _FocusHubScreenState();
}

// Renamed from _WorkbenchHubScreenState
class _FocusHubScreenState extends ConsumerState<FocusHubScreen> {
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
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('New Focus Board'), // Updated text
            content: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: CupertinoTextField(
                controller: _instanceNameController,
                placeholder: 'Board Name (e.g., Work, Project X)', // Updated text
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
      ref
          .read(focusInstancesProvider.notifier) // Correct provider
          .saveInstance(name)
          .then((success) {
            if (success) {
              // No automatic navigation or active setting after creation
              if (mounted) {
                // Optionally show a confirmation SnackBar or similar
                // ScaffoldMessenger.of(context).showSnackBar(
                //   SnackBar(content: Text('Focus Board "$name" created.')), // Updated text
                // );
              }
            } else {
              // Error handling is done within the notifier, maybe show alert here if needed
            }
          });
    }
  }

  void _showRenameInstanceDialog(FocusInstance instance) {
    // Correct type
    _instanceNameController.text = instance.name;
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Rename Focus Board'), // Updated text
            content: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: CupertinoTextField(
                controller: _instanceNameController,
                placeholder: 'New Board Name', // Updated text
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
          .read(focusInstancesProvider.notifier) // Correct provider
          .renameInstance(instanceId, newName);
    }
  }

  void _showDeleteConfirmationDialog(FocusInstance instance) {
    // Correct type
    final instancesState = ref.read(focusInstancesProvider); // Correct provider
    if (instancesState.instances.length <= 1 || instance.isSystemDefault) {
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: const Text('Cannot Delete'),
              content: Text(
                instance.isSystemDefault
                    ? 'The default "${instance.name}" board cannot be deleted.' // Updated text
                    : 'Cannot delete the last remaining board.', // Updated text
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
      builder:
          (context) => CupertinoAlertDialog(
            title: Text('Delete "${instance.name}"?'),
            content: const Text(
              'Are you sure? All items within this focus board will also be permanently deleted.', // Updated text
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
                      .read(focusInstancesProvider.notifier) // Correct provider
                      .deleteInstance(instance.id);
                },
              ),
            ],
          ),
    );
  }

  void _showInstanceActions(FocusInstance instance) {
    // Correct type
    final instancesState = ref.read(focusInstancesProvider); // Correct provider
    final bool canDelete =
        instancesState.instances.length > 1 && !instance.isSystemDefault;

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: Text(
              'Actions for "${instance.name}"',
            ),
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
                    _showDeleteConfirmationDialog(
                      instance,
                    ); // Show confirmation dialog
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
    final instancesState = ref.watch(
      focusInstancesProvider,
    ); // Correct provider
    final instances = instancesState.instances;
    final isLoading = instancesState.isLoading;
    final error = instancesState.error;

    // Sort instances: default first, then by creation date or name
    final sortedInstances = [...instances]..sort((a, b) {
      if (a.isSystemDefault) return -1;
      if (b.isSystemDefault) return 1;
      return a.createdAt.compareTo(
        b.createdAt,
      );
    });

    final separator = Container(
      height: 1,
      color: CupertinoColors.separator.resolveFrom(context),
      margin: const EdgeInsets.only(left: 56), // Indent separator past icon
    );

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
        context,
      ),
      navigationBar: CupertinoNavigationBar(
        middle: const Text("Focus Boards"), // Updated text
        automaticallyImplyLeading: false,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.refresh),
          onPressed: () {
            // Invalidate providers to trigger reload
            ref.invalidate(focusInstancesProvider); // Correct provider
            final currentInstanceIds =
                ref
                    .read(focusInstancesProvider) // Correct provider
                    .instances
                    .map((i) => i.id)
                    .toList();
            for (final id in currentInstanceIds) {
              ref.invalidate(
                focusProviderFamily(id),
              ); // Correct provider family
            }
            // Optional: Show a confirmation or feedback
            // ScaffoldMessenger.of(context).showSnackBar(
            //   const SnackBar(content: Text('Refreshing all focus boards...')), // Updated text
            // );
          },
        ),
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
                          'Error loading Focus Boards: $error', // Updated text
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      CupertinoButton(
                        child: const Text('Retry'),
                        onPressed:
                            () =>
                            ref.invalidate(
                              focusInstancesProvider,
                            ), // Correct provider
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
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final instance = sortedInstances[index];
                    final isLast = index == sortedInstances.length - 1;

                    Widget tile = FocusInstanceTile(
                      // Correct widget
                      instance: instance,
                      onTap: () {
                        // Navigate to the detail screen using the nested navigator
                        // Update route path if necessary
                        Navigator.of(
                          context,
                        ).pushNamed('/focus/${instance.id}'); // Updated route path
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
                  }, childCount: sortedInstances.length),
                ),
              ),

            // --- Add New Instance Button ---
            SliverPadding(
              padding: const EdgeInsets.only(
                top: 10.0,
                bottom: 20.0,
              ), // Add padding
              sliver: SliverToBoxAdapter(
                child: Container(
                  color: CupertinoTheme.of(context).barBackgroundColor,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
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
                            'New Focus Board', // Updated text
                            style:
                                CupertinoTheme.of(context).textTheme.textStyle,
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
