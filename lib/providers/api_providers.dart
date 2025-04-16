import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/server_config.dart'; // Import ServerType
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/providers/settings_provider.dart';
// Import BaseApiService and concrete implementations
import 'package:flutter_memos/services/base_api_service.dart';
import 'package:flutter_memos/services/blinko_api_service.dart'; // Import Blinko service
import 'package:flutter_memos/services/memos_api_service.dart'; // Renamed to MemosApiService
// Keep other service imports
import 'package:flutter_memos/services/minimal_openai_service.dart';
import 'package:flutter_memos/services/todoist_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// OPTIMIZATION: Provider for API service configuration
final apiConfigProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {
    'verboseLogging': true,
    // Remove Memos-specific flags if not applicable to Blinko or handle differently
    // 'useFilterExpressions': true,
    // 'clientSideSorting': true,
  };
}, name: 'apiConfig');

/// Provider for the active API Service (either Memos or Blinko)
/// Returns the BaseApiService interface.
final apiServiceProvider = Provider<BaseApiService>((ref) {
  // OPTIMIZATION: Directly watch multiServerConfigProvider to get the latest state
  final multiServerState = ref.watch(multiServerConfigProvider);
  final activeId = multiServerState.activeServerId;
  final config = ref.watch(apiConfigProvider); // General config like logging

  // Get the active config directly from the latest state's servers list
  final activeServerConfig =
      activeId == null
          ? null
          : multiServerState.servers.firstWhereOrNull((s) => s.id == activeId);

  // *** ADD DETAILED LOGGING HERE ***
  if (kDebugMode) {
    if (activeServerConfig != null) {
      // Log the entire object using its toString() and the type directly
      print(
        '[apiServiceProvider] Found activeServerConfig object: ${activeServerConfig.toString()}',
      );
      print(
        '[apiServiceProvider] Directly accessing activeServerConfig.serverType: ${activeServerConfig.serverType.name}',
      );
    } else {
      print('[apiServiceProvider] activeServerConfig is null.');
    }
  }
  // *** END ADDED LOGGING ***

  if (activeServerConfig == null) {
    if (kDebugMode) {
      print(
        '[apiServiceProvider] Warning: No active server configured. Returning DummyApiService.',
      );
    }
    return DummyApiService();
  }

  // Handle Todoist potentially having an empty URL, but require a token
  if (activeServerConfig.serverType != ServerType.todoist &&
      activeServerConfig.serverUrl.isEmpty) {
    if (kDebugMode) {
      print(
        '[apiServiceProvider] Warning: Active server (${activeServerConfig.serverType.name}) URL is empty. Returning DummyApiService.',
      );
    }
    // Return a non-functional dummy service to avoid null errors downstream
    return DummyApiService();
  }

  final serverUrl = activeServerConfig.serverUrl; // Might be empty for Todoist
  final authToken =
      activeServerConfig.authToken; // Use the token from the active config
  // Get the type *after* logging the object
  final serverType = activeServerConfig.serverType;

  // *** ADD MORE SPECIFIC LOGGING HERE ***
  if (kDebugMode) {
    // Log the variable derived from the object
    print(
      '[apiServiceProvider] Variable serverType before switch: ${serverType.name}',
    );
    print(
      '[apiServiceProvider] Auth Token from activeServerConfig: ${authToken.isNotEmpty ? 'Present' : 'EMPTY'}',
    );
  }
  // *** END ADDED LOGGING ***

  BaseApiService service; // Use the abstract type

  switch (serverType) {
    case ServerType.memos:
      // *** ADD LOGGING INSIDE CASE ***
      if (kDebugMode) {
        print('[apiServiceProvider] Switch case: Matched ServerType.memos');
      }
      // *** END ADDED LOGGING ***
      final memosService =
          MemosApiService(); // Use concrete type for instantiation
      // Configure MemosApiService
      MemosApiService.verboseLogging = config['verboseLogging'] ?? true;
      // MemosApiService.useFilterExpressions = config['useFilterExpressions'] ?? true; // Memos specific
      memosService.configureService(baseUrl: serverUrl, authToken: authToken);
      service = memosService;
      break;
    case ServerType.blinko:
      // *** ADD LOGGING INSIDE CASE ***
      if (kDebugMode) {
        print('[apiServiceProvider] Switch case: Matched ServerType.blinko');
      }
      // *** END ADDED LOGGING ***
      final blinkoService =
          BlinkoApiService(); // Use concrete type for instantiation
      // Configure BlinkoApiService
      BlinkoApiService.verboseLogging =
          config['verboseLogging'] ?? true; // Blinko specific or shared
      blinkoService.configureService(baseUrl: serverUrl, authToken: authToken);
      service = blinkoService;
      break;
    case ServerType.todoist:
      if (kDebugMode) {
        print('[apiServiceProvider] Switch case: Matched ServerType.todoist');
      }
      // *** CHANGE HERE: Instantiate and configure TodoistApiService directly ***
      final todoistService = TodoistApiService(); // Get the singleton instance
      TodoistApiService.verboseLogging = config['verboseLogging'] ?? true;

      // Check if the authToken (API Key for Todoist) from the active config is valid
      if (authToken.isEmpty) {
        if (kDebugMode) {
          print(
            '[apiServiceProvider] Warning: Active Todoist config has an empty API key (authToken). Returning DummyApiService.',
          );
        }
        service =
            DummyApiService(); // Return dummy if key is missing in the config
      } else {
        // Configure the service instance. baseUrl is ignored by TodoistApiService.
        // Use await since configureService is async now (though not strictly needed here as we don't wait)
        // The configureService method itself handles the async setup internally.
        todoistService.configureService(baseUrl: '', authToken: authToken);
        if (kDebugMode) {
          print(
            '[apiServiceProvider] Configured Todoist service instance using token from active ServerConfig.',
          );
        }
        // Assign the configured instance
        // TodoistApiService implements TaskApiService which extends BaseApiService
        service = todoistService;
      }
      break;
    // No default needed if all enum cases are handled. Add if ServerType might expand.
    // default:
    //   print('[apiServiceProvider] Error: Unsupported server type: $serverType');
    //   service = DummyApiService();
  }

  if (kDebugMode) {
    print(
      '[apiServiceProvider] Configured ${serverType.name} service for server: ${activeServerConfig.name ?? activeServerConfig.id}',
    );
    print(
      '[apiServiceProvider] Returning service of type: ${service.runtimeType}',
    );
  }

  ref.onDispose(() {
    if (kDebugMode) {
      // Use a local copy of serverType because activeServerConfig might change before disposal
      final disposedServerType = activeServerConfig.serverType;
      print(
        '[apiServiceProvider] Disposing API service provider for ${disposedServerType.name}',
      );
      // Add any cleanup specific to the service type if needed
    }
  });

  return service; // Return the abstract type
}, name: 'apiService');

