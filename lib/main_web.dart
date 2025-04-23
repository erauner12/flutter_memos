import 'package:flutter/material.dart';
import 'package:flutter_memos/web_app_root.dart'; // Import the new web root
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  // Ensure Flutter bindings are initialized for async operations before runApp
  WidgetsFlutterBinding.ensureInitialized();
  // Use ProviderScope for Riverpod state management
  runApp(const ProviderScope(child: WebAppRoot()));
}
