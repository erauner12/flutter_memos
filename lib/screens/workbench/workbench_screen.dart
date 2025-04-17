import 'package:flutter/cupertino.dart';
// ADD selective import for Material widgets needed
import 'package:flutter/material.dart' show ReorderableListView;
import 'package:flutter_memos/models/workbench_instance.dart'; // Import WorkbenchInstance
// ADD import for WorkbenchItemReference
import 'package:flutter_memos/models/workbench_item_reference.dart';
import 'package:flutter_memos/providers/workbench_instances_provider.dart'; // Import instances provider
import 'package:flutter_memos/providers/workbench_provider.dart'; // Keep for activeWorkbenchProvider etc.
import 'package:flutter_memos/screens/item_detail/item_detail_screen.dart'; // Import ItemDetailScreen
import 'package:flutter_memos/screens/settings_screen.dart'; // Import SettingsScreen
import 'package:flutter_memos/screens/workbench/widgets/workbench_instance_selector.dart'; // Import the new selector
import 'package:flutter_memos/screens/workbench/widgets/workbench_item_tile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Convert to ConsumerStatefulWidget
class WorkbenchScreen extends ConsumerStatefulWidget {
  const WorkbenchScreen({super.key});

  @override
  ConsumerState<WorkbenchScreen> createState() => _WorkbenchScreenState();
}

// Removed SingleTickerProviderStateMixin
class WorkbenchScreenState extends ConsumerState<WorkbenchScreen> {
  final TextEditingController _instanceNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // No TabController initialization needed
  }

  @override
  void dispose() {
    _instanceNameController.dispose();
    super.dispose();
    // No TabController disposal needed
  }

  // --- Instance Management Dialogs (Unchanged logic) ---

  void _showAddInstanceDialog() {
    _instanceNameController.clear();
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
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
      ref.read(workbenchInstancesProvider.notifier).saveInstance(name);
    }
  }

  void _showRenameInstanceDialog(WorkbenchInstance instance) {
    _instanceNameController.text = instance.name;
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
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
        builder:
            (context) => CupertinoAlertDialog(
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
      builder:
          (context) => CupertinoAlertDialog(
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

  // Action sheet for Rename/Delete instance actions
  void showInstanceActions(WorkbenchInstance instance) {
    final instancesState = ref.read(workbenchInstancesProvider);
    final bool canDelete =
        instancesState.instances.length > 1 && !instance.isSystemDefault;

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
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

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    // Watch necessary states
    final workbenchState = ref.watch(activeWorkbenchProvider);
    final instancesState = ref.watch(workbenchInstancesProvider);
    // REMOVED unused local variable: final instances = instancesState.instances;
    final activeInstanceId = instancesState.activeInstanceId;

    final items = workbenchState.items;
    final bool canRefresh =
        !workbenchState.isLoading && !workbenchState.isRefreshingDetails;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
        context,
      ),
      navigationBar: CupertinoNavigationBar(
        middle: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400), // Keep constraint
          child: const WorkbenchInstanceSelector(), // Use the new widget
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.arrow_up_arrow_down),
          onPressed:
              () => ref.read(activeWorkbenchNotifierProvider).resetOrder(),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ellipsis button for instance actions (Rename/Delete)
            if (instancesState
                .instances
                .isNotEmpty) // Check instancesState directly
              CupertinoButton(
                padding: const EdgeInsets.only(left: 8.0),
                child: const Icon(CupertinoIcons.ellipsis_circle, size: 22),
                onPressed: () {
                  // Find the currently active instance object
                  final activeInstance = instancesState.instances.firstWhere(
                    (i) => i.id == activeInstanceId,
                    // Provide a fallback or handle error if not found (shouldn't happen in normal flow)
                    orElse: () => instancesState.instances.first,
                  );
                  showInstanceActions(activeInstance); // Updated call
                },
              ),
            CupertinoButton(
              padding: const EdgeInsets.only(left: 8.0),
              onPressed: _showAddInstanceDialog,
              child: const Icon(CupertinoIcons.add),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed:
                  canRefresh
                      ? () =>
                          ref
                              .read(activeWorkbenchNotifierProvider)
                              .refreshItemDetails()
                  : null,
              child:
                  canRefresh
                  ? const Icon(CupertinoIcons.refresh)
                  : const CupertinoActivityIndicator(radius: 10),
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.settings, size: 22),
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder:
                        (context) =>
                            const SettingsScreen(isInitialSetup: false),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: _buildBody(
          context,
          instancesState,
          workbenchState,
          items,
          activeInstanceId,
        ),
      ),
    );
  }

  // Extracted body build logic into a separate method for clarity
  Widget _buildBody(
    BuildContext context,
    WorkbenchInstancesState instancesState,
    WorkbenchState workbenchState,
    List<WorkbenchItemReference> items, // Type is now recognized
    String activeInstanceId,
  ) {
    // Use instancesState.instances directly where needed
    final instances = instancesState.instances;

    // Loading/Error states for instances (unchanged logic)
    if (instancesState.isLoading && instances.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (instancesState.error != null && instances.isEmpty) {
      return Center(
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
                'Error loading Workbenches: ${instancesState.error}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
            const SizedBox(height: 10),
            CupertinoButton(
              child: const Text('Retry'),
              onPressed:
                  () =>
                      ref
                          .read(workbenchInstancesProvider.notifier)
                          .loadInstances(),
            ),
          ],
        ),
      );
    }

    // Loading/Error states for active workbench items (unchanged logic)
    if (workbenchState.isLoading && items.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (workbenchState.error != null && items.isEmpty) {
      return Center(
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
                'Error loading items: ${workbenchState.error}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
            const SizedBox(height: 10),
            CupertinoButton(
              child: const Text('Retry'),
              onPressed:
                  () => ref.read(activeWorkbenchNotifierProvider).loadItems(),
            ),
          ],
        ),
      );
    }

    // Empty state messages (unchanged logic)
    if (instances.isEmpty && !instancesState.isLoading) {
      return const Center(
        child: Text(
          'No Workbenches found.\nTap the + button to create one.',
          textAlign: TextAlign.center,
          style: TextStyle(color: CupertinoColors.secondaryLabel),
        ),
      );
    }
    if (items.isEmpty && !workbenchState.isLoading && instances.isNotEmpty) {
      return const Center(
        child: Text(
          'This Workbench is empty.\nAdd items via long-press or actions.',
          textAlign: TextAlign.center,
          style: TextStyle(color: CupertinoColors.secondaryLabel),
        ),
      );
    }

    // Item List (Uses ReorderableListView which is now imported)
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 50.0,
      ), // Keep padding for FAB/bottom bar space
      child: ReorderableListView.builder(
        // Type is now recognized
        buildDefaultDragHandles:
            false, // Keep custom drag handles if used via tile
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return WorkbenchItemTile(
            key: ValueKey(item.id), // Use unique item ID for key
            itemReference: item,
            index: index, // Pass index for reorder handle
            onTap: () {
              // Update last opened item for the *currently active* instance
              ref
                  .read(workbenchInstancesProvider.notifier)
                  .setLastOpenedItem(activeInstanceId, item.id);
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder:
                      (_) => ItemDetailScreen(itemId: item.referencedItemId),
                ),
              );
            },
          );
        },
        onReorder: (oldIndex, newIndex) {
          ref
              .read(activeWorkbenchNotifierProvider)
              .reorderItems(oldIndex, newIndex);
        },
      ),
    );
  }
}
