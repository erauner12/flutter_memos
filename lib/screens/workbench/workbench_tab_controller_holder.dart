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
  // Use WidgetRef, provided by ConsumerStatefulWidget's State
  final WidgetRef ref;
  final TickerProvider vsync; // Provided by the hosting State widget
  TabController? _controller; // Internal controller instance
  ProviderSubscription<WorkbenchInstancesState>? _instancesSub;

  // Constructor now expects WidgetRef
  WorkbenchTabControllerHolder(this.ref, this.vsync) {
    // Get initial state to create the first controller
    final initialState = ref.read(workbenchInstancesProvider);
    _recreate(
      length: _calculateLength(initialState.instances),
      initialIndex: _indexFor(initialState.instances, initialState.activeInstanceId),
    );

    // Listen for subsequent changes using the standard listen API
    _instancesSub = ref.listen<WorkbenchInstancesState>(
      // Use listen instead of listenManual
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
      if (kDebugMode) {
        print("Error disposing previous TabController: $e\n$s");
      }
    }
    _controller = null;

    // 2. Create the new controller
    _controller = TabController(
      vsync: vsync,
      length: length,
      initialIndex: initialIndex.clamp(0, max(0, length - 1)),
    )..addListener(_onTabChanged);

    // 3. Publish the new controller by updating the StateProvider's state
    ref.read(workbenchTabControllerProvider.notifier).state = _controller;
    if (kDebugMode) {
      print(
        "[WorkbenchTabControllerHolder] Recreated and published new TabController (length: $length, index: $initialIndex)",
      );
    }
  }

  /// Listener attached to the TabController (Controller -> Provider).
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
    // It's safe to call read in dispose. No need for context/mounted checks here.
    try {
      ref.read(workbenchTabControllerProvider.notifier).state = null;
    } catch (e, s) {
      // Catch potential errors if the provider/notifier itself is already disposed (unlikely but possible)
      if (kDebugMode) {
        print(
          "[WorkbenchTabControllerHolder] Error setting provider state to null during dispose: $e\n$s",
        );
      }
    }
  }
}
