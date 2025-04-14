import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'package:flutter_memos/api/lib/api.dart'
    as memos_api; // Import Memos API for V1Resource
import 'package:flutter_memos/blinko_api/lib/api.dart' as blinko_api; // Alias Blinko API
// Assuming memos_api and http packages are imported for resource upload
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/list_notes_response.dart';
import 'package:flutter_memos/models/memo_relation.dart';
import 'package:flutter_memos/models/note_item.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/services/base_api_service.dart';
import 'package:http/http.dart' as http;

class BlinkoApiService implements BaseApiService {
  // Singleton pattern (optional)
  static final BlinkoApiService _instance = BlinkoApiService._internal();
  factory BlinkoApiService() => _instance;

  late blinko_api.ApiClient _apiClient;
  late blinko_api.NoteApi _noteApi;
  late blinko_api.CommentApi _commentApi;
  late blinko_api.FileApi _fileApi; // Add FileApi instance
  // Add other Blinko API parts as needed (e.g., TagApi, FileApi)

  String _baseUrl = '';
  String _authToken = '';

  // Static config flags (can be instance members too)
  static bool verboseLogging = true;

  BlinkoApiService._internal() {
    // Initialize with dummy client; configureService will set it up properly
    _apiClient = blinko_api.ApiClient(basePath: '');
    _noteApi = blinko_api.NoteApi(_apiClient);
    _commentApi = blinko_api.CommentApi(_apiClient);
    _fileApi = blinko_api.FileApi(_apiClient); // Initialize FileApi
    // Initialize other APIs...
  }

  @override
  String get apiBaseUrl => _baseUrl;

  @override
  bool get isConfigured => _baseUrl.isNotEmpty && _authToken.isNotEmpty;

  @override
  Future<void> configureService({required String baseUrl, required String authToken}) async {
    // Check if already configured with the exact same inputs and is valid
    if (_baseUrl == baseUrl && _authToken == authToken && isConfigured) {
      if (kDebugMode) {
        print(
          '[BlinkoApiService] configureService: Already configured with same URL/Token. Skipping.',
        );
      }
      return;
    }
    if (kDebugMode) {
      print(
        '[BlinkoApiService] configureService: Configuring with baseUrl=$baseUrl',
      );
    }

    _baseUrl = baseUrl; // Store the original URL provided
    _baseUrl = baseUrl; // Store the original URL provided
    _authToken = authToken;

    // --- START MODIFICATION ---
    String effectiveBaseUrl = baseUrl;
    // Ensure base URL doesn't end with '/'
    if (effectiveBaseUrl.endsWith('/')) {
      effectiveBaseUrl = effectiveBaseUrl.substring(0, effectiveBaseUrl.length - 1);
    }

    // *** REMOVE AUTOMATIC /api APPENDING ***
    // The user should provide the correct base URL for the API, e.g., https://host/api or https://host/api/v1
    if (kDebugMode) {
      print(
        '[BlinkoApiService] configureService: Using effectiveBaseUrl for ApiClient: $effectiveBaseUrl',
      );
    }
    // --- END MODIFICATION ---

    try {
      _apiClient = blinko_api.ApiClient(
        // Use the cleaned base URL directly
        basePath: effectiveBaseUrl, // <--- Use cleaned path
        authentication: blinko_api.HttpBearerAuth()..accessToken = authToken,
      );
      _noteApi = blinko_api.NoteApi(_apiClient);
      _commentApi = blinko_api.CommentApi(_apiClient);
      _fileApi = blinko_api.FileApi(
        _apiClient,
      ); // Initialize FileApi here as well
      // Initialize other Blinko APIs...
      // TODO: Initialize FileApi if needed for uploads
      if (kDebugMode) {
        print(
          '[BlinkoApiService] configureService: Blinko API client configured successfully for $effectiveBaseUrl',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '[BlinkoApiService] configureService: Error initializing Blinko API client: $e',
        );
      }
      // Reset internal state on failure to ensure isConfigured reflects reality
      _baseUrl = '';
      _authToken = '';
      rethrow; // Rethrow the exception
    }
  }

  // --- Implement BaseApiService Methods ---

