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
  // *** Watch the active server config ***
  final activeServerConfig = ref.watch(activeServerConfigProvider);

  // Use the URL and token from the persisted configuration
  final serverUrl =
      activeServerConfig?.serverUrl ?? ''; // Get from active config
  final authToken =
      activeServerConfig?.authToken ?? ''; // Get from active config
  final serverName =
      activeServerConfig?.name ??
      activeServerConfig?.id ??
      'none'; // For logging

  // If the server URL is not configured, return a dummy/uninitialized service.
  // The ConfigCheckWrapper should prevent this provider from being used before
  // config is set, but this provides a fallback.
  if (serverUrl.isEmpty) {
    if (kDebugMode) {
      print(
        '[apiServiceProvider] Warning: No active server configured. Returning non-functional ApiService.',
      );
    }
    // Return a service that will likely fail if used, or a specific NoOpApiService
    // For now, return one with empty base URL which will cause errors on use.
    final nonFunctionalService = ApiService();
    // Avoid configuring with empty string if it causes issues, maybe return a specific null/error state?
    // For now, configure with empty to match previous behavior in this state.
    nonFunctionalService.configureService(baseUrl: '', authToken: '');
    return nonFunctionalService;
  }

  // Create the API service (using singleton pattern internally)
  final apiService = ApiService();

  // Configure the service
  ApiService.verboseLogging = config['verboseLogging'] ?? true;
  ApiService.useFilterExpressions = config['useFilterExpressions'] ?? true;

  if (kDebugMode) {
    print(
      '[apiServiceProvider] Configuring API service for active server: "$serverName" (URL: $serverUrl, Token: ${authToken.isNotEmpty ? 'present' : 'empty'})',
    );
  }

  // Apply server configuration from activeServerConfigProvider
  // This will re-initialize the internal client if URL/token changes
  apiService.configureService(
    baseUrl: serverUrl, // Use URL from active config
    authToken: authToken, // Use token from active config
  );

  if (kDebugMode) {
    print(
      '[apiServiceProvider] API service configured for server: $serverName',
    );
    // print('[apiServiceProvider] Using server: $serverUrl'); // Redundant log
  }

  // OPTIMIZATION: Add cleanup when this provider is disposed
  ref.onDispose(() {
    if (kDebugMode) {
      print(
        '[apiServiceProvider] Disposing API service provider (ApiService instance itself is a singleton)',
      );
    }
    // Add any cleanup if needed in the future (e.g., closing connections if ApiService managed them)
  });

  return apiService;
}, name: 'apiService');

// --- apiStatusProvider and apiHealthCheckerProvider need updates ---

/// OPTIMIZATION: Provider for API service status
/// This tracks the health and status of the API connection for the *active* server
final apiStatusProvider = StateProvider<String>((ref) {
  // Initial state depends on whether an active server exists
  final activeConfig = ref.watch(activeServerConfigProvider);
  return activeConfig == null ? 'unconfigured' : 'unknown';
}, name: 'apiStatus');


/// OPTIMIZATION: Provider that pings the API periodically to check health
/// This ensures we know when the API is unavailable for the *active* server
final apiHealthCheckerProvider = Provider<void>((ref) {
  // Rerun health check when the active server changes
  ref.watch(activeServerConfigProvider);

  // Initial check
  _checkApiHealth(ref);

  // TODO: Set up periodic health check (e.g., using Timer.periodic)
  // Consider cancelling the timer in onDispose

  ref.onDispose(() {
    // Cancel timer here
  });

  return;
}, name: 'apiHealthChecker');

// Helper function to check API health for the *active* server
Future<void> _checkApiHealth(Ref ref) async {
  // Read the active config
  final activeConfig = ref.read(activeServerConfigProvider);
  if (activeConfig == null || activeConfig.serverUrl.isEmpty) {
    ref.read(apiStatusProvider.notifier).state = 'unconfigured';
    return;
  }

  // Get the API service configured for the active server
  final apiService = ref.read(apiServiceProvider);
  // Ensure the service is functional (base URL is set)
  if (apiService.apiBaseUrl.isEmpty) {
    ref.read(apiStatusProvider.notifier).state = 'unconfigured';
    return;
  }

  // Set status to checking
  ref.read(apiStatusProvider.notifier).state = 'checking';

  try {
    // Use a lightweight call like listMemos with pageSize=1
    // TODO: Replace 'users/1' with a more robust check if possible (e.g., get workspace settings)
    await apiService.listMemos(
      pageSize: 1,
      parent: 'users/1', // Assuming user 1 exists or adjust as needed
    );

    // If we get here, the API is available
    // Check if the status is still 'checking' before updating to 'available'
    // This prevents race conditions if the active server changes during the check
    if (ref.read(apiStatusProvider) == 'checking') {
      ref.read(apiStatusProvider.notifier).state = 'available';
    }
  } catch (e) {
    // API is unavailable
    if (kDebugMode) {
      print(
        '[apiHealthChecker] API health check failed for ${activeConfig.name ?? activeConfig.id}: $e',
      );
    }
    if (ref.read(apiStatusProvider) == 'checking') {
      ref.read(apiStatusProvider.notifier).state = 'unavailable';
    }
  }
}
