import 'dart:async'; // Import for Future.microtask
import 'dart:math';

import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // Import for SchedulerBinding
import 'package:flutter_memos/models/workbench_instance.dart';
import 'package:flutter_memos/providers/workbench_instances_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages the lifecycle of the TabController for the WorkbenchScreen.
///
/// Listens to `workbenchInstancesProvider` and recreates the `TabController`
/// when the number of instances changes, or animates the index when the
/// active instance ID changes. It updates the `workbenchTabControllerProvider`
/// state whenever the controller is recreated or disposed.
class WorkbenchTabControllerHolder {
  final WidgetRef ref;
  final TickerProvider vsync;
  TabController? _controller;

  WorkbenchTabControllerHolder(this.ref, this.vsync) {
    final initialState = ref.read(workbenchInstancesProvider);
    _recreate(
      length: _calculateLength(initialState.instances),
      initialIndex: _indexFor(initialState.instances, initialState.activeInstanceId),
    );

    ref.listen<WorkbenchInstancesState>(
      workbenchInstancesProvider,
      _maybeRecreateOrAnimate,
    );
  }

  int _calculateLength(List<WorkbenchInstance> instances) {
    return instances.isEmpty ? 1 : instances.length;
  }

  int _indexFor(List<WorkbenchInstance> list, String id) {
    if (list.isEmpty) return 0;
    final i = list.indexWhere((w) => w.id == id);
    return (i < 0) ? 0 : i.clamp(0, max(0, list.length - 1));
  }

  void _maybeRecreateOrAnimate(
    WorkbenchInstancesState? prev,
    WorkbenchInstancesState next,
  ) {
    if (_controller == null) {
      if (kDebugMode) {
        print(
          "[WorkbenchTabControllerHolder] Controller was null during update. Recreating.",
        );
      }
      _recreate(
        length: _calculateLength(next.instances),
        initialIndex: _indexFor(next.instances, next.activeInstanceId),
      );
      return;
    }

    final requiredLen = _calculateLength(next.instances);
    final desiredIndex = _indexFor(next.instances, next.activeInstanceId);

    if (_controller!.length != requiredLen) {
      _recreate(length: requiredLen, initialIndex: desiredIndex);
      return;
    }

    if (!_controller!.indexIsChanging &&
        _controller!.index != desiredIndex &&
        desiredIndex >= 0 &&
        desiredIndex < _controller!.length) {
      _controller!.animateTo(desiredIndex);
    }
  }

  /// Helper to safely publish the controller state.
  void _safePublishController() {
    // Check if controller is still valid before publishing
    if (_controller != null) {
      ref.read(workbenchTabControllerProvider.notifier).state = _controller;
      if (kDebugMode) {
        print(
          "[WorkbenchTabControllerHolder] Safely published new TabController (length: ${_controller!.length}, index: ${_controller!.initialIndex})",
        );
      }
    } else if (kDebugMode) {
      print(
        "[WorkbenchTabControllerHolder] Attempted to publish null controller. Skipping.",
      );
    }
  }

  /// Disposes the old controller (if any) and creates/publishes a new one via the StateProvider,
  /// deferring the publication if called during a build phase.
  void _recreate({required int length, required int initialIndex}) {
    // 1. Dispose previous controller
    _controller?.removeListener(_onTabChanged);
    try {
      _controller?.dispose();
    } catch (e, s) {
      if (kDebugMode) {
        print("Error disposing previous TabController: $e\n$s");
      }
    }
    _controller = null; // Set internal field to null

    // 2. Create the new controller
    _controller = TabController(
      vsync: vsync,
      length: length,
      initialIndex: initialIndex.clamp(0, max(0, length - 1)),
    )..addListener(_onTabChanged);

    // 3. Publish the new controller state, deferring if necessary
    final currentPhase = SchedulerBinding.instance.schedulerPhase;
    if (currentPhase == SchedulerPhase.idle ||
        currentPhase == SchedulerPhase.postFrameCallbacks) {
      // Safe to publish immediately (e.g., called from listener callback)
      _safePublishController();
    } else {
      // Unsafe to publish during build/layout/paint phases. Defer.
      if (kDebugMode) {
        print(
          "[WorkbenchTabControllerHolder] Deferring controller publication (current phase: $currentPhase)",
        );
      }
      // Use microtask to schedule the update just after the current event loop task.
      Future.microtask(_safePublishController);
      // Alternatively, use addPostFrameCallback to schedule after the frame:
      // SchedulerBinding.instance.addPostFrameCallback((_) => _safePublishController());
    }
  }

  void _onTabChanged() {
    if (_controller == null || _controller!.indexIsChanging) return;

    final instances = ref.read(workbenchInstancesProvider).instances;
    if (instances.isNotEmpty && _controller!.index < instances.length) {
      final tappedId = instances[_controller!.index].id;
      if (ref.read(workbenchInstancesProvider).activeInstanceId != tappedId) {
        ref
            .read(workbenchInstancesProvider.notifier)
            .setActiveInstance(tappedId);
      }
    }
  }

  void dispose() {
    if (kDebugMode) {
      print("[WorkbenchTabControllerHolder] Disposing...");
    }
    // Listener is managed by ref.listen, no need to close manually
    _controller?.removeListener(_onTabChanged);
    _controller?.dispose();
    _controller = null;

    // Set the provider state back to null
    try {
      // Check if the provider is still active before trying to modify its state
      // This avoids errors if the provider was already disposed (e.g., due to autoDispose removal)
      // Note: Since we removed autoDispose, this check might be less critical, but still good practice.
      final notifier = ref.read(workbenchTabControllerProvider.notifier);
      // Check if the notifier's state itself is already null before setting it again
      if (notifier.state != null) {
        notifier.state = null;
      }
    } catch (e, s) {
      if (kDebugMode) {
        print(
          "[WorkbenchTabControllerHolder] Error setting provider state to null during dispose: $e\n$s",
        );
      }
    }
  }
}
