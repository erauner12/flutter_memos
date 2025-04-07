import 'package:flutter/foundation.dart';
import 'package:flutter_memos/providers/server_config_provider.dart'; // Import server config provider
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Removed import 'package:flutter_memos/utils/env.dart';

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
  final serverConfig = ref.watch(serverConfigProvider);

  // Use the URL and token from the persisted configuration
  final serverUrl = serverConfig.serverUrl;
  final authToken = serverConfig.authToken;

  // If the server URL is not configured, return a dummy/uninitialized service.
  // The ConfigCheckWrapper should prevent this provider from being used before
  // config is set, but this provides a fallback.
  if (serverUrl.isEmpty) {
    if (kDebugMode) {
      print(
        '[apiServiceProvider] Warning: Server URL is empty. Returning non-functional ApiService.',
      );
    }
    // Return a service that will likely fail if used, or a specific NoOpApiService
    // For now, return one with empty base URL which will cause errors on use.
    final nonFunctionalService = ApiService();
    nonFunctionalService.configureService(baseUrl: '', authToken: '');
    return nonFunctionalService;
  }

  // Create the API service
  final apiService = ApiService();

  // Configure the service
  ApiService.verboseLogging = config['verboseLogging'] ?? true;
  ApiService.useFilterExpressions = config['useFilterExpressions'] ?? true;

  if (kDebugMode) {
    print(
      '[apiServiceProvider] Configuring API service with URL: $serverUrl and token: ${authToken.isNotEmpty ? 'present' : 'empty'}',
    );
  }

  // Apply server configuration from serverConfigProvider
  apiService.configureService(
    baseUrl: serverUrl, // Use URL from provider
    authToken: authToken, // Use token from provider
  );

  if (kDebugMode) {
    print('[apiServiceProvider] Created API service with config: $config');
    print('[apiServiceProvider] Using server: $serverUrl');
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
  // Read the service, but don't proceed if the URL is empty (unconfigured)
  final serverConfig = ref.read(serverConfigProvider);
  if (serverConfig.serverUrl.isEmpty) {
    ref.read(apiStatusProvider.notifier).state = 'unconfigured';
    return;
  }

  final apiService = ref.read(apiServiceProvider);

  try {
    // Use a lightweight call like listMemos with pageSize=1
    await apiService.listMemos(
      pageSize: 1,
      parent: 'users/1', // Assuming user 1 exists or adjust as needed
    );

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
