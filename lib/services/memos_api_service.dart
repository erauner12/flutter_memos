import 'dart:convert'; // For base64Encode, utf8

import 'package:flutter/foundation.dart'; // For kDebugMode, Uint8List
import 'package:flutter_memos/api/lib/api.dart' as memos_api; // Alias Memos API
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/list_notes_response.dart';
import 'package:flutter_memos/models/note_item.dart'; // Use NoteItem
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/services/auth_strategy.dart'; // Import AuthStrategy
import 'package:flutter_memos/services/note_api_service.dart'; // Implement NoteApiService
import 'package:flutter_memos/utils/env.dart';
import 'package:http/http.dart' as http;

// Implement NoteApiService
class MemosApiService implements NoteApiService {
  static final MemosApiService _instance = MemosApiService._internal();
  factory MemosApiService() => _instance;

  late memos_api.MemoServiceApi _memoApi;
  late memos_api.ResourceServiceApi _resourceApi;
  late memos_api.ApiClient _apiClient;

  String _baseUrl = '';
  AuthStrategy? _authStrategy; // Store the strategy
  String? _configuredServerId; // Store the server ID

  @override
  String get apiBaseUrl => _baseUrl;

  @override
  bool get isConfigured => _baseUrl.isNotEmpty && _authStrategy != null;

  @override
  AuthStrategy? get authStrategy => _authStrategy;

  static bool verboseLogging = true;

  static List<String>? _lastServerOrder;
  static List<String> get lastServerOrder => _lastServerOrder ?? [];

  MemosApiService._internal() {
    // Initialize with dummy client initially
    _initializeClient('', null);
  }

  @override
  Future<void> configureService({
    required String baseUrl,
    AuthStrategy? authStrategy,
    @Deprecated('Use authStrategy instead') String? authToken,
    String? serverId, // Make serverId optional
  }) async {
    AuthStrategy? effectiveStrategy = authStrategy;

    // Fallback to authToken if authStrategy is not provided
    if (effectiveStrategy == null &&
        authToken != null &&
        authToken.isNotEmpty) {
      // Assuming Memos uses Bearer token based on previous implementation
      effectiveStrategy = BearerTokenAuthStrategy(authToken);
      if (kDebugMode) {
        print(
          "[MemosApiService] configureService: Using fallback BearerTokenAuthStrategy from authToken.",
        );
      }
    }

    // Check if configuration actually changed
    final currentToken = _authStrategy?.getSimpleToken();
    final newToken = effectiveStrategy?.getSimpleToken();
    if (_baseUrl == baseUrl &&
        currentToken == newToken &&
        _configuredServerId == serverId && // Also check serverId
        isConfigured) {
      if (kDebugMode) {
        print("[MemosApiService] configureService: Configuration unchanged.");
      }
      return;
    }

    _baseUrl = baseUrl;
    _authStrategy = effectiveStrategy;
    _configuredServerId = serverId; // Store the server ID

    try {
      _initializeClient(baseUrl, _authStrategy);
      if (kDebugMode) {
        print(
          "[MemosApiService] configureService: Service configured. Base URL: $_baseUrl, Auth Strategy: ${_authStrategy?.runtimeType}, Server ID: $_configuredServerId",
        );
      }
    } catch (e) {
      _baseUrl = ''; // Reset on failure
      _authStrategy = null;
      _configuredServerId = null;
      if (kDebugMode) {
        print("[MemosApiService] configureService: Configuration failed. $e");
      }
      rethrow;
    }
  }

  void _initializeClient(String baseUrl, AuthStrategy? authStrategy) {
    try {
      if (baseUrl.isEmpty) {
        baseUrl =
            Env.apiBaseUrl; // Fallback to env if needed, though configureService should provide it
      }
      // Normalize base URL
      if (baseUrl.toLowerCase().contains('/api/v1')) {
        final apiIndex = baseUrl.toLowerCase().indexOf('/api/v1');
        baseUrl = baseUrl.substring(0, apiIndex);
      } else if (baseUrl.toLowerCase().endsWith('/memos')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 6);
      }
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }

      // Use the strategy to create the Authentication object
      final authentication =
          authStrategy?.createMemosAuth() ??
          memos_api.HttpBearerAuth(); // Default to empty auth if no strategy

      _apiClient = memos_api.ApiClient(
        basePath: baseUrl,
        authentication: authentication,
      );
      _memoApi = memos_api.MemoServiceApi(_apiClient);
      _resourceApi = memos_api.ResourceServiceApi(_apiClient);

