import 'dart:convert'; // For base64Encode, utf8

import 'package:flutter/foundation.dart'; // For kDebugMode, Uint8List
import 'package:flutter_memos/api/lib/api.dart' as memos_api; // Alias Memos API
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/list_notes_response.dart';
import 'package:flutter_memos/models/note_item.dart'; // Use NoteItem
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/services/base_api_service.dart';
import 'package:flutter_memos/utils/env.dart';
import 'package:http/http.dart' as http;

// Keep class name MemosApiService, implements BaseApiService
class MemosApiService implements BaseApiService {
  static final MemosApiService _instance = MemosApiService._internal();
  factory MemosApiService() => _instance;

  late memos_api.MemoServiceApi _memoApi;
  late memos_api.ResourceServiceApi _resourceApi;
  late memos_api.ApiClient _apiClient;

  String _baseUrl = '';
  String _authToken = '';

  @override
  String get apiBaseUrl => _baseUrl;

  @override
  bool get isConfigured => _baseUrl.isNotEmpty && _authToken.isNotEmpty;

  static bool verboseLogging = true;

  static List<String>? _lastServerOrder;
  static List<String> get lastServerOrder => _lastServerOrder ?? [];

  MemosApiService._internal() {
    _initializeClient('', '');
  }

  @override
  Future<void> configureService({
    required String baseUrl,
    required String authToken,
  }) async {
    if (_baseUrl == baseUrl && _authToken == authToken) {
      return;
    }
    _baseUrl = baseUrl;
    _authToken = authToken;
    try {
      _initializeClient(baseUrl, authToken);
    } catch (e) {
      rethrow;
    }
  }

  void _initializeClient(String baseUrl, String authToken) {
    try {
      if (baseUrl.isEmpty) {
        baseUrl = Env.apiBaseUrl;
      }
      if (baseUrl.toLowerCase().contains('/api/v1')) {
        final apiIndex = baseUrl.toLowerCase().indexOf('/api/v1');
        baseUrl = baseUrl.substring(0, apiIndex);
      } else if (baseUrl.toLowerCase().endsWith('/memos')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 6);
      }
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }

