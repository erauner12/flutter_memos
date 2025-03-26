import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks the currently selected memo index for keyboard navigation
final selectedMemoIndexProvider = StateProvider<int>((ref) => -1);
