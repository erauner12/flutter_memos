import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/workbench_instance.dart';
import '../../providers/workbench_instances_provider.dart';

/// Invisible widget that keeps a [TabController] in sync with
/// [workbenchInstancesProvider] and publishes it through
/// [workbenchTabControllerProvider].
///
/// Place it high in the Workbench subtree; it simply renders [child].
class WorkbenchTabControllerManager extends ConsumerStatefulWidget {
  const WorkbenchTabControllerManager({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<WorkbenchTabControllerManager> createState() =>
      _WorkbenchTabControllerManagerState();
}

class _WorkbenchTabControllerManagerState
    extends ConsumerState<WorkbenchTabControllerManager>
    with SingleTickerProviderStateMixin {
  TabController? _controller;
  ProviderSubscription<WorkbenchInstancesState>? _sub;

  // ---------- life‑cycle ----------
  @override
  void initState() {
    super.initState();
    _createControllerFrom(ref.read(workbenchInstancesProvider));

    // Manual subscription is required here because initState
    // runs outside the build phase.
    _sub = ref.listenManual<WorkbenchInstancesState>(
      workbenchInstancesProvider,
      _maybeRecreateOrAnimate,
    );
  }

  @override
  void dispose() {
    _sub?.close();
    _disposeController();
    super.dispose();
  }

  // ---------- controller helpers ----------
  void _disposeController() {
    _controller?.removeListener(_onTabChanged);
    // Check if mounted before accessing ref in dispose, although read should be safe.
    // It's generally safer to avoid async gaps or complex logic in dispose.
    // Setting provider state might be better handled slightly differently if complex cleanup is needed,
    // but for nulling it out, this is usually acceptable.
    if (mounted) {
      try {
        // Ensure the provider hasn't been disposed itself if using autoDispose (though it's not here)
        ref.read(workbenchTabControllerProvider.notifier).state = null;
      } catch (e) {
        // Handle potential errors if the provider/notifier is somehow inaccessible
        if (kDebugMode) {
          print("Error setting workbenchTabControllerProvider to null in dispose: $e");
        }
      }
    }
    // Dispose the controller *after* potentially notifying consumers it's gone.
    _controller?.dispose();
    _controller = null;
  }


  void _createControllerFrom(WorkbenchInstancesState state) {
    final len = max(1, state.instances.length);
    final idx = _indexFor(state.instances, state.activeInstanceId);

    _controller = TabController(
      vsync: this,
      length: len,
      initialIndex: idx,
    )..addListener(_onTabChanged);

    _safePublishController();
  }

  int _indexFor(List<WorkbenchInstance> list, String id) {
    if (list.isEmpty) return 0;
    final i = list.indexWhere((w) => w.id == id);
    // Clamp the index to be within the valid range [0, length-1]
    // max(0, list.length - 1) handles the empty list case correctly returning 0.
    return (i < 0 ? 0 : i).clamp(0, max(0, list.length - 1));
  }


  void _maybeRecreateOrAnimate(
    WorkbenchInstancesState? prev,
    WorkbenchInstancesState next,
  ) {
    // Ensure widget is still mounted before proceeding
    if (!mounted) return;

    final requiredLen = max(1, next.instances.length);

    // Recreate if controller doesn't exist OR if the length requirement changed
    if (_controller == null || _controller!.length != requiredLen) {
      _disposeController(); // Dispose old one first
      _createControllerFrom(next); // Create and schedule publish new one
      return;
    }

    // If length is the same, check if the active tab index needs animation
    final desired = _indexFor(next.instances, next.activeInstanceId);

    // Animate only if:
    // 1. The controller is not already changing index (mid-swipe/animation)
    // 2. The desired index is different from the current index
    // 3. The desired index is valid within the controller's bounds
    if (!_controller!.indexIsChanging &&
        desired != _controller!.index &&
        desired >= 0 && // Redundant due to clamp in _indexFor, but safe
        desired < _controller!.length) {
      _controller!.animateTo(desired);
    }
  }


  void _onTabChanged() {
    // Ensure widget is mounted and controller exists
    if (!mounted || _controller == null) return;

    // Only react when the tab change is finalized (not during animation/swipe)
    if (_controller!.indexIsChanging) return;

    final instancesState = ref.read(workbenchInstancesProvider);
    final instances = instancesState.instances;

    // Check if instances list is valid for the current index
    if (instances.isEmpty || _controller!.index >= instances.length) {
      // This might happen briefly if instances change while tab is changing.
      // Or if the list is empty (length 1 controller, index 0).
      // In the empty case, there's no ID to set.
      return;
    }

    final tappedId = instances[_controller!.index].id;

    // Update the active instance ID in the provider only if it's different
    if (instancesState.activeInstanceId != tappedId) {
      ref.read(workbenchInstancesProvider.notifier).setActiveInstance(tappedId);
    }
  }


  // Publish the controller state after the current frame.
  void _safePublishController() {
    // Ensure widget is mounted before scheduling the callback
    if (!mounted) return;

    void publish() {
      // Double-check mounted status inside the callback
      if (mounted) {
        // Optional instrumentation
        assert(
          _controller != null,
          'Controller should not be null when publishing',
        );
        if (kDebugMode) {
          print(
            '[WorkbenchTabControllerManager] Publishing controller '
            'len=${_controller!.length}, index=${_controller!.index}',
          );
        }
        // Actual publication
        ref.read(workbenchTabControllerProvider.notifier).state = _controller;
      }
    }

    // Always wait until *after* the current frame has completed so that
    //   1. the provider has been lazily instantiated by the first `ref.watch`
    //   2. any widgets that rely on the value are already mounted
    WidgetsBinding.instance.addPostFrameCallback((_) => publish());
  }


  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    // This widget is purely for management and doesn't render anything itself,
    // it just passes through its child.
    return widget.child;
  }
}
