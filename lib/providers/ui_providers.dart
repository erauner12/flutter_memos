import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for selected memo ID (replacing index-based selection)
final selectedMemoIdProvider = StateProvider<String?>(
  (ref) => null,
  name: 'selectedMemoIdProvider',
);

/// Legacy provider for selected memo index (kept for backward compatibility)
/// This will be removed in a future update
@Deprecated('Use selectedMemoIdProvider instead for more robust selection')
final selectedMemoIndexProvider = StateProvider<int>(
  (ref) => -1,
  name: 'selectedMemoIndexProvider',
);

/// Provider for selected comment index
final selectedCommentIndexProvider = StateProvider<int>(
  (ref) => -1,
  name: 'selectedCommentIndexProvider',
);

/// Provider for the ID of a comment to highlight (e.g., from a deep link)
final highlightedCommentIdProvider = StateProvider<String?>(
  (ref) => null,
  name: 'highlightedCommentIdProvider',
);

/// Toggle provider for the capture utility expansion state
final captureUtilityToggleProvider = StateProvider<bool>((ref) => false);

/// A method to toggle the capture utility state
void toggleCaptureUtility(WidgetRef ref) {
  ref.read(captureUtilityToggleProvider.notifier).state =
      !ref.read(captureUtilityToggleProvider);
}

/// Provider for memo multi-select mode
final memoMultiSelectModeProvider = StateProvider<bool>(
  (ref) => false,
  name: 'memoMultiSelectMode',
);

/// Provider for storing selected memo IDs during multi-select
final selectedMemoIdsForMultiSelectProvider = StateProvider<Set<String>>(
  (ref) => {},
  name: 'selectedMemoIdsForMultiSelect',
);

/// Provider for comment multi-select mode
final commentMultiSelectModeProvider = StateProvider<bool>(
  (ref) => false,
  name: 'commentMultiSelectMode',
);

/// Provider for storing selected comment IDs during multi-select
/// Format: 'memoId/commentId'
final selectedCommentIdsForMultiSelectProvider = StateProvider<Set<String>>(
  (ref) => {},
  name: 'selectedCommentIdsForMultiSelect',
);

/// Provider for toggling memo multi-select mode
final toggleMemoMultiSelectModeProvider = Provider<void Function()>((ref) {
  return () {
    // Read the current state
    final currentMode = ref.read(memoMultiSelectModeProvider);
    
    // Toggle to the opposite state
    final newMode = !currentMode;
    
    if (kDebugMode) {
      print(
        '[toggleMemoMultiSelectModeProvider] Toggling from $currentMode to $newMode',
      );
    }

    // Update the mode
    ref.read(memoMultiSelectModeProvider.notifier).state = newMode;

    // If turning off multi-select mode, clear selections
    if (!newMode) {
      ref.read(selectedMemoIdsForMultiSelectProvider.notifier).state = {};
    }
  };
}, name: 'toggleMemoMultiSelectMode');

/// Provider for toggling comment multi-select mode
final toggleCommentMultiSelectModeProvider = Provider<void Function()>((ref) {
  return () {
    // Read the current state
    final currentMode = ref.read(commentMultiSelectModeProvider);
    
    // Toggle to the opposite state
    final newMode = !currentMode;
    
    if (kDebugMode) {
      print(
        '[toggleCommentMultiSelectModeProvider] Toggling from $currentMode to $newMode',
      );
    }

    // Update the mode
    ref.read(commentMultiSelectModeProvider.notifier).state = newMode;

    // If turning off multi-select mode, clear selections
    if (!newMode) {
      ref.read(selectedCommentIdsForMultiSelectProvider.notifier).state = {};
    }
  };
}, name: 'toggleCommentMultiSelectMode');
