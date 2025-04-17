import 'dart:math'; // Import math for min() and max()

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Import Material for TabBar, ReorderableListView
import 'package:flutter_memos/models/workbench_instance.dart'; // Import WorkbenchInstance
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

// Add SingleTickerProviderStateMixin for TabController
class _WorkbenchScreenState extends ConsumerState<WorkbenchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _instanceNameController = TextEditingController();
  late TabController _tabController;
  // Re-introduce the ProviderSubscription
  late ProviderSubscription<WorkbenchInstancesState> _instancesSub;

  @override
  void initState() {
    super.initState();

    // --- Initialize Controller and Listener ---
    final bootstrap = ref.read(workbenchInstancesProvider);
    _tabController = TabController(
      // Initial length based on bootstrap state
      length: max(1, bootstrap.instances.length),
      vsync: this,
      // Initial index based on bootstrap state
      initialIndex: _indexFor(bootstrap.instances, bootstrap.activeInstanceId),
    )..addListener(_onTabChanged); // Add listener for UI -> Provider updates

    // --- Setup Provider Listener (Provider -> UI updates) ---
    _instancesSub = ref.listenManual<WorkbenchInstancesState>(
      workbenchInstancesProvider,
      (prev, next) {
        if (!mounted) return; // Guard against updates after dispose

        // Calculate required length and desired index from the *next* state
        final requiredLen = next.instances.isEmpty ? 1 : next.instances.length;
        final desiredIndex =
            next.instances.isEmpty
                ? 0 // Index is 0 if list becomes empty
                : _indexFor(next.instances, next.activeInstanceId);

        // --- Case 1: Length Changed ---
        if (requiredLen != _tabController.length) {
          // Use the dedicated helper to dispose old and create new controller
          _recreateTabController(
            length: requiredLen,
            desiredIndex: desiredIndex,
          );
          // Return early because recreate handles the index implicitly via initialIndex
          return;
        }

        // --- Case 2: Length Same, Index Might Have Changed ---
        // Check if animation is needed (and possible)
        if (!_tabController.indexIsChanging && // Not currently user-swiping
            desiredIndex != _tabController.index && // Index actually different
            desiredIndex >= 0 && // Desired index is valid
            desiredIndex <
                _tabController
                    .length // Desired index is within bounds
                    ) {
          _tabController.animateTo(desiredIndex);
        }
      },
      // Do not fire immediately; initState already configured the controller
      fireImmediately: false,
    );
    // --- End Listener Setup ---
  }

  // Helper to find the index for a given instance ID
  int _indexFor(List<WorkbenchInstance> list, String id) {
    if (list.isEmpty) return 0; // Index for the single placeholder tab
    final i = list.indexWhere((w) => w.id == id);
    // If ID not found (e.g., during deletion transition), default to 0 or clamp
    // Clamp to valid range [0, list.length - 1]
    return (i < 0) ? 0 : i.clamp(0, max(0, list.length - 1));
  }

  // Helper to build the initial TabController (REMOVED - logic moved to initState)
  // TabController _buildController(List<WorkbenchInstance> initialInstances) { ... }

  // Listener: TabController changes ➜ Update Provider (Unchanged)
  void _onTabChanged() {
    // Avoid updating provider during programmatic animation or rebuilds
    if (_tabController.indexIsChanging || !mounted) return;

    final instances = ref.read(workbenchInstancesProvider).instances;
    // Check bounds, especially for the zero-instance case
    if (instances.isNotEmpty && _tabController.index < instances.length) {
      final tappedId = instances[_tabController.index].id;
      // Only update if the ID actually changed
      if (ref.read(workbenchInstancesProvider).activeInstanceId != tappedId) {
        ref
            .read(workbenchInstancesProvider.notifier)
            .setActiveInstance(tappedId);
      }
    }
    // If instances is empty, do nothing as there's no valid ID to set
  }

  // New Helper: Safely recreates the TabController outside of build()
  void _recreateTabController({
    required int length,
    required int desiredIndex,
  }) {
    if (!mounted) return; // Guard

    // 1. Dispose old ticker *first*
    // Remove listener before disposing
    _tabController.removeListener(_onTabChanged);
    try {
      // Dispose might throw if called rapidly, though unlikely here
      _tabController.dispose();
    } catch (e, s) {
      print("Error disposing old TabController: $e\n$s");
      // Continue execution even if dispose fails
    }


    // 2. Create replacement
    _tabController = TabController(
      length: length,
      vsync: this, // `this` is the SingleTickerProviderStateMixin
      // Clamp desiredIndex to be safe, although listener logic should ensure validity
      initialIndex: desiredIndex.clamp(0, max(0, length - 1)),
    )..addListener(_onTabChanged); // Re-add listener

    // 3. Refresh the UI to use the new controller
    // Check mounted again before calling setState
    if (mounted) {
      setState(() {});
    }
  }


  // Old sync method (REMOVED)
  // void _ensureControllerSync(List<WorkbenchInstance> list, String activeId) { ... }

  @override
  void dispose() {
    // Close the Riverpod listener
    _instancesSub.close();
    // Remove listener and dispose the controller
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    // Dispose text controller
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
    // Watch necessary states
    final workbenchState = ref.watch(activeWorkbenchProvider);
    final instancesState = ref.watch(workbenchInstancesProvider);
    final instances = instancesState.instances;
    final activeInstanceId =
        instancesState.activeInstanceId; // Needed for item tap

    // --- REMOVE Controller Sync Call from build() ---
    // _ensureControllerSync(instances, activeInstanceId); // DELETED

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
              // Use the controller managed by initState/listener
              controller: _tabController,
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
              // Disable taps if the list is empty
              onTap: instances.isEmpty ? (_) {} : null,
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
          builder: (context) {
            // Loading/Error states (unchanged logic)
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

            // Active Workbench Content (unchanged logic)
            if (workbenchState.isLoading && items.isEmpty) {
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
              padding: const EdgeInsets.only(bottom: 50.0),
              child: ReorderableListView.builder(
                buildDefaultDragHandles: false,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return WorkbenchItemTile(
                    key: ValueKey(item.id),
                    itemReference: item,
                    index: index,
                    onTap: () {
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
