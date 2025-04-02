import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier that provides a toggle signal for CaptureUtility
class CaptureUtilityToggleNotifier extends StateNotifier<int> {
  CaptureUtilityToggleNotifier() : super(0);

  void toggle() {
    state = state + 1; // Increment to signal a toggle request
    if (kDebugMode) {
      print(
        '[CaptureUtilityToggleNotifier] Toggle requested. New signal value: $state',
      );
    }
  }
}

/// Provider for toggling CaptureUtility expansion state
final captureUtilityToggleProvider =
    StateNotifierProvider<CaptureUtilityToggleNotifier, int>((ref) {
      return CaptureUtilityToggleNotifier();
    }, name: 'captureUtilityToggleProvider');

/// Tracks the currently selected memo index for keyboard navigation
final selectedMemoIndexProvider = StateProvider<int>((ref) {
  ref.listenSelf((previous, next) {
    if (kDebugMode) {
      print('[selectedMemoIndexProvider] Changed from $previous to $next');
    }
  });
  return -1;
});

/// Tracks the currently selected comment index for keyboard navigation in memo detail screen
final selectedCommentIndexProvider = StateProvider<int>((ref) {
  ref.listenSelf((previous, next) {
    if (kDebugMode) {
      print('[selectedCommentIndexProvider] Changed from $previous to $next');
    }
  });
  return -1;
}, name: 'selectedCommentIndexProvider');
