import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_memos/blinko_api/lib/api.dart'
    as blinko_api; // Alias Blinko API
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/list_notes_response.dart';
import 'package:flutter_memos/models/memo_relation.dart';
import 'package:flutter_memos/models/note_item.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/services/base_api_service.dart';

class BlinkoApiService implements BaseApiService {
  // Singleton pattern (optional)
  static final BlinkoApiService _instance = BlinkoApiService._internal();
  factory BlinkoApiService() => _instance;

  late blinko_api.ApiClient _apiClient;
  late blinko_api.NoteApi _noteApi;
  // Removed _commentApi field as it is unused
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
    // Removed initialization of _commentApi
    _fileApi = blinko_api.FileApi(_apiClient); // Initialize FileApi
    // Initialize other APIs...
  }

  @override
  String get apiBaseUrl => _baseUrl;

  @override
  bool get isConfigured => _baseUrl.isNotEmpty && _authToken.isNotEmpty;

  @override
  Future<void> configureService({
    required String baseUrl,
    required String authToken,
  }) async {
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
      effectiveBaseUrl = effectiveBaseUrl.substring(
        0,
        effectiveBaseUrl.length - 1,
      );
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
      // Removed initialization of _commentApi
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
    // Removed unused tagId variable

    // --- Direct API Call using invokeAPI ---
    const path = r'/v1/note/list'; // The endpoint path
    final queryParams = <blinko_api.QueryParam>[]; // Use blinko_api.QueryParam
    final headerParams = <String, String>{};
    final formParams = <String, String>{};
    // Define accepts based on what the server provides (usually JSON)
    const accepts = ['application/json'];
    // Define contentType for the request (null since no body, or 'application/json')
    const requestContentType =
        null; // Or 'application/json' if required by server even with null body

    // Add query parameters manually using QueryParam constructor
    queryParams.add(blinko_api.QueryParam('page', pageNumber.toString()));
    queryParams.add(blinko_api.QueryParam('size', (pageSize ?? 30).toString()));
    queryParams.add(
      blinko_api.QueryParam('orderBy', orderBy.toJson()),
    ); // Use toJson() for enum string value

    if (isArchivedFilter != null) {
      queryParams.add(
        blinko_api.QueryParam('isArchived', isArchivedFilter.toString()),
      );
    }
    // Always send isRecycle, defaulting to false if not explicitly ARCHIVED
    queryParams.add(
      blinko_api.QueryParam('isRecycle', isRecycleFilter.toString()),
    );

    // Add other potential query params if mapped from 'filter'
    if (searchText.isNotEmpty) {
      queryParams.add(blinko_api.QueryParam('searchText', searchText));
    }
    // Add Accept header to headerParams
    headerParams['Accept'] = accepts.join(',');

    try {
      if (kDebugMode) {
        print('[BlinkoApiService.listNotes] Calling invokeAPI POST $path');
        print('[BlinkoApiService.listNotes] Query Params: $queryParams');
        print('[BlinkoApiService.listNotes] Header Params: $headerParams');
      }

      // Make the API call using invokeAPI with the correct 7 arguments
      final response = await apiClient.invokeAPI(
        path, // endpoint path
        'POST', // method
        queryParams, // query parameters
        null, // body (explicitly null)
        headerParams, // header parameters (includes Accept)
        formParams, // form parameters (empty)
        requestContentType, // contentType (null)
      );

      if (kDebugMode) {
        print(
          '[BlinkoApiService.listNotes] invokeAPI response status: ${response.statusCode}',
        );
      }

      // Process the response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isNotEmpty) {
          // Deserialize the response body using deserializeAsync
          final decoded =
              await apiClient.deserializeAsync(
                    response.body,
                    'List<NotesList200ResponseInner>',
                  )
                  as List; // Cast to List<dynamic>

          // The 'decoded' list already contains NotesList200ResponseInner objects.
          // Directly cast the list elements.
          final notesResponse =
              decoded
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
          if (kDebugMode) {
            print(
              '[BlinkoApiService.listNotes] invokeAPI returned successful status but empty body.',
            );
          }
          return ListNotesResponse(notes: [], nextPageToken: null);
        }
      } else {
        if (kDebugMode) {
          print(
            '[BlinkoApiService.listNotes] invokeAPI failed with status ${response.statusCode}, body: ${response.body}',
          );
        }
        throw blinko_api.ApiException(response.statusCode, response.body);
      }
    } catch (e) {
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

  // Change 1: Refactor createNote to use notesUpsertWithHttpInfo and handle response manually
  @override
  Future<NoteItem> createNote(
    NoteItem note, {
    ServerConfig? targetServerOverride,
  }) async {
    final noteApi = _getNoteApiForServer(targetServerOverride);
    final request = blinko_api.NotesUpsertRequest(
      content: note.content,
      isArchived: note.state == NoteState.archived,
      isTop: note.pinned,
      // Ensure 'id' is not included in the request for creation
    );

    try {
      if (kDebugMode) {
        print(
          '[BlinkoApiService.createNote] Calling notesUpsertWithHttpInfo with request: ${request.toJson()}',
        );
      }

      // Use the WithHttpInfo variant to get the raw response
      final response = await noteApi.notesUpsertWithHttpInfo(request);

      // Check the status code directly from the response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Success! Decode the body and extract the ID.
        try {
          final responseBody =
              response.body.isNotEmpty ? jsonDecode(response.body) : null;
          if (kDebugMode) {
            print(
              '[BlinkoApiService.createNote] Success response body: $responseBody',
            );
          }
          if (responseBody is Map<String, dynamic> &&
              responseBody.containsKey('id')) {
            final num createdIdNum = responseBody['id'];
            final String createdIdStr = createdIdNum.toString();
            if (kDebugMode) {
              print(
                '[BlinkoApiService.createNote] Successfully created note with ID: $createdIdStr',
              );
            }
            // Return a new NoteItem with the correct ID and original content details
            return note.copyWith(id: createdIdStr);
          } else {
            if (kDebugMode) {
              print(
                '[BlinkoApiService.createNote] Upsert successful but response body did not contain expected ID. Body: ${response.body}',
              );
            }
            // Fallback: Operation succeeded, but we couldn\'t get the ID.
            // Return the placeholder. The list refresh will fix it.
            return note;
          }
        } catch (decodeError) {
          if (kDebugMode) {
            print(
              '[BlinkoApiService.createNote] Upsert successful but failed to decode/parse response body: $decodeError. Body: ${response.body}',
            );
          }
          // Fallback: Operation succeeded, but we couldn\'t process the response.
          return note;
        }
      } else {
        // Handle API error status codes
        throw blinko_api.ApiException(response.statusCode, response.body);
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print(
          '[BlinkoApiService.createNote] Error during notesUpsertWithHttpInfo call: $e',
        );
        print('[BlinkoApiService.createNote] Stack Trace: $stackTrace');
      }
      if (e is blinko_api.ApiException) {
        throw Exception(
          'Failed to create note: API Error ${e.code} - ${e.message}',
        );
      }
      throw Exception('Failed to create note: $e');
    }
  }

  // Change 2: Refactor updateNote to use notesUpsertWithHttpInfo
  @override
  Future<NoteItem> updateNote(
    String id,
    NoteItem note, {
    ServerConfig? targetServerOverride,
  }) async {
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
      // Use WithHttpInfo for update as well, for consistency, though we expect success.
      final response = await noteApi.notesUpsertWithHttpInfo(request);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Update succeeded, now fetch the definitive state.
        return await getNote(id, targetServerOverride: targetServerOverride);
      } else {
        throw blinko_api.ApiException(response.statusCode, response.body);
      }
    } catch (e) {
      if (e is blinko_api.ApiException) {
        throw Exception(
          'Failed to update note $id: API Error ${e.code} - ${e.message}',
        );
      }
      throw Exception('Failed to update note $id: $e');
    }
  }

  // Change 3: Refactor deleteNote to use notesTrashManyWithHttpInfo
  @override
  Future<void> deleteNote(
    String id, {
    ServerConfig? targetServerOverride,
  }) async {
    final noteApi = _getNoteApiForServer(targetServerOverride);
    final num? noteIdNum = num.tryParse(id);
    if (noteIdNum == null) {
      throw ArgumentError('Invalid numeric ID format for Blinko: $id');
    }
    final request = blinko_api.NotesListByIdsRequest(ids: [noteIdNum]);
    try {
      final response = await noteApi.notesTrashManyWithHttpInfo(request);
      if (!(response.statusCode >= 200 && response.statusCode < 300)) {
        throw blinko_api.ApiException(response.statusCode, response.body);
      }
      // Success, no return value needed.
    } catch (e) {
      if (e is blinko_api.ApiException) {
        throw Exception(
          'Failed to delete/trash note $id: API Error ${e.code} - ${e.message}',
        );
      }
      throw Exception('Failed to delete/trash note $id: $e');
    }
  }

  // Change 4: Refactor archiveNote to call the updated updateNote method
  @override
  Future<NoteItem> archiveNote(
    String id, {
    ServerConfig? targetServerOverride,
  }) async {
    NoteItem currentNote;
    try {
      currentNote = await getNote(
        id,
        targetServerOverride: targetServerOverride,
      );
    } catch (e) {
      throw Exception(
        'Failed to archive note $id: Could not fetch current state. Error: $e',
      );
    }

    final targetNoteState = currentNote.copyWith(
      pinned: false, // Unpin on archive
      state: NoteState.archived, // Target state
      updateTime: DateTime.now(), // Update timestamp
    );

    try {
      // Call updateNote, which handles the upsert and fetching the result
      return await updateNote(
        id,
        targetNoteState,
        targetServerOverride: targetServerOverride,
      );
    } catch (e) {
      throw Exception('Failed to archive note $id: $e');
    }
  }

  // Change 5: Refactor togglePinNote to call the updated updateNote method
  @override
  Future<NoteItem> togglePinNote(
    String id, {
    ServerConfig? targetServerOverride,
  }) async {
    NoteItem currentNote;
    try {
      currentNote = await getNote(
        id,
        targetServerOverride: targetServerOverride,
      );
    } catch (e) {
      throw Exception(
        'Failed to toggle pin for note $id: Could not fetch current state. Error: $e',
      );
    }

    bool newPinState = !currentNote.pinned;
    final targetNoteState = currentNote.copyWith(
      pinned: newPinState, // Set the new pin state
      updateTime: DateTime.now(), // Update timestamp
    );

    try {
      // Call updateNote to perform the upsert and fetch the result
      return await updateNote(
        id,
        targetNoteState,
        targetServerOverride: targetServerOverride,
      );
    } catch (e) {
      throw Exception('Failed to toggle pin for note $id: $e');
    }
  }

  // Change 6: Refactor listNoteComments to use commentsListWithHttpInfo
  @override
  Future<List<Comment>> listNoteComments(
    String noteId, {
    ServerConfig? targetServerOverride,
  }) async {
    final apiClient = _getApiClientForServer(
      targetServerOverride,
    ); // Get ApiClient first
    final commentApi = blinko_api.CommentApi(
      apiClient,
    ); // Pass ApiClient to CommentApi

    final num? noteIdNum = num.tryParse(noteId);
    if (noteIdNum == null) {
      throw ArgumentError(
        'Invalid numeric ID format for Blinko noteId: $noteId',
      );
    }
    final request = blinko_api.CommentsListRequest(noteId: noteIdNum);
    try {
      final response = await commentApi.commentsListWithHttpInfo(request);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return [];
        final decodedResponse =
            await apiClient.deserializeAsync(
                  response.body,
                  'CommentsList200Response',
                )
                as blinko_api.CommentsList200Response?;
        if (decodedResponse == null) return [];
        final comments =
            decodedResponse.items.map(_convertBlinkoCommentToComment).toList();
        return comments;
      } else {
        throw blinko_api.ApiException(response.statusCode, response.body);
      }
    } catch (e) {
      if (e is blinko_api.ApiException) {
        throw Exception(
          'Failed to load comments for note $noteId: API Error ${e.code} - ${e.message}',
        );
      }
      throw Exception('Failed to load comments for note $noteId: $e');
    }
  }

  // Change 7: Refactor createNoteComment to use commentsCreateWithHttpInfo
  @override
  Future<Comment> createNoteComment(
    String noteId,
    Comment comment, {
    ServerConfig? targetServerOverride,
    List<Map<String, dynamic>>? resources, // <-- New optional parameter
  }) async {
    final commentApi = blinko_api.CommentApi(
      _getApiClientForServer(targetServerOverride),
    );
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
      guestName: '', // Required based on previous 400 error
      parentId: null, // Explicitly null for top-level comments
    );
    try {
      final response = await commentApi.commentsCreateWithHttpInfo(request);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Success, but API returns bool?. Return placeholder.
        return comment;
      } else {
        throw blinko_api.ApiException(response.statusCode, response.body);
      }
    } catch (e) {
      if (e is blinko_api.ApiException) {
        throw Exception(
          'Failed to create comment for note $noteId: API Error ${e.code} - ${e.message}',
        );
      }
      throw Exception('Failed to create comment for note $noteId: $e');
    }
  }

  // Change 8: Refactor updateNoteComment to use commentsUpdateWithHttpInfo
  @override
  Future<Comment> updateNoteComment(
    String commentId,
    Comment comment, {
    ServerConfig? targetServerOverride,
  }) async {
    final apiClient = _getApiClientForServer(
      targetServerOverride,
    ); // Get ApiClient
    final commentApi = blinko_api.CommentApi(apiClient); // Pass ApiClient

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
      final response = await commentApi.commentsUpdateWithHttpInfo(request);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          throw Exception(
            'Failed to update comment $commentId: Empty response body on success',
          );
        }
        final blinko_api.CommentsList200ResponseItemsInner? updatedCommentData =
            await apiClient.deserializeAsync(
                  response.body,
                  'CommentsList200ResponseItemsInner',
                )
                as blinko_api.CommentsList200ResponseItemsInner?;
        if (updatedCommentData == null) {
          throw Exception(
            'Failed to update comment $commentId: Could not deserialize response',
          );
        }
        return _convertBlinkoCommentToComment(updatedCommentData);
      } else {
        throw blinko_api.ApiException(response.statusCode, response.body);
      }
    } catch (e) {
      if (e is blinko_api.ApiException) {
        throw Exception(
          'Failed to update comment $commentId: API Error ${e.code} - ${e.message}',
        );
      }
      throw Exception('Failed to update comment $commentId: $e');
    }
  }

  // Change 9: Refactor deleteNoteComment to use commentsDeleteWithHttpInfo
  @override
  Future<void> deleteNoteComment(
    String noteId,
    String commentId, {
    ServerConfig? targetServerOverride,
  }) async {
    final commentApi = blinko_api.CommentApi(
      _getApiClientForServer(targetServerOverride),
    );
    final num? commentIdNum = num.tryParse(commentId);
    if (commentIdNum == null) {
      throw ArgumentError(
        'Invalid numeric ID format for Blinko commentId: $commentId',
      );
    }
    try {
      final request = blinko_api.NotesDetailRequest(id: commentIdNum);
      final response = await commentApi.commentsDeleteWithHttpInfo(request);
      if (!(response.statusCode >= 200 && response.statusCode < 300)) {
        throw blinko_api.ApiException(response.statusCode, response.body);
      }
      // Success, no return value needed.
    } catch (e) {
      if (e is blinko_api.ApiException) {
        throw Exception(
          'Failed to delete comment $commentId (note $noteId): API Error ${e.code} - ${e.message}',
        );
      }
      throw Exception('Failed to delete comment $commentId (note $noteId): $e');
    }
  }

  // Change 10: Refactor setNoteRelations to use notesAddReferenceWithHttpInfo
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
          if (kDebugMode) {
            print(
              "[BlinkoApiService.setNoteRelations] Skipping relation with invalid relatedMemoId: ${relation.relatedMemoId}",
            );
          }
          continue; // Skip if related ID is invalid
        }
        final request = blinko_api.NotesAddReferenceRequest(
          fromNoteId: noteIdNum,
          toNoteId: relatedNoteIdNum,
        );
        final response = await noteApi.notesAddReferenceWithHttpInfo(request);
        if (!(response.statusCode >= 200 && response.statusCode < 300)) {
          throw blinko_api.ApiException(
            response.statusCode,
            'Failed to add relation to note $relatedNoteIdNum: ${response.body}',
          );
        }
      }
    } catch (e) {
      if (e is blinko_api.ApiException) {
        throw Exception(
          'Failed to set relations for note $noteId: API Error ${e.code} - ${e.message}',
        );
      }
      throw Exception('Failed to set relations for note $noteId: $e');
    }
  }

  // --- Helper & Mapping Methods ---

  blinko_api.ApiClient _getApiClientForServer(ServerConfig? serverConfig) {
    if (serverConfig == null ||
        (serverConfig.serverUrl == _baseUrl &&
            serverConfig.authToken == _authToken)) {
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
        'Failed to create Blinko API client for target server ${serverConfig.name ?? serverConfig.id}: $e',
      );
    }
  }

  blinko_api.NoteApi _getNoteApiForServer(ServerConfig? serverConfig) {
    return blinko_api.NoteApi(_getApiClientForServer(serverConfig));
  }

  // Removed the unused _getCommentApiForServer method

  // Change 6: Implement _getFileApiForServer helper method
  blinko_api.FileApi _getFileApiForServer(ServerConfig? serverConfig) {
    if (serverConfig == null ||
        (serverConfig.serverUrl == _baseUrl &&
            serverConfig.authToken == _authToken)) {
      return _fileApi;
    }
    return blinko_api.FileApi(_getApiClientForServer(serverConfig));
  }

  NoteItem _convertBlinkoNoteToNoteItem(
    blinko_api.NotesList200ResponseInner blinkoNote,
  ) {
    DateTime parseBlinkoDate(String? dateString) {
      if (dateString == null) {
        return DateTime(1970);
      }
      return DateTime.tryParse(dateString) ?? DateTime(1970);
    }

    NoteState state = NoteState.normal;
    if (blinkoNote.isRecycle) {
      state = NoteState.archived;
    } else if (blinkoNote.isArchived) {
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
      creatorId: blinkoNote.accountId.toString(),
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
      tags:
          blinkoDetail.tags.map((t) => t.tag.name).whereType<String>().toList(),
      resources: blinkoDetail.attachments.map((a) => a.toJson()).toList(),
      relations: blinkoDetail.references.map((r) => r.toJson()).toList(),
      creatorId: blinkoDetail.accountId.toString(),
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
      content: blinkoComment.content,
      createTime:
          parseBlinkoDate(blinkoComment.createdAt).millisecondsSinceEpoch,
      updateTime:
          parseBlinkoDate(blinkoComment.updatedAt).millisecondsSinceEpoch,
      creatorId: blinkoComment.accountId.toString(),
      pinned: pinned,
      state: state,
    );
  }
}