// --- apiStatusProvider and apiHealthCheckerProvider need updates ---

/// Provider for API service status (tracks the active server's health)
final apiStatusProvider = StateProvider<String>((ref) {
  final activeConfig = ref.watch(activeServerConfigProvider);
  return activeConfig == null ? 'unconfigured' : 'unknown';
}, name: 'apiStatus');

/// Provider that pings the active API periodically to check health
final apiHealthCheckerProvider = Provider<void>((ref) {
  ref.watch(activeServerConfigProvider); // Rerun on server change
  _checkApiHealth(ref); // Initial check
  // TODO: Add Timer.periodic for regular checks
  ref.onDispose(() {
    /* Cancel timer */
  });
  return;
}, name: 'apiHealthChecker');

// Helper function to check API health for the *active* server
Future<void> _checkApiHealth(Ref ref) async {
  final activeConfig = ref.read(activeServerConfigProvider);

  // No active config? Status is unconfigured.
  if (activeConfig == null) {
    if (ref.read(apiStatusProvider) != 'unconfigured') {
      ref.read(apiStatusProvider.notifier).state = 'unconfigured';
    }
    return;
  }

  // Get the correctly configured service (Memos, Blinko, or Todoist) via the main provider
  // This now correctly handles Todoist configuration using the active config's token.
  final apiService = ref.read(apiServiceProvider);

  // Check if the service is actually configured (not the DummyApiService)
  // This covers cases where URL/token is missing for Memos/Blinko,
  // or the token is missing in the active Todoist config.
  if (!apiService.isConfigured || apiService is DummyApiService) {
    if (ref.read(apiStatusProvider) != 'unconfigured') {
      ref.read(apiStatusProvider.notifier).state = 'unconfigured';
      if (kDebugMode) {
        print(
          '[apiHealthChecker] Setting status to unconfigured because apiService is Dummy or not configured.',
        );
      }
    }
    return;
  }

  // Proceed with health check for the configured service
  final currentStatus = ref.read(apiStatusProvider);
  if (currentStatus == 'checking') return;
  ref.read(apiStatusProvider.notifier).state = 'checking';

  try {
    // Call the checkHealth method defined in BaseApiService
    final isHealthy = await apiService.checkHealth();

    // Check if config is still the same before updating state
    final potentiallyChangedConfig = ref.read(activeServerConfigProvider);
    if (potentiallyChangedConfig?.id == activeConfig.id &&
        ref.read(apiStatusProvider) == 'checking') {
      ref.read(apiStatusProvider.notifier).state =
          isHealthy ? 'available' : 'unavailable';
      if (kDebugMode) {
        print(
          '[apiHealthChecker] Health check for ${activeConfig.name ?? activeConfig.id} (${activeConfig.serverType.name}): ${isHealthy ? 'Available' : 'Unavailable'}',
        );
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print(
        '[apiHealthChecker] API health check failed for ${activeConfig.name ?? activeConfig.id}: $e',
      );
    }
    // Check if config is still the same before updating state
    final potentiallyChangedConfig = ref.read(activeServerConfigProvider);
    if (potentiallyChangedConfig?.id == activeConfig.id &&
        ref.read(apiStatusProvider) == 'checking') {
      ref.read(apiStatusProvider.notifier).state = 'unavailable'; // Or 'error'
    }
  }
}


// --- Todoist API Providers (Keep as is - Used for Settings/Integrations Check) ---
/// Provider for Todoist API service (primarily for settings check)
final todoistApiServiceProvider = Provider<TodoistApiService>((ref) {
  // Configuration from apiConfigProvider if needed
  final config = ref.watch(apiConfigProvider);
  // Watch the persisted API key from settings_provider (GLOBAL key)
  final todoistToken = ref.watch(todoistApiKeyProvider);

  // Create and configure the Todoist API service using the GLOBAL key
  final todoistApiService = TodoistApiService(); // Get singleton
  TodoistApiService.verboseLogging = config['verboseLogging'] ?? true;

  if (todoistToken.isEmpty) {
    if (kDebugMode) {
      print(
        '[todoistApiServiceProvider] Warning: No GLOBAL Todoist API token configured via provider.',
      );
    }
    // Return unconfigured service
    todoistApiService.configureService(baseUrl: '', authToken: '');
  } else {
    // Configure with the GLOBAL token
    todoistApiService.configureService(baseUrl: '', authToken: todoistToken);
    if (kDebugMode) {
      print(
        '[todoistApiServiceProvider] Todoist API service configured successfully via GLOBAL provider.',
      );
    }
  }

  // Add cleanup if needed
  ref.onDispose(() {
    if (kDebugMode) {
      print(
        '[todoistApiServiceProvider] Disposing Todoist API service provider (for global key)',
      );
    }
  });

  return todoistApiService;
}, name: 'todoistApiService');

/// Provider for Todoist API service status (based on GLOBAL key)
final todoistApiStatusProvider = StateProvider<String>((ref) {
  // Initial state depends on whether the GLOBAL token is configured
  final token = ref.watch(
    todoistApiKeyProvider,
  ); // Watch the GLOBAL key provider
  return token.isEmpty ? 'unconfigured' : 'unknown';
}, name: 'todoistApiStatus');

/// Provider that checks Todoist API health periodically (using GLOBAL key)
final todoistApiHealthCheckerProvider = Provider<void>((ref) {
  // Rerun health check when the GLOBAL API key changes
  ref.watch(todoistApiKeyProvider);
  // Initial check
  _checkTodoistApiHealth(ref);

  // TODO: Set up periodic health check

  ref.onDispose(() {
    // Cancel any timers or other resources
  });

  return;
}, name: 'todoistApiHealthChecker');

// Helper function to check Todoist API health (using GLOBAL key via todoistApiServiceProvider)
Future<void> _checkTodoistApiHealth(Ref ref) async {
  // Get the service instance configured with the GLOBAL key.
  final todoistApiService = ref.read(todoistApiServiceProvider);

  // If the service isn't configured (no GLOBAL token), set status and return.
  if (!todoistApiService.isConfigured) {
    if (ref.read(todoistApiStatusProvider) != 'unconfigured') {
      ref.read(todoistApiStatusProvider.notifier).state = 'unconfigured';
    }
    return;
  }

  // Set status to checking
  final currentStatus = ref.read(todoistApiStatusProvider);
  if (currentStatus == 'checking') return; // Already checking
  ref.read(todoistApiStatusProvider.notifier).state = 'checking';

  try {
    // Call the health check method on the service instance (using GLOBAL key)
    final isHealthy = await todoistApiService.checkHealth();

    if (ref.read(todoistApiStatusProvider) == 'checking') {
      ref.read(todoistApiStatusProvider.notifier).state =
          isHealthy ? 'available' : 'unavailable';
    }
  } catch (e) {
    if (kDebugMode) {
      print('[todoistApiHealthChecker] Error checking health (global key): $e');
    }
    if (ref.read(todoistApiStatusProvider) == 'checking') {
      ref.read(todoistApiStatusProvider.notifier).state =
          'error'; // Or 'unavailable'
    }
  }
}


// --- OpenAI API Providers (Keep as is) ---

/// Provider for OpenAI API service
final openaiApiServiceProvider = Provider<MinimalOpenAiService>((ref) {
  // Configuration from apiConfigProvider if needed
  final config = ref.watch(apiConfigProvider);
  // Watch the persisted API key from settings_provider
  final openaiToken = ref.watch(openAiApiKeyProvider);

  // Get the singleton instance
  final openaiApiService = MinimalOpenAiService();
  MinimalOpenAiService.verboseLogging = config['verboseLogging'] ?? true;

  if (openaiToken.isEmpty) {
    if (kDebugMode) {
      print(
        '[openaiApiServiceProvider] Warning: No OpenAI API token configured via provider.',
      );
    }
    // Configure with empty token (service handles initialization state)
    // MinimalOpenAiService likely only needs authToken
    openaiApiService.configureService(authToken: '');
  } else {
    // MinimalOpenAiService likely only needs authToken
    openaiApiService.configureService(authToken: openaiToken);
    if (kDebugMode) {
      print(
        '[openaiApiServiceProvider] OpenAI API service configured successfully via provider.',
      );
    }
  }

  // Add cleanup if needed
  ref.onDispose(() {
    if (kDebugMode) {
      print(
        '[openaiApiServiceProvider] Disposing OpenAI API service provider (singleton instance persists)',
      );
    }
    // Optionally close the client when provider is disposed
    // openaiApiService.dispose();
  });

  return openaiApiService;
}, name: 'openaiApiService');

/// Provider for OpenAI API service status (available, unavailable, etc.)
final openaiApiStatusProvider = StateProvider<String>((ref) {
  // Initial state depends on whether the token is configured via the provider
  final token = ref.watch(openAiApiKeyProvider); // Watch the key provider
  return token.isEmpty ? 'unconfigured' : 'unknown';
}, name: 'openaiApiStatus');

/// Provider that checks OpenAI API health periodically
final openaiApiHealthCheckerProvider = Provider<void>((ref) {
  // Rerun health check when the API key changes
  ref.watch(openAiApiKeyProvider);
  // Initial check
  _checkOpenAiApiHealth(ref);

  // TODO: Set up periodic health check

  ref.onDispose(() {
    // Cancel any timers or other resources
  });

  return;
}, name: 'openaiApiHealthChecker');

// Helper function to check OpenAI API health
Future<void> _checkOpenAiApiHealth(Ref ref) async {
  // Get the service instance. Configuration is handled by the provider watching the key.
  final openaiApiService = ref.read(openaiApiServiceProvider);

  // If the service isn't configured (no token), set status and return.
  if (!openaiApiService.isConfigured) {
    if (ref.read(openaiApiStatusProvider) != 'unconfigured') {
      ref.read(openaiApiStatusProvider.notifier).state = 'unconfigured';
    }
    return;
  }

  // Set status to checking
  final currentStatus = ref.read(openaiApiStatusProvider);
  if (currentStatus == 'checking') return; // Already checking
  ref.read(openaiApiStatusProvider.notifier).state = 'checking';

  try {
    // Call the health check method on the service instance
    final isHealthy = await openaiApiService.checkHealth();

    // Check if the status is still 'checking' before updating
    if (ref.read(openaiApiStatusProvider) == 'checking') {
      if (isHealthy) {
        ref.read(openaiApiStatusProvider.notifier).state = 'available';
      } else {
        // If checkHealth returns false, it likely means an API error (e.g., bad token)
        ref.read(openaiApiStatusProvider.notifier).state = 'unavailable';
      }
    }
  } catch (e) {
    // Catch any exceptions during the health check (e.g., network error)
    if (kDebugMode) {
      print('[openaiApiHealthChecker] Error checking health: $e');
    }
    if (ref.read(openaiApiStatusProvider) == 'checking') {
      ref.read(openaiApiStatusProvider.notifier).state =
          'error'; // Or 'unavailable'
    }
  }
}
