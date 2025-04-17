import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter/material.dart'; // Import Material for ReorderableListView
import 'package:flutter_memos/models/workbench_instance.dart'; // Import WorkbenchInstance
import 'package:flutter_memos/models/workbench_item_reference.dart';
import 'package:flutter_memos/providers/workbench_instances_provider.dart'; // Import instances provider
import 'package:flutter_memos/providers/workbench_provider.dart'; // Keep for activeWorkbenchProvider etc.
import 'package:flutter_memos/screens/item_detail/item_detail_screen.dart'; // Import ItemDetailScreen
import 'package:flutter_memos/screens/settings_screen.dart'; // Import SettingsScreen
import 'package:flutter_memos/screens/workbench/widgets/workbench_item_tile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Convert to ConsumerStatefulWidget
class WorkbenchScreen extends ConsumerStatefulWidget {
  const WorkbenchScreen({super.key});

  @override
  ConsumerState<WorkbenchScreen> createState() => _WorkbenchScreenState();
}

class _WorkbenchScreenState extends ConsumerState<WorkbenchScreen> {
  final TextEditingController _instanceNameController = TextEditingController();
  // Add ProviderSubscription for manual listener management
  late ProviderSubscription<WorkbenchInstancesState> _instancesSub;

  @override
  void initState() {
    super.initState();
    // Initialize the manual listener in initState
    _instancesSub = ref.listenManual<WorkbenchInstancesState>(
      workbenchInstancesProvider,
      _maybeNavigateToLastOpenedItem,
      fireImmediately: true, // Fire immediately to check initial state
    );
  }

  // Renamed and rewritten function to be the callback for listenManual
  void _maybeNavigateToLastOpenedItem(
    WorkbenchInstancesState? prev, // Previous state (can be null on first call)
    WorkbenchInstancesState next, // Current state
  ) {
    // Guard against navigating while loading or if widget is disposed
    if (!mounted || next.isLoading) return;

    final activeId = next.activeInstanceId;
    final lastId = next.lastOpenedItemId[activeId];
    if (lastId == null) return; // No last opened item for this instance

    // Read the *current* state of the active workbench items
    final wbState = ref.read(activeWorkbenchProvider);
    WorkbenchItemReference? item;
    try {
      item = wbState.items.firstWhere((i) => i.id == lastId);
    } catch (_) {
      // Item not found, do not navigate
      return;
    }

    // Perform navigation
    if (kDebugMode) {
      print(
        '[WorkbenchScreen] Navigating to last opened item $lastId (ref: ${item.referencedItemId}) for instance $activeId',
      );
    }
    // TODO: Determine item type correctly if needed for navigation
    // Currently ItemDetailScreen assumes Note type.
    Navigator.of(context)
        .push(
          CupertinoPageRoute(
            builder: (_) => ItemDetailScreen(itemId: item!.referencedItemId),
          ),
        )
        .then((_) {
          // Optional: Clear the last opened item for this instance after returning
          // ref.read(workbenchInstancesProvider.notifier).setLastOpenedItem(activeId, null);
        });
  }

  @override
  void dispose() {
    _instanceNameController.dispose();
    // Close the manual subscription when the widget is disposed
    _instancesSub.close();
    super.dispose();
  }

  // --- Instance Management Dialogs ---

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
    // Check if the dialog can be popped before popping
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context); // only close the dialog if it’s still there
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
    // Check if the dialog can be popped before popping (optional but good practice)
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
    // Double-check conditions preventing deletion
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
                  // Check if the dialog can be popped before popping
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
                    Navigator.pop(context); // Close action sheet
                    _showDeleteConfirmationDialog(instance);
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
    // Watch the active workbench state using the new provider
    final workbenchState = ref.watch(activeWorkbenchProvider);
    // Watch the instances state for the segmented control
    final instancesState = ref.watch(workbenchInstancesProvider);
    final instances = instancesState.instances;
    final activeInstanceId = instancesState.activeInstanceId;

    final items = workbenchState.items;
    // Determine if refresh can be triggered for the *active* workbench
    final bool canRefresh =
        !workbenchState.isLoading && !workbenchState.isRefreshingDetails;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
        context,
      ),
      navigationBar: CupertinoNavigationBar(
        // Use Segmented Control for instance selection if more than one instance
        middle:
            instances.length <= 1
                ? const Text('Workbench')
                : SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: CupertinoSlidingSegmentedControl<String>(
                      groupValue: activeInstanceId,
                      thumbColor: CupertinoTheme.of(context).primaryColor,
                      children: {
                        for (var instance in instances)
                          instance.id: GestureDetector(
                            onLongPress: () => _showInstanceActions(instance),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10.0,
                              ),
                              child: Text(
                                instance.name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color:
                                      activeInstanceId == instance.id
                                          ? CupertinoColors.white
                                          : CupertinoTheme.of(
                                            context,
                                          ).primaryColor,
                                ),
                              ),
                            ),
                          ),
                      },
                      onValueChanged: (String? newInstanceId) {
                        if (newInstanceId != null) {
                          ref
                              .read(workbenchInstancesProvider.notifier)
                              .setActiveInstance(newInstanceId);
                        }
                      },
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
            // Add Instance Button
            CupertinoButton(
              padding: const EdgeInsets.only(left: 8.0),
              onPressed: _showAddInstanceDialog,
              child: const Icon(CupertinoIcons.add),
            ),
            // Existing Refresh Button - uses active notifier
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
            // Existing Settings Button
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
        child: Builder(
          builder: (context) {
            // Show loading indicator based on instance provider if instances are loading
            if (instancesState.isLoading && instances.isEmpty) {
              return const Center(child: CupertinoActivityIndicator());
            }
            // Show error from instance provider if instances failed to load
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

            // Show loading indicator based on the *active* workbench state
            if (workbenchState.isLoading && items.isEmpty) {
              return const Center(child: CupertinoActivityIndicator());
            }

            // Show error from the *active* workbench state
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

            if (items.isEmpty && !workbenchState.isLoading) {
              return const Center(
                child: Text(
                  'This Workbench is empty.\nAdd items via long-press or actions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: CupertinoColors.secondaryLabel),
                ),
              );
            }

            // Use ReorderableListView with custom drag handles
            return ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return WorkbenchItemTile(
                  key: ValueKey(item.id),
                  itemReference: item,
                  index: index,
                  onTap: () {
                    // Set last opened item when tapped
                    ref
                        .read(workbenchInstancesProvider.notifier)
                        .setLastOpenedItem(activeInstanceId, item.id);
                    // Actual navigation is handled by the tile itself now
                  },
                );
              },
              onReorder: (oldIndex, newIndex) {
                ref
                    .read(activeWorkbenchNotifierProvider)
                    .reorderItems(oldIndex, newIndex);
              },
            );
          },
        ),
      ),
    );
  }
}
