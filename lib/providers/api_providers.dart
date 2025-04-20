import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/comment.dart'; // Import Comment
import 'package:flutter_memos/models/list_notes_response.dart'; // Import ListNotesResponse
import 'package:flutter_memos/models/note_item.dart'; // Import NoteItem
import 'package:flutter_memos/models/server_config.dart'; // Import ServerType
// Import new single config providers
import 'package:flutter_memos/models/task_item.dart'; // Import TaskItem
import 'package:flutter_memos/providers/note_server_config_provider.dart';
import 'package:flutter_memos/providers/settings_provider.dart';
import 'package:flutter_memos/providers/task_server_config_provider.dart';
// Import BaseApiService and concrete implementations
import 'package:flutter_memos/services/auth_strategy.dart'; // Import AuthStrategy
import 'package:flutter_memos/services/base_api_service.dart';
import 'package:flutter_memos/services/blinko_api_service.dart';
import 'package:flutter_memos/services/memos_api_service.dart';
import 'package:flutter_memos/services/minimal_openai_service.dart';
import 'package:flutter_memos/services/note_api_service.dart'; // Import NoteApiService interface
import 'package:flutter_memos/services/task_api_service.dart'; // Import TaskApiService interface
import 'package:flutter_memos/services/vikunja_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// General API configuration (e.g., logging)
final apiConfigProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {'verboseLogging': true};
}, name: 'apiConfig');

/// Provider for the active NOTE API Service (Memos or Blinko)
/// Returns the NoteApiService interface.
final noteApiServiceProvider = Provider<NoteApiService>((ref) {
  final noteServerConfig = ref.watch(noteServerConfigProvider);
  final config = ref.watch(apiConfigProvider); // General config like logging

  if (noteServerConfig == null || noteServerConfig.serverUrl.isEmpty) {
    if (kDebugMode) {
      print(
        '[noteApiServiceProvider] Warning: No note server configured or URL is empty. Returning DummyNoteApiService.',
      );
    }
    return DummyNoteApiService();
  }

  final serverUrl = noteServerConfig.serverUrl;
  final authToken = noteServerConfig.authToken;
  final serverType = noteServerConfig.serverType;
  final authStrategy = BearerTokenAuthStrategy(
    authToken,
  ); // Assume Bearer for all note types for now

  NoteApiService service = DummyNoteApiService(); // Initialize with dummy

  switch (serverType) {
    case ServerType.memos:
      final memosService = MemosApiService();
      MemosApiService.verboseLogging = config['verboseLogging'] ?? true;
      // Note: configureService is async but we don't necessarily need to wait here
      // unless subsequent logic depends on it being fully configured immediately.
      // For provider setup, it's often okay to configure without await.
      memosService.configureService(
        baseUrl: serverUrl,
        authStrategy: authStrategy,
        serverId: noteServerConfig.id, // Pass serverId
      );
      service = memosService;
      break;
    case ServerType.blinko:
      final blinkoService = BlinkoApiService();
      BlinkoApiService.verboseLogging = config['verboseLogging'] ?? true;
      blinkoService.configureService(
        baseUrl: serverUrl,
        authStrategy: authStrategy,
        serverId: noteServerConfig.id, // Pass serverId
      );
      service = blinkoService;
      break;
    case ServerType.vikunja: // Vikunja is NO LONGER a valid Note service type
      if (kDebugMode) {
        print(
          '[noteApiServiceProvider] Error: Vikunja is not a valid note server type. Config found: ${noteServerConfig.id}. Returning DummyNoteApiService.',
        );
      }
      service = DummyNoteApiService();
      break;
    case ServerType.todoist:
      // Todoist is not a note service
      if (kDebugMode) {
        print(
          '[noteApiServiceProvider] Error: Todoist is not a valid note server type.',
        );
      }
      service = DummyNoteApiService();
      break;
  }

  if (kDebugMode) {
    print(
      '[noteApiServiceProvider] Configured ${serverType.name} service for note server: ${noteServerConfig.name ?? noteServerConfig.id}',
    );
    print(
      '[noteApiServiceProvider] Returning service of type: ${service.runtimeType}',
    );
  }

  ref.onDispose(() {
    if (kDebugMode) {
      // Use local variable as noteServerConfig might be null during disposal
      final disposedServerType = noteServerConfig.serverType.name;
      print(
        '[noteApiServiceProvider] Disposing API service provider for $disposedServerType',
      );
    }
  });

  return service;
}, name: 'noteApiService');


