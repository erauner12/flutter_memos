import 'dart:math';

import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'package:flutter/material.dart';
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
  // Use Ref directly, no need for WidgetRef specifically here
  final Ref ref;
  final TickerProvider vsync; // Provided by the hosting State widget
  TabController? _controller; // Internal controller instance
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
    // Read the current controller state from the provider *if needed*,
    // but _controller internal field should be the source of truth here.
    // final currentControllerFromProvider = ref.read(workbenchTabControllerProvider);
    // assert(currentControllerFromProvider == _controller); // Should match

    if (_controller == null) {
      // This might happen if dispose was called just before a state update.
      // Recreate if necessary based on the 'next' state.
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

    // --- Case 1: Length Changed ---
    if (_controller!.length != requiredLen) {
      _recreate(length: requiredLen, initialIndex: desiredIndex);
      return; // Index handled by _recreate's initialIndex
    }

    // --- Case 2: Length Same, Index Might Have Changed ---
    if (!_controller!.indexIsChanging &&
        _controller!.index != desiredIndex &&
        desiredIndex >= 0 &&
        desiredIndex < _controller!.length) {
      // Animate the existing controller
      _controller!.animateTo(desiredIndex);
    }
  }

  /// Disposes the old controller (if any) and creates/publishes a new one via the StateProvider.
  void _recreate({required int length, required int initialIndex}) {
    // 1. Dispose previous controller *synchronously*
    _controller?.removeListener(_onTabChanged);
    try {
      _controller?.dispose();
    } catch (e, s) {
      // Use kDebugMode for printing
      if (kDebugMode) {
        print("Error disposing previous TabController: $e\n$s");
      }
    }
    // Set internal field to null temporarily
    _controller = null;
    // Also update provider state to null briefly, might help avoid race conditions
    // although the synchronous update below should be sufficient.
    // ref.read(workbenchTabControllerProvider.notifier).state = null;

    // 2. Create the new controller
    _controller = TabController(
      vsync: vsync,
      length: length,
      initialIndex: initialIndex.clamp(0, max(0, length - 1)),
    )..addListener(_onTabChanged);

    // 3. Publish the new controller by updating the StateProvider's state
    // Use read() for synchronous update within the same microtask.
    ref.read(workbenchTabControllerProvider.notifier).state = _controller;
    if (kDebugMode) {
      print(
        "[WorkbenchTabControllerHolder] Recreated and published new TabController (length: $length, index: $initialIndex)",
      );
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
  }

  /// Dispose the controller and clean up the listener subscription.
  /// Also sets the provider state back to null.
  void dispose() {
    if (kDebugMode) {
      print("[WorkbenchTabControllerHolder] Disposing...");
    }
    _instancesSub?.close();
    _instancesSub = null;
    _controller?.removeListener(_onTabChanged);
    _controller?.dispose();
    _controller = null;

    // Set the provider state to null upon disposal
    // Use read() as we are outside a build context. Check if ref is still valid.
    try {
      // Check if the element associated with ref is still mounted before reading.
      // This avoids errors if dispose is called after the widget is removed.
      if ((ref as ProviderRef).context.mounted) {
        ref.read(workbenchTabControllerProvider.notifier).state = null;
      }
    } catch (e, s) {
      // Catch potential errors if the ref/context is already invalid during dispose.
      if (kDebugMode) {
        print(
          "[WorkbenchTabControllerHolder] Error setting provider state to null during dispose: $e\n$s",
        );
      }
    }
  }
}
