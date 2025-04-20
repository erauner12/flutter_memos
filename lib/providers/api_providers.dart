import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/note_item.dart';
import 'package:flutter_memos/models/server_config.dart'; // Import ServerType
import 'package:flutter_memos/models/task_item.dart';
// Import new single config providers
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

/// Provider for the active NOTE API Service (Memos, Blinko, or Vikunja-as-note)
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
      memosService.configureService(
        baseUrl: serverUrl,
        authStrategy: authStrategy,
      );
      service = memosService;
      break;
    case ServerType.blinko:
      final blinkoService = BlinkoApiService();
      BlinkoApiService.verboseLogging = config['verboseLogging'] ?? true;
      blinkoService.configureService(
        baseUrl: serverUrl,
        authStrategy: authStrategy,
      );
      service = blinkoService;
      break;
    case ServerType.vikunja: // Vikunja can act as a Note service
      final vikunjaService = VikunjaApiService();
      VikunjaApiService.verboseLogging = config['verboseLogging'] ?? true;
      vikunjaService.configureService(
        baseUrl: serverUrl,
        authStrategy: authStrategy,
      );
      service =
          vikunjaService
              as NoteApiService; // VikunjaApiService implements NoteApiService
      break;
    case ServerType.todoist:
      // Todoist is not a note service
      if (kDebugMode)
        print(
          '[noteApiServiceProvider] Error: Todoist is not a valid note server type.',
        );
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
      print(
        '[noteApiServiceProvider] Disposing API service provider for ${noteServerConfig.serverType.name}',
      );
    }
  });

  return service;
}, name: 'noteApiService');

/// Provider for the active TASK API Service (currently only Vikunja)
/// Returns the TaskApiService interface.
final taskApiServiceProvider = Provider<TaskApiService>((ref) {
  final taskServerConfig = ref.watch(taskServerConfigProvider);
  final config = ref.watch(apiConfigProvider); // General config like logging
  // Watch the separate Vikunja API key provider as well, might be needed if not in ServerConfig token
  final vikunjaApiKey = ref.watch(vikunjaApiKeyProvider);

  if (taskServerConfig == null || taskServerConfig.serverUrl.isEmpty) {
    if (kDebugMode)
      print(
        '[taskApiServiceProvider] Warning: No task server configured or URL is empty. Returning DummyTaskApiService.',
      );
    return DummyTaskApiService();
  }

  // Currently only Vikunja is supported as a task server
  if (taskServerConfig.serverType != ServerType.vikunja) {
    if (kDebugMode)
      print(
        '[taskApiServiceProvider] Error: Configured task server type (${taskServerConfig.serverType}) is not Vikunja. Returning DummyTaskApiService.',
      );
    return DummyTaskApiService();
  }

  final serverUrl = taskServerConfig.serverUrl;
  // Use token from config primarily, fallback to separate API key if config token is empty
  final authToken =
      taskServerConfig.authToken.isNotEmpty
          ? taskServerConfig.authToken
          : vikunjaApiKey;
  final authStrategy = BearerTokenAuthStrategy(authToken);

  if (authToken.isEmpty) {
    if (kDebugMode)
      print(
        '[taskApiServiceProvider] Warning: Vikunja task server configured but token/API key is missing. Returning DummyTaskApiService.',
      );
    // Update the configuration status provider
    ref.read(isVikunjaConfiguredProvider.notifier).state = false;
    return DummyTaskApiService();
  }

  final vikunjaService = VikunjaApiService();
  VikunjaApiService.verboseLogging = config['verboseLogging'] ?? true;
  vikunjaService.configureService(
    baseUrl: serverUrl,
    authStrategy: authStrategy,
  );

  // Update the configuration status provider AFTER configuration attempt
  ref.read(isVikunjaConfiguredProvider.notifier).state =
      vikunjaService.isConfigured;

  if (kDebugMode) {
    print(
      '[taskApiServiceProvider] Configured Vikunja service for task server: ${taskServerConfig.name ?? taskServerConfig.id}. isConfigured: ${vikunjaService.isConfigured}',
    );
  }

  ref.onDispose(() {
    if (kDebugMode)
      print('[taskApiServiceProvider] Disposing Task API service provider.');
  });

  // Return the configured service if successful, otherwise dummy
  return vikunjaService.isConfigured ? vikunjaService : DummyTaskApiService();
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
  final noteConfig = ref.read(noteServerConfigProvider);
  if (noteConfig == null) {
    if (ref.read(noteApiStatusProvider) != 'unconfigured') {
      ref.read(noteApiStatusProvider.notifier).state = 'unconfigured';
    }
    return;
  }

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
    final potentiallyChangedConfig = ref.read(noteServerConfigProvider);
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
    final potentiallyChangedConfig = ref.read(noteServerConfigProvider);
    if (potentiallyChangedConfig?.id == noteConfig.id &&
        ref.read(noteApiStatusProvider) == 'checking') {
      ref.read(noteApiStatusProvider.notifier).state = 'unavailable';
    }
  }
}

