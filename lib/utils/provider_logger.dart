import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A simplified provider observer that logs state changes for debugging purposes
class LoggingProviderObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      print('[Provider Updated] ${provider.name ?? provider.runtimeType}');
      
      // For simple values, print the whole value
      if (_isSimpleValue(newValue)) {
        print('  Value: $newValue');
      }
    }
  }
  
  @override
  void didAddProvider(
    ProviderBase provider,
    Object? value,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      print('[Provider Added] ${provider.name ?? provider.runtimeType}');
    }
  }

  @override
  void didDisposeProvider(
    ProviderBase provider,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      print('[Provider Disposed] ${provider.name ?? provider.runtimeType}');
    }
  }
  
  /// Checks if a value is simple enough to print entirely
  bool _isSimpleValue(Object? value) {
    if (value == null) return true;
    return value is num ||
        value is String ||
        value is bool ||
        value is DateTime;
  }
}
