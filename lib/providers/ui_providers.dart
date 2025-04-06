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
