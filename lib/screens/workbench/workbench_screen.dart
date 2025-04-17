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
  late ProviderSubscription<WorkbenchInstancesState> _instancesSub;

  @override
  void initState() {
    super.initState();

    final initState = ref.read(workbenchInstancesProvider);
    _tabController = _buildController(initState);

    // A) controller ➜ provider
    _tabController.addListener(_onTabChanged);

    // B) provider ➜ controller (replaces the old _maybeNavigateToLastOpenedItem listener)
    _instancesSub = ref.listenManual<WorkbenchInstancesState>(
      workbenchInstancesProvider,
      _syncControllerFromProvider,
      fireImmediately: true, // Fire immediately to set initial state/controller
    );

    // Note: The _maybeNavigateToLastOpenedItem logic is no longer triggered by this listener
    // based on the provided plan. If that navigation is still needed, it would require
    // a different trigger mechanism or integration into the new sync logic.
  }

  // Helper to find the index for a given instance ID
  int _indexFor(List<WorkbenchInstance> list, String id) {
    if (list.isEmpty) return 0; // Should match the dummy controller index
    final i = list.indexWhere((w) => w.id == id);
    return (i < 0) ? 0 : i; // Default to first tab if ID not found
  }

  // Helper to build or rebuild the TabController
  TabController _buildController(WorkbenchInstancesState s) {
    // Handle zero instances case
    final length = s.instances.isEmpty ? 1 : s.instances.length;
    final initialIndex = _indexFor(s.instances, s.activeInstanceId);

    return TabController(
      length: length,
      vsync: this,
      // Ensure initialIndex is valid for the calculated length
      initialIndex: (initialIndex >= length) ? 0 : initialIndex,
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

  // Listener: Provider changes ➜ Update TabController
  void _syncControllerFromProvider(
    WorkbenchInstancesState? previous,
    WorkbenchInstancesState next,
  ) {
    if (!mounted) return;

    final previousLength =
        previous?.instances.length ?? (next.instances.isEmpty ? 1 : 0);
    final nextLength = next.instances.isEmpty ? 1 : next.instances.length;

    // Re-create controller when the *count* changes (or goes to/from zero)
    if (previous == null || previousLength != nextLength) {
      final oldController = _tabController;
      // Ensure the listener isn't called during dispose/rebuild
      oldController.removeListener(_onTabChanged);

      _tabController = _buildController(next);
      _tabController.addListener(_onTabChanged);

      // Dispose the old controller *after* the new one is ready and state is set
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Check again as this is async
          oldController.dispose();
        }
      });

      // Rebuild the widget tree to use the new controller
      setState(() {});
      return; // Exit early as controller was rebuilt
    }

    // If count is the same, just sync the active index
    final desiredIndex = _indexFor(next.instances, next.activeInstanceId);
    if (_tabController.index != desiredIndex &&
        desiredIndex < _tabController.length) {
      // Check if the controller is currently animating from user input
      if (!_tabController.indexIsChanging) {
        _tabController.animateTo(desiredIndex);
      }
    }
  }


  @override
  void dispose() {
    _instanceNameController.dispose();
    _instancesSub.close(); // Close the manual listener
    // Remove listener before disposing to prevent errors during dispose
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  // --- Instance Management Dialogs (Unchanged from original) ---

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
    // Check if deletion is allowed (not last instance and not system default)
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
    // Watch the instances state for the TabBar
    final instancesState = ref.watch(workbenchInstancesProvider);
    final instances = instancesState.instances;
    final activeInstanceId =
        instancesState.activeInstanceId; // Still needed for item tap logic

    final items = workbenchState.items;
    // Determine if refresh can be triggered for the *active* workbench
    final bool canRefresh =
        !workbenchState.isLoading && !workbenchState.isRefreshingDetails;

    // Get theme colors for TabBar styling
    final theme = CupertinoTheme.of(context);
    final primaryColor = theme.primaryColor;
    final inactiveColor = CupertinoColors.inactiveGray.resolveFrom(context);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
        context,
      ),
      navigationBar: CupertinoNavigationBar(
        // --- Replace middle with TabBar ---
        middle: SizedBox(
          height:
              32, // Keeps nav-bar height stable, similar to segmented control
          child: Material(
            // Required for TabBar ink effects and theme dependencies
            color:
                Colors
                    .transparent, // Blend with CupertinoNavigationBar background
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: primaryColor,
              labelColor: primaryColor,
              unselectedLabelColor: inactiveColor,
              // Use default indicator size and weight for Material look
              // indicatorSize: TabBarIndicatorSize.label, // Optional: make indicator smaller
              // indicatorWeight: 2.0,
              tabs:
                  instances.isEmpty
                      // Handle zero-instance case as per plan
                      ? [const Tab(text: 'Workbench')]
                      : [
                        for (final instance in instances)
                          // Wrap Tab with GestureDetector for long-press
                          GestureDetector(
                            // Use a Behavior to ensure hit testing works correctly within TabBar
                            behavior: HitTestBehavior.opaque,
                            onLongPress: () => _showInstanceActions(instance),
                            child: Tab(
                              // Apply ellipsis for long names automatically
                              child: Text(
                                instance.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
            ),
          ),
        ),
        // --- End TabBar replacement ---

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
        // Keep bottom SafeArea
        bottom: false, // Allow list to scroll behind potential home indicator
        child: Builder(
          builder: (context) {
            // Show loading indicator based on instance provider if instances are loading
            // AND the list is actually empty (or showing the dummy tab)
            if (instancesState.isLoading && instances.isEmpty) {
              return const Center(child: CupertinoActivityIndicator());
            }
            // Show error from instance provider if instances failed to load AND list is empty
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

            // --- Active Workbench Content (largely unchanged) ---

            // Show loading indicator based on the *active* workbench state
            if (workbenchState.isLoading && items.isEmpty) {
              // Avoid showing loading indicator if instances are also loading initially
              if (!instancesState.isLoading || instances.isNotEmpty) {
                return const Center(child: CupertinoActivityIndicator());
              }
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

            // Handle the case where there are instances, but the active one is empty
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

            // Handle the placeholder case when there are *zero* instances overall
            if (instances.isEmpty && !instancesState.isLoading) {
              return const Center(
                child: Text(
                  'No Workbenches found.\nTap the + button to create one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: CupertinoColors.secondaryLabel),
                ),
              );
            }


            // Use ReorderableListView with custom drag handles
            // Add padding to the bottom to avoid the home indicator/nav bar
            return Padding(
              padding: const EdgeInsets.only(bottom: 50.0), // Adjust as needed
              child: ReorderableListView.builder(
                buildDefaultDragHandles: false,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return WorkbenchItemTile(
                    key: ValueKey(item.id), // Use unique item ID for key
                    itemReference: item,
                    index: index,
                    onTap: () {
                      // Set last opened item when tapped
                      ref
                          .read(workbenchInstancesProvider.notifier)
                          .setLastOpenedItem(activeInstanceId, item.id);

                      // Navigate to detail screen
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder:
                              (_) => ItemDetailScreen(
                                itemId: item.referencedItemId,
                              ),
                        ),
                      );
                      // Note: The original _maybeNavigateToLastOpenedItem logic
                      // is not being called automatically on provider changes anymore.
                      // Navigation now happens explicitly on tap here and potentially
                      // needs re-evaluation if automatic navigation on instance switch
                      // is desired.
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
