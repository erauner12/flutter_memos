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
    // 1. Create the initial controller
    _createController(ref.read(workbenchInstancesProvider));
    // 2. Schedule the first publish after the frame
    _safePublishController();

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
    // When the manager itself is disposed, publish null
    _disposeController(publishNull: true);
    super.dispose();
  }

  // ---------- controller helpers ----------

  /// Disposes the current controller.
  /// If [publishNull] is true, also sets the provider state to null.
  void _disposeController({bool publishNull = false}) {
    _controller?.removeListener(_onTabChanged);

    // Only publish null when the manager is permanently disposed
    if (publishNull && mounted) {
      try {
        ref.read(workbenchTabControllerProvider.notifier).state = null;
        if (kDebugMode) {
          print(
            "[WorkbenchTabControllerManager] Published null to provider during dispose.",
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print("Error setting workbenchTabControllerProvider to null in dispose: $e");
        }
      }
    }

    // Dispose the actual controller
    try {
      _controller?.dispose();
    } catch (e) {
      if (kDebugMode) {
        print("Error disposing TabController: $e");
      }
    }
    _controller = null;
  }

  /// Creates a new TabController instance based on the state.
  /// Does NOT publish the controller.
  void _createController(WorkbenchInstancesState state) {
    final len = max(1, state.instances.length);
    final idx = _indexFor(state.instances, state.activeInstanceId);

    _controller = TabController(
      vsync: this,
      length: len,
      initialIndex: idx,
    )..addListener(_onTabChanged);
    if (kDebugMode) {
      print(
        "[WorkbenchTabControllerManager] Created new controller (len: $len, idx: $idx)",
      );
    }
  }

  /// Replaces the existing controller with a new one atomically.
  /// Creates the new controller, publishes it, then disposes the old one.
  void _replaceController(WorkbenchInstancesState state) {
    final oldController =
        _controller; // 1. Keep reference to the old controller

    // 2. Create the new controller (updates `_controller` field)
    _createController(state);

    // 3. Publish the *new* controller (schedules for post-frame)
    _safePublishController();

    // 4. Dispose the old controller *after* creating and scheduling the publish
    //    Use a post-frame callback to ensure disposal happens after the new
    //    controller is potentially used in the next frame's build.
    if (oldController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          oldController.dispose();
          if (kDebugMode) {
            print(
              "[WorkbenchTabControllerManager] Disposed old controller (len: ${oldController.length}) after replacement.",
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print("Error disposing old TabController during replacement: $e");
          }
        }
      });
    }
  }


  int _indexFor(List<WorkbenchInstance> list, String id) {
    if (list.isEmpty) return 0;
    final i = list.indexWhere((w) => w.id == id);
    return (i < 0 ? 0 : i).clamp(0, max(0, list.length - 1));
  }


  void _maybeRecreateOrAnimate(
    WorkbenchInstancesState? prev,
    WorkbenchInstancesState next,
  ) {
    if (!mounted) return;

    final requiredLen = max(1, next.instances.length);

    // If controller doesn't exist or length changed, replace it atomically
    if (_controller == null || _controller!.length != requiredLen) {
      if (kDebugMode) {
        print(
          "[WorkbenchTabControllerManager] Length changed or controller null. Replacing controller.",
        );
      }
      _replaceController(next); // Use the atomic replacement method
      return;
    }

    // If length is the same, check if the active tab index needs animation
    final desired = _indexFor(next.instances, next.activeInstanceId);

    if (!_controller!.indexIsChanging &&
        desired != _controller!.index &&
        desired >= 0 &&
        desired < _controller!.length) {
      if (kDebugMode) {
        print("[WorkbenchTabControllerManager] Animating to index: $desired");
      }
      _controller!.animateTo(desired);
    }
  }


  void _onTabChanged() {
    if (!mounted || _controller == null || _controller!.indexIsChanging) return;

    final instancesState = ref.read(workbenchInstancesProvider);
    final instances = instancesState.instances;

    if (instances.isEmpty || _controller!.index >= instances.length) {
      return;
    }

    final tappedId = instances[_controller!.index].id;

    if (instancesState.activeInstanceId != tappedId) {
      ref.read(workbenchInstancesProvider.notifier).setActiveInstance(tappedId);
    }
  }


  // Publish the controller state after the current frame. Never publishes null.
  void _safePublishController() {
    if (!mounted) return;

    // Capture the controller *now* for the closure.
    final controllerToPublish = _controller;

    void publish() {
      // Check mounted status again inside the callback
      if (mounted) {
        // Only publish if the controller we captured is still the current one
        // and it's not null. This prevents publishing a stale controller if
        // multiple replacements happen rapidly.
        if (_controller == controllerToPublish && controllerToPublish != null) {
          if (kDebugMode) {
            print(
              '[WorkbenchTabControllerManager] Publishing controller '
              'len=${controllerToPublish.length}, index=${controllerToPublish.index}',
            );
          }
          ref.read(workbenchTabControllerProvider.notifier).state =
              controllerToPublish;
        } else if (kDebugMode) {
          print(
            '[WorkbenchTabControllerManager] Skipped publishing stale or null controller.',
          );
        }
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => publish());
  }


  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
