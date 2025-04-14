import 'dart:convert'; // For base64Encode, utf8
import 'dart:typed_data';

import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter_memos/api/lib/api.dart' as memos_api; // Alias Memos API
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/list_notes_response.dart';
import 'package:flutter_memos/models/memo_relation.dart';
import 'package:flutter_memos/models/note_item.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/services/base_api_service.dart';
import 'package:flutter_memos/utils/env.dart';
import 'package:http/http.dart' as http;

// Rename class and implement BaseApiService
class MemosApiService implements BaseApiService {
  // Keep singleton pattern if desired
  static final MemosApiService _instance = MemosApiService._internal();
  factory MemosApiService() => _instance;

  // Use aliased types
  late memos_api.MemoServiceApi _memoApi;
  late memos_api.ResourceServiceApi _resourceApi;
  late memos_api.ApiClient _apiClient;

  // Keep internal state
  String _baseUrl = '';
  String _authToken = '';

  // Implement BaseApiService properties
  @override
  String get apiBaseUrl => _baseUrl;

  @override
  bool get isConfigured => _baseUrl.isNotEmpty && _authToken.isNotEmpty;

  // Keep static config flags or manage them differently
  static bool verboseLogging = true; // Consider making this instance-based

  // For testing purposes
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
        baseUrl = Env.apiBaseUrl; // Fallback to environment variable if empty
      }
      // Clean up base URL
      if (baseUrl.toLowerCase().contains('/api/v1')) {
        final apiIndex = baseUrl.toLowerCase().indexOf('/api/v1');
        baseUrl = baseUrl.substring(0, apiIndex);
      } else if (baseUrl.toLowerCase().endsWith('/memos')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 6);
      }
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }

      final token =
          authToken.isNotEmpty
              ? authToken
              : Env.memosApiKey; // Use provided token or fallback
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

  // --- MEMO/NOTE OPERATIONS ---

  @override
  Future<ListNotesResponse> listNotes({
    int? pageSize,
    String? pageToken,
    String? filter,
    String? state,
    String? sort = 'updateTime', // Default sort
    String? direction = 'DESC', // Default direction
    ServerConfig? targetServerOverride,
  }) async {
    final memoApi = _getMemoApiForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
    const parent = 'users/-'; // Memos API requirement
    try {
      final memos_api.V1ListMemosResponse? response = await memoApi
          .memoServiceListMemos2(
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
      _lastServerOrder =
          notes
              .map((note) => note.id)
              .toList(); // Store order for testing/debug
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
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
    try {
      final formattedId = _formatResourceName(id, 'memos');
      final memos_api.Apiv1Memo? apiMemo = await memoApi.memoServiceGetMemo(
        formattedId,
      );
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
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
    try {
      final apiMemo = memos_api.Apiv1Memo(
        content: note.content,
        pinned: note.pinned,
        state: _getApiStateFromNoteState(note.state),
        visibility: _getApiVisibilityFromNoteVisibility(note.visibility),
        // Resources and relations are handled separately via setNoteRelations/uploadResource
      );
      final memos_api.Apiv1Memo? response = await memoApi.memoServiceCreateMemo(
        apiMemo,
      );
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
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
    try {
      final formattedId = _formatResourceName(id, 'memos');
      final originalCreateTime =
          note.createTime; // Preserve original create time
      final clientNow = DateTime.now().toUtc(); // Use client time for update

      final updatePayload = memos_api.TheMemoToUpdateTheNameFieldIsRequired(
        content: note.content,
        pinned: note.pinned,
        state: _getApiStateFromNoteState(note.state),
        visibility: _getApiVisibilityFromNoteVisibility(note.visibility),
        updateTime: clientNow, // Send client's update time
        // Resources and relations are handled separately
      );
      final memos_api.Apiv1Memo? response = await memoApi.memoServiceUpdateMemo(
        formattedId,
        updatePayload,
      );
      if (response == null) {
        throw Exception(
          'Failed to update note $id on $serverIdForLog: No response',
        );
      }
      NoteItem updatedAppNote = _convertApiMemoToNoteItem(response);
      // Restore original create time if server returns invalid one
      if (response.createTime != null &&
          (response.createTime!.year == 1970 ||
              response.createTime!.year == 1)) {
        updatedAppNote = updatedAppNote.copyWith(
          createTime: originalCreateTime,
        );
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
      final http.Response response = await memoApi
          .memoServiceDeleteMemoWithHttpInfo(formattedId);
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
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
    try {
      final formattedId = _formatResourceName(id, 'memos');
      final memos_api.Apiv1Memo? currentApiMemo = await memoApi
          .memoServiceGetMemo(formattedId);
      if (currentApiMemo == null) {
        throw Exception('Note $id not found on $serverIdForLog');
      }
      final updatePayload = memos_api.TheMemoToUpdateTheNameFieldIsRequired(
        content: currentApiMemo.content, // Keep content
        visibility: currentApiMemo.visibility, // Keep visibility
        state: memos_api.V1State.ARCHIVED, // Set state to ARCHIVED
        pinned: false, // Unpin on archive
        updateTime: DateTime.now().toUtc(),
      );
      final memos_api.Apiv1Memo? response = await memoApi.memoServiceUpdateMemo(
        formattedId,
        updatePayload,
      );
      if (response == null) {
        throw Exception(
          'Failed to archive note $id on $serverIdForLog: No response',
        );
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
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
    try {
      final formattedId = _formatResourceName(id, 'memos');
      final memos_api.Apiv1Memo? currentApiMemo = await memoApi
          .memoServiceGetMemo(formattedId);
      if (currentApiMemo == null) {
        throw Exception('Note $id not found on $serverIdForLog');
      }
      final bool currentPinState = currentApiMemo.pinned ?? false;
      final updatePayload = memos_api.TheMemoToUpdateTheNameFieldIsRequired(
        content: currentApiMemo.content, // Keep content
        visibility: currentApiMemo.visibility, // Keep visibility
        state: currentApiMemo.state, // Keep state
        pinned: !currentPinState, // Toggle pinned state
        updateTime: DateTime.now().toUtc(),
      );
      final memos_api.Apiv1Memo? response = await memoApi.memoServiceUpdateMemo(
        formattedId,
        updatePayload,
      );
      if (response == null) {
        throw Exception(
          'Failed to toggle pin for note $id on $serverIdForLog: No response',
        );
      }
      return _convertApiMemoToNoteItem(response);
    } catch (e) {
      throw Exception(
        'Failed to toggle pin for note $id on $serverIdForLog: $e',
      );
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
      final memos_api.V1ListMemoCommentsResponse? response = await memoApi
          .memoServiceListMemoComments(formattedId);
      if (response == null) {
        return [];
      }
      return _parseCommentsFromApiResponse(response);
    } catch (e) {
      throw Exception(
        'Failed to load comments for $noteId from $serverIdForLog: $e',
      );
    }
  }

  @override
  Future<Comment> getNoteComment(
    String commentId, {
    ServerConfig? targetServerOverride,
  }) async {
    final memoApi = _getMemoApiForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
    try {
      // Memos uses the same endpoint for notes and comments
      final formattedId = _formatResourceName(commentId, 'memos');
      final memos_api.Apiv1Memo? apiMemo = await memoApi.memoServiceGetMemo(
        formattedId,
      );
      if (apiMemo == null) {
        throw Exception('Comment $commentId not found on $serverIdForLog');
      }
      return _convertApiMemoToComment(apiMemo);
    } catch (e) {
      throw Exception(
        'Failed to load comment $commentId from $serverIdForLog: $e',
      );
    }
  }

  @override
  Future<Comment> createNoteComment(
    String noteId,
    Comment comment, {
    ServerConfig? targetServerOverride,
    List<memos_api.V1Resource>? resources, // Use V1Resource type
  }) async {
    final memoApi = _getMemoApiForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
    try {
      final formattedMemoId = _formatResourceName(noteId, 'memos');
      // Use the passed resources, or the ones from the comment object if available
      final List<memos_api.V1Resource> effectiveResources =
          resources ?? comment.resources ?? [];

      final apiMemo = memos_api.Apiv1Memo(
        content: comment.content,
        pinned: comment.pinned,
        state: _getApiStateFromCommentState(comment.state),
        resources: effectiveResources, // Pass resources
      );
      final memos_api.Apiv1Memo? response = await memoApi
          .memoServiceCreateMemoComment(formattedMemoId, apiMemo);
      if (response == null) {
        throw Exception(
          'Failed to create comment on $serverIdForLog: No response',
        );
      }
      return _convertApiMemoToComment(response);
    } catch (e) {
      throw Exception(
        'Failed to create comment for $noteId on $serverIdForLog: $e',
      );
    }
  }

  @override
  Future<Comment> updateNoteComment(
    String commentId, // Use commentId as the primary identifier
    Comment comment, { // Pass the updated Comment object
    ServerConfig? targetServerOverride,
  }) async {
    final memoApi = _getMemoApiForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
    try {
      final formattedCommentId = _formatResourceName(commentId, 'memos');
      final updateMemo = memos_api.TheMemoToUpdateTheNameFieldIsRequired(
        content: comment.content,
        pinned: comment.pinned,
        state: _getApiStateFromCommentState(comment.state),
        updateTime: DateTime.now().toUtc(),
        // Resources might need separate handling if update isn't direct
      );
      final memos_api.Apiv1Memo? response = await memoApi.memoServiceUpdateMemo(
        formattedCommentId,
        updateMemo,
      );
      if (response == null) {
        throw Exception(
          'Failed to update comment $commentId on $serverIdForLog: No response',
        );
      }
      return _convertApiMemoToComment(response);
    } catch (e) {
      throw Exception(
        'Failed to update comment $commentId on $serverIdForLog: $e',
      );
    }
  }

  @override
  Future<void> deleteNoteComment(
    String
    noteId, // Keep noteId for context if needed, though Memos API might not use it
    String commentId, {
    ServerConfig? targetServerOverride,
  }) async {
    final memoApi = _getMemoApiForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
    try {
      // Memos uses the same delete endpoint for notes and comments
      final formattedCommentId = _formatResourceName(commentId, 'memos');
      final http.Response response = await memoApi
          .memoServiceDeleteMemoWithHttpInfo(formattedCommentId);
      if (!(response.statusCode >= 200 && response.statusCode < 300)) {
        final errorBody = await _decodeBodyBytes(response);
        throw memos_api.ApiException(response.statusCode, errorBody);
      }
    } catch (e) {
      if (e is memos_api.ApiException) rethrow;
      throw Exception(
        'Failed to delete comment $commentId (note $noteId) on $serverIdForLog: $e',
      );
    }
  }

  // --- RESOURCE OPERATIONS ---

  @override
  Future<memos_api.V1Resource> uploadResource(
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
        content: base64Content,
      );
      final memos_api.V1Resource? createdResource = await resourceApi
          .resourceServiceCreateResource(resourcePayload);
      if (createdResource == null || createdResource.name == null) {
        throw Exception(
          'Failed to upload resource to $serverIdForLog: Server returned null or invalid resource',
        );
      }
      return createdResource;
    } catch (e) {
      throw Exception('Failed to upload resource to $serverIdForLog: $e');
    }
  }

  // --- RELATION OPERATIONS ---

  @override
  Future<void> setNoteRelations(
    String noteId,
    List<MemoRelation> relations, {
    ServerConfig? targetServerOverride,
  }) async {
    final memoApi = _getMemoApiForServer(targetServerOverride);
    final serverIdForLog =
        targetServerOverride?.name ?? targetServerOverride?.id ?? 'active';
    try {
      final formattedId = _formatResourceName(noteId, 'memos');
      final List<memos_api.V1MemoRelation> apiRelations =
          relations.map((relation) => relation.toApiRelation()).toList();
      final requestBody = memos_api.MemoServiceSetMemoRelationsBody(
        relations: apiRelations,
      );
      await memoApi.memoServiceSetMemoRelations(formattedId, requestBody);
    } catch (e) {
      throw Exception(
        'Failed to set note relations for $noteId on $serverIdForLog: $e',
      );
    }
  }

  // --- HEALTH CHECK ---

  @override
  Future<bool> checkHealth() async {
    if (!isConfigured) return false;
    try {
      // Use a lightweight call like listing 1 note
      await listNotes(pageSize: 1);
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- HELPER METHODS ---

  // Gets the appropriate MemoServiceApi instance (active or temporary)
  memos_api.MemoServiceApi _getMemoApiForServer(ServerConfig? serverConfig) {
    if (serverConfig == null ||
        (serverConfig.serverUrl == _baseUrl &&
            serverConfig.authToken == _authToken)) {
      return _memoApi; // Use the default instance
    }
    // Create a temporary client for the target server
    return memos_api.MemoServiceApi(_getApiClientForServer(serverConfig));
  }

  // Gets the appropriate ResourceServiceApi instance (active or temporary)
  memos_api.ResourceServiceApi _getResourceApiForServer(
    ServerConfig? serverConfig,
  ) {
    if (serverConfig == null ||
        (serverConfig.serverUrl == _baseUrl &&
            serverConfig.authToken == _authToken)) {
      return _resourceApi; // Use the default instance
    }
    // Create a temporary client for the target server
    return memos_api.ResourceServiceApi(_getApiClientForServer(serverConfig));
  }

  // Creates a temporary ApiClient for a specific server config
  memos_api.ApiClient _getApiClientForServer(ServerConfig serverConfig) {
    try {
      String targetBaseUrl = serverConfig.serverUrl;
      // Clean up URL
      if (targetBaseUrl.toLowerCase().contains('/api/v1')) {
        targetBaseUrl = targetBaseUrl.substring(
          0,
          targetBaseUrl.toLowerCase().indexOf('/api/v1'),
        );
      } else if (targetBaseUrl.toLowerCase().endsWith('/memos')) {
        targetBaseUrl = targetBaseUrl.substring(0, targetBaseUrl.length - 6);
      }
      if (targetBaseUrl.endsWith('/')) {
        targetBaseUrl = targetBaseUrl.substring(0, targetBaseUrl.length - 1);
      }
      return memos_api.ApiClient(
        basePath: targetBaseUrl,
        authentication:
            memos_api.HttpBearerAuth()..accessToken = serverConfig.authToken,
      );
    } catch (e) {
      throw Exception(
        'Failed to create API client for target server ${serverConfig.name ?? serverConfig.id}: $e',
      );
    }
  }

  // Formats ID into Memos resource name (e.g., "memos/123")
  String _formatResourceName(String id, String resourceType) {
    if (id.contains('/')) {
      return id; // Already formatted
    }
    return '$resourceType/$id';
  }

  // Extracts numeric ID from Memos resource name (e.g., "memos/123" -> "123")
  String _extractIdFromName(String name) {
    return name.split('/').last;
  }

  // Converts Memos API memo object to common NoteItem
  NoteItem _convertApiMemoToNoteItem(memos_api.Apiv1Memo apiMemo) {
    DateTime parseDateTimeSafe(DateTime? dt) {
      if (dt == null) return DateTime(1970);
      // Handle potential zero/epoch dates from API
      if (dt.year == 1 || dt.year == 1970) return DateTime(1970);
      return dt;
    }

    final createTime = parseDateTimeSafe(apiMemo.createTime);
    final updateTime = parseDateTimeSafe(apiMemo.updateTime);
    final displayTime = parseDateTimeSafe(
      apiMemo.displayTime ?? apiMemo.updateTime,
    ); // Fallback display time

    return NoteItem(
      id: _extractIdFromName(apiMemo.name ?? ''),
      content: apiMemo.content ?? '',
      pinned: apiMemo.pinned ?? false,
      state: _parseApiStateToNoteState(apiMemo.state),
      visibility: _parseApiVisibilityToNoteVisibility(apiMemo.visibility),
      createTime: createTime,
      updateTime: updateTime,
      displayTime: displayTime,
      tags:
          apiMemo.tags ?? [], // Correctly assign List<String>? to List<String>
      resources:
          apiMemo.resources
              .map((r) => r.toJson())
              .toList(), // Store as JSON for now
      relations:
          apiMemo.relations
              .map((r) => r.toJson())
              .toList(), // Store as JSON for now
      creatorId:
          apiMemo.creator != null ? _extractIdFromName(apiMemo.creator!) : null,
      parentId:
          apiMemo.parent != null ? _extractIdFromName(apiMemo.parent!) : null,
    );
  }

  // Converts Memos API memo object to common Comment model
  Comment _convertApiMemoToComment(memos_api.Apiv1Memo apiMemo) {
    DateTime parseDateTimeSafe(DateTime? dt) {
      if (dt == null) return DateTime(1970);
      if (dt.year == 1 || dt.year == 1970) return DateTime(1970);
      return dt;
    }

    final createTime = parseDateTimeSafe(apiMemo.createTime);
    final updateTime = parseDateTimeSafe(apiMemo.updateTime);

    return Comment(
      id: _extractIdFromName(apiMemo.name ?? ''),
      content: apiMemo.content ?? '',
      creatorId:
          apiMemo.creator != null ? _extractIdFromName(apiMemo.creator!) : null,
      createTime: createTime.millisecondsSinceEpoch,
      updateTime: updateTime.millisecondsSinceEpoch,
      state: _parseApiStateToCommentState(apiMemo.state),
      pinned: apiMemo.pinned ?? false,
      resources: apiMemo.resources, // Pass V1Resource list directly
    );
  }

  // Parses Memos API comment list response
  List<Comment> _parseCommentsFromApiResponse(
    memos_api.V1ListMemoCommentsResponse response,
  ) {
    return response.memos.map(_convertApiMemoToComment).toList();
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

  NoteVisibility _parseApiVisibilityToNoteVisibility(
    memos_api.V1Visibility? apiVisibility,
  ) {
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
      case CommentState.deleted: // Map deleted to archived for Memos
        return memos_api.V1State.ARCHIVED;
      case CommentState.normal:
      default:
        return memos_api.V1State.NORMAL;
    }
  }

  memos_api.V1Visibility _getApiVisibilityFromNoteVisibility(
    NoteVisibility noteVisibility,
  ) {
    switch (noteVisibility) {
      case NoteVisibility.private:
        return memos_api.V1Visibility.PRIVATE;
      case NoteVisibility.protected:
        return memos_api.V1Visibility.PROTECTED;
      case NoteVisibility.public:
      default:
        return memos_api.V1Visibility.PUBLIC;
    }
  }

  // Helper to decode response body safely
  Future<String> _decodeBodyBytes(http.Response response) async {
    try {
      // TODO: Check content encoding if necessary (e.g., gzip)
      return utf8.decode(response.bodyBytes, allowMalformed: true);
    } catch (e) {
      // Fallback or rethrow
      return response.body; // May be garbled if encoding is wrong
    }
  }
}