      if (kDebugMode) {
        print(
          "[MemosApiService] _initializeClient: Memos API client initialized. BasePath: $baseUrl, Auth: ${authentication.runtimeType}",
        );
      }

    } catch (e) {
      // Ensure client instances are reset or handled if initialization fails
      _apiClient = memos_api.ApiClient(
        authentication: memos_api.HttpBearerAuth(),
      ); // Reset to dummy
      _memoApi = memos_api.MemoServiceApi(_apiClient);
      _resourceApi = memos_api.ResourceServiceApi(_apiClient);
      throw Exception('Failed to initialize Memos API client: $e');
    }
  }

  // --- NOTE OPERATIONS (NoteApiService Implementation) ---

  @override
  Future<ListNotesResponse> listNotes({
    int? pageSize,
    String? pageToken,
    String? filter,
    String? state,
    String? sort = 'updateTime',
    String? direction = 'DESC',
    ServerConfig? targetServerOverride,
    BlinkoNoteType? blinkoType, // Add parameter, but ignore it
  }) async {
    final memoApi = _getMemoApiForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ??
        targetServerOverride?.id ??
        _configuredServerId ??
        'active';
    const parent = 'users/-';
    try {
      final memos_api.V1ListMemosResponse? response = await memoApi.memoServiceListMemos2(
        parent,
        state: state?.isNotEmpty ?? false ? state : null,
        sort: sort,
        direction: direction,
        filter: filter,
        pageSize: pageSize,
        pageToken: pageToken,
      );
      if (response == null) {
        return ListNotesResponse(notes: [], nextPageToken: null);
      }
      final notes = response.memos.map(_convertApiMemoToNoteItem).toList();
      final nextToken = response.nextPageToken;
      _lastServerOrder = notes.map((note) => note.id).toList();
      return ListNotesResponse(notes: notes, nextPageToken: nextToken);
    } catch (e) {
      throw Exception('Failed to load notes from $serverIdForLog: $e');
    }
  }

  @override
  Future<NoteItem> getNote(
    String id, {
    ServerConfig? targetServerOverride,
  }) async {
    final memoApi = _getMemoApiForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ??
        targetServerOverride?.id ??
        _configuredServerId ??
        'active';
    try {
      final formattedId = _formatResourceName(id, 'memos');
      final memos_api.Apiv1Memo? apiMemo = await memoApi.memoServiceGetMemo(formattedId);
      if (apiMemo == null) {
        throw Exception('Note $id not found on $serverIdForLog');
      }
      return _convertApiMemoToNoteItem(apiMemo);
    } catch (e) {
      throw Exception('Failed to load note $id from $serverIdForLog: $e');
    }
  }

  @override
  Future<NoteItem> createNote(
    NoteItem note, {
    ServerConfig? targetServerOverride,
  }) async {
    final memoApi = _getMemoApiForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ??
        targetServerOverride?.id ??
        _configuredServerId ??
        'active';
    try {
      final apiMemo = memos_api.Apiv1Memo(
        content: note.content,
        pinned: note.pinned,
        state: _getApiStateFromNoteState(note.state),
        visibility: _getApiVisibilityFromNoteVisibility(note.visibility),
        tags: note.tags, // Pass tags
        resources: _convertResourcesToApi(note.resources), // Pass resources
      );
      final memos_api.Apiv1Memo? response = await memoApi.memoServiceCreateMemo(apiMemo);
      if (response == null) {
        throw Exception('Failed to create note on $serverIdForLog: No response');
      }
      return _convertApiMemoToNoteItem(response);
    } catch (e) {
      throw Exception('Failed to create note on $serverIdForLog: $e');
    }
  }

  @override
  Future<NoteItem> updateNote(
    String id,
    NoteItem note, {
    ServerConfig? targetServerOverride,
  }) async {
    final memoApi = _getMemoApiForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ??
        targetServerOverride?.id ??
        _configuredServerId ??
        'active';
    try {
      final formattedId = _formatResourceName(id, 'memos');
      final originalCreateTime = note.createTime;
      final clientNow = DateTime.now().toUtc();

      final updatePayload = memos_api.TheMemoToUpdateTheNameFieldIsRequired(
        content: note.content,
        pinned: note.pinned,
        state: _getApiStateFromNoteState(note.state),
        visibility: _getApiVisibilityFromNoteVisibility(note.visibility),
        updateTime: clientNow,
        tags: note.tags, // Pass tags
        resources: _convertResourcesToApi(note.resources), // Pass resources
      );
      final memos_api.Apiv1Memo? response = await memoApi.memoServiceUpdateMemo(formattedId, updatePayload);
      if (response == null) {
        throw Exception('Failed to update note $id on $serverIdForLog: No response');
      }
      NoteItem updatedAppNote = _convertApiMemoToNoteItem(response);
      // Preserve original create time if server returns epoch/zero
      if (response.createTime != null && (response.createTime!.year == 1970 || response.createTime!.year == 1)) {
        updatedAppNote = updatedAppNote.copyWith(createTime: originalCreateTime);
      }
      return updatedAppNote;
    } catch (e) {
      throw Exception('Failed to update note $id on $serverIdForLog: $e');
    }
  }

  @override
  Future<void> deleteNote(
    String id, {
    ServerConfig? targetServerOverride,
  }) async {
    final memoApi = _getMemoApiForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ??
        targetServerOverride?.id ??
        _configuredServerId ??
        'active';
    try {
      final formattedId = _formatResourceName(id, 'memos');
      final http.Response response = await memoApi.memoServiceDeleteMemoWithHttpInfo(formattedId);
      if (!(response.statusCode >= 200 && response.statusCode < 300)) {
        final errorBody = await _decodeBodyBytes(response);
        throw memos_api.ApiException(response.statusCode, errorBody);
      }
    } catch (e) {
      if (e is memos_api.ApiException) rethrow;
      throw Exception('Failed to delete note $id from $serverIdForLog: $e');
    }
  }

  @override
  Future<NoteItem> archiveNote(
    String id, {
    ServerConfig? targetServerOverride,
  }) async {
    final memoApi = _getMemoApiForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ??
        targetServerOverride?.id ??
        _configuredServerId ??
        'active';
    try {
      final formattedId = _formatResourceName(id, 'memos');
      final memos_api.Apiv1Memo? currentApiMemo = await memoApi.memoServiceGetMemo(formattedId);
      if (currentApiMemo == null) {
        throw Exception('Note $id not found on $serverIdForLog');
      }
      final updatePayload = memos_api.TheMemoToUpdateTheNameFieldIsRequired(
        content: currentApiMemo.content,
        visibility: currentApiMemo.visibility,
        state: memos_api.V1State.ARCHIVED,
        pinned: false, // Unpin when archiving
        updateTime: DateTime.now().toUtc(),
        tags: currentApiMemo.tags, // Preserve tags
        resources: currentApiMemo.resources, // Preserve resources
      );
      final memos_api.Apiv1Memo? response = await memoApi.memoServiceUpdateMemo(formattedId, updatePayload);
      if (response == null) {
        throw Exception('Failed to archive note $id on $serverIdForLog: No response');
      }
      return _convertApiMemoToNoteItem(response);
    } catch (e) {
      throw Exception('Failed to archive note $id on $serverIdForLog: $e');
    }
  }

  @override
  Future<NoteItem> togglePinNote(
    String id, {
    ServerConfig? targetServerOverride,
  }) async {
    final memoApi = _getMemoApiForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ??
        targetServerOverride?.id ??
        _configuredServerId ??
        'active';
    try {
      final formattedId = _formatResourceName(id, 'memos');
      final memos_api.Apiv1Memo? currentApiMemo = await memoApi.memoServiceGetMemo(formattedId);
      if (currentApiMemo == null) {
        throw Exception('Note $id not found on $serverIdForLog');
      }
      final bool currentPinState = currentApiMemo.pinned ?? false;
      final updatePayload = memos_api.TheMemoToUpdateTheNameFieldIsRequired(
        content: currentApiMemo.content,
        visibility: currentApiMemo.visibility,
        state: currentApiMemo.state,
        pinned: !currentPinState, // Toggle pin state
        updateTime: DateTime.now().toUtc(),
        tags: currentApiMemo.tags, // Preserve tags
        resources: currentApiMemo.resources, // Preserve resources
      );
      final memos_api.Apiv1Memo? response = await memoApi.memoServiceUpdateMemo(formattedId, updatePayload);
      if (response == null) {
        throw Exception('Failed to toggle pin for note $id on $serverIdForLog: No response');
      }
      return _convertApiMemoToNoteItem(response);
    } catch (e) {
      throw Exception('Failed to toggle pin for note $id on $serverIdForLog: $e');
    }
  }

  // --- COMMENT OPERATIONS (NoteApiService Implementation) ---

  @override
  Future<List<Comment>> listNoteComments(
    String noteId, {
    ServerConfig? targetServerOverride,
  }) async {
    final memoApi = _getMemoApiForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ??
        targetServerOverride?.id ??
        _configuredServerId ??
        'active';
    try {
      final formattedId = _formatResourceName(noteId, 'memos');
      final memos_api.V1ListMemoCommentsResponse? response = await memoApi.memoServiceListMemoComments(formattedId);
      if (response == null) {
        return [];
      }
      // Pass serverId for context
      final serverId =
          targetServerOverride?.id ??
          _configuredServerId ?? // Use configured ID if override is null
          _apiClient.basePath; // Use base path as fallback ID
      return _parseCommentsFromApiResponse(response, noteId, serverId);
    } catch (e) {
      throw Exception('Failed to load comments for note $noteId from $serverIdForLog: $e');
    }
  }

  @override
  Future<Comment> getNoteComment(
    String commentId, {
    ServerConfig? targetServerOverride,
  }) async {
    final memoApi = _getMemoApiForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ??
        targetServerOverride?.id ??
        _configuredServerId ??
        'active';
    try {
      final formattedId = _formatResourceName(commentId, 'memos');
      final memos_api.Apiv1Memo? apiMemo = await memoApi.memoServiceGetMemo(formattedId);
      if (apiMemo == null) {
        throw Exception('Comment $commentId not found on $serverIdForLog');
      }
      if (apiMemo.parent == null || apiMemo.parent!.isEmpty) {
        throw Exception('Resource $commentId is not a comment (missing parent) on $serverIdForLog');
      }
      // Pass serverId for context
      final serverId =
          targetServerOverride?.id ??
          _configuredServerId ??
          _apiClient.basePath;
      return _convertApiMemoToComment(apiMemo, serverId);
    } catch (e) {
      throw Exception('Failed to load comment $commentId from $serverIdForLog: $e');
    }
  }

  @override
  Future<Comment> createNoteComment(
    String noteId,
    Comment comment, {
    ServerConfig? targetServerOverride,
    List<Map<String, dynamic>>? resources,
  }) async {
    final memoApi = _getMemoApiForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ??
        targetServerOverride?.id ??
        _configuredServerId ??
        'active';
    try {
      final formattedMemoId = _formatResourceName(noteId, 'memos');

      final List<memos_api.V1Resource> effectiveResources = (resources ?? [])
          .map((resMap) {
                // Map the generic resource map back to V1Resource for the API call
            return memos_api.V1Resource(
                  name:
                      resMap['name']
                          as String?, // Use 'name' which is 'resources/id'
              filename: resMap['filename'] as String?,
              type: resMap['contentType'] as String?, // Map contentType to type
                  // Other fields like externalLink, size are usually read-only
            );
          })
          .where((r) => r.name != null && r.name!.isNotEmpty)
          .toList();

      final apiMemo = memos_api.Apiv1Memo(
        content: comment.content,
        pinned: comment.pinned,
        state: _getApiStateFromCommentState(comment.state),
        resources: effectiveResources,
        // parent: formattedMemoId, // API handles this via endpoint
      );
      final memos_api.Apiv1Memo? response = await memoApi.memoServiceCreateMemoComment(formattedMemoId, apiMemo);
      if (response == null) {
        throw Exception('Failed to create comment on $serverIdForLog: No response');
      }
      // Pass serverId for context
      final serverId =
          targetServerOverride?.id ??
          _configuredServerId ??
          _apiClient.basePath;
      return _convertApiMemoToComment(response, serverId);
    } catch (e) {
      throw Exception('Failed to create comment for note $noteId on $serverIdForLog: $e');
    }
  }

  @override
  Future<Comment> updateNoteComment(
    String commentId,
    Comment comment, {
    ServerConfig? targetServerOverride,
  }) async {
    final memoApi = _getMemoApiForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ??
        targetServerOverride?.id ??
        _configuredServerId ??
        'active';
    try {
      final formattedCommentId = _formatResourceName(commentId, 'memos');
      final updateMemo = memos_api.TheMemoToUpdateTheNameFieldIsRequired(
        content: comment.content,
        pinned: comment.pinned,
        state: _getApiStateFromCommentState(comment.state),
        updateTime: DateTime.now().toUtc(),
        resources: _convertResourcesToApi(
          comment.resources,
        ), // Update resources if needed
      );
      final memos_api.Apiv1Memo? response = await memoApi.memoServiceUpdateMemo(formattedCommentId, updateMemo);
      if (response == null) {
        throw Exception('Failed to update comment $commentId on $serverIdForLog: No response');
      }
      if (response.parent == null || response.parent!.isEmpty) {
        throw Exception('Resource $commentId is not a comment after update (missing parent) on $serverIdForLog');
      }
      // Pass serverId for context
      final serverId =
          targetServerOverride?.id ??
          _configuredServerId ??
          _apiClient.basePath;
      return _convertApiMemoToComment(response, serverId);
    } catch (e) {
      throw Exception('Failed to update comment $commentId on $serverIdForLog: $e');
    }
  }

  @override
  Future<void> deleteNoteComment(
    String noteId,
    String commentId, {
    ServerConfig? targetServerOverride,
  }) async {
    final memoApi = _getMemoApiForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ??
        targetServerOverride?.id ??
        _configuredServerId ??
        'active';
    try {
      final formattedCommentId = _formatResourceName(commentId, 'memos');
      final http.Response response = await memoApi.memoServiceDeleteMemoWithHttpInfo(formattedCommentId);
      if (!(response.statusCode >= 200 && response.statusCode < 300)) {
        final errorBody = await _decodeBodyBytes(response);
        throw memos_api.ApiException(response.statusCode, errorBody);
      }
    } catch (e) {
      if (e is memos_api.ApiException) rethrow;
      throw Exception('Failed to delete comment $commentId (note $noteId) on $serverIdForLog: $e');
    }
  }

  // --- RESOURCE OPERATIONS (BaseApiService Implementation) ---

  @override
  Future<Map<String, dynamic>> uploadResource(
    Uint8List fileBytes,
    String filename,
    String contentType, {
    ServerConfig? targetServerOverride,
  }) async {
    final resourceApi = _getResourceApiForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ??
        targetServerOverride?.id ??
        _configuredServerId ??
        'active';
    try {
      final String base64Content = base64Encode(fileBytes);
      final resourcePayload = memos_api.V1Resource(
        filename: filename,
        type: contentType,
        content: base64Content,
      );
      final memos_api.V1Resource? createdResource = await resourceApi.resourceServiceCreateResource(resourcePayload);
      if (createdResource == null || createdResource.name == null) {
        throw Exception('Failed to upload resource to $serverIdForLog: Server returned null or invalid resource');
      }
      return {
        'id': _extractIdFromName(createdResource.name!),
        'name': createdResource.name!,
        'filename': createdResource.filename ?? filename,
        'contentType': createdResource.type ?? contentType,
        'size': createdResource.size != null ? int.tryParse(createdResource.size!) : null,
        'createTime': createdResource.createTime?.toIso8601String(),
        'externalLink': createdResource.externalLink,
      };
    } catch (e) {
      throw Exception('Failed to upload resource to $serverIdForLog: $e');
    }
  }

  @override
  Future<Uint8List> getResourceData(
    String resourceIdentifier, {
    ServerConfig? targetServerOverride,
  }) async {
    final apiClient = _getApiClientForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ??
        targetServerOverride?.id ??
        _configuredServerId ??
        'active';
    final String resourceId = _extractIdFromName(resourceIdentifier);
    final resourceUrl = '${apiClient.basePath}/o/r/$resourceId';

    if (kDebugMode) {
      print(
        '[MemosApiService.getResourceData] Attempting to fetch resource $resourceIdentifier (ID: $resourceId) from URL: $resourceUrl on server $serverIdForLog',
      );
    }

    try {
      // Get headers from the ApiClient's Authentication object
      final headers = <String, String>{'Accept': '*/*'};
      await apiClient.authentication?.applyToParams(
        [],
        headers,
      ); // Populates headers

      final response = await http.get(
        Uri.parse(resourceUrl),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (kDebugMode) {
          print(
            '[MemosApiService.getResourceData] Successfully fetched ${response.bodyBytes.length} bytes for resource $resourceIdentifier',
          );
        }
        return response.bodyBytes;
      } else {
        String errorBody = response.body;
        try {
          errorBody = utf8.decode(response.bodyBytes);
        } catch (_) {}
        if (kDebugMode) {
          print(
            '[MemosApiService.getResourceData] Failed to fetch resource $resourceIdentifier. Status: ${response.statusCode}, Body: $errorBody',
          );
        }
        throw memos_api.ApiException(
          response.statusCode,
          'Failed to fetch resource data from $resourceUrl: $errorBody',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '[MemosApiService.getResourceData] Error fetching resource $resourceIdentifier: $e',
        );
      }
      if (e is memos_api.ApiException) rethrow;
      if (e is http.ClientException) {
        throw Exception(
          'Network error fetching resource data for $resourceIdentifier from $serverIdForLog: ${e.message}',
        );
      }
      throw Exception(
        'Failed to fetch resource data for $resourceIdentifier from $serverIdForLog: $e',
      );
    }
  }

  // --- RELATION OPERATIONS (NoteApiService Implementation) ---

  @override
  Future<void> setNoteRelations(
    String noteId,
    List<Map<String, dynamic>> relations, {
    ServerConfig? targetServerOverride,
  }) async {
    final memoApi = _getMemoApiForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ??
        targetServerOverride?.id ??
        _configuredServerId ??
        'active';
    try {
      final formattedId = _formatResourceName(noteId, 'memos');
      final List<memos_api.V1MemoRelation> apiRelations = relations
          .map((relationMap) {
            final String? relatedMemoId = relationMap['relatedMemoId'] as String?;
            final String? typeString = relationMap['type'] as String?;
            memos_api.V1MemoRelationType? relationType;
            if (typeString != null) {
              switch (typeString.toUpperCase()) {
                case 'REFERENCE':
                  relationType = memos_api.V1MemoRelationType.REFERENCE;
                  break;
                case 'COMMENT':
                  relationType = memos_api.V1MemoRelationType.COMMENT;
                  break;
              }
            }
            final String? formattedRelatedMemoId = relatedMemoId != null ? _formatResourceName(relatedMemoId, 'memos') : null;
            if (formattedRelatedMemoId == null || relationType == null) {
              return null;
            }
            final relatedMemo = memos_api.V1MemoRelationMemo(name: formattedRelatedMemoId);
            final currentMemo = memos_api.V1MemoRelationMemo(name: formattedId);
            return memos_api.V1MemoRelation(
              memo: currentMemo,
              relatedMemo: relatedMemo,
              type: relationType,
            );
          })
          .whereType<memos_api.V1MemoRelation>()
          .toList();

      final requestBody = memos_api.MemoServiceSetMemoRelationsBody(
        relations: apiRelations,
      );
      await memoApi.memoServiceSetMemoRelations(formattedId, requestBody);
    } catch (e) {
      throw Exception('Failed to set note relations for $noteId on $serverIdForLog: $e');
    }
  }

  // --- HEALTH CHECK (BaseApiService Implementation) ---

  @override
  Future<bool> checkHealth() async {
    if (!isConfigured) return false;
    try {
      // Use a lightweight call, like getting workspace profile or listing 1 memo
      await listNotes(pageSize: 1);
      // Alternatively, Memos has a health check endpoint if the generated client supports it
      // await _someHealthCheckApi.getHealth();
      return true;
    } catch (e) {
      if (kDebugMode) print('[MemosApiService] Health check failed: $e');
      return false;
    }
  }

  // --- HELPER METHODS ---

  memos_api.MemoServiceApi _getMemoApiForServer(ServerConfig? serverConfig) {
    if (serverConfig == null) return _memoApi; // Use default configured client
    return memos_api.MemoServiceApi(_getApiClientForServer(serverConfig));
  }

  memos_api.ResourceServiceApi _getResourceApiForServer(ServerConfig? serverConfig) {
    if (serverConfig == null) {
      return _resourceApi; // Use default configured client
    }
    return memos_api.ResourceServiceApi(_getApiClientForServer(serverConfig));
  }

  memos_api.ApiClient _getApiClientForServer(ServerConfig? serverConfig) {
    if (serverConfig == null) {
      // Ensure the default client is initialized if accessed directly
       if (!_apiClient.basePath.startsWith('http')) {
        if (kDebugMode) {
          print(
            "[MemosApiService._getApiClientForServer] Warning: Default ApiClient seems uninitialized. Attempting re-init with current config.",
          );
        }
        if (_baseUrl.isNotEmpty && _authStrategy != null) {
          _initializeClient(_baseUrl, _authStrategy);
         } else {
           throw Exception("Default MemosApiService ApiClient is not configured.");
         }
       }
      return _apiClient;
    }

    // Create a temporary AuthStrategy for the target server
    // Assuming ServerConfig still holds authToken for this override scenario
    final targetAuthStrategy = BearerTokenAuthStrategy(serverConfig.authToken);
    final targetAuthentication = targetAuthStrategy.createMemosAuth();

    try {
      String targetBaseUrl = serverConfig.serverUrl;
      // Normalize URL
      if (targetBaseUrl.toLowerCase().contains('/api/v1')) {
        targetBaseUrl = targetBaseUrl.substring(0, targetBaseUrl.toLowerCase().indexOf('/api/v1'));
      } else if (targetBaseUrl.toLowerCase().endsWith('/memos')) {
        targetBaseUrl = targetBaseUrl.substring(0, targetBaseUrl.length - 6);
      }
      if (targetBaseUrl.endsWith('/')) {
        targetBaseUrl = targetBaseUrl.substring(0, targetBaseUrl.length - 1);
      }

      return memos_api.ApiClient(
        basePath: targetBaseUrl,
        authentication: targetAuthentication,
      );
    } catch (e) {
      throw Exception('Failed to create API client for target server ${serverConfig.name ?? serverConfig.id}: $e');
    }
  }

  String _formatResourceName(String id, String resourceType) {
    // Memos API uses 'memos/{id}' or 'resources/{id}' format
    if (id.contains('/')) {
      // Already formatted (e.g., 'memos/123')
      return id;
    }
    // Assume it's just the ID, format it
    return '$resourceType/$id';
  }

  String _extractIdFromName(String name) {
    // Extracts '123' from 'memos/123' or 'resources/123'
    return name.split('/').last;
  }

  NoteItem _convertApiMemoToNoteItem(memos_api.Apiv1Memo apiMemo) {
    DateTime parseDateTimeSafe(DateTime? dt) {
      // Handle potential null or epoch dates from API
      if (dt == null || dt.year == 1 || dt.year == 1970) {
        return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      }
      return dt
          .toLocal(); // Convert to local time for consistency? Or keep UTC? Let's try local.
    }
    final createTime = parseDateTimeSafe(apiMemo.createTime);
    final updateTime = parseDateTimeSafe(apiMemo.updateTime);
    // Use displayTime if available, otherwise updateTime, ensuring safety
    final displayTime = parseDateTimeSafe(apiMemo.displayTime ?? apiMemo.updateTime);

    return NoteItem(
      id: _extractIdFromName(apiMemo.name ?? ''),
      content: apiMemo.content ?? '',
      pinned: apiMemo.pinned ?? false,
      state: _parseApiStateToNoteState(apiMemo.state),
      visibility: _parseApiVisibilityToNoteVisibility(apiMemo.visibility),
      createTime: createTime,
      updateTime: updateTime,
      displayTime: displayTime,
      tags: apiMemo.tags,
      resources: apiMemo.resources.map(_convertApiResourceToMap).toList(),
      relations: apiMemo.relations.map(_convertApiRelationToMap).toList(),
      creatorId: apiMemo.creator != null ? _extractIdFromName(apiMemo.creator!) : null,
      parentId: apiMemo.parent != null ? _extractIdFromName(apiMemo.parent!) : null,
      startDate:
          null, // Memos API doesn't have start/end dates directly on memo
      endDate: null,
      // Memos doesn't have Blinko types, default to unknown
      blinkoType: BlinkoNoteType.unknown,
    );
  }

  Map<String, dynamic> _convertApiResourceToMap(memos_api.V1Resource apiResource) {
    DateTime? createTime;
    if (apiResource.createTime != null) {
      createTime = apiResource.createTime!.toLocal(); // Convert to local
    }
    return {
      'id': apiResource.name != null ? _extractIdFromName(apiResource.name!) : null,
      'name': apiResource.name, // Full name like 'resources/123'
      'filename': apiResource.filename,
      'contentType': apiResource.type,
      'size': apiResource.size != null ? int.tryParse(apiResource.size!) : null,
      'createTime': createTime?.toIso8601String(),
      'externalLink': apiResource.externalLink,
    };
  }

  // Updated converter to Comment model
  Comment _convertApiMemoToComment(
    memos_api.Apiv1Memo apiMemo,
    String serverId, // Server ID context passed in
  ) {
    DateTime parseDateTimeSafe(DateTime? dt) {
      if (dt == null || dt.year == 1 || dt.year == 1970) {
        return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      }
      return dt.toLocal(); // Convert to local time
    }
    final createTime = parseDateTimeSafe(apiMemo.createTime);
    final updateTime = parseDateTimeSafe(apiMemo.updateTime);

    return Comment(
      id: _extractIdFromName(apiMemo.name ?? ''),
      content: apiMemo.content ?? '',
      creatorId: apiMemo.creator != null ? _extractIdFromName(apiMemo.creator!) : null,
      createdTs: createTime, // Use DateTime
      updatedTs: updateTime, // Use DateTime
      state: _parseApiStateToCommentState(apiMemo.state),
      pinned: apiMemo.pinned ?? false,
      resources: apiMemo.resources.map(_convertApiResourceToMap).toList(),
      parentId:
          apiMemo.parent != null
              ? _extractIdFromName(apiMemo.parent!)
              : '', // Ensure parentId is non-null string
      serverId: serverId, // Pass serverId
      relations:
          const [], // Memos comments don't have relations in this context
      // attachment: null, // Removed - This was the cause of the error
    );
  }

  List<Comment> _parseCommentsFromApiResponse(
    memos_api.V1ListMemoCommentsResponse response,
    String parentId, // Parent note ID
    String serverId, // Server ID context
  ) {
    return response.memos
        .map((apiMemo) => _convertApiMemoToComment(apiMemo, serverId))
        .toList();
  }

  Map<String, dynamic> _convertApiRelationToMap(memos_api.V1MemoRelation apiRelation) {
    return {
      'memoId': apiRelation.memo?.name != null ? _extractIdFromName(apiRelation.memo!.name!) : null,
      'relatedMemoId': apiRelation.relatedMemo?.name != null ? _extractIdFromName(apiRelation.relatedMemo!.name!) : null,
      'type':
          apiRelation.type
              ?.toJson()
              .toUpperCase(), // e.g., "REFERENCE", "COMMENT"
    };
  }

  // Helper to convert app resource map list back to API V1Resource list
  List<memos_api.V1Resource> _convertResourcesToApi(
    List<Map<String, dynamic>>? resources,
  ) {
    if (resources == null) return [];
    return resources
        .map((resMap) {
          // Ensure 'name' is correctly formatted as 'resources/{id}' if available
          String? resourceName = resMap['name'] as String?;
          final String? resourceId = resMap['id'] as String?;
          if (resourceName == null && resourceId != null) {
            resourceName = _formatResourceName(resourceId, 'resources');
          }

          return memos_api.V1Resource(
            name: resourceName, // Use formatted name
            filename: resMap['filename'] as String?,
            type: resMap['contentType'] as String?,
            // Other fields like content, size, externalLink are usually read-only or set by server
          );
        })
        .where(
          (r) => r.name != null && r.name!.isNotEmpty,
        ) // Filter out invalid resources
        .toList();
  }

  // --- Enum Mapping Helpers ---

  NoteState _parseApiStateToNoteState(memos_api.V1State? apiState) {
    switch (apiState) {
      case memos_api.V1State.ARCHIVED:
        return NoteState.archived;
      case memos_api.V1State.NORMAL:
      default: // Treat unspecified or unknown as normal
        return NoteState.normal;
    }
  }

  CommentState _parseApiStateToCommentState(memos_api.V1State? apiState) {
    switch (apiState) {
      case memos_api.V1State.ARCHIVED:
        return CommentState.archived; // Memos only has Normal/Archived
      case memos_api.V1State.NORMAL:
      default:
        return CommentState.normal;
    }
  }

  NoteVisibility _parseApiVisibilityToNoteVisibility(memos_api.V1Visibility? apiVisibility) {
    switch (apiVisibility) {
      case memos_api.V1Visibility.PRIVATE:
        return NoteVisibility.private;
      case memos_api.V1Visibility.PROTECTED:
        return NoteVisibility.protected;
      case memos_api.V1Visibility.PUBLIC:
        return NoteVisibility.public;
      default: // Treat unspecified or unknown as private for safety
        return NoteVisibility.private;
    }
  }

  memos_api.V1State _getApiStateFromNoteState(NoteState noteState) {
    switch (noteState) {
      case NoteState.archived:
        return memos_api.V1State.ARCHIVED;
      case NoteState.normal:
      default:
        return memos_api.V1State.NORMAL;
    }
  }

  memos_api.V1State _getApiStateFromCommentState(CommentState commentState) {
    switch (commentState) {
      case CommentState.archived:
      case CommentState.deleted: // Map deleted to archived for Memos API
        return memos_api.V1State.ARCHIVED;
      case CommentState.normal:
      default:
        return memos_api.V1State.NORMAL;
    }
  }

  memos_api.V1Visibility _getApiVisibilityFromNoteVisibility(NoteVisibility noteVisibility) {
    switch (noteVisibility) {
      case NoteVisibility.private:
        return memos_api.V1Visibility.PRIVATE;
      case NoteVisibility.protected:
        return memos_api.V1Visibility.PROTECTED;
      case NoteVisibility.public:
      default: // Default to public if mapping from app model
        return memos_api.V1Visibility.PUBLIC;
    }
  }

  Future<String> _decodeBodyBytes(http.Response response) async {
    try {
      // Attempt to decode as UTF-8, allowing malformed sequences
      return utf8.decode(response.bodyBytes, allowMalformed: true);
    } catch (e) {
      // Fallback to Latin-1 or raw string if UTF-8 fails
      try {
        return latin1.decode(response.bodyBytes);
      } catch (_) {
        // Last resort: return the raw body string if decoding fails completely
        return response.body;
      }
    }
  }
}
