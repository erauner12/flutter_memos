import 'dart:math'; // Import math for min()

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
  // Remove the ProviderSubscription, as the build method now handles sync
  // late ProviderSubscription<WorkbenchInstancesState> _instancesSub;

  @override
  void initState() {
    super.initState();

    final init = ref.read(workbenchInstancesProvider);
    // Build initial controller - length might be adjusted immediately by _ensureControllerSync
    _tabController = _buildController(init.instances);

    // A) controller ➜ provider
    _tabController.addListener(_onTabChanged);

    // B) provider ➜ controller (Now handled by _ensureControllerSync in build)
    // Remove the listener setup
    // _instancesSub = ref.listenManual<WorkbenchInstancesState>(
    //   workbenchInstancesProvider,
    //   _syncControllerFromProvider, // This listener will be removed/simplified
    //   fireImmediately: true,
    // );

    // Call initial sync right after creating the first controller
    // Use WidgetsBinding to ensure the first frame is built before sync
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _ensureControllerSync(init.instances, init.activeInstanceId);
      }
    });
  }

  // Helper to find the index for a given instance ID
  int _indexFor(List<WorkbenchInstance> list, String id) {
    if (list.isEmpty) return 0; // Index for the single placeholder tab
    final i = list.indexWhere((w) => w.id == id);
    // If ID not found (e.g., during deletion transition), default to 0 or clamp
    return (i < 0) ? 0 : i;
  }

  // Helper to build the initial TabController
  // Length will be managed by _ensureControllerSync after this initial build
  TabController _buildController(List<WorkbenchInstance> initialInstances) {
    // During initState, use max(1, length) to handle the empty case initially.
    // _ensureControllerSync will take over management immediately after.
    final length = max(1, initialInstances.length);
    // Initial index calculation needs the *actual* list, not the potentially faked length=1
    final initialIndex = _indexFor(
      initialInstances,
      ref.read(workbenchInstancesProvider).activeInstanceId,
    );

    return TabController(
      length: length,
      vsync: this,
      // Ensure initialIndex is valid for the calculated length
      initialIndex: min(initialIndex, length - 1),
    );
  }

  // Listener: TabController changes ➜ Update Provider
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

  // New method: Ensures TabController length and index match the provider state
  void _ensureControllerSync(List<WorkbenchInstance> list, String activeId) {
    if (!mounted) return; // Ensure widget is still mounted

    final requiredLen = list.isEmpty ? 1 : list.length;

    // --- 1. Sync Length ---
    if (_tabController.length != requiredLen) {
      // Store old index before disposing
      final oldIndex = _tabController.index;
      _tabController.removeListener(_onTabChanged);

      // Calculate new index, clamped to the new length
      // If list becomes empty, index must be 0. Otherwise, keep old index if valid, else clamp.
      final newIndex = list.isEmpty ? 0 : min(oldIndex, requiredLen - 1);

      // Dispose the old controller *before* creating the new one
      // Note: Disposing immediately might cause issues if accessed in the same frame.
      // Consider deferring dispose if problems arise, but usually okay.
      try {
        _tabController.dispose();
      } catch (e) {
        // Log error if dispose fails, but continue
        print("Error disposing old TabController: $e");
      }

      // Create the new controller
      _tabController = TabController(
        length: requiredLen,
        vsync: this,
        initialIndex: newIndex, // Use the calculated new index
      )..addListener(_onTabChanged);

      // Request a rebuild to use the new controller
      // Use addPostFrameCallback to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }

    // --- 2. Sync Index (only if length didn't change, or after length sync) ---
    // Find the desired index based on the activeId
    final desiredIndex = list.isEmpty ? 0 : _indexFor(list, activeId);

    // Check if index needs animation
    if (!_tabController
            .indexIsChanging && // Not currently animating (user swipe)
        desiredIndex >= 0 && // Desired index is valid
        desiredIndex <
            _tabController.length && // Desired index is within bounds
        _tabController.index !=
            desiredIndex // Current index is different
            ) {
      // Use addPostFrameCallback to ensure animation starts after build/layout
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_tabController.indexIsChanging) {
          // Check mounted and animation status again
          _tabController.animateTo(desiredIndex);
        }
      });
    }
  }


  // Listener: Provider changes ➜ Update TabController (Simplified / Removed)
  // This listener is no longer needed as _ensureControllerSync called from build() handles everything.
  // Keeping it might cause redundant updates or conflicts.
  /*
  void _syncControllerFromProvider(
    WorkbenchInstancesState? previous,
    WorkbenchInstancesState next,
  ) {
    // Logic moved to _ensureControllerSync called from build()
  }
  */

  @override
  void dispose() {
    _instanceNameController.dispose();
    // _instancesSub.close(); // Close the manual listener - REMOVED
    // Remove listener before disposing to prevent errors during dispose
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  // --- Instance Management Dialogs (Unchanged logic, just formatting) ---

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

  // Shows the confirmation dialog *before* calling deleteInstance
  void _showDeleteConfirmationDialog(WorkbenchInstance instance) {
    // This dialog is already implemented and calls deleteInstance on confirmation.
    // No changes needed here based on the roadmap, just ensuring it's called correctly.
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
                  // Call the notifier method which handles CloudKit deletion etc.
                  ref
                      .read(workbenchInstancesProvider.notifier)
                      .deleteInstance(instance.id);
                },
              ),
            ],
          ),
    );
  }

  // Action sheet shown on long-press
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
              // --- Add Delete Button ---
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
              // --- End Add Delete Button ---
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
    // Watch the active workbench state using the active workbench provider
    final workbenchState = ref.watch(activeWorkbenchProvider);
    // Watch the instances state for the TabBar and controller sync
    final instancesState = ref.watch(workbenchInstancesProvider);
    final instances = instancesState.instances;
    final activeInstanceId = instancesState.activeInstanceId;

    // --- Call _ensureControllerSync before building the TabBar ---
    // This guarantees the controller's length and index are correct *before* TabBar uses it.
    _ensureControllerSync(instances, activeInstanceId);
    // --- End Controller Sync Call ---

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
              controller: _tabController, // Use the synced controller
              isScrollable: true,
              indicatorColor: primaryColor,
              labelColor: primaryColor,
              unselectedLabelColor: inactiveColor,
              tabs:
                  instances.isEmpty
                      // Show a single, non-interactive placeholder tab when empty
                      ? [const Tab(text: 'Workbench')]
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
              // Disable taps if the list is empty (controller length is 1 but no real instances)
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
            // Loading/Error states based on *instances* provider first
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

            // --- Active Workbench Content ---
            // Loading/Error states based on the *active* workbench provider
            if (workbenchState.isLoading && items.isEmpty) {
              // Avoid double indicator if instances are also loading
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

            // Empty state messages
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

            // --- Item List ---
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
