import 'package:flutter_memos/utils/shared_prefs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lazily initialises and caches a singleton [SharedPrefsService].
final sharedPrefsServiceProvider = AutoDisposeFutureProvider<SharedPrefsService>((ref) async {
  // Always call the factory so that the class can manage the singleton internally.
  return SharedPrefsService.getInstance();
});
