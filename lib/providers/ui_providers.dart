import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for selected item ID (replacing index-based selection)
final selectedItemIdProvider = StateProvider<String?>(
  // Renamed from selectedMemoIdProvider
  (ref) => null,
  name: 'selectedItemIdProvider', // Renamed name
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

/// Toggle provider for the capture utility expansion state
final captureUtilityToggleProvider = StateProvider<bool>((ref) => false);

/// A method to toggle the capture utility state
void toggleCaptureUtility(WidgetRef ref) {
  ref.read(captureUtilityToggleProvider.notifier).state =
      !ref.read(captureUtilityToggleProvider);
}

/// Provider for item multi-select mode
final itemMultiSelectModeProvider = StateProvider<bool>(
  // Renamed from memoMultiSelectModeProvider
  (ref) => false,
  name: 'itemMultiSelectMode', // Renamed name
);

/// Provider for storing selected item IDs during multi-select
final selectedItemIdsForMultiSelectProvider = StateProvider<Set<String>>(
  // Renamed from selectedMemoIdsForMultiSelectProvider
  (ref) => {},
  name: 'selectedItemIdsForMultiSelect', // Renamed name
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
  // Renamed from toggleMemoMultiSelectModeProvider
  return () {
    // Read the current state
    final currentMode = ref.read(
      itemMultiSelectModeProvider,
    ); // Use renamed provider

    // Toggle to the opposite state
    final newMode = !currentMode;

    if (kDebugMode) {
      print(
        '[toggleItemMultiSelectModeProvider] Toggling from $currentMode to $newMode', // Updated log identifier
      );
    }

    // Update the mode
    ref.read(itemMultiSelectModeProvider.notifier).state =
        newMode; // Use renamed provider

    // If turning off multi-select mode, clear selections
    if (!newMode) {
      ref.read(selectedItemIdsForMultiSelectProvider.notifier).state =
          {}; // Use renamed provider
    }
  };
}, name: 'toggleItemMultiSelectMode'); // Renamed name

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