/// Provider for the active TASK API Service (currently only Vikunja)
/// Returns the TaskApiService interface.
/// configuration needs to be awaited. Consumers must handle the Future.
final taskApiServiceProvider = FutureProvider<TaskApiService>((ref) async {
  final taskServerConfig = ref.watch(taskServerConfigProvider);
  final config = ref.watch(apiConfigProvider); // General config like logging

  // --- Start Enhanced Logging ---
  if (taskServerConfig == null) {
    if (kDebugMode)
      print("[taskApiServiceProvider] No task server config. Returning dummy.");
    return DummyTaskApiService();
  }
  if (taskServerConfig.serverUrl.isEmpty) {
    if (kDebugMode)
      print("[taskApiServiceProvider] Blank URL for Vikunja. Returning dummy.");
    return DummyTaskApiService();
  }
  if (taskServerConfig.serverType != ServerType.vikunja) {
    if (kDebugMode)
      print(
        "[taskApiServiceProvider] Server type (${taskServerConfig.serverType}) not vikunja. Returning dummy.",
      );
    return DummyTaskApiService();
  }
  if (taskServerConfig.authToken.isEmpty) {
    if (kDebugMode)
      print("[taskApiServiceProvider] Token is empty. Returning dummy.");
    return DummyTaskApiService();
  }
  // --- End Enhanced Logging ---

  // We have Vikunja config with a token:
  final vikunjaService = VikunjaApiService();
  VikunjaApiService.verboseLogging = config['verboseLogging'] ?? true;

  if (kDebugMode) {
    print(
      "[taskApiServiceProvider] Attempting to configure Vikunja with baseUrl=${taskServerConfig.serverUrl} tokenLength=${taskServerConfig.authToken.length} serverId=${taskServerConfig.id}",
    );
  }

  try {
    // *** CRITICAL CHANGE: Await configureService and pass serverId ***
    await vikunjaService.configureService(
      baseUrl: taskServerConfig.serverUrl,
      authStrategy: BearerTokenAuthStrategy(taskServerConfig.authToken),
      serverId: taskServerConfig.id, // Pass the server ID from the config
    );

    if (kDebugMode) {
      print(
        "[taskApiServiceProvider] configureService done. isConfigured=${vikunjaService.isConfigured}",
      );
    }

    // Return the configured service if successful, otherwise dummy
    if (vikunjaService.isConfigured) {
      if (kDebugMode) {
        print(
          '[taskApiServiceProvider] Configured Vikunja service for task server: ${taskServerConfig.name ?? taskServerConfig.id}. Returning VikunjaApiService.',
        );
      }
      return vikunjaService;
    } else {
      if (kDebugMode) {
        print(
          '[taskApiServiceProvider] Vikunja service configuration failed (isConfigured=false). Returning DummyTaskApiService.',
        );
      }
      return DummyTaskApiService();
    }
  } catch (e) {
    if (kDebugMode) {
      print(
        "[taskApiServiceProvider] configureService threw error: $e. Returning DummyTaskApiService.",
      );
    }
    // Ensure the internal state of the service instance is also marked as not configured
    // (configureService should handle this, but double-check if issues persist)
    return DummyTaskApiService();
  } finally {
    ref.onDispose(() {
      if (kDebugMode)
        print('[taskApiServiceProvider] Disposing Task API service provider.');
    });
  }
}, name: 'taskApiService');


// --- Status and Health Check Providers ---

