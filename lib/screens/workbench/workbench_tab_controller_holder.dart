import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_memos/models/workbench_instance.dart';
import 'package:flutter_memos/providers/workbench_instances_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages the lifecycle of the TabController for the WorkbenchScreen.
///
/// Listens to `workbenchInstancesProvider` and recreates the `TabController`
/// when the number of instances changes, or animates the index when the
/// active instance ID changes. It updates the `workbenchTabControllerProvider`
/// override whenever the controller is recreated.
class WorkbenchTabControllerHolder {
  final WidgetRef ref; // Use WidgetRef for direct access to container/overrides
  final TickerProvider vsync; // Provided by the hosting State widget
  TabController? _controller;
  ProviderSubscription<WorkbenchInstancesState>? _instancesSub;

  WorkbenchTabControllerHolder(this.ref, this.vsync) {
    // Get initial state to create the first controller
    final initialState = ref.read(workbenchInstancesProvider);
    _recreate(
      length: _calculateLength(initialState.instances),
      initialIndex: _indexFor(initialState.instances, initialState.activeInstanceId),
    );

    // Listen for subsequent changes in instances state
    _instancesSub = ref.listenManual<WorkbenchInstancesState>(
      workbenchInstancesProvider,
      _maybeRecreateOrAnimate,
      fireImmediately: false, // Already handled by initial _recreate
    );
  }

  // Helper to calculate the required length (min 1 for placeholder)
  int _calculateLength(List<WorkbenchInstance> instances) {
    return instances.isEmpty ? 1 : instances.length;
  }

  // Helper to find the correct index for an instance ID
  int _indexFor(List<WorkbenchInstance> list, String id) {
    if (list.isEmpty) return 0;
    final i = list.indexWhere((w) => w.id == id);
    // Clamp to valid range [0, list.length - 1]
    return (i < 0) ? 0 : i.clamp(0, max(0, list.length - 1));
  }

  /// Called when the workbenchInstancesProvider state changes.
  void _maybeRecreateOrAnimate(WorkbenchInstancesState? prev, WorkbenchInstancesState next) {
    if (_controller == null) {
      // Should not happen after initial _recreate, but handle defensively
      _recreate(
        length: _calculateLength(next.instances),
        initialIndex: _indexFor(next.instances, next.activeInstanceId),
      );
      return;
    }

    final requiredLen = _calculateLength(next.instances);
    final desiredIndex = _indexFor(next.instances, next.activeInstanceId);

    // --- Case 1: Length Changed ---
    if (_controller!.length != requiredLen) {
      _recreate(length: requiredLen, initialIndex: desiredIndex);
      return; // Index handled by _recreate's initialIndex
    }

    // --- Case 2: Length Same, Index Might Have Changed ---
    if (!_controller!.indexIsChanging &&
        _controller!.index != desiredIndex &&
        desiredIndex >= 0 && // Redundant check due to _indexFor clamping, but safe
        desiredIndex < _controller!.length) {
      _controller!.animateTo(desiredIndex);
    }
  }

  /// Disposes the old controller (if any) and creates/publishes a new one.
  void _recreate({required int length, required int initialIndex}) {
    // 1. Dispose previous controller *synchronously* before creating the new one
    _controller?.removeListener(_onTabChanged); // Remove listener first
    try {
      _controller?.dispose();
    } catch (e) {
      print("Error disposing previous TabController: $e");
    }

    // 2. Create the new controller
    _controller = TabController(
      vsync: vsync, // Use the TickerProvider from the State
      length: length,
      initialIndex: initialIndex.clamp(0, max(0, length - 1)), // Clamp index
    )..addListener(_onTabChanged); // Add listener for tab changes

    // 3. Publish the new controller by updating the provider override
    // This ensures consumers watching the provider get the new instance synchronously.
    // Access container via ref.container
    try {
       // Check if container is available (it should be unless disposed rapidly)
       if ((ref as Element).mounted) {
          ref.container.updateOverrides([
            workbenchTabControllerProvider.overrideWithValue(_controller!),
          ]);
       }
    } catch (e,s) {
        print("Error updating provider override: $e\n$s");
        // This might happen if the screen is disposed very quickly after an update.
    }

  }

  /// Listener attached to the TabController (Controller -> Provider).
  void _onTabChanged() {
    // Avoid updating provider during programmatic animation or rebuilds
    if (_controller == null || _controller!.indexIsChanging) return;

    final instances = ref.read(workbenchInstancesProvider).instances;
    // Check bounds, especially for the zero-instance case
    if (instances.isNotEmpty && _controller!.index < instances.length) {
      final tappedId = instances[_controller!.index].id;
      // Only update if the ID actually changed
      if (ref.read(workbenchInstancesProvider).activeInstanceId != tappedId) {
        ref
            .read(workbenchInstancesProvider.notifier)
            .setActiveInstance(tappedId);
      }
    }
    // If instances is empty, do nothing as there's no valid ID to set
  }

  /// Dispose the controller and clean up the listener subscription.
  void dispose() {
    _instancesSub?.close(); // Close the Riverpod listener
    _instancesSub = null;
    _controller?.removeListener(_onTabChanged);
    _controller?.dispose();
    _controller = null;
  }
}
