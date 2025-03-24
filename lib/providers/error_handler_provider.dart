import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Error types for categorization
enum ErrorType {
  network,
  authentication,
  authorization,
  notFound,
  validation,
  server,
  unknown
}

/// Error data model for structured error handling
class ErrorData {
  final String message;
  final ErrorType type;
  final DateTime timestamp;
  final String? code;
  final StackTrace? stackTrace;
  final String? source;
  
  ErrorData({
    required this.message,
    required this.type,
    DateTime? timestamp,
    this.code,
    this.stackTrace,
    this.source,
  }) : timestamp = timestamp ?? DateTime.now();
  
  @override
  String toString() {
    return 'Error [$type${code != null ? ':$code' : ''}]: $message (from $source)';
  }
}

/// Provider that tracks the most recent error
final lastErrorProvider = StateProvider<ErrorData?>((ref) => null, name: 'lastError');

/// Provider that tracks error history
final errorHistoryProvider = StateProvider<List<ErrorData>>((ref) {
  return [];
}, name: 'errorHistory');

/// Provider for recording new errors
final errorHandlerProvider = Provider<void Function(
  String message, {
  ErrorType type,
  String? code,
  StackTrace? stackTrace,
  String? source,
})>((ref) {
  return (
    String message, {
    ErrorType type = ErrorType.unknown,
    String? code,
    StackTrace? stackTrace,
    String? source,
  }) {
    // Create the error data
    final error = ErrorData(
      message: message,
      type: type,
      code: code,
      stackTrace: stackTrace,
      source: source,
    );
    
    // Log the error
    if (kDebugMode) {
      print('[Error Handler] ${error.toString()}');
      if (stackTrace != null) {
        print(stackTrace);
      }
    }
    
    // Update the last error
    ref.read(lastErrorProvider.notifier).state = error;
    
    // Add to history, limiting size
    final history = ref.read(errorHistoryProvider);
    ref.read(errorHistoryProvider.notifier).state = [
      error,
      ...history.take(19), // Keep only the 20 most recent errors
    ];
  };
}, name: 'errorHandler');

/// Helper provider that categorizes errors automatically
final categorizeErrorProvider = Provider<ErrorType Function(dynamic error)>((ref) {
  return (dynamic error) {
    final message = error.toString().toLowerCase();
    
    if (message.contains('network') ||
        message.contains('connection') ||
        message.contains('timeout')) {
      return ErrorType.network;
    }
    
    if (message.contains('authentication') ||
        message.contains('login') ||
        message.contains('signin')) {
      return ErrorType.authentication;
    }
    
    if (message.contains('permission') ||
        message.contains('forbidden') ||
        message.contains('403')) {
      return ErrorType.authorization;
    }
    
    if (message.contains('not found') || message.contains('404')) {
      return ErrorType.notFound;
    }
    
    if (message.contains('validation') ||
        message.contains('invalid') ||
        message.contains('400')) {
      return ErrorType.validation;
    }
    
    if (message.contains('server') ||
        message.contains('500') ||
        message.contains('502') ||
        message.contains('503')) {
      return ErrorType.server;
    }
    
    return ErrorType.unknown;
  };
}, name: 'categorizeError');

/// Provider that listens for authentication errors and handles them
final authErrorHandlerProvider = Provider<void>((ref) {
  ref.listen<ErrorData?>(lastErrorProvider, (previous, current) {
    if (current?.type == ErrorType.authentication) {
      // Handle auth errors (e.g., clear credentials, redirect to login)
      if (kDebugMode) {
        print('[Auth Error Handler] Authentication error detected: ${current!.message}');
      }
      
      // In a real app, you would:
      // 1. Clear credentials
      // 2. Redirect to login screen
      // 3. Show a notification
    }
  });
  
  return;
}, name: 'authErrorHandler');
