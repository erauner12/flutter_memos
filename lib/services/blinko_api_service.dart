import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_memos/blinko_api/lib/api.dart'
    as blinko_api; // Alias Blinko API
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/list_notes_response.dart'; // Ensure import
// import 'package:flutter_memos/models/memo_relation.dart'; // Removed unused import
import 'package:flutter_memos/models/note_item.dart'; // Ensure import
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/services/base_api_service.dart';
import 'package:http/http.dart' as http; // Added http import
import 'package:http_parser/http_parser.dart';

class BlinkoApiService implements BaseApiService {
  // Singleton pattern (optional)
  static final BlinkoApiService _instance = BlinkoApiService._internal();
  factory BlinkoApiService() => _instance;

  late blinko_api.ApiClient _apiClient;
  // Removed the unused _noteApi field
  // late blinko_api.NoteApi _noteApi;
  late blinko_api.FileApi _fileApi; // FileApi instance

  String _baseUrl = '';
  String _authToken = '';

  // Static config flags (can be instance members too)
  static bool verboseLogging = true;

  BlinkoApiService._internal() {
    // Initialize with dummy client; configureService will set it up properly
    _apiClient = blinko_api.ApiClient(basePath: '');
    // Removed initialization of unused _noteApi
    // _noteApi = blinko_api.NoteApi(_apiClient);
    _fileApi = blinko_api.FileApi(_apiClient); // Initialize FileApi
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
        basePath: effectiveBaseUrl,
        authentication: blinko_api.HttpBearerAuth()..accessToken = authToken,
      );
      // Removed initialization of unused _noteApi
      // _noteApi = blinko_api.NoteApi(_apiClient);
      _fileApi = blinko_api.FileApi(_apiClient);
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
      _baseUrl = '';
      _authToken = '';
      rethrow;
    }
  }

  // Implement missing checkHealth method
  @override
  Future<bool> checkHealth() async {
    final configApi = blinko_api.ConfigApi(_apiClient);
    try {
      final response = await configApi.configListWithHttpInfo();
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      if (kDebugMode) {
        print('[BlinkoApiService.checkHealth] Health check failed: $e');
      }
      return false;
    }
  }

  // Implement missing getNote method
  @override
  Future<NoteItem> getNote(
    String id, {
    ServerConfig? targetServerOverride,
  }) async {
    final noteApi = _getNoteApiForServer(targetServerOverride);
    final num? noteIdNum = num.tryParse(id);
    if (noteIdNum == null) {
      throw ArgumentError('Invalid numeric ID format for Blinko: $id');
    }
    final request = blinko_api.NotesDetailRequest(id: noteIdNum);
    try {
      final response = await noteApi.notesDetailWithHttpInfo(request);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isNotEmpty) {
          final blinkoDetail =
              await noteApi.apiClient.deserializeAsync(
                    response.body,
                    'NotesDetail200Response',
                  )
                  as blinko_api.NotesDetail200Response?;
          if (blinkoDetail != null) {
            return _convertBlinkoDetailToNoteItem(blinkoDetail);
          } else {
            throw Exception(
              'Failed to deserialize note detail response for ID $id',
            );
          }
        } else {
          throw Exception(
            'Empty response body when fetching note detail for ID $id',
          );
        }
      } else {
        throw blinko_api.ApiException(response.statusCode, response.body);
      }
    } catch (e) {
      if (e is blinko_api.ApiException) {
        throw Exception(
          'Failed to get note $id: API Error ${e.code} - ${e.message}',
        );
      }
      throw Exception('Failed to get note $id: $e');
    }
  }

  // Implement missing getNoteComment method (as Unimplemented)
  @override
  Future<Comment> getNoteComment(
    String commentId, {
    ServerConfig? targetServerOverride,
  }) async {
    // Blinko API might not support fetching a single comment directly by its ID
    // without knowing the note ID. Throwing error as per plan.
    throw UnimplementedError(
      'BlinkoApiService does not support getting a single comment by ID.',
    );
  }

  // Implement missing uploadResource method
  @override
  Future<Map<String, dynamic>> uploadResource(
    Uint8List fileBytes,
    String filename,
    String contentType, {
    ServerConfig? targetServerOverride,
  }) async {
    final fileApi = _getFileApiForServer(targetServerOverride);
    final apiClient = fileApi.apiClient;
    // Use http.MultipartFile for creating the file part
    final multipartFile = http.MultipartFile.fromBytes(
      'file', // API likely expects the field name to be 'file'
      fileBytes,
      filename: filename,
      contentType: MediaType.parse(contentType),
    );

    try {
      if (kDebugMode) {
        print(
          '[BlinkoApiService.uploadResource] Calling fileApi.uploadFileWithHttpInfo for $filename ($contentType, ${fileBytes.lengthInBytes} bytes)',
        );
      }

      // Use the generated FileApi method which should handle multipart correctly
      final response = await fileApi.uploadFileWithHttpInfo(multipartFile);

      if (kDebugMode) {
        print(
          '[BlinkoApiService.uploadResource] uploadFileWithHttpInfo response status: ${response.statusCode}',
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isNotEmpty) {
          final uploadResponse =
              await apiClient.deserializeAsync(
                    response.body,
                    'UploadFile200Response', // Target Blinko response model
                  )
                  as blinko_api.UploadFile200Response?;

          if (uploadResponse != null && uploadResponse.path != null) {
            // Blinko API response might not have a 'name' field, use 'path' or original filename.
            String resourceName =
                'blinkoResources/${uploadResponse.path!.split('/').last}'; // Construct a unique name
            String? responseFilename; // Blinko API doesn't have a 'name' field
            if (kDebugMode) {
              print(
                '[BlinkoApiService.uploadResource] Upload successful. Path: ${uploadResponse.path}, Type: ${uploadResponse.type}, Size: ${uploadResponse.size}',
              );
            }
            // Map to the generic structure expected by BaseApiService
            return {
              'name': resourceName, // Use constructed name as identifier
              'filename':
                  responseFilename ??
                  filename, // Prefer API filename if available
              'contentType':
                  uploadResponse.type ??
                  contentType, // Prefer API type if available
              'size':
                  uploadResponse.size
                      ?.toString(), // Size from API response as String
              'externalLink':
                  uploadResponse.path!, // Blinko path likely serves as link
            };
          } else {
            if (kDebugMode) {
              print(
                '[BlinkoApiService.uploadResource] Upload successful but response deserialization failed or path missing. Body: ${response.body}',
              );
            }
            throw Exception(
              'Upload successful but failed to parse response or missing path.',
            );
          }
        } else {
          if (kDebugMode) {
            print(
              '[BlinkoApiService.uploadResource] Upload successful but response body is empty.',
            );
          }
          throw Exception(
            'Upload successful but received empty response body.',
          );
        }
      } else {
        if (kDebugMode) {
          print(
            '[BlinkoApiService.uploadResource] Upload failed with status ${response.statusCode}. Body: ${response.body}',
          );
        }
        throw blinko_api.ApiException(response.statusCode, response.body);
      }
    } catch (e) {
      if (kDebugMode) {
        print('[BlinkoApiService.uploadResource] Error during upload: $e');
      }
      if (e is blinko_api.ApiException) {
        throw Exception(
          'Failed to upload resource: API Error ${e.code} - ${e.message}',
        );
      }
      if (e is http.ClientException) {
        throw Exception(
          'Failed to upload resource: Network error - ${e.message}',
        );
      }
      throw Exception('Failed to upload resource: $e');
    }
  }

  // --- Implement BaseApiService Methods ---
  @override
  Future<ListNotesResponse> listNotes({
    int? pageSize = 30,
    String? pageToken,
    String? filter,
    String? state,
    String? sort,
    String? direction,
    ServerConfig? targetServerOverride,
  }) async {
    final noteApi = _getNoteApiForServer(targetServerOverride);
    final apiClient = noteApi.apiClient;
    int pageNumber = 1;
    if (pageToken != null) {
      pageNumber = int.tryParse(pageToken) ?? 1;
    }
    bool? isArchivedFilter;
    bool isRecycleFilter = false;
    if (state != null) {
      if (state.toUpperCase() == 'ARCHIVED') {
        isRecycleFilter = true;
        isArchivedFilter = null;
      } else if (state.toUpperCase() == 'NORMAL') {
        isRecycleFilter = false;
        isArchivedFilter = false;
      }
    }
    blinko_api.NotesListRequestOrderByEnum orderBy =
        blinko_api.NotesListRequestOrderByEnum.desc;
    if (direction != null && direction.toUpperCase() == 'ASC') {
      orderBy = blinko_api.NotesListRequestOrderByEnum.asc;
    }
    String searchText = '';
    const path = r'/v1/note/list';
    final queryParams = <blinko_api.QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};
    const accepts = ['application/json'];
    const requestContentType = null;
    queryParams.add(blinko_api.QueryParam('page', pageNumber.toString()));
    queryParams.add(blinko_api.QueryParam('size', (pageSize ?? 30).toString()));
    queryParams.add(blinko_api.QueryParam('orderBy', orderBy.toJson()));
    if (isArchivedFilter != null) {
      queryParams.add(
        blinko_api.QueryParam('isArchived', isArchivedFilter.toString()),
      );
    }
    queryParams.add(
      blinko_api.QueryParam('isRecycle', isRecycleFilter.toString()),
    );
    if (searchText.isNotEmpty) {
      queryParams.add(blinko_api.QueryParam('searchText', searchText));
    }
    headerParams['Accept'] = accepts.join(',');
    try {
      if (kDebugMode) {
        print('[BlinkoApiService.listNotes] Calling invokeAPI POST $path');
        print('[BlinkoApiService.listNotes] Query Params: $queryParams');
        print('[BlinkoApiService.listNotes] Header Params: $headerParams');
      }
      final response = await apiClient.invokeAPI(
        path,
        'POST',
        queryParams,
        null,
        headerParams,
        formParams,
        requestContentType,
      );
      if (kDebugMode) {
        print(
          '[BlinkoApiService.listNotes] invokeAPI response status: ${response.statusCode}',
        );
      }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isNotEmpty) {
          final decoded =
              await apiClient.deserializeAsync(
                    response.body,
                    'List<NotesList200ResponseInner>',
                  )
                  as List;
          final notesResponse =
              decoded
                  .whereType<blinko_api.NotesList200ResponseInner>()
                  .toList();
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

  // Change 1: Refactored createNote
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
    );
    try {
      if (kDebugMode) {
        print(
          '[BlinkoApiService.createNote] Calling notesUpsertWithHttpInfo with request: ${request.toJson()}',
        );
      }
      final response = await noteApi.notesUpsertWithHttpInfo(request);
      if (response.statusCode >= 200 && response.statusCode < 300) {
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
            // Fetch the created note to get all details
            return await getNote(
              createdIdStr,
              targetServerOverride: targetServerOverride,
            );
          } else {
            if (kDebugMode) {
              print(
                '[BlinkoApiService.createNote] Upsert successful but response body did not contain expected ID. Body: ${response.body}',
              );
            }
            return note.copyWith(
              id: 'temp_created_${DateTime.now().millisecondsSinceEpoch}',
            );
          }
        } catch (decodeError) {
          if (kDebugMode) {
            print(
              '[BlinkoApiService.createNote] Upsert successful but failed to decode/parse response body: $decodeError. Body: ${response.body}',
            );
          }
          return note.copyWith(
            id: 'temp_created_${DateTime.now().millisecondsSinceEpoch}',
          );
        }
      } else {
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

  // Change 2: Refactored updateNote
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
      // --- Add these lines (CRITICAL: Assumes Blinko API supports these fields in NotesUpsertRequest) ---
      // Verify the actual field names and expected format (e.g., String ISO 8601) in the Blinko API spec.
      // If the API uses a different structure (like NotesListRequestStartDate), adapt accordingly.
      // If the API does *not* support updating these fields here, remove these lines.
      // startDate: note.startDate?.toIso8601String(), // Example if API expects ISO String
      // endDate: note.endDate?.toIso8601String(),     // Example if API expects ISO String
      // --- End of potentially added lines ---
    );
    try {
      if (kDebugMode) {
        print(
          '[BlinkoApiService.updateNote] Calling notesUpsertWithHttpInfo for ID $id with request: ${request.toJson()}',
        );
      }
      final response = await noteApi.notesUpsertWithHttpInfo(request);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Fetch the updated note to ensure we have the latest state, including potentially updated dates
        return await getNote(id, targetServerOverride: targetServerOverride);
      } else {
        if (kDebugMode) {
          print(
            '[BlinkoApiService.updateNote] notesUpsertWithHttpInfo failed for ID $id. Status: ${response.statusCode}, Body: ${response.body}',
          );
        }
        throw blinko_api.ApiException(response.statusCode, response.body);
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print(
          '[BlinkoApiService.updateNote] Error during notesUpsertWithHttpInfo call for ID $id: $e',
        );
        print('[BlinkoApiService.updateNote] Stack Trace: $stackTrace');
      }
      if (e is blinko_api.ApiException) {
        throw Exception(
          'Failed to update note $id: API Error ${e.code} - ${e.message}',
        );
      }
      throw Exception('Failed to update note $id: $e');
    }
  }

  // Change 3: Refactored deleteNote
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
    } catch (e) {
      if (e is blinko_api.ApiException) {
        throw Exception(
          'Failed to delete/trash note $id: API Error ${e.code} - ${e.message}',
        );
      }
      throw Exception('Failed to delete/trash note $id: $e');
    }
  }

  // Change 4: Refactored archiveNote
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
      pinned: false,
      state: NoteState.archived,
      updateTime: DateTime.now(),
    );
    try {
      return await updateNote(
        id,
        targetNoteState,
        targetServerOverride: targetServerOverride,
      );
    } catch (e) {
      throw Exception('Failed to archive note $id: $e');
    }
  }

  // Change 5: Refactored togglePinNote
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
      pinned: newPinState,
      updateTime: DateTime.now(),
    );
    try {
      return await updateNote(
        id,
        targetNoteState,
        targetServerOverride: targetServerOverride,
      );
    } catch (e) {
      throw Exception('Failed to toggle pin for note $id: $e');
    }
  }

  // Change 6: Refactored listNoteComments
  @override
  Future<List<Comment>> listNoteComments(
    String noteId, {
    ServerConfig? targetServerOverride,
  }) async {
    final apiClient = _getApiClientForServer(targetServerOverride);
    final commentApi = blinko_api.CommentApi(apiClient);
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

  // Change 7: Refactored createNoteComment to accept resources parameter (though ignored)
  @override
  Future<Comment> createNoteComment(
    String noteId,
    Comment comment, {
    ServerConfig? targetServerOverride,
    List<Map<String, dynamic>>? resources,
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
    final request = blinko_api.CommentsCreateRequest(
      noteId: noteIdNum,
      content: comment.content,
      guestName:
          '', // Blinko specific, maybe map from comment.creatorId if needed?
      parentId:
          null, // Blinko specific, maybe map from comment if it has parent info?
    );
    try {
      final response = await commentApi.commentsCreateWithHttpInfo(request);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (kDebugMode) {
          print(
            '[BlinkoApiService.createNoteComment] Succeeded, but Blinko does not return the created comment ID. Returning placeholder.',
          );
        }
        return comment.copyWith(
          id: 'temp_comment_${DateTime.now().millisecondsSinceEpoch}',
        );
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

  // Change 8: Refactored updateNoteComment
  @override
  Future<Comment> updateNoteComment(
    String commentId,
    Comment comment, {
    ServerConfig? targetServerOverride,
  }) async {
    final apiClient = _getApiClientForServer(targetServerOverride);
    final commentApi = blinko_api.CommentApi(apiClient);
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

  // Change 9: Refactored deleteNoteComment
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
    } catch (e) {
      if (e is blinko_api.ApiException) {
        throw Exception(
          'Failed to delete comment $commentId (note $noteId): API Error ${e.code} - ${e.message}',
        );
      }
      throw Exception('Failed to delete comment $commentId (note $noteId): $e');
    }
  }

  // Change 10: Refactored setNoteRelations to accept List<Map<String, dynamic>>
  @override
  Future<void> setNoteRelations(
    String noteId,
    List<Map<String, dynamic>> relations, {
    ServerConfig? targetServerOverride,
  }) async {
    final noteApi = _getNoteApiForServer(targetServerOverride);
    final num? noteIdNum = num.tryParse(noteId);
    if (noteIdNum == null) {
      throw ArgumentError(
        'Invalid numeric ID format for Blinko noteId: $noteId',
      );
    }
    if (kDebugMode) {
      print(
        '[BlinkoApiService.setNoteRelations] Warning: Current implementation only adds relations, does not remove existing ones.',
      );
    }
    List<Exception> errors = [];
    // Iterate through the generic map list
    for (final relationMap in relations) {
      // Extract related ID and type (Blinko only supports REFERENCE implicitly)
      final String? relatedNoteIdStr = relationMap['relatedMemoId'] as String?;
      final num? relatedNoteIdNum = num.tryParse(relatedNoteIdStr ?? '');
      if (relatedNoteIdNum == null) {
        if (kDebugMode) {
          print(
            "[BlinkoApiService.setNoteRelations] Skipping relation with invalid relatedMemoId: $relatedNoteIdStr",
          );
        }
        continue;
      }
      // Create Blinko request
      final request = blinko_api.NotesAddReferenceRequest(
        fromNoteId: noteIdNum,
        toNoteId: relatedNoteIdNum,
      );
      try {
        final response = await noteApi.notesAddReferenceWithHttpInfo(request);
        if (!(response.statusCode >= 200 && response.statusCode < 300)) {
          errors.add(
            blinko_api.ApiException(
              response.statusCode,
              'Failed to add relation to note $relatedNoteIdNum: ${response.body}',
            ),
          );
        }
      } catch (e) {
        errors.add(
          Exception('Failed to add relation to note $relatedNoteIdNum: $e'),
        );
      }
    }
    if (errors.isNotEmpty) {
      final errorMessages = errors.map((e) => e.toString()).join('\n');
      if (kDebugMode) {
        print(
          '[BlinkoApiService.setNoteRelations] Error details: $errorMessages',
        );
      }
      throw Exception(
        'Failed to set some relations for note $noteId. Check logs for details.',
      );
    }
  }

  // Change 6: Implement _getFileApiForServer helper method
  blinko_api.FileApi _getFileApiForServer(ServerConfig? serverConfig) {
    if (serverConfig == null ||
        (serverConfig.serverUrl == _baseUrl &&
            serverConfig.authToken == _authToken)) {
      if (!_fileApi.apiClient.basePath.startsWith('http')) {
        if (kDebugMode) {
          print(
            "[BlinkoApiService._getFileApiForServer] Warning: Default FileApi seems uninitialized. Attempting re-init.",
          );
        }
        if (_baseUrl.isNotEmpty && _authToken.isNotEmpty) {
          configureService(baseUrl: _baseUrl, authToken: _authToken);
        } else {
          throw Exception(
            "Default BlinkoApiService FileApi is not configured.",
          );
        }
      }
      return _fileApi;
    }
    return blinko_api.FileApi(_getApiClientForServer(serverConfig));
  }

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

  // Change 16: Updated _convertBlinkoDetailToNoteItem helper method with null checks and mapping
  NoteItem _convertBlinkoDetailToNoteItem(
    blinko_api.NotesDetail200Response blinkoDetail,
  ) {
    DateTime? tryParseDateTime(String? dateString) {
      if (dateString == null || dateString.isEmpty) {
        return null;
      }
      // Handle potential '0001-01-01T00:00:00Z' or similar zero dates from API
      if (dateString.startsWith('0001-')) {
        return null;
      }
      return DateTime.tryParse(dateString);
    }

    DateTime parseBlinkoDate(String? dateString) {
      return tryParseDateTime(dateString) ?? DateTime(1970);
    }

    NoteState state = NoteState.normal;
    if (blinkoDetail.isRecycle == true) {
      state = NoteState.archived;
    } else if (blinkoDetail.isArchived == true) {
      state = NoteState.archived;
    }

    NoteVisibility visibility =
        NoteVisibility
            .private; // Blinko doesn't seem to have public/protected distinction easily available here

    // Remove unnecessary null-aware operators
    final String idStr = blinkoDetail.id.toString();
    final String contentStr = blinkoDetail.content;
    final bool isPinned = blinkoDetail.isTop;
    final DateTime createdAt = parseBlinkoDate(blinkoDetail.createdAt);
    final DateTime updatedAt = parseBlinkoDate(blinkoDetail.updatedAt);
    // Keep ?? for accountId as it's nullable num?
    final String creatorIdStr =
        blinkoDetail.accountId?.toString() ?? 'unknown_creator';

    // --- Parse Start/End Dates ---
    // Verify the actual field names in the Blinko API spec (e.g., startDate, start_date)
    // Access directly, tryParseDateTime handles nulls
    final DateTime? startDate = tryParseDateTime(blinkoDetail.startDate);
    final DateTime? endDate = tryParseDateTime(blinkoDetail.endDate);
    // ---------------------------

    // Keep ?? for tags as it's nullable list?
    final List<String> tags =
        (blinkoDetail.tags ?? [])
            .map((t) => t.tag.name) // Safely access nested name
            .whereType<String>()
            .toList();

    // Keep ?? for attachments as it's nullable list?
    final List<Map<String, dynamic>> resources =
        (blinkoDetail.attachments ?? []).map((a) {
          return {
            'id':
                a.path, // Use path as a unique identifier if no specific ID is available
            'name': a.path, // Use path or filename as name
            'filename': a.name,
            'externalLink': a.path, // Assuming path is the link
            'contentType': a.type,
            'size':
                a.size?.toString(), // Keep ?? for size as it's nullable num?
            'createTime':
                a.createdAt, // Assuming this is a parsable date string
          };
        }).toList();

    // Keep ?? for references as it's nullable list?
    final List<Map<String, dynamic>> relations =
        (blinkoDetail.references ?? [])
            .map((r) {
              final relatedNoteId = r.toNoteId.toString(); // Use toNoteId
              final type =
                  'REFERENCE'; // Blinko references are likely this type
              return {'relatedMemoId': relatedNoteId, 'type': type};
            })
            .whereType<Map<String, dynamic>>()
            .toList();

    return NoteItem(
      id: idStr,
      content: contentStr,
      pinned: isPinned,
      state: state,
      visibility: visibility,
      createTime: createdAt,
      updateTime: updatedAt,
      displayTime: createdAt, // Or maybe updatedAt? Decide display logic.
      tags: tags,
      resources: resources,
      relations: relations,
      creatorId: creatorIdStr,
      startDate: startDate, // Assign parsed start date
      endDate: endDate, // Assign parsed end date
    );
  }

  // Change 17: Updated _convertBlinkoNoteToNoteItem helper method with null checks and mapping
  NoteItem _convertBlinkoNoteToNoteItem(
    blinko_api.NotesList200ResponseInner blinkoNote,
  ) {
    DateTime? tryParseDateTime(String? dateString) {
      if (dateString == null || dateString.isEmpty) {
        return null;
      }
      // Handle potential '0001-01-01T00:00:00Z' or similar zero dates from API
      if (dateString.startsWith('0001-')) {
        return null;
      }
      return DateTime.tryParse(dateString);
    }

    DateTime parseBlinkoDate(String? dateString) {
      return tryParseDateTime(dateString) ?? DateTime(1970);
    }

    NoteState state = NoteState.normal;
    if (blinkoNote.isRecycle == true) {
      state = NoteState.archived;
    } else if (blinkoNote.isArchived == true) {
      state = NoteState.archived;
    }

    NoteVisibility visibility =
        NoteVisibility
            .private; // Blinko doesn't seem to have public/protected distinction easily available here

    // Remove unnecessary null-aware operators
    final String idStr = blinkoNote.id.toString();
    final String contentStr = blinkoNote.content;
    final bool isPinned = blinkoNote.isTop;
    final DateTime createdAt = parseBlinkoDate(blinkoNote.createdAt);
    final DateTime updatedAt = parseBlinkoDate(blinkoNote.updatedAt);
    // Keep ?? for accountId as it's nullable num?
    final String creatorIdStr =
        blinkoNote.accountId?.toString() ?? 'unknown_creator';

    // --- Parse Start/End Dates ---
    // Verify the actual field names in the Blinko API spec (e.g., startDate, start_date)
    // Access directly, tryParseDateTime handles nulls
    final DateTime? startDate = tryParseDateTime(blinkoNote.startDate);
    final DateTime? endDate = tryParseDateTime(blinkoNote.endDate);
    // ---------------------------

    // Keep ?? for tags as it's nullable list?
    final List<String> tags =
        (blinkoNote.tags ?? [])
            .map((t) => t.tag.name)
            .whereType<String>()
            .toList();

    // Keep ?? for attachments as it's nullable list?
    final List<Map<String, dynamic>> resources =
        (blinkoNote.attachments ?? []).map((a) {
          return {
            'id':
                a.path, // Use path as a unique identifier if no specific ID is available
            'name': a.path, // Use path or filename as name
            'filename': a.name,
            'externalLink': a.path, // Assuming path is the link
            'contentType': a.type,
            'size':
                a.size?.toString(), // Keep ?? for size as it's nullable num?
            'createTime':
                a.createdAt, // Assuming this is a parsable date string
          };
        }).toList();

    // Keep ?? for references as it's nullable list?
    final List<Map<String, dynamic>> relations =
        (blinkoNote.references ?? [])
            .map((r) {
              final relatedNoteId = r.toNoteId.toString(); // Use toNoteId
              final type =
                  'REFERENCE'; // Blinko references are likely this type
              return {'relatedMemoId': relatedNoteId, 'type': type};
            })
            .whereType<Map<String, dynamic>>()
            .toList();

    return NoteItem(
      id: idStr,
      content: contentStr,
      pinned: isPinned,
      state: state,
      visibility: visibility,
      createTime: createdAt,
      updateTime: updatedAt,
      displayTime: createdAt, // Or maybe updatedAt? Decide display logic.
      tags: tags,
      resources: resources,
      relations: relations,
      creatorId: creatorIdStr,
      startDate: startDate, // Assign parsed start date
      endDate: endDate, // Assign parsed end date
    );
  }

  // Change 18: Updated _convertBlinkoCommentToComment helper method
  Comment _convertBlinkoCommentToComment(
    blinko_api.CommentsList200ResponseItemsInner blinkoComment,
  ) {
    DateTime parseBlinkoDate(String? dateString) {
      if (dateString == null) {
        return DateTime(1970);
      }
      try {
        return DateTime.parse(dateString);
      } catch (_) {
        return DateTime.tryParse(dateString) ?? DateTime(1970);
      }
    }
    CommentState state = CommentState.normal;
    bool pinned = false;
    // Remove unnecessary null-aware operators
    final String idStr = blinkoComment.id.toString();
    final String contentStr = blinkoComment.content;
    final DateTime createdAt = parseBlinkoDate(blinkoComment.createdAt);
    final DateTime updatedAt = parseBlinkoDate(blinkoComment.updatedAt);
    // Keep ?? for accountId as it's nullable num?
    final String creatorIdStr =
        blinkoComment.accountId?.toString() ?? 'unknown_creator';
    return Comment(
      id: idStr,
      content: contentStr,
      createTime: createdAt.millisecondsSinceEpoch,
      updateTime: updatedAt.millisecondsSinceEpoch,
      creatorId: creatorIdStr,
      pinned: pinned,
      state: state,
      resources: [],
    );
  }
}