/// Provider for NOTE API service status
final noteApiStatusProvider = StateProvider<String>((ref) {
  final noteConfig = ref.watch(noteServerConfigProvider);
  return noteConfig == null ? 'unconfigured' : 'unknown';
}, name: 'noteApiStatus');

/// Provider that pings the NOTE API periodically to check health
final noteApiHealthCheckerProvider = Provider<void>((ref) {
  ref.watch(noteServerConfigProvider); // Rerun on server change
  _checkNoteApiHealth(ref); // Initial check
  // TODO: Add Timer.periodic for regular checks
  ref.onDispose(() {
    /* Cancel timer */
  });
}, name: 'noteApiHealthChecker');

// Helper function to check NOTE API health
Future<void> _checkNoteApiHealth(Ref ref) async {
  final noteConfig = ref.read(noteServerConfigProvider); // Read current config
  if (noteConfig == null) {
    if (ref.read(noteApiStatusProvider) != 'unconfigured') {
      ref.read(noteApiStatusProvider.notifier).state = 'unconfigured';
    }
    return;
  }

  // Read the service directly, handle potential Dummy service
  final noteApiService = ref.read(noteApiServiceProvider);
  if (!noteApiService.isConfigured || noteApiService is DummyNoteApiService) {
    if (ref.read(noteApiStatusProvider) != 'unconfigured') {
      ref.read(noteApiStatusProvider.notifier).state = 'unconfigured';
      if (kDebugMode)
        print(
          '[noteApiHealthChecker] Setting status to unconfigured (service is Dummy or not configured).',
        );
    }
    return;
  }

  final currentStatus = ref.read(noteApiStatusProvider);
  if (currentStatus == 'checking') return;
  ref.read(noteApiStatusProvider.notifier).state = 'checking';

  try {
    final isHealthy = await noteApiService.checkHealth();
    // Check if config is still the same before updating state
    final potentiallyChangedConfig = ref.read(
      noteServerConfigProvider,
    ); // Read again after await
    if (potentiallyChangedConfig?.id == noteConfig.id &&
        ref.read(noteApiStatusProvider) == 'checking') {
      ref.read(noteApiStatusProvider.notifier).state =
          isHealthy ? 'available' : 'unavailable';
      if (kDebugMode)
        print(
          '[noteApiHealthChecker] Health check for ${noteConfig.name ?? noteConfig.id}: ${isHealthy ? 'Available' : 'Unavailable'}',
        );
    }
  } catch (e) {
    if (kDebugMode)
      print(
        '[noteApiHealthChecker] API health check failed for ${noteConfig.name ?? noteConfig.id}: $e',
      );
    final potentiallyChangedConfig = ref.read(
      noteServerConfigProvider,
    ); // Read again after await
    if (potentiallyChangedConfig?.id == noteConfig.id &&
        ref.read(noteApiStatusProvider) == 'checking') {
      ref.read(noteApiStatusProvider.notifier).state = 'unavailable';
    }
  }
}

/// Computed provider indicating if the Vikunja task service is configured.
/// Derives its state from the `taskApiServiceProvider`.
/// IMPORTANT: Now watches the FutureProvider and checks the result.
final isVikunjaConfiguredProvider = Provider<bool>((ref) {
  final taskServiceAsyncValue = ref.watch(taskApiServiceProvider);
  // Add logging here to see what taskServiceAsyncValue contains
  if (kDebugMode) {
    print(
      "[isVikunjaConfiguredProvider] taskServiceAsyncValue: $taskServiceAsyncValue",
    );
  }
  return taskServiceAsyncValue.when(
    data: (service) {
      if (kDebugMode) {
        print(
          "[isVikunjaConfiguredProvider] Data received: service.isConfigured=${service.isConfigured}, service type=${service.runtimeType}",
        );
      }
      // Ensure it's the correct service type AND configured
      return service.isConfigured && service is VikunjaApiService;
    },
    loading: () {
      if (kDebugMode) print("[isVikunjaConfiguredProvider] State: loading");
      return false; // Not configured while loading
    },
    error: (err, stack) {
      if (kDebugMode)
        print("[isVikunjaConfiguredProvider] State: error - $err");
      return false; // Not configured on error
    },
  );
}, name: 'isVikunjaConfiguredProvider');


