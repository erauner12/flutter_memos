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

  if (activeServerConfig == null || activeServerConfig.serverUrl.isEmpty) {
    if (kDebugMode) {
      print(
        '[apiServiceProvider] Warning: No active server configured or URL is empty. Returning DummyApiService.',
      );
    }
    // Return a non-functional dummy service to avoid null errors downstream
    return DummyApiService();
  }

  final serverUrl = activeServerConfig.serverUrl;
  final authToken = activeServerConfig.authToken;
  // Get the type *after* logging the object
  final serverType = activeServerConfig.serverType;

  // *** ADD MORE SPECIFIC LOGGING HERE ***
  if (kDebugMode) {
    // Log the variable derived from the object
    print(
      '[apiServiceProvider] Variable serverType before switch: ${serverType.name}',
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
      // Todoist service uses a global API key from settings, not the server config's authToken.
      // We get the globally configured instance.
      final todoistService = ref.watch(todoistApiServiceProvider);
      if (!todoistService.isConfigured) {
        if (kDebugMode) {
          print(
            '[apiServiceProvider] Warning: Todoist selected but API key not configured in settings.',
          );
        }
        // Return a dummy service to prevent errors, although UI should ideally prevent selection
        // of Todoist server if the key isn't set.
        service = DummyApiService(); // Or potentially a specific DummyTaskService if created
      } else {
        // The TodoistApiService implements TaskApiService, which extends BaseApiService.
        // We return it cast as BaseApiService as per the provider's type signature.
        // Callers will need to check the type and cast to TaskApiService to use task-specific methods.
        service = todoistService; // Direct assignment works due to interface inheritance
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
      print(
        '[apiServiceProvider] Disposing API service provider for ${serverType.name}',
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

  // Special handling for Todoist: It uses a global key, not server-specific URL/token
  if (activeConfig != null && activeConfig.serverType == ServerType.todoist) {
    // For Todoist, we rely on its specific health check triggered elsewhere (settings)
    // We can read the status from the dedicated Todoist status provider
    final todoistStatus = ref.read(todoistApiStatusProvider);
    final currentApiStatus = ref.read(apiStatusProvider);
    if (currentApiStatus != todoistStatus) {
       ref.read(apiStatusProvider.notifier).state = todoistStatus;
       if (kDebugMode) {
          print('[apiHealthChecker] Setting general API status based on Todoist status: $todoistStatus');
       }
    }
     return; // Don't proceed with generic check for Todoist
  }

  // Generic check for Memos/Blinko
  if (activeConfig == null || activeConfig.serverUrl.isEmpty) {
    if (ref.read(apiStatusProvider) != 'unconfigured') {
       ref.read(apiStatusProvider.notifier).state = 'unconfigured';
    }
    return;
  }

  // Get the correctly configured service (Memos or Blinko) via the main provider
  final apiService = ref.read(apiServiceProvider);

  // Check if the service is actually configured (not the DummyApiService)
  // This check also covers the Todoist case returning DummyApiService if not configured
  if (!apiService.isConfigured || apiService is DummyApiService) {
    if (ref.read(apiStatusProvider) != 'unconfigured') {
      ref.read(apiStatusProvider.notifier).state = 'unconfigured';
    }
    return;
  }

  final currentStatus = ref.read(apiStatusProvider);
  if (currentStatus == 'checking') return;
  ref.read(apiStatusProvider.notifier).state = 'checking';

  try {
    // Call the checkHealth method defined in BaseApiService
    final isHealthy = await apiService.checkHealth();

    // Check if config is still the same before updating state
    if (ref.read(activeServerConfigProvider)?.id == activeConfig.id &&
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
    if (ref.read(activeServerConfigProvider)?.id == activeConfig.id &&
        ref.read(apiStatusProvider) == 'checking') {
      ref.read(apiStatusProvider.notifier).state = 'unavailable'; // Or 'error'
    }
  }
}

// --- Todoist API Providers (Keep as is) ---
/// Provider for Todoist API service
final todoistApiServiceProvider = Provider<TodoistApiService>((ref) {
  // Configuration from apiConfigProvider if needed
  final config = ref.watch(apiConfigProvider);
  // Watch the persisted API key from settings_provider
  final todoistToken = ref.watch(todoistApiKeyProvider);

  // Create and configure the Todoist API service
  final todoistApiService = TodoistApiService();
  TodoistApiService.verboseLogging = config['verboseLogging'] ?? true;

  if (todoistToken.isEmpty) {
    if (kDebugMode) {
      print(
        '[todoistApiServiceProvider] Warning: No Todoist API token configured via provider.',
      );
    }
    // Return unconfigured service, which will fail if used
    // Ensure the service is initialized even without a token
    todoistApiService.configureService(authToken: '');
  } else {
    todoistApiService.configureService(authToken: todoistToken);
    if (kDebugMode) {
      print(
        '[todoistApiServiceProvider] Todoist API service configured successfully via provider.',
      );
    }
  }

  // Add cleanup if needed
  ref.onDispose(() {
    if (kDebugMode) {
      print(
        '[todoistApiServiceProvider] Disposing Todoist API service provider',
      );
    }
  });

  return todoistApiService;
}, name: 'todoistApiService');

/// Provider for Todoist API service status (available, unavailable, etc.)
final todoistApiStatusProvider = StateProvider<String>((ref) {
  // Initial state depends on whether the token is configured via the provider
  final token = ref.watch(todoistApiKeyProvider); // Watch the key provider
  return token.isEmpty ? 'unconfigured' : 'unknown';
}, name: 'todoistApiStatus');

/// Provider that checks Todoist API health periodically
final todoistApiHealthCheckerProvider = Provider<void>((ref) {
  // Rerun health check when the API key changes
  ref.watch(todoistApiKeyProvider);
  // Initial check
  _checkTodoistApiHealth(ref);

  // TODO: Set up periodic health check

  ref.onDispose(() {
    // Cancel any timers or other resources
  });

  return;
}, name: 'todoistApiHealthChecker');

// Helper function to check Todoist API health
Future<void> _checkTodoistApiHealth(Ref ref) async {
  // Get the service instance. The provider itself handles configuration based on todoistApiKeyProvider.
  final todoistApiService = ref.read(todoistApiServiceProvider);

  // If the service isn't configured (no token from the provider), set status and return.
  if (!todoistApiService.isConfigured) {
    // Check current state before setting to avoid unnecessary updates if already unconfigured
    if (ref.read(todoistApiStatusProvider) != 'unconfigured') {
      ref.read(todoistApiStatusProvider.notifier).state = 'unconfigured';
    }
    return;
  }

  // Set status to checking
  // Check current state before setting to avoid unnecessary updates
  final currentStatus = ref.read(todoistApiStatusProvider);
  if (currentStatus == 'checking') return; // Already checking
  ref.read(todoistApiStatusProvider.notifier).state = 'checking';

  try {
    // Call the health check method on the service instance
    final isHealthy = await todoistApiService.checkHealth();

    // Check if the status is still 'checking' before updating
    // This prevents race conditions if the check takes time or the key changes
    if (ref.read(todoistApiStatusProvider) == 'checking') {
      if (isHealthy) {
        ref.read(todoistApiStatusProvider.notifier).state = 'available';
      } else {
        // If checkHealth returns false, it means the API call failed (e.g., bad token)
        ref.read(todoistApiStatusProvider.notifier).state = 'unavailable';
      }
    }
  } catch (e) {
    // Catch any exceptions during the health check (e.g., network error)
    if (kDebugMode) {
      print('[todoistApiHealthChecker] Error checking health: $e');
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
    openaiApiService.configureService(authToken: '');
  } else {
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