/// Provider for TASK API service status (currently Vikunja)
final taskApiStatusProvider = StateProvider<String>((ref) {
  final taskConfig = ref.watch(taskServerConfigProvider);
  final isConfigured = ref.watch(
    isVikunjaConfiguredProvider,
  ); // Use the dedicated config status
  return (taskConfig == null || !isConfigured) ? 'unconfigured' : 'unknown';
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
  final taskConfig = ref.read(taskServerConfigProvider);
  final isConfigured = ref.read(isVikunjaConfiguredProvider);

  if (taskConfig == null || !isConfigured) {
    if (ref.read(taskApiStatusProvider) != 'unconfigured') {
      ref.read(taskApiStatusProvider.notifier).state = 'unconfigured';
    }
    return;
  }

  final taskApiService = ref.read(taskApiServiceProvider);
  if (!taskApiService.isConfigured || taskApiService is DummyTaskApiService) {
    if (ref.read(taskApiStatusProvider) != 'unconfigured') {
      ref.read(taskApiStatusProvider.notifier).state = 'unconfigured';
      if (kDebugMode)
        print(
          '[taskApiHealthChecker] Setting status to unconfigured (service is Dummy or not configured).',
        );
    }
    return;
  }

  final currentStatus = ref.read(taskApiStatusProvider);
  if (currentStatus == 'checking') return;
  ref.read(taskApiStatusProvider.notifier).state = 'checking';

  try {
    final isHealthy = await taskApiService.checkHealth();
    final potentiallyChangedConfig = ref.read(taskServerConfigProvider);
    if (potentiallyChangedConfig?.id == taskConfig.id &&
        ref.read(taskApiStatusProvider) == 'checking') {
      ref.read(taskApiStatusProvider.notifier).state =
          isHealthy ? 'available' : 'unavailable';
      if (kDebugMode)
        print(
          '[taskApiHealthChecker] Health check for ${taskConfig.name ?? taskConfig.id}: ${isHealthy ? 'Available' : 'Unavailable'}',
        );
    }
  } catch (e) {
    if (kDebugMode)
      print(
        '[taskApiHealthChecker] API health check failed for ${taskConfig.name ?? taskConfig.id}: $e',
      );
    final potentiallyChangedConfig = ref.read(taskServerConfigProvider);
    if (potentiallyChangedConfig?.id == taskConfig.id &&
        ref.read(taskApiStatusProvider) == 'checking') {
      ref.read(taskApiStatusProvider.notifier).state = 'unavailable';
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
    if (ref.read(openaiApiStatusProvider) == 'checking') {
      ref.read(openaiApiStatusProvider.notifier).state =
          isHealthy ? 'available' : 'unavailable';
    }
  } catch (e) {
    if (kDebugMode) print('[openaiApiHealthChecker] Error checking health: $e');
    if (ref.read(openaiApiStatusProvider) == 'checking') {
      ref.read(openaiApiStatusProvider.notifier).state = 'error';
    }
  }
}

// --- Dummy Services ---
class DummyNoteApiService extends BaseApiService implements NoteApiService {
  @override
  bool get isConfigured => false;
  @override
  Future<bool> checkHealth() async => false;
  @override
  Future<NoteItem> createNote(NoteItem note, {String? targetServerId}) async =>
      throw UnimplementedError();
  @override
  Future<void> deleteNote(String id, {String? targetServerId}) async =>
      throw UnimplementedError();
  @override
  Future<NoteItem> getNote(String id, {String? targetServerId}) async =>
      throw UnimplementedError();
  @override
  Future<ListNotesResponse> listNotes({
    String? filter,
    String? state,
    String? sort,
    String? direction,
    int? pageSize,
    String? pageToken,
    String? targetServerId,
  }) async => ListNotesResponse(notes: [], nextPageToken: null);
  @override
  Future<NoteItem> updateNote(
    String id,
    NoteItem note, {
    String? targetServerId,
  }) async => throw UnimplementedError();
  @override
  Future<NoteItem> archiveNote(String id, {String? targetServerId}) async =>
      throw UnimplementedError();
  @override
  Future<NoteItem> togglePinNote(String id, {String? targetServerId}) async =>
      throw UnimplementedError();
  @override
  Future<void> setNoteRelations(
    String noteId,
    List<Map<String, dynamic>> relations, {
    String? targetServerId,
  }) async => throw UnimplementedError();
  @override
  Future<List<Comment>> listNoteComments(
    String noteId, {
    String? targetServerId,
  }) async => [];
  @override
  Future<Comment> getNoteComment(
    String commentId, {
    String? targetServerId,
  }) async => throw UnimplementedError();
  @override
  Future<Comment> createNoteComment(
    String noteId,
    Comment comment, {
    String? targetServerId,
  }) async => throw UnimplementedError();
  @override
  Future<Comment> updateNoteComment(
    String commentId,
    Comment comment, {
    String? targetServerId,
  }) async => throw UnimplementedError();
  @override
  Future<void> deleteNoteComment(
    String noteId,
    String commentId, {
    String? targetServerId,
  }) async => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> uploadResource(
    Uint8List fileBytes,
    String filename,
    String contentType, {
    String? targetServerId,
  }) async => throw UnimplementedError();
  @override
  Future<Uint8List> getResourceData(
    String resourceIdentifier, {
    String? targetServerId,
  }) async => throw UnimplementedError();
  
  @override
  // TODO: implement apiBaseUrl
  String get apiBaseUrl => throw UnimplementedError();
  
  @override
  // TODO: implement authStrategy
  AuthStrategy? get authStrategy => throw UnimplementedError();
  
  @override
  Future<void> configureService({
    required String baseUrl,
    AuthStrategy? authStrategy,
    String? authToken,
  }) {
    // TODO: implement configureService
    throw UnimplementedError();
  }
}

class DummyTaskApiService extends BaseApiService implements TaskApiService {
  @override
  bool get isConfigured => false;
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
  }) async => throw UnimplementedError();
  @override
  Future<TaskItem> createTask(
    TaskItem task, {
    int? projectId,
    ServerConfig? targetServerOverride,
  }) async => throw UnimplementedError();
  @override
  Future<TaskItem> updateTask(
    String id,
    TaskItem task, {
    ServerConfig? targetServerOverride,
  }) async => throw UnimplementedError();
  @override
  Future<void> deleteTask(
    String id, {
    ServerConfig? targetServerOverride,
  }) async => throw UnimplementedError();
  @override
  Future<TaskItem> completeTask(
    String id, {
    ServerConfig? targetServerOverride,
  }) async => throw UnimplementedError();
  @override
  Future<TaskItem> reopenTask(
    String id, {
    ServerConfig? targetServerOverride,
  }) async => throw UnimplementedError();
  @override
  Future<List<Comment>> listComments(
    String taskId, {
    ServerConfig? targetServerOverride,
  }) async => [];
  @override
  Future<Comment> addComment(
    String taskId,
    String content, {
    ServerConfig? targetServerOverride,
  }) async => throw UnimplementedError();
}