/// Provider for TASK API service status (currently Vikunja)
final taskApiStatusProvider = StateProvider<String>((ref) {
  final isConfigured = ref.watch(
    isVikunjaConfiguredProvider,
  ); // Use the computed provider
  final status = !isConfigured ? 'unconfigured' : 'unknown';
  if (kDebugMode)
    print(
      "[taskApiStatusProvider] Status updated: $status (based on isVikunjaConfigured: $isConfigured)",
    );
  return status;
}, name: 'taskApiStatus');

/// Provider that pings the TASK API periodically to check health
final taskApiHealthCheckerProvider = Provider<void>((ref) {
  ref.watch(taskServerConfigProvider); // Rerun on server change
  ref.watch(
    isVikunjaConfiguredProvider,
  ); // Rerun if configuration status changes
  _checkTaskApiHealth(ref); // Initial check
  // TODO: Add Timer.periodic for regular checks
  ref.onDispose(() {
    /* Cancel timer */
  });
}, name: 'taskApiHealthChecker');

// Helper function to check TASK API health (currently Vikunja)
Future<void> _checkTaskApiHealth(Ref ref) async {
  final isConfigured = ref.read(
    isVikunjaConfiguredProvider,
  ); // Use computed provider

  if (!isConfigured) {
    if (ref.read(taskApiStatusProvider) != 'unconfigured') {
      if (kDebugMode)
        print(
          "[_checkTaskApiHealth] Not configured, setting status to unconfigured.",
        );
      ref.read(taskApiStatusProvider.notifier).state = 'unconfigured';
    }
    return;
  }

  // Read the service from the FutureProvider's result
  final taskApiServiceAsyncValue = ref.read(taskApiServiceProvider);
  TaskApiService? taskApiService;
  // Use maybeWhen to safely extract data without crashing if it's loading/error
  taskApiServiceAsyncValue.maybeWhen(
    data: (service) => taskApiService = service,
    orElse: () {
      // Handle loading/error case for health check - treat as not ready
      if (kDebugMode)
        print(
          "[_checkTaskApiHealth] Task service provider not ready (loading/error). Skipping health check.",
        );
    },
  );

  // If service is null (still loading or error), or dummy, treat as unconfigured for health check
  if (taskApiService == null ||
      !taskApiService!.isConfigured ||
      taskApiService is DummyTaskApiService) {
    if (ref.read(taskApiStatusProvider) != 'unconfigured') {
      if (kDebugMode)
        print(
          "[_checkTaskApiHealth] Service is null, dummy, or not configured internally. Setting status to unconfigured.",
        );
      ref.read(taskApiStatusProvider.notifier).state = 'unconfigured';
    }
    return;
  }

  final currentStatus = ref.read(taskApiStatusProvider);
  if (currentStatus == 'checking') return;
  if (kDebugMode) print("[_checkTaskApiHealth] Setting status to checking.");
  ref.read(taskApiStatusProvider.notifier).state = 'checking';

  try {
    final isHealthy =
        await taskApiService!.checkHealth(); // checkHealth now logs internally
    // Check if still configured before updating state
    final stillConfigured = ref.read(
      isVikunjaConfiguredProvider,
    ); // Read again after await
    if (stillConfigured && ref.read(taskApiStatusProvider) == 'checking') {
      final newStatus = isHealthy ? 'available' : 'unavailable';
      if (kDebugMode)
        print(
          "[_checkTaskApiHealth] Health check result: $isHealthy. Setting status to $newStatus.",
        );
      ref.read(taskApiStatusProvider.notifier).state = newStatus;
      if (kDebugMode) {
        final taskConfig = ref.read(
          taskServerConfigProvider,
        ); // Read for logging
        print(
          '[taskApiHealthChecker] Health check for ${taskConfig?.name ?? taskConfig?.id ?? 'Vikunja'}: ${isHealthy ? 'Available' : 'Unavailable'}',
        );
      }
    } else {
      if (kDebugMode)
        print(
          "[_checkTaskApiHealth] Configuration changed or status no longer 'checking' after health check. Not updating status.",
        );
    }
  } catch (e) {
    final taskConfig = ref.read(taskServerConfigProvider); // Read for logging
    if (kDebugMode)
      print(
        '[taskApiHealthChecker] API health check failed for ${taskConfig?.name ?? taskConfig?.id ?? 'Vikunja'}: $e',
      );
    final stillConfigured = ref.read(
      isVikunjaConfiguredProvider,
    ); // Read again after await
    if (stillConfigured && ref.read(taskApiStatusProvider) == 'checking') {
      if (kDebugMode)
        print(
          "[_checkTaskApiHealth] Health check failed. Setting status to unavailable.",
        );
      ref.read(taskApiStatusProvider.notifier).state = 'unavailable';
    } else {
      if (kDebugMode)
        print(
          "[_checkTaskApiHealth] Configuration changed or status no longer 'checking' after health check failure. Not updating status.",
        );
    }
  }
}


