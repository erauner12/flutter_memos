import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls whether the Chat Overlay is visible
final chatOverlayVisibleProvider = StateProvider<bool>((ref) => false, name: 'chatOverlayVisibleProvider');
