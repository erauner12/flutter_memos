import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/models/workbench_instance.dart';
import 'package:flutter_memos/providers/workbench_instances_provider.dart';
import 'package:flutter_memos/providers/workbench_provider.dart';
import 'package:flutter_memos/screens/settings_screen.dart';
import 'package:flutter_memos/screens/workbench/widgets/workbench_detail_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkbenchMainScreen extends ConsumerStatefulWidget {
  const WorkbenchMainScreen({super.key});

  @override
  ConsumerState<WorkbenchMainScreen> createState() => _WorkbenchMainScreenState();
}

class _WorkbenchMainScreenState extends ConsumerState<WorkbenchMainScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _instanceNameController = TextEditingController();
  final GlobalKey _detailAreaKey = GlobalKey(); // Key to find detail area position

  @override
  void dispose() {
    _scrollController.dispose();
    _instanceNameController.dispose();
    super.dispose();
  }

  // --- Instance Management Dialogs (Moved from WorkbenchScreenState) ---

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
           // Optionally scroll to bottom after creating and activating
           // Need to wait for state update and layout pass
           WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToDetailArea());
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

  // Action sheet for Rename/Delete instance actions (triggered by long-press on menu item)
  void showInstanceActions(WorkbenchInstance instance) {
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

  // --- Scrolling ---
  void _scrollToDetailArea() {
     // Ensure the detail area widget has rendered and has a size
    final RenderBox? detailBox = _detailAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (detailBox != null && _scrollController.hasClients) {
      final offset = _scrollController.position.maxScrollExtent; // Scroll to the end
      // Alternative: Calculate offset based on detailBox position if needed
      // final offset = _scrollController.offset + detailBox.localToGlobal(Offset.zero).dy - kToolbarHeight - MediaQuery.of(context).padding.top;

      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
       // Fallback or retry logic if needed
       WidgetsBinding.instance.addPostFrameCallback((_) {
         if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
         }
       });
    }
  }

  // --- Build Menu Item ---
  Widget _buildWorkbenchMenuItem({
    required BuildContext context, // Pass context
    required WorkbenchInstance instance,
    required bool isActive,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) {
    final theme = CupertinoTheme.of(context);
    return Container(
      color: theme.barBackgroundColor,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        onPressed: onTap,
        onLongPress: onLongPress, // Add long press handler
        child: Row(
          children: [
            Icon(
              isActive ? CupertinoIcons.square_list_fill : CupertinoIcons.square_list,
              color: isActive ? theme.primaryColor : CupertinoColors.secondaryLabel.resolveFrom(context),
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                instance.name,
                style: theme.textTheme.textStyle.copyWith(
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.forward,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final instancesState = ref.watch(workbenchInstancesProvider);
    final instances = instancesState.instances;
    final activeInstanceId = instancesState.activeInstanceId;
    final workbenchState = ref.watch(activeWorkbenchProvider); // Watch active state for refresh button

    final bool canRefresh = !workbenchState.isLoading && !workbenchState.isRefreshingDetails;

    // Define separator widget for reuse
    final separator = Container(
      height: 1,
      color: CupertinoColors.separator.resolveFrom(context),
      margin: const EdgeInsets.only(left: 54), // Indent separator
    );

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      navigationBar: CupertinoNavigationBar(
        middle: const Text("Workbenches"),
        // Prevent back button on root tab screen
        automaticallyImplyLeading: false,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
             CupertinoButton(
              padding: const EdgeInsets.only(left: 8.0),
              onPressed: _showAddInstanceDialog,
              child: const Icon(CupertinoIcons.add),
            ),
             CupertinoButton(
              padding: const EdgeInsets.only(left: 8.0),
              onPressed: canRefresh
                  ? () => ref.read(activeWorkbenchNotifierProvider).refreshItemDetails()
                  : null,
              child: canRefresh
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
                    builder: (context) => const SettingsScreen(isInitialSetup: false),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      child: SafeArea(
        // Use SafeArea to avoid notch/system areas
        bottom: false, // Allow content to go to bottom edge if needed
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // --- Loading/Error for Instances ---
            if (instancesState.isLoading && instances.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CupertinoActivityIndicator()),
              ),
            if (instancesState.error != null && instances.isEmpty)
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
                        onPressed: () => ref.read(workbenchInstancesProvider.notifier).loadInstances(),
                      ),
                    ],
                  ),
                ),
              ),

            // --- Top Menu Section (List of Workbenches) ---
            if (instances.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(vertical: 10.0), // Add some padding around the list
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final instance = instances[index];
                      final isActive = instance.id == activeInstanceId;
                      // Add separator logic
                      final isLast = index == instances.length - 1;
                      Widget item = _buildWorkbenchMenuItem(
                        context: context, // Pass context
                        instance: instance,
                        isActive: isActive,
                        onTap: () {
                          if (!isActive) {
                             ref.read(workbenchInstancesProvider.notifier).setActiveInstance(instance.id);
                          }
                          // Always scroll after tap
                          _scrollToDetailArea();
                        },
                        onLongPress: () => showInstanceActions(instance), // Add long press
                      );

                      if (!isLast) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [item, separator],
                        );
                      } else {
                        return item; // No separator after the last item
                      }
                    },
                    childCount: instances.length,
                  ),
                ),
              ),
            if (instances.isEmpty && !instancesState.isLoading)
              const SliverFillRemaining(
                 child: Center(
                   child: Text(
                     'No Workbenches found.\nTap the + button to create one.',
                     textAlign: TextAlign.center,
                     style: TextStyle(color: CupertinoColors.secondaryLabel),
                   ),
                 ),
               ),

            // --- Bottom "Detail" Section ---
            // Add a key to identify the start of the detail area for scrolling
             SliverToBoxAdapter(child: SizedBox(key: _detailAreaKey, height: 10)), // Spacer with key
            // Conditionally display detail view only if there are instances
            if (instances.isNotEmpty)
              const WorkbenchDetailView(),
          ],
        ),
      ),
    );
  }
}