// --- OpenAI API Providers (Keep as is) ---

/// Provider for OpenAI API service
final openaiApiServiceProvider = Provider<MinimalOpenAiService>((ref) {
  final config = ref.watch(apiConfigProvider);
  final openaiToken = ref.watch(openAiApiKeyProvider);
  final openaiApiService = MinimalOpenAiService();
  MinimalOpenAiService.verboseLogging = config['verboseLogging'] ?? true;

  if (openaiToken.isEmpty) {
    if (kDebugMode)
      print(
        '[openaiApiServiceProvider] Warning: No OpenAI API token configured.',
      );
    openaiApiService.configureService(authToken: '');
  } else {
    openaiApiService.configureService(authToken: openaiToken);
    if (kDebugMode)
      print(
        '[openaiApiServiceProvider] OpenAI API service configured successfully.',
      );
  }

  ref.onDispose(() {
    if (kDebugMode)
      print(
        '[openaiApiServiceProvider] Disposing OpenAI API service provider.',
      );
  });

  return openaiApiService;
}, name: 'openaiApiService');

/// Provider for OpenAI API service status
final openaiApiStatusProvider = StateProvider<String>((ref) {
  final token = ref.watch(openAiApiKeyProvider);
  return token.isEmpty ? 'unconfigured' : 'unknown';
}, name: 'openaiApiStatus');

/// Provider that checks OpenAI API health periodically
final openaiApiHealthCheckerProvider = Provider<void>((ref) {
  ref.watch(openAiApiKeyProvider);
  _checkOpenAiApiHealth(ref);
  // TODO: Set up periodic health check
  ref.onDispose(() {
    /* Cancel timer */
  });
}, name: 'openaiApiHealthChecker');

// Helper function to check OpenAI API health
Future<void> _checkOpenAiApiHealth(Ref ref) async {
  final openaiApiService = ref.read(openaiApiServiceProvider);
  if (!openaiApiService.isConfigured) {
    if (ref.read(openaiApiStatusProvider) != 'unconfigured') {
      ref.read(openaiApiStatusProvider.notifier).state = 'unconfigured';
    }
    return;
  }

  final currentStatus = ref.read(openaiApiStatusProvider);
  if (currentStatus == 'checking') return;
  ref.read(openaiApiStatusProvider.notifier).state = 'checking';

  try {
    final isHealthy = await openaiApiService.checkHealth();
    // Check if still configured before updating state
    final stillConfigured = ref.read(openAiApiKeyProvider).isNotEmpty;
    if (stillConfigured && ref.read(openaiApiStatusProvider) == 'checking') {
      ref.read(openaiApiStatusProvider.notifier).state =
          isHealthy ? 'available' : 'unavailable';
    }
  } catch (e) {
    if (kDebugMode) print('[openaiApiHealthChecker] Error checking health: $e');
    final stillConfigured = ref.read(openAiApiKeyProvider).isNotEmpty;
    if (stillConfigured && ref.read(openaiApiStatusProvider) == 'checking') {
      // Keep status as 'checking' or set to 'error'? Let's use 'unavailable' for consistency.
      ref.read(openaiApiStatusProvider.notifier).state = 'unavailable';
    }
  }
}

