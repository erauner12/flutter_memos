import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for selected item ID (replacing index-based selection)
final selectedItemIdProvider = StateProvider<String?>(
  (ref) => null,
  name: 'selectedItemIdProvider',
);

/// Legacy provider for selected memo index (kept for backward compatibility)
/// This will be removed in a future update
@Deprecated('Use selectedItemIdProvider instead for more robust selection')
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

/// Provider for the active workbench item ID
final activeWorkbenchItemIdProvider = StateProvider<String?>(
  (ref) => null,
  name: 'activeWorkbenchItemIdProvider',
);

/// Provider for the active comment ID
final activeCommentIdProvider = StateProvider<String?>(
  (ref) => null,
  name: 'activeCommentIdProvider',
);

/// Toggle provider for the capture utility expansion state
final captureUtilityToggleProvider = StateProvider<bool>((ref) => false);

/// A method to toggle the capture utility state
void toggleCaptureUtility(WidgetRef ref) {
  ref.read(captureUtilityToggleProvider.notifier).state =
      !ref.read(captureUtilityToggleProvider);
}

/// Provider for item multi-select mode
final itemMultiSelectModeProvider = StateProvider<bool>(
  (ref) => false,
  name: 'itemMultiSelectMode',
);

/// Provider for storing selected item IDs during multi-select
final selectedItemIdsForMultiSelectProvider = StateProvider<Set<String>>(
  (ref) => {},
  name: 'selectedItemIdsForMultiSelect',
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

/// Provider for toggling item multi-select mode
final toggleItemMultiSelectModeProvider = Provider<void Function()>((ref) {
  return () {
    // Read the current state
    final currentMode = ref.read(itemMultiSelectModeProvider);

    // Toggle to the opposite state
    final newMode = !currentMode;

    if (kDebugMode) {
      print(
        '[toggleItemMultiSelectModeProvider] Toggling from $currentMode to $newMode',
      );
    }

    // Update the mode
    ref.read(itemMultiSelectModeProvider.notifier).state = newMode;

    // If turning off multi-select mode, clear selections
    if (!newMode) {
      ref.read(selectedItemIdsForMultiSelectProvider.notifier).state = {};
    }
  };
}, name: 'toggleItemMultiSelectMode');

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
