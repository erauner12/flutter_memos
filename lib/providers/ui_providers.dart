import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks the currently selected memo index for keyboard navigation
final selectedMemoIndexProvider = StateProvider<int>((ref) {
  ref.listenSelf((previous, next) {
    if (kDebugMode) {
      print('[selectedMemoIndexProvider] Changed from $previous to $next');
    }
  });
  return -1;
});

/// Tracks the currently selected comment index in memo detail view
final selectedCommentIndexProvider = StateProvider<int>((ref) {
  ref.listenSelf((previous, next) {
    if (kDebugMode) {
      print('[selectedCommentIndexProvider] Changed from $previous to $next');
    }
  });
  return -1;
});
