import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A provider observer that logs state changes for debugging purposes
class LoggingProviderObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      // Only log in debug mode
      final providerName = provider.name ?? provider.runtimeType.toString();
      print('[Provider Updated] $providerName');
      
      // For small values, print the entire value
      if (_isSimpleValue(newValue)) {
        print('  Value: $newValue');
      } else {
        // For complex objects, just print the type to avoid console clutter
        print('  Type: ${newValue.runtimeType}');
      }
      
      // Log if the value changed significantly
      if (_hasSignificantChange(previousValue, newValue)) {
        print('  Changed: true');
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
           value is DateTime ||
           (value is List && value.length < 5) ||
           (value is Map && value.length < 5);
  }
  
  /// Check if there's a significant change between values
  bool _hasSignificantChange(Object? previous, Object? current) {
    if (previous == null && current == null) return false;
    if (previous == null || current == null) return true;
    
    // For collections, check length changes as a simple heuristic
    if (previous is List && current is List) {
      return previous.length != current.length;
    }
    
    if (previous is Map && current is Map) {
      return previous.length != current.length;
    }
    
    return previous != current;
  }
}