  @override
  Future<ListNotesResponse> listNotes({
    int? pageSize = 30,
    String? pageToken,
    String? filter,
    String? state,
    String? sort, // Keep sort parameter
    String? direction,
    ServerConfig? targetServerOverride,
  }) async {
    final noteApi = _getNoteApiForServer(targetServerOverride);
    final apiClient = noteApi.apiClient; // Get the ApiClient instance

    // --- Mapping Logic (Keep existing logic) ---
    int pageNumber = 1;
    if (pageToken != null) {
      pageNumber = int.tryParse(pageToken) ?? 1;
    }
    bool? isArchivedFilter;
    bool isRecycleFilter = false;
    if (state != null) {
      if (state.toUpperCase() == 'ARCHIVED') {
        isRecycleFilter = true;
        isArchivedFilter = null; // Blinko might handle archive via recycle bin
      } else if (state.toUpperCase() == 'NORMAL') {
        isRecycleFilter = false;
        isArchivedFilter = false; // Explicitly set isArchived for NORMAL state
      }
    }
    blinko_api.NotesListRequestOrderByEnum orderBy =
        blinko_api.NotesListRequestOrderByEnum.desc; // Default order
    if (direction != null && direction.toUpperCase() == 'ASC') {
      orderBy = blinko_api.NotesListRequestOrderByEnum.asc;
    }
    String searchText = ''; // TODO: Map filter if possible
    num? tagId; // TODO: Map filter if possible

    // --- Direct API Call using invokeAPI ---
    const path = r'/v1/note/list'; // The endpoint path
    final queryParams = <blinko_api.QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};
    const contentTypes = <String>[
      'application/json',
    ]; // Expected request content type (though body is null)
    const accepts = <String>[
      'application/json',
    ]; // Expected response content type

    // Add query parameters
    queryParams.addAll(
      blinko_api.ApiClient.parameterToQueryParams('', 'page', pageNumber),
    );
    queryParams.addAll(
      blinko_api.ApiClient.parameterToQueryParams('', 'size', pageSize ?? 30),
    );
    queryParams.addAll(
      blinko_api.ApiClient.parameterToQueryParams(
        '',
        'orderBy',
        orderBy.toJson(),
      ),
    ); // Send enum value as string
    if (isArchivedFilter != null) {
      queryParams.addAll(
        blinko_api.ApiClient.parameterToQueryParams(
          '',
          'isArchived',
          isArchivedFilter,
        ),
      );
    }
    // Always send isRecycle, defaulting to false if not explicitly ARCHIVED
    queryParams.addAll(
      blinko_api.ApiClient.parameterToQueryParams(
        '',
        'isRecycle',
        isRecycleFilter,
      ),
    );

    // Add other potential query params if mapped from 'filter'
    if (searchText.isNotEmpty) {
      queryParams.addAll(
        blinko_api.ApiClient.parameterToQueryParams(
          '',
          'searchText',
          searchText,
        ),
      );
    }
    // Add sort parameter if provided (Blinko might use a different param name)
    // Assuming Blinko uses 'sort' and 'direction' or just 'orderBy' which we already handle
    // If Blinko uses 'sort' separately:
    // if (sort != null) {
    //   queryParams.addAll(blinko_api.ApiClient.parameterToQueryParams('', 'sort', sort));
    // }