// --- Dummy Services ---
class DummyNoteApiService extends BaseApiService implements NoteApiService {
  @override
  bool get isConfigured => false;
  @override
  String get apiBaseUrl => '';
  @override
  AuthStrategy? get authStrategy => null;

  @override
  Future<void> configureService({
    required String baseUrl,
    AuthStrategy? authStrategy,
    @Deprecated('Use authStrategy instead') String? authToken,
    String? serverId, // Add optional serverId
  }) async {}
  @override
  Future<bool> checkHealth() async => false;

  @override
  Future<NoteItem> createNote(
    NoteItem note, {
    ServerConfig? targetServerOverride,
  }) async => throw UnimplementedError('DummyNoteApiService.createNote');
  @override
  Future<void> deleteNote(
    String id, {
    ServerConfig? targetServerOverride,
  }) async => throw UnimplementedError('DummyNoteApiService.deleteNote');
  @override
  Future<NoteItem> getNote(
    String id, {
    ServerConfig? targetServerOverride,
  }) async => throw UnimplementedError('DummyNoteApiService.getNote');
  @override
  Future<ListNotesResponse> listNotes({
    String? filter,
    String? state,
    String? sort,
    String? direction,
    int? pageSize,
    String? pageToken,
    ServerConfig? targetServerOverride,
  }) async => ListNotesResponse(notes: [], nextPageToken: null);
  @override
  Future<NoteItem> updateNote(
    String id,
    NoteItem note, {
    ServerConfig? targetServerOverride,
  }) async => throw UnimplementedError('DummyNoteApiService.updateNote');
  @override
  Future<NoteItem> archiveNote(
    String id, {
    ServerConfig? targetServerOverride,
  }) async => throw UnimplementedError('DummyNoteApiService.archiveNote');
  @override
  Future<NoteItem> togglePinNote(
    String id, {
    ServerConfig? targetServerOverride,
  }) async => throw UnimplementedError('DummyNoteApiService.togglePinNote');
  @override
  Future<void> setNoteRelations(
    String noteId,
    List<Map<String, dynamic>> relations, {
    ServerConfig? targetServerOverride,
  }) async => throw UnimplementedError('DummyNoteApiService.setNoteRelations');
  @override
  Future<List<Comment>> listNoteComments(
    String noteId, {
    ServerConfig? targetServerOverride,
  }) async => [];
  @override
  Future<Comment> getNoteComment(
    String commentId, {
    ServerConfig? targetServerOverride,
    String? noteId, // Add noteId to match interface
  }) async => throw UnimplementedError('DummyNoteApiService.getNoteComment');
  @override
  Future<Comment> createNoteComment(
    String noteId,
    Comment comment, {
    List<Map<String, dynamic>>? resources,
    ServerConfig? targetServerOverride,
  }) async => throw UnimplementedError('DummyNoteApiService.createNoteComment');
  @override
  Future<Comment> updateNoteComment(
    String commentId,
    Comment comment, {
    ServerConfig? targetServerOverride,
  }) async => throw UnimplementedError('DummyNoteApiService.updateNoteComment');
  @override
  Future<void> deleteNoteComment(
    String noteId,
    String commentId, {
    ServerConfig? targetServerOverride,
  }) async => throw UnimplementedError('DummyNoteApiService.deleteNoteComment');
  @override
  Future<Map<String, dynamic>> uploadResource(
    Uint8List fileBytes,
    String filename,
    String contentType, {
    ServerConfig? targetServerOverride,
  }) async => throw UnimplementedError('DummyNoteApiService.uploadResource');
  @override
  Future<Uint8List> getResourceData(
    String resourceIdentifier, {
    ServerConfig? targetServerOverride,
    String? noteId, // Add noteId to match interface
  }) async => throw UnimplementedError('DummyNoteApiService.getResourceData');
}

