import 'package:flutter/material.dart';
// Assuming BlinkoWebAppRoot might be renamed or adapted later.
// For now, keep the import structure but acknowledge the app name change.
// If BlinkoWebAppRoot contains the app title, it should also be updated there.
import 'package:flutter_memos/blinko_web_app_root.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  // Ensure Flutter bindings are initialized for async operations before runApp
  WidgetsFlutterBinding.ensureInitialized();
  // Use ProviderScope for Riverpod state management
  // The title inside BlinkoWebAppRoot might need changing too.
  runApp(const ProviderScope(child: BlinkoWebAppRoot()));
}
