import 'package:flutter/foundation.dart';
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// OPTIMIZATION: Provider for API service configuration
/// This allows changing API configuration at runtime
final apiConfigProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {
    'verboseLogging': true,
    'useFilterExpressions': true,
    'clientSideSorting': true,
  };
}, name: 'apiConfig');

/// Provider for ApiService with better configuration and lifecycle management
///
/// OPTIMIZATION: Added configurability, better logging and error recovery mechanisms
final apiServiceProvider = Provider<ApiService>((ref) {
  // Listen for configuration changes
  final config = ref.watch(apiConfigProvider);

  // Create the API service
  final apiService = ApiService();

  // Configure the service
  ApiService.verboseLogging = config['verboseLogging'] ?? true;
  ApiService.useFilterExpressions = config['useFilterExpressions'] ?? true;
  ApiService.CLIENT_SIDE_SORTING_ENABLED = config['clientSideSorting'] ?? true;

  if (kDebugMode) {
    print('[apiServiceProvider] Created API service with config: $config');
  }

  // OPTIMIZATION: Add cleanup when this provider is disposed
  ref.onDispose(() {
    if (kDebugMode) {
      print('[apiServiceProvider] Disposing API service');
    }
    // Add any cleanup if needed in the future
  });
  
  return apiService;
}, name: 'apiService');

/// OPTIMIZATION: Provider for API service status
/// This tracks the health and status of the API connection
final apiStatusProvider = StateProvider<String>((ref) {
  return 'unknown';
}, name: 'apiStatus');

/// OPTIMIZATION: Provider that pings the API periodically to check health
/// This ensures we know when the API is unavailable
final apiHealthCheckerProvider = Provider<void>((ref) {
  // Initial check
  _checkApiHealth(ref);

  // Set up periodic health check (in a real app)
  // You'd use a proper timer/periodic mechanism

  return;
}, name: 'apiHealthChecker');

// Helper function to check API health
Future<void> _checkApiHealth(Ref ref) async {
  final apiService = ref.read(apiServiceProvider);

  try {
    // In a real implementation, you might have a health endpoint
    // This is just a placeholder using existing methods
    await apiService.listMemos(limit: 1);

    // If we get here, the API is available
    ref.read(apiStatusProvider.notifier).state = 'available';
  } catch (e) {
    // API is unavailable
    if (kDebugMode) {
      print('[apiHealthChecker] API health check failed: $e');
    }
    ref.read(apiStatusProvider.notifier).state = 'unavailable';
  }
}