      final token = authToken.isNotEmpty ? authToken : Env.memosApiKey;
      _apiClient = memos_api.ApiClient(
        basePath: baseUrl,
        authentication: memos_api.HttpBearerAuth()..accessToken = token,
      );
      _memoApi = memos_api.MemoServiceApi(_apiClient);
      _resourceApi = memos_api.ResourceServiceApi(_apiClient);
    } catch (e) {
      throw Exception('Failed to initialize Memos API client: $e');
    }
  }

  // --- NOTE OPERATIONS --- // Renamed section comment

  @override
  Future<ListNotesResponse> listNotes({
    int? pageSize,
    String? pageToken,
    String? filter,
    String? state,
    String? sort = 'updateTime',
    String? direction = 'DESC',
    ServerConfig? targetServerOverride,
  }) async {
    final memoApi = _getMemoApiForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
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
      final notes = response.memos.map(_convertApiMemoToNoteItem).toList(); // Use NoteItem
      final nextToken = response.nextPageToken;
      _lastServerOrder = notes.map((note) => note.id).toList();
      return ListNotesResponse(notes: notes, nextPageToken: nextToken);
    } catch (e) {
      throw Exception('Failed to load notes from $serverIdForLog: $e');
    }
  }

  @override
  Future<NoteItem> getNote( // Return NoteItem
    String id, {
    ServerConfig? targetServerOverride,
  }) async {
    final memoApi = _getMemoApiForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
    try {
      final formattedId = _formatResourceName(id, 'memos');
      final memos_api.Apiv1Memo? apiMemo = await memoApi.memoServiceGetMemo(formattedId);
      if (apiMemo == null) {
        throw Exception('Note $id not found on $serverIdForLog');
      }
      return _convertApiMemoToNoteItem(apiMemo); // Use NoteItem
    } catch (e) {
      throw Exception('Failed to load note $id from $serverIdForLog: $e');
    }
  }

  @override
  Future<NoteItem> createNote( // Accept and return NoteItem
    NoteItem note, {
    ServerConfig? targetServerOverride,
  }) async {
    final memoApi = _getMemoApiForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
    try {
      final apiMemo = memos_api.Apiv1Memo(
        content: note.content,
        pinned: note.pinned,
        state: _getApiStateFromNoteState(note.state),
        visibility: _getApiVisibilityFromNoteVisibility(note.visibility),
        // Add tags if needed: tags: note.tags,
        // Add resources if needed: resources: _convertResourcesToApi(note.resources),
      );
      final memos_api.Apiv1Memo? response = await memoApi.memoServiceCreateMemo(apiMemo);
      if (response == null) {
        throw Exception('Failed to create note on $serverIdForLog: No response');
      }
      return _convertApiMemoToNoteItem(response); // Use NoteItem
    } catch (e) {
      throw Exception('Failed to create note on $serverIdForLog: $e');
    }
  }

  @override
  Future<NoteItem> updateNote( // Accept and return NoteItem
    String id,
    NoteItem note, {
    ServerConfig? targetServerOverride,
  }) async {
    final memoApi = _getMemoApiForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
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
        // Add tags if needed: tags: note.tags,
        // Add resources if needed: resources: _convertResourcesToApi(note.resources),
      );
      final memos_api.Apiv1Memo? response = await memoApi.memoServiceUpdateMemo(formattedId, updatePayload);
      if (response == null) {
        throw Exception('Failed to update note $id on $serverIdForLog: No response');
      }
      NoteItem updatedAppNote = _convertApiMemoToNoteItem(response); // Use NoteItem
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
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
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
  Future<NoteItem> archiveNote( // Return NoteItem
    String id, {
    ServerConfig? targetServerOverride,
  }) async {
    final memoApi = _getMemoApiForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
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
        // tags: currentApiMemo.tags, // Preserve tags
        // resources: currentApiMemo.resources, // Preserve resources
      );
      final memos_api.Apiv1Memo? response = await memoApi.memoServiceUpdateMemo(formattedId, updatePayload);
      if (response == null) {
        throw Exception('Failed to archive note $id on $serverIdForLog: No response');
      }
      return _convertApiMemoToNoteItem(response); // Use NoteItem
    } catch (e) {
      throw Exception('Failed to archive note $id on $serverIdForLog: $e');
    }
  }

  @override
  Future<NoteItem> togglePinNote( // Return NoteItem
    String id, {
    ServerConfig? targetServerOverride,
  }) async {
    final memoApi = _getMemoApiForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
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
        // tags: currentApiMemo.tags, // Preserve tags
        // resources: currentApiMemo.resources, // Preserve resources
      );
      final memos_api.Apiv1Memo? response = await memoApi.memoServiceUpdateMemo(formattedId, updatePayload);
      if (response == null) {
        throw Exception('Failed to toggle pin for note $id on $serverIdForLog: No response');
      }
      return _convertApiMemoToNoteItem(response); // Use NoteItem
    } catch (e) {
      throw Exception('Failed to toggle pin for note $id on $serverIdForLog: $e');
    }
  }

  // --- COMMENT OPERATIONS ---

  @override
  Future<List<Comment>> listNoteComments(
    String noteId, {
    ServerConfig? targetServerOverride,
  }) async {
    final memoApi = _getMemoApiForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
    try {
      final formattedId = _formatResourceName(noteId, 'memos');
      final memos_api.V1ListMemoCommentsResponse? response = await memoApi.memoServiceListMemoComments(formattedId);
      if (response == null) {
        return [];
      }
      return _parseCommentsFromApiResponse(response);
    } catch (e) {
      throw Exception('Failed to load comments for note $noteId from $serverIdForLog: $e');
    }
  }

  @override
  Future<Comment> getNoteComment(
    String commentId, { // commentId is expected to be "memos/{id}" or just "{id}"
    ServerConfig? targetServerOverride,
  }) async {
    final memoApi = _getMemoApiForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
    try {
      // Memos API uses the same endpoint for getting notes and comments
      final formattedId = _formatResourceName(commentId, 'memos');
      final memos_api.Apiv1Memo? apiMemo = await memoApi.memoServiceGetMemo(formattedId);
      if (apiMemo == null) {
        throw Exception('Comment $commentId not found on $serverIdForLog');
      }
      // Ensure it's actually a comment (check parent field?) - Memos API doesn't enforce this well
      if (apiMemo.parent == null || apiMemo.parent!.isEmpty) {
        throw Exception('Resource $commentId is not a comment (missing parent) on $serverIdForLog');
      }
      return _convertApiMemoToComment(apiMemo);
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
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
    try {
      final formattedMemoId = _formatResourceName(noteId, 'memos');

      final List<memos_api.V1Resource> effectiveResources = (resources ?? [])
          .map((resMap) {
            return memos_api.V1Resource(
              name: resMap['name'] as String?,
              filename: resMap['filename'] as String?,
              type: resMap['contentType'] as String?, // Map contentType to type
            );
          })
          .where((r) => r.name != null && r.name!.isNotEmpty)
          .toList();

      final apiMemo = memos_api.Apiv1Memo(
        content: comment.content,
        pinned: comment.pinned,
        state: _getApiStateFromCommentState(comment.state),
        resources: effectiveResources,
        // parent: formattedMemoId, // Set parent to link it as a comment - API might handle this automatically
      );
      final memos_api.Apiv1Memo? response = await memoApi.memoServiceCreateMemoComment(formattedMemoId, apiMemo);
      if (response == null) {
        throw Exception('Failed to create comment on $serverIdForLog: No response');
      }
      return _convertApiMemoToComment(response);
    } catch (e) {
      throw Exception('Failed to create comment for note $noteId on $serverIdForLog: $e');
    }
  }

  @override
  Future<Comment> updateNoteComment(
    String commentId, // commentId is expected to be "memos/{id}" or just "{id}"
    Comment comment, {
    ServerConfig? targetServerOverride,
  }) async {
    final memoApi = _getMemoApiForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
    try {
      // Memos API uses the same endpoint for updating notes and comments
      final formattedCommentId = _formatResourceName(commentId, 'memos');
      final updateMemo = memos_api.TheMemoToUpdateTheNameFieldIsRequired(
        content: comment.content,
        pinned: comment.pinned,
        state: _getApiStateFromCommentState(comment.state),
        updateTime: DateTime.now().toUtc(),
        // resources: _convertResourcesToApi(comment.resources), // Update resources if needed
      );
      final memos_api.Apiv1Memo? response = await memoApi.memoServiceUpdateMemo(formattedCommentId, updateMemo);
      if (response == null) {
        throw Exception('Failed to update comment $commentId on $serverIdForLog: No response');
      }
      // Ensure it's still a comment after update (check parent field?)
      if (response.parent == null || response.parent!.isEmpty) {
        throw Exception('Resource $commentId is not a comment after update (missing parent) on $serverIdForLog');
      }
      return _convertApiMemoToComment(response);
    } catch (e) {
      throw Exception('Failed to update comment $commentId on $serverIdForLog: $e');
    }
  }

  @override
  Future<void> deleteNoteComment(
    String noteId, // noteId is technically not needed by Memos API for deletion
    String commentId, { // commentId is expected to be "memos/{id}" or just "{id}"
    ServerConfig? targetServerOverride,
  }) async {
    final memoApi = _getMemoApiForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
    try {
      // Memos API uses the same endpoint for deleting notes and comments
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

  // --- RESOURCE OPERATIONS ---

  @override
  Future<Map<String, dynamic>> uploadResource(
    Uint8List fileBytes,
    String filename,
    String contentType, {
    ServerConfig? targetServerOverride,
  }) async {
    final resourceApi = _getResourceApiForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
    try {
      final String base64Content = base64Encode(fileBytes);
      final resourcePayload = memos_api.V1Resource(
        filename: filename,
        type: contentType,
        content: base64Content, // Send content as base64 string
      );
      final memos_api.V1Resource? createdResource = await resourceApi.resourceServiceCreateResource(resourcePayload);
      if (createdResource == null || createdResource.name == null) {
        throw Exception('Failed to upload resource to $serverIdForLog: Server returned null or invalid resource');
      }
      // Map V1Resource fields to the expected Map structure
      return {
        'id': _extractIdFromName(createdResource.name!), // Extract ID from name
        'name': createdResource.name!, // Keep the full name
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

  // --- RELATION OPERATIONS ---

  @override
  Future<void> setNoteRelations(
    String noteId,
    List<Map<String, dynamic>> relations, {
    ServerConfig? targetServerOverride,
  }) async {
    final memoApi = _getMemoApiForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
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

  // --- HEALTH CHECK ---

  @override
  Future<bool> checkHealth() async {
    if (!isConfigured) return false;
    try {
      // Use a lightweight endpoint if available, otherwise listNotes is okay
      await listNotes(pageSize: 1);
      return true;
    } catch (e) {
      if (kDebugMode) print('[MemosApiService] Health check failed: $e');
      return false;
    }
  }

  // --- RESOURCE DATA FETCHING ---

  @override
  Future<Uint8List> getResourceData(
    String resourceIdentifier, { // Identifier is likely the 'name' (e.g., "resources/123")
    ServerConfig? targetServerOverride,
  }) async {
    final apiClient = _getApiClientForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';

    // Memos resource URL structure: {baseUrl}/o/r/{resourceId}/{filename}
    // The 'resourceIdentifier' is the 'name' field, like "resources/123"
    // We need to extract the ID and potentially get the filename from the API if not provided.
    // For simplicity, let's assume the identifier *is* the name and construct the URL.
    // A more robust way might involve fetching the resource metadata first if needed.

    final String resourceId = _extractIdFromName(resourceIdentifier);
    // Construct the URL. We might not know the filename here, but Memos often redirects
    // or serves the content even without the correct filename in the URL path.
    // Using a placeholder filename or just the ID might work. Let's try with just the ID first.
    // The actual path is /o/r/{resourceId}/{optional_filename}
    // Let's try the direct resource link format if available or construct one.
    // The ResourceServiceApi doesn't have a dedicated download method.
    // We need to use a direct HTTP GET request.

    // Construct the URL based on the API base path and Memos resource path structure
    final resourceUrl = '${apiClient.basePath}/o/r/$resourceId';

    if (kDebugMode) {
      print(
        '[MemosApiService.getResourceData] Attempting to fetch resource $resourceIdentifier (ID: $resourceId) from URL: $resourceUrl on server $serverIdForLog',
      );
    }

    try {
      final response = await http.get(
        Uri.parse(resourceUrl),
        headers: {
          'Authorization':
              'Bearer ${apiClient.authentication is memos_api.HttpBearerAuth ? (apiClient.authentication as memos_api.HttpBearerAuth).accessToken : ''}',
          'Accept': '*/*', // Accept any content type
        },
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
          // Try decoding as UTF-8 for potential error messages
          errorBody = utf8.decode(response.bodyBytes);
        } catch (_) {
          // Ignore decoding errors, keep original body string
        }
        if (kDebugMode) {
          print(
            '[MemosApiService.getResourceData] Failed to fetch resource $resourceIdentifier. Status: ${response.statusCode}, Body: $errorBody',
          );
        }
        // Throw an exception that mimics ApiException structure if possible
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
      if (e is memos_api.ApiException) rethrow; // Re-throw API exceptions directly
      if (e is http.ClientException) {
        // Wrap HTTP client errors
        throw Exception(
          'Network error fetching resource data for $resourceIdentifier from $serverIdForLog: ${e.message}',
        );
      }
      // Wrap other potential errors
      throw Exception(
        'Failed to fetch resource data for $resourceIdentifier from $serverIdForLog: $e',
      );
    }
  }


  // --- HELPER METHODS ---

  memos_api.MemoServiceApi _getMemoApiForServer(ServerConfig? serverConfig) {
    if (serverConfig == null ||
        (serverConfig.serverUrl == _baseUrl &&
         serverConfig.authToken == _authToken)) {
      return _memoApi;
    }
    return memos_api.MemoServiceApi(_getApiClientForServer(serverConfig));
  }

  memos_api.ResourceServiceApi _getResourceApiForServer(ServerConfig? serverConfig) {
    if (serverConfig == null ||
        (serverConfig.serverUrl == _baseUrl &&
         serverConfig.authToken == _authToken)) {
      return _resourceApi;
    }
    return memos_api.ResourceServiceApi(_getApiClientForServer(serverConfig));
  }

  memos_api.ApiClient _getApiClientForServer(ServerConfig? serverConfig) {
     // Added null check for serverConfig
    if (serverConfig == null ||
        (serverConfig.serverUrl == _baseUrl &&
         serverConfig.authToken == _authToken)) {
      // Ensure the default client is properly initialized if used
       if (!_apiClient.basePath.startsWith('http')) {
         if (kDebugMode) print("[MemosApiService._getApiClientForServer] Warning: Default ApiClient seems uninitialized. Attempting re-init.");
         if (_baseUrl.isNotEmpty && _authToken.isNotEmpty) {
           _initializeClient(_baseUrl, _authToken);
         } else {
           throw Exception("Default MemosApiService ApiClient is not configured.");
         }
       }
      return _apiClient;
    }
    try {
      String targetBaseUrl = serverConfig.serverUrl;
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
        authentication: memos_api.HttpBearerAuth()..accessToken = serverConfig.authToken,
      );
    } catch (e) {
      throw Exception('Failed to create API client for target server ${serverConfig.name ?? serverConfig.id}: $e');
    }
  }

  String _formatResourceName(String id, String resourceType) {
    if (id.contains('/')) {
      return id;
    }
    return '$resourceType/$id';
  }

  String _extractIdFromName(String name) {
    return name.split('/').last;
  }

  // Updated converter to NoteItem
  NoteItem _convertApiMemoToNoteItem(memos_api.Apiv1Memo apiMemo) {
    DateTime parseDateTimeSafe(DateTime? dt) {
      if (dt == null || dt.year == 1 || dt.year == 1970) return DateTime(1970);
      return dt;
    }
    final createTime = parseDateTimeSafe(apiMemo.createTime);
    final updateTime = parseDateTimeSafe(apiMemo.updateTime);
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
      // Add startDate and endDate mapping if Memos API supports them
      startDate: null, // Placeholder
      endDate: null,   // Placeholder
    );
  }

  // Helper to convert V1Resource to a generic Map
  Map<String, dynamic> _convertApiResourceToMap(memos_api.V1Resource apiResource) {
    return {
      'id': apiResource.name != null ? _extractIdFromName(apiResource.name!) : null,
      'name': apiResource.name, // Keep the full name (e.g., resources/123)
      'filename': apiResource.filename,
      'contentType': apiResource.type,
      'size': apiResource.size != null ? int.tryParse(apiResource.size!) : null,
      'createTime': apiResource.createTime?.toIso8601String(),
      'externalLink': apiResource.externalLink,
      // Add other fields if needed, e.g., publicId, uid
    };
  }

  Comment _convertApiMemoToComment(memos_api.Apiv1Memo apiMemo) {
    DateTime parseDateTimeSafe(DateTime? dt) {
      if (dt == null || dt.year == 1 || dt.year == 1970) return DateTime(1970);
      return dt;
    }
    final createTime = parseDateTimeSafe(apiMemo.createTime);
    final updateTime = parseDateTimeSafe(apiMemo.updateTime);

    return Comment(
      id: _extractIdFromName(apiMemo.name ?? ''),
      content: apiMemo.content ?? '',
      creatorId: apiMemo.creator != null ? _extractIdFromName(apiMemo.creator!) : null,
      createTime: createTime.millisecondsSinceEpoch,
      updateTime: updateTime.millisecondsSinceEpoch,
      state: _parseApiStateToCommentState(apiMemo.state),
      pinned: apiMemo.pinned ?? false,
      resources: apiMemo.resources.map(_convertApiResourceToMap).toList(),
    );
  }

  List<Comment> _parseCommentsFromApiResponse(memos_api.V1ListMemoCommentsResponse response) {
    return response.memos.map(_convertApiMemoToComment).toList();
  }

  Map<String, dynamic> _convertApiRelationToMap(memos_api.V1MemoRelation apiRelation) {
    return {
      'memoId': apiRelation.memo?.name != null ? _extractIdFromName(apiRelation.memo!.name!) : null,
      'relatedMemoId': apiRelation.relatedMemo?.name != null ? _extractIdFromName(apiRelation.relatedMemo!.name!) : null,
      'type': apiRelation.type?.toJson().toUpperCase(),
    };
  }

  // --- Enum Mapping Helpers ---

  NoteState _parseApiStateToNoteState(memos_api.V1State? apiState) {
    switch (apiState) {
      case memos_api.V1State.ARCHIVED:
        return NoteState.archived;
      case memos_api.V1State.NORMAL:
      default:
        return NoteState.normal;
    }
  }

  CommentState _parseApiStateToCommentState(memos_api.V1State? apiState) {
    switch (apiState) {
      case memos_api.V1State.ARCHIVED:
        return CommentState.archived;
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
      default:
        return NoteVisibility.public;
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
      case CommentState.deleted:
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
        return memos_api.V1Visibility.PUBLIC;
    }
  }

  Future<String> _decodeBodyBytes(http.Response response) async {
    try {
      return utf8.decode(response.bodyBytes, allowMalformed: true);
    } catch (e) {
      return response.body;
    }
  }
}