class DummyTaskApiService extends BaseApiService implements TaskApiService {
  @override
  bool get isConfigured => false;
  @override
  String get apiBaseUrl => '';
  @override
  AuthStrategy? get authStrategy => null;

  @override
  Future<void> configureService({
    required String baseUrl,
    AuthStrategy? authStrategy,
    @Deprecated('Use authStrategy instead') String? authToken,
    String? serverId, // Add optional serverId
  }) async {}
  @override
  Future<bool> checkHealth() async => false;

  @override
  Future<List<TaskItem>> listTasks({
    String? filter,
    ServerConfig? targetServerOverride,
  }) async => [];
  @override
  Future<TaskItem> getTask(
    String id, {
    ServerConfig? targetServerOverride,
  }) async => throw UnimplementedError('DummyTaskApiService.getTask');
  @override
  Future<TaskItem> createTask(
    TaskItem task, {
    int? projectId,
    ServerConfig? targetServerOverride,
  }) async => throw UnimplementedError('DummyTaskApiService.createTask');
  @override
  Future<TaskItem> updateTask(
    String id,
    TaskItem task, {
    ServerConfig? targetServerOverride,
  }) async => throw UnimplementedError('DummyTaskApiService.updateTask');
  @override
  Future<void> deleteTask(
    String id, {
    ServerConfig? targetServerOverride,
  }) async => throw UnimplementedError('DummyTaskApiService.deleteTask');
  @override
  Future<void> completeTask(
    // Changed return type to void
    String id, {
    ServerConfig? targetServerOverride,
  }) async => throw UnimplementedError('DummyTaskApiService.completeTask');
  @override
  Future<void> reopenTask(
    // Changed return type to void
    String id, {
    ServerConfig? targetServerOverride,
  }) async => throw UnimplementedError('DummyTaskApiService.reopenTask');
  @override
  Future<List<Comment>> listComments(
    String taskId, {
    ServerConfig? targetServerOverride,
  }) async => [];
  // Removed addComment as it's not in the interface
  // Future<Comment> addComment(
  //   String taskId,
  //   String content, {
  //   ServerConfig? targetServerOverride,
  // }) async => throw UnimplementedError('DummyTaskApiService.addComment');
  @override
  Future<Comment> createComment(
    String taskId,
    Comment comment, {
    List<Map<String, dynamic>>? resources,
    ServerConfig? targetServerOverride,
  }) async => throw UnimplementedError('DummyTaskApiService.createComment');
  @override
  Future<void> deleteComment(
    String taskId,
    String commentId, {
    ServerConfig? targetServerOverride,
  }) async => throw UnimplementedError('DummyTaskApiService.deleteComment');
  @override
  Future<Comment> getComment(
    String commentId, {
    ServerConfig? targetServerOverride,
    String? taskId, // Add taskId to match interface
  }) async => throw UnimplementedError('DummyTaskApiService.getComment');
  @override
  Future<Comment> updateComment(
    String commentId,
    Comment comment, {
    ServerConfig? targetServerOverride,
  }) async => throw UnimplementedError('DummyTaskApiService.updateComment');
  @override
  Future<Map<String, dynamic>> uploadResource(
    Uint8List fileBytes,
    String filename,
    String contentType, {
    ServerConfig? targetServerOverride,
  }) async => throw UnimplementedError('DummyTaskApiService.uploadResource');
  @override
  Future<Uint8List> getResourceData(
    String resourceIdentifier, {
    ServerConfig? targetServerOverride,
    String? taskId, // Add taskId to match interface
  }) async => throw UnimplementedError('DummyTaskApiService.getResourceData');
}