    try {
      if (kDebugMode) {
        print('[BlinkoApiService.listNotes] Calling invokeAPI POST $path');
        print('[BlinkoApiService.listNotes] Query Params: $queryParams');
      }

      // Make the API call using invokeAPI with null body
      final response = await apiClient.invokeAPI(
        path,
        'POST', // Use POST method as per original spec/curl
        queryParams,
        null, // Explicitly pass null for the body
        headerParams,
        formParams,
        accepts.join(','), // Pass Accept header value
        contentTypes.first, // Pass Content-Type header value
        ['bearerAuth'], // Authentication names
      );

      if (kDebugMode) {
        print(
          '[BlinkoApiService.listNotes] invokeAPI response status: ${response.statusCode}',
        );
      }

      // Process the response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isNotEmpty) {
          // Deserialize the response body
          final decoded =
              apiClient.deserialize(
                    response.body,
                    'List<NotesList200ResponseInner>',
                  )
                  as List;
          final notesResponse =
              decoded
                  .map(
                    (dynamic item) =>
                        blinko_api.NotesList200ResponseInner.fromJson(
                          item as Map<String, dynamic>,
                        ),
                  )
                  .whereType<blinko_api.NotesList200ResponseInner>()
                  .toList();

          // --- Continue with existing logic using notesResponse ---
          final notes =
              notesResponse.map(_convertBlinkoNoteToNoteItem).toList();
          String? nextPageToken =
              (notes.length == (pageSize ?? 30))
                  ? (pageNumber + 1).toString()
                  : null;
          return ListNotesResponse(notes: notes, nextPageToken: nextPageToken);
        } else {
          // Handle empty body case - return empty list
          if (kDebugMode) {
            print(
              '[BlinkoApiService.listNotes] invokeAPI returned successful status but empty body.',
            );
          }
          return ListNotesResponse(notes: [], nextPageToken: null);
        }
      } else {
        // Throw exception based on response status/body
        if (kDebugMode) {
          print(
            '[BlinkoApiService.listNotes] invokeAPI failed with status ${response.statusCode}, body: ${response.body}',
          );
        }
        throw blinko_api.ApiException(response.statusCode, response.body);
      }
    } catch (e) {
      // Keep enhanced logging
      if (kDebugMode) {
        print('[BlinkoApiService.listNotes] API call failed: $e');
      }
      if (e is blinko_api.ApiException) {
        if (kDebugMode) {
          print('[BlinkoApiService.listNotes] API Exception: ${e.message}');
        }
        throw Exception(
          'Failed to load notes: ${e.message} (Status code: ${e.code})',
        );
      }
      throw Exception('Failed to load notes: $e');
    }
  }

  @override
  Future<NoteItem> getNote(String id, {ServerConfig? targetServerOverride}) async {
    final noteApi = _getNoteApiForServer(targetServerOverride);
    final num? noteIdNum = num.tryParse(id);
    if (noteIdNum == null) {
      throw ArgumentError('Invalid numeric ID format for Blinko: $id');
    }
    final request = blinko_api.NotesDetailRequest(id: noteIdNum);
    try {
      final blinko_api.NotesDetail200Response? response = await noteApi.notesDetail(request);
      if (response == null) {
        throw Exception('Note $id not found');
      }
      return _convertBlinkoDetailToNoteItem(response);
    } catch (e) {
      throw Exception('Failed to load note $id: $e');
    }
  }

  @override
  Future<NoteItem> createNote(NoteItem note, {ServerConfig? targetServerOverride}) async {
    final noteApi = _getNoteApiForServer(targetServerOverride);
    final request = blinko_api.NotesUpsertRequest(
      content: note.content,
      isArchived: note.state == NoteState.archived,
      isTop: note.pinned,
    );
    try {
      final dynamic upsertResponse = await noteApi.notesUpsert(request);
      if (upsertResponse is Map && upsertResponse.containsKey('id')) {
        final num createdId = upsertResponse['id'];
        return await getNote(
          createdId.toString(),
          targetServerOverride: targetServerOverride,
        );
      } else {
        throw Exception(
          'Blinko upsert succeeded but failed to retrieve created note details.',
        );
      }
    } catch (e) {
      throw Exception('Failed to create note: $e');
    }
  }

  @override
  Future<NoteItem> updateNote(String id, NoteItem note, {ServerConfig? targetServerOverride}) async {
    final noteApi = _getNoteApiForServer(targetServerOverride);
    final num? noteIdNum = num.tryParse(id);
    if (noteIdNum == null) {
      throw ArgumentError('Invalid numeric ID format for Blinko: $id');
    }
    final request = blinko_api.NotesUpsertRequest(
      id: noteIdNum,
      content: note.content,
      isArchived: note.state == NoteState.archived,
      isTop: note.pinned,
    );
    try {
      await noteApi.notesUpsert(request);
      return await getNote(id, targetServerOverride: targetServerOverride);
    } catch (e) {
      throw Exception('Failed to update note $id: $e');
    }
  }

  @override
  Future<void> deleteNote(String id, {ServerConfig? targetServerOverride}) async {
    final noteApi = _getNoteApiForServer(targetServerOverride);
    final num? noteIdNum = num.tryParse(id);
    if (noteIdNum == null) {
      throw ArgumentError('Invalid numeric ID format for Blinko: $id');
    }
    final request = blinko_api.NotesListByIdsRequest(ids: [noteIdNum]);
    try {
      await noteApi.notesTrashMany(request);
    } catch (e) {
      throw Exception('Failed to delete/trash note $id: $e');
    }
  }

  @override
  Future<NoteItem> archiveNote(
    String id, {
    ServerConfig? targetServerOverride,
  }) async {
    final num? noteIdNum = num.tryParse(id);
    if (noteIdNum == null) {
      throw ArgumentError('Invalid numeric ID format for Blinko: $id');
    }
    final request = blinko_api.NotesUpsertRequest(
      id: noteIdNum,
      isArchived: true,
      isTop: false,
    );
    try {
      await _noteApi.notesUpsert(request);
      return await getNote(id, targetServerOverride: targetServerOverride);
    } catch (e) {
      throw Exception('Failed to archive note $id: $e');
    }
  }

  @override
  Future<NoteItem> togglePinNote(
    String id, {
    ServerConfig? targetServerOverride,
  }) async {
    final num? noteIdNum = num.tryParse(id);
    if (noteIdNum == null) {
      throw ArgumentError('Invalid numeric ID format for Blinko: $id');
    }
    NoteItem currentNote = await getNote(id, targetServerOverride: targetServerOverride);
    bool newPinState = !currentNote.pinned;
    final request = blinko_api.NotesUpsertRequest(
      id: noteIdNum,
      isTop: newPinState,
    );
    try {
      await _noteApi.notesUpsert(request);
      return await getNote(id, targetServerOverride: targetServerOverride);
    } catch (e) {
      throw Exception('Failed to toggle pin for note $id: $e');
    }
  }

  // --- Comments ---

  @override
  Future<List<Comment>> listNoteComments(String noteId, {ServerConfig? targetServerOverride}) async {
    final commentApi = _getCommentApiForServer(targetServerOverride);
    final num? noteIdNum = num.tryParse(noteId);
    if (noteIdNum == null) {
      throw ArgumentError(
        'Invalid numeric ID format for Blinko noteId: $noteId',
      );
    }
    final request = blinko_api.CommentsListRequest(noteId: noteIdNum);
    try {
      final blinko_api.CommentsList200Response? response = await commentApi
          .commentsList(request);
      if (response == null) {
        return [];
      }
      final comments =
          response.items.map(_convertBlinkoCommentToComment).toList();
      return comments;
    } catch (e) {
      throw Exception('Failed to load comments for note $noteId: $e');
    }
  }

  // Change 2: Correct createNoteComment signature to include resources of type List<memos_api.V1Resource>
  @override
  Future<Comment> createNoteComment(
    String noteId,
    Comment comment, {
    ServerConfig? targetServerOverride,
    List<memos_api.V1Resource>? resources,
  }) async {
    final commentApi = _getCommentApiForServer(targetServerOverride);
    final num? noteIdNum = num.tryParse(noteId);
    if (noteIdNum == null) {
      throw ArgumentError(
        'Invalid numeric ID format for Blinko noteId: $noteId',
      );
    }
    // TODO: Map common V1Resource to Blinko's attachment format if needed for create request
    final request = blinko_api.CommentsCreateRequest(
      noteId: noteIdNum,
      content: comment.content,
    );
    try {
      final bool? success = await commentApi.commentsCreate(request);
      if (success == null || !success) {
        throw Exception(
          'Failed to create comment: API returned failure or null.',
        );
      }
      throw Exception(
        "Comment created successfully, but refresh required to view.",
      );
    } catch (e) {
      if (e is blinko_api.ApiException || e is Exception) {
        rethrow;
      }
      throw Exception('Failed to create comment for note $noteId: $e');
    }
  }

  // Change 3: Correct arguments for notesAddReference call in setNoteRelations
  @override
  Future<void> setNoteRelations(
    String noteId,
    List<MemoRelation> relations, {
    ServerConfig? targetServerOverride,
  }) async {
    final noteApi = _getNoteApiForServer(targetServerOverride);
    final num? noteIdNum = num.tryParse(noteId);
    if (noteIdNum == null) {
      throw ArgumentError(
        'Invalid numeric ID format for Blinko noteId: $noteId',
      );
    }
    try {
      for (final relation in relations) {
        final num? relatedNoteIdNum = num.tryParse(relation.relatedMemoId);
        if (relatedNoteIdNum == null) {
          continue;
        }
        final request = blinko_api.NotesAddReferenceRequest(
          fromNoteId: noteIdNum,
          toNoteId: relatedNoteIdNum,
        );
        await noteApi.notesAddReference(request);
      }
    } catch (e) {
      throw Exception('Failed to set relations for note $noteId: $e');
    }
  }

  @override
  Future<Comment> updateNoteComment(
    String commentId,
    Comment comment, {
    ServerConfig? targetServerOverride,
  }) async {
    final commentApi = _getCommentApiForServer(targetServerOverride);
    final num? commentIdNum = num.tryParse(commentId);
    if (commentIdNum == null) {
      throw ArgumentError(
        'Invalid numeric ID format for Blinko commentId: $commentId',
      );
    }
    final request = blinko_api.CommentsUpdateRequest(
      id: commentIdNum,
      content: comment.content,
    );
    try {
      final blinko_api.CommentsList200ResponseItemsInner? response =
          await commentApi.commentsUpdate(request);
      if (response == null) {
        throw Exception('Failed to update comment $commentId: No response');
      }
      return _convertBlinkoCommentToComment(response);
    } catch (e) {
      throw Exception('Failed to update comment $commentId: $e');
    }
  }

  @override
  Future<void> deleteNoteComment(String noteId, String commentId, {ServerConfig? targetServerOverride}) async {
    final commentApi = _getCommentApiForServer(targetServerOverride);
    final num? commentIdNum = num.tryParse(commentId);
    if (commentIdNum == null) {
      throw ArgumentError(
        'Invalid numeric ID format for Blinko commentId: $commentId',
      );
    }
    try {
      final request = blinko_api.NotesDetailRequest(id: commentIdNum);
      await commentApi.commentsDelete(request);
    } catch (e) {
      if (e is blinko_api.ApiException || e is Exception) {
        rethrow;
      }
      throw Exception(
        'Failed to delete comment $commentId (note $noteId): $e',
      );
    }
  }

  // Dummy Implementations for missing BaseApiService methods (Change 1)
  @override
  Future<Comment> getNoteComment(
    String commentId, {
    ServerConfig? targetServerOverride,
  }) async {
    final num? commentIdNum = num.tryParse(commentId);
    if (commentIdNum == null) {
      throw ArgumentError(
        'Invalid numeric ID format for Blinko commentId: $commentId',
      );
    }
    try {
      throw UnimplementedError(
        "Blinko API does not support getting a single comment directly.",
      );
    } catch (e) {
      throw Exception('Failed to load comment $commentId: $e');
    }
  }

  @override
  Future<memos_api.V1Resource> uploadResource(
    Uint8List fileBytes,
    String filename,
    String contentType, {
    ServerConfig? targetServerOverride,
  }) async {
    final fileApi = _getFileApiForServer(targetServerOverride);
    try {
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: filename,
      );
      final blinko_api.UploadFile200Response? response = await fileApi
          .uploadFile(multipartFile);
      if (response == null || response.path == null) {
        throw Exception('Failed to upload resource: Invalid response');
      }
      String resourceName = response.path!;
      if (resourceName.startsWith('/api/file/')) {
        resourceName = resourceName.substring('/api/file/'.length);
      }
      resourceName = 'blinkoResources/$resourceName';
      return memos_api.V1Resource(
        name: resourceName,
        filename: filename,
        type: response.type ?? contentType,
        size: response.size?.toInt().toString(),
      );
    } catch (e) {
      throw Exception('Failed to upload resource: $e');
    }
  }

  @override
  Future<bool> checkHealth() async {
    if (!isConfigured) {
      return false;
    }
    try {
      await listNotes(pageSize: 1);
      return true;
    } catch (e) {
      if (e is blinko_api.ApiException && (e.code == 401 || e.code == 403)) {
        return false;
      }
      return false;
    }
  }

  // --- Helper & Mapping Methods ---

  blinko_api.ApiClient _getApiClientForServer(ServerConfig? serverConfig) {
    if (serverConfig == null || (serverConfig.serverUrl == _baseUrl && serverConfig.authToken == _authToken)) {
      return _apiClient;
    }
    try {
      String targetBaseUrl = serverConfig.serverUrl;
      if (targetBaseUrl.endsWith('/')) {
        targetBaseUrl = targetBaseUrl.substring(0, targetBaseUrl.length - 1);
      }
      return blinko_api.ApiClient(
        basePath: targetBaseUrl,
        authentication:
            blinko_api.HttpBearerAuth()..accessToken = serverConfig.authToken,
      );
    } catch (e) {
      throw Exception(
        'Failed to create Blinko API client for target server \${serverConfig.name ?? serverConfig.id}: $e',
      );
    }
  }

  blinko_api.NoteApi _getNoteApiForServer(ServerConfig? serverConfig) {
    return blinko_api.NoteApi(_getApiClientForServer(serverConfig));
  }

  blinko_api.CommentApi _getCommentApiForServer(ServerConfig? serverConfig) {
    return blinko_api.CommentApi(_getApiClientForServer(serverConfig));
  }

  // Change 6: Implement _getFileApiForServer helper method
  blinko_api.FileApi _getFileApiForServer(ServerConfig? serverConfig) {
    // Return the instance member if no override or if override matches current config
    if (serverConfig == null ||
        (serverConfig.serverUrl == _baseUrl &&
            serverConfig.authToken == _authToken)) {
      return _fileApi;
    }
    // Otherwise, create a temporary one
    return blinko_api.FileApi(_getApiClientForServer(serverConfig));
  }

  NoteItem _convertBlinkoNoteToNoteItem(blinko_api.NotesList200ResponseInner blinkoNote) {
    DateTime parseBlinkoDate(String? dateString) {
      if (dateString == null) {
        return DateTime(1970);
      }
      return DateTime.tryParse(dateString) ?? DateTime(1970);
    }
    NoteState state = NoteState.normal;
    if (blinkoNote.isRecycle ?? false) {
      state = NoteState.archived;
    } else if (blinkoNote.isArchived ?? false) {
      state = NoteState.archived;
    }
    NoteVisibility visibility = NoteVisibility.private;
    return NoteItem(
      id: blinkoNote.id.toString(),
      content: blinkoNote.content,
      pinned: blinkoNote.isTop,
      state: state,
      visibility: visibility,
      createTime: parseBlinkoDate(blinkoNote.createdAt),
      updateTime: parseBlinkoDate(blinkoNote.updatedAt),
      displayTime: parseBlinkoDate(blinkoNote.createdAt),
      tags: blinkoNote.tags.map((t) => t.tag.name).whereType<String>().toList(),
      resources: blinkoNote.attachments.map((a) => a.toJson()).toList(),
      relations: blinkoNote.references.map((r) => r.toJson()).toList(),
      // accountId is nullable in the response model, handle appropriately
      creatorId: blinkoNote.accountId?.toString(),
    );
  }

  NoteItem _convertBlinkoDetailToNoteItem(
    blinko_api.NotesDetail200Response blinkoDetail,
  ) {
    DateTime parseBlinkoDate(String? dateString) {
      if (dateString == null) {
        return DateTime(1970);
      }
      return DateTime.tryParse(dateString) ?? DateTime(1970);
    }
    NoteState state = NoteState.normal;
    if (blinkoDetail.isRecycle) {
      state = NoteState.archived;
    } else if (blinkoDetail.isArchived) {
      state = NoteState.archived;
    }
    NoteVisibility visibility = NoteVisibility.private;
    if (blinkoDetail.isShare) {
      visibility = NoteVisibility.public;
    }
    return NoteItem(
      id: blinkoDetail.id.toString(),
      content: blinkoDetail.content,
      pinned: blinkoDetail.isTop,
      state: state,
      visibility: visibility,
      createTime: parseBlinkoDate(blinkoDetail.createdAt),
      updateTime: parseBlinkoDate(blinkoDetail.updatedAt),
      displayTime: parseBlinkoDate(blinkoDetail.createdAt),
      tags: blinkoDetail.tags.map((t) => t.tag.name).whereType<String>().toList(),
      resources: blinkoDetail.attachments.map((a) => a.toJson()).toList(),
      relations: blinkoDetail.references.map((r) => r.toJson()).toList(),
      // accountId is nullable in the response model, handle appropriately
      creatorId: blinkoDetail.accountId?.toString(),
    );
  }

  Comment _convertBlinkoCommentToComment(
    blinko_api.CommentsList200ResponseItemsInner blinkoComment,
  ) {
    DateTime parseBlinkoDate(String? dateString) {
      if (dateString == null) {
        return DateTime(1970);
      }
      return DateTime.tryParse(dateString) ?? DateTime(1970);
    }
    CommentState state = CommentState.normal;
    bool pinned = false;
    return Comment(
      id: blinkoComment.id.toString(),
      content: blinkoComment.content ?? '',
      createTime: parseBlinkoDate(blinkoComment.createdAt).millisecondsSinceEpoch,
      updateTime: parseBlinkoDate(blinkoComment.updatedAt).millisecondsSinceEpoch,
      // accountId is nullable in the response model, handle appropriately
      creatorId: blinkoComment.accountId?.toString(),
      pinned: pinned,
      state: state,
    );
  }
}
