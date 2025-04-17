import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'package:flutter/material.dart'; // Import Material for TabBar, ReorderableListView
import 'package:flutter_memos/models/workbench_instance.dart'; // Import WorkbenchInstance
import 'package:flutter_memos/providers/workbench_instances_provider.dart'; // Import instances provider
import 'package:flutter_memos/providers/workbench_provider.dart'; // Keep for activeWorkbenchProvider etc.
import 'package:flutter_memos/screens/item_detail/item_detail_screen.dart'; // Import ItemDetailScreen
import 'package:flutter_memos/screens/settings_screen.dart'; // Import SettingsScreen
import 'package:flutter_memos/screens/workbench/widgets/workbench_item_tile.dart';
// Import the new manager widget
import 'package:flutter_memos/screens/workbench/workbench_tab_controller_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Convert to ConsumerStatefulWidget
class WorkbenchScreen extends ConsumerStatefulWidget {
  const WorkbenchScreen({super.key});

  @override
  ConsumerState<WorkbenchScreen> createState() => _WorkbenchScreenState();
}

// Remove SingleTickerProviderStateMixin - vsync is now handled by the manager
class _WorkbenchScreenState extends ConsumerState<WorkbenchScreen> {
  final TextEditingController _instanceNameController = TextEditingController();
  // Remove the holder field
  // late final WorkbenchTabControllerHolder _holder;

  @override
  void initState() {
    super.initState();
    // Remove holder initialization
    // _holder = WorkbenchTabControllerHolder(ref, this);
  }

  @override
  void dispose() {
    // Remove holder disposal
    // _holder.dispose();
    _instanceNameController.dispose();
    super.dispose();
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

  void _showInstanceActions(WorkbenchInstance instance) {
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
    // Wrap the actual scaffold content with the manager widget.
    // Use a Builder to ensure _buildScaffold runs *after* the manager
    // is mounted and its initState has potentially scheduled the first publish.
    return WorkbenchTabControllerManager(
      child: Builder(builder: _buildScaffold),
    );
  }

  // Extracted scaffold build logic into a separate method
  // Note: This method now receives the context from the Builder.
  Widget _buildScaffold(BuildContext context) {
    // Watch necessary states
    final workbenchState = ref.watch(activeWorkbenchProvider);
    final instancesState = ref.watch(workbenchInstancesProvider);
    final instances = instancesState.instances;
    final activeInstanceId = instancesState.activeInstanceId;

    // Watch the TabController? from the StateProvider
    final TabController? tabCtrl = ref.watch(workbenchTabControllerProvider);

    // --- Handle null controller state (initial frame or after dispose) ---
    // This check is crucial as the manager might publish null during dispose/recreate.
    if (tabCtrl == null) {
      if (kDebugMode) {
        print(
          "[WorkbenchScreen._buildScaffold] TabController is null, showing loading indicator.",
        );
      }
      // Show a loading indicator while the controller is being initialized/recreated
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    // --- End null controller handling ---

    final items = workbenchState.items;
    final bool canRefresh =
        !workbenchState.isLoading && !workbenchState.isRefreshingDetails;

    final theme = CupertinoTheme.of(context);
    final primaryColor = theme.primaryColor;
    final inactiveColor = CupertinoColors.inactiveGray.resolveFrom(context);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
        context,
      ),
      navigationBar: CupertinoNavigationBar(
        middle: SizedBox(
          height: 32,
          child: Material(
            color: Colors.transparent,
            child: TabBar(
              // Use the controller obtained from the provider
              controller: tabCtrl, // Now guaranteed non-null here
              isScrollable: true,
              indicatorColor: primaryColor,
              labelColor: primaryColor,
              unselectedLabelColor: inactiveColor,
              tabs:
                  instances.isEmpty
                      ? [const Tab(text: 'Workbench')] // Placeholder tab
                      : [
                        for (final instance in instances)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onLongPress: () => _showInstanceActions(instance),
                            child: Tab(
                              child: Text(
                                instance.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
              // Disable taps if the list is empty (controller length is 1)
              // The controller's listener (_onTabChanged in manager) handles the logic
              // based on the actual instances list, so direct onTap disabling here might
              // be redundant or could conflict if not careful. The manager handles the
              // active instance update based on the tap.
              // onTap: instances.isEmpty ? (_) {} : null, // Keep original logic or rely on manager
            ),
          ),
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
        child: Builder(
          // Using Builder here is fine, context is already correct
          builder: (context) {
            // Loading/Error states for instances (unchanged logic)
            if (instancesState.isLoading && instances.isEmpty) {
              // Avoid showing loading if controller is also null (already handled above)
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
              // Avoid showing this if instances are also loading (handled above)
              if (!instancesState.isLoading || instances.isNotEmpty) {
                return const Center(child: CupertinoActivityIndicator());
              }
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
                              ref
                                  .read(activeWorkbenchNotifierProvider)
                                  .loadItems(),
                    ),
                  ],
                ),
              );
            }

            // Empty state messages (unchanged logic)
            if (instances.isEmpty && !instancesState.isLoading) {
              // This case might be less likely now with the manager ensuring a controller
              // of length 1, but keep the message for clarity.
              return const Center(
                child: Text(
                  'No Workbenches found.\nTap the + button to create one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: CupertinoColors.secondaryLabel),
                ),
              );
            }
            if (items.isEmpty &&
                !workbenchState.isLoading &&
                instances.isNotEmpty) {
              return const Center(
                child: Text(
                  'This Workbench is empty.\nAdd items via long-press or actions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: CupertinoColors.secondaryLabel),
                ),
              );
            }

            // Item List (unchanged logic)
            return Padding(
              padding: const EdgeInsets.only(
                bottom: 50.0,
              ), // Keep padding for FAB/bottom bar space
              child: ReorderableListView.builder(
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
                              (_) => ItemDetailScreen(
                                itemId: item.referencedItemId,
                              ),
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
          },
        ),
      ),
    );
  }
}
