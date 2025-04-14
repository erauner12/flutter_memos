//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class NoteApi {
  NoteApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Add note reference
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [NotesAddReferenceRequest] notesAddReferenceRequest (required):
  Future<Response> notesAddReferenceWithHttpInfo(NotesAddReferenceRequest notesAddReferenceRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/note/add-reference';

    // ignore: prefer_final_locals
    Object? postBody = notesAddReferenceRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Add note reference
  ///
  /// Parameters:
  ///
  /// * [NotesAddReferenceRequest] notesAddReferenceRequest (required):
  Future<Object?> notesAddReference(NotesAddReferenceRequest notesAddReferenceRequest,) async {
    final response = await notesAddReferenceWithHttpInfo(notesAddReferenceRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Object',) as Object;
    
    }
    return null;
  }

  /// Clear recycle bin
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> notesClearRecycleBinWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/note/clear-recycle-bin';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Clear recycle bin
  Future<Object?> notesClearRecycleBin() async {
    final response = await notesClearRecycleBinWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Object',) as Object;
    
    }
    return null;
  }

  /// Query daily review note list
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> notesDailyReviewNoteListWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/note/daily-review-list';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Query daily review note list
  Future<List<NotesDailyReviewNoteList200ResponseInner>?> notesDailyReviewNoteList() async {
    final response = await notesDailyReviewNoteListWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<NotesDailyReviewNoteList200ResponseInner>') as List)
        .cast<NotesDailyReviewNoteList200ResponseInner>()
        .toList(growable: false);

    }
    return null;
  }

  /// Batch delete note
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [NotesListByIdsRequest] notesListByIdsRequest (required):
  Future<Response> notesDeleteManyWithHttpInfo(NotesListByIdsRequest notesListByIdsRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/note/batch-delete';

    // ignore: prefer_final_locals
    Object? postBody = notesListByIdsRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Batch delete note
  ///
  /// Parameters:
  ///
  /// * [NotesListByIdsRequest] notesListByIdsRequest (required):
  Future<Object?> notesDeleteMany(NotesListByIdsRequest notesListByIdsRequest,) async {
    final response = await notesDeleteManyWithHttpInfo(notesListByIdsRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Object',) as Object;
    
    }
    return null;
  }

  /// Query note detail
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [NotesDetailRequest] notesDetailRequest (required):
  Future<Response> notesDetailWithHttpInfo(NotesDetailRequest notesDetailRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/note/detail';

    // ignore: prefer_final_locals
    Object? postBody = notesDetailRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Query note detail
  ///
  /// Parameters:
  ///
  /// * [NotesDetailRequest] notesDetailRequest (required):
  Future<NotesDetail200Response?> notesDetail(NotesDetailRequest notesDetailRequest,) async {
    final response = await notesDetailWithHttpInfo(notesDetailRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'NotesDetail200Response',) as NotesDetail200Response;
    
    }
    return null;
  }

  /// Get users with internal access to note
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [NotesDetailRequest] notesDetailRequest (required):
  Future<Response> notesGetInternalSharedUsersWithHttpInfo(NotesDetailRequest notesDetailRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/note/internal-shared-users';

    // ignore: prefer_final_locals
    Object? postBody = notesDetailRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Get users with internal access to note
  ///
  /// Parameters:
  ///
  /// * [NotesDetailRequest] notesDetailRequest (required):
  Future<List<NotesGetInternalSharedUsers200ResponseInner>?> notesGetInternalSharedUsers(NotesDetailRequest notesDetailRequest,) async {
    final response = await notesGetInternalSharedUsersWithHttpInfo(notesDetailRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<NotesGetInternalSharedUsers200ResponseInner>') as List)
        .cast<NotesGetInternalSharedUsers200ResponseInner>()
        .toList(growable: false);

    }
    return null;
  }

  /// Get note history
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [num] noteId (required):
  Future<Response> notesGetNoteHistoryWithHttpInfo(num noteId,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/note/history';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'noteId', noteId));

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Get note history
  ///
  /// Parameters:
  ///
  /// * [num] noteId (required):
  Future<List<NotesGetNoteHistory200ResponseInner>?> notesGetNoteHistory(num noteId,) async {
    final response = await notesGetNoteHistoryWithHttpInfo(noteId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<NotesGetNoteHistory200ResponseInner>') as List)
        .cast<NotesGetNoteHistory200ResponseInner>()
        .toList(growable: false);

    }
    return null;
  }

  /// Get specific note version
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [num] noteId (required):
  ///
  /// * [num] version:
  Future<Response> notesGetNoteVersionWithHttpInfo(num noteId, { num? version, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/note/version';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'noteId', noteId));
    if (version != null) {
      queryParams.addAll(_queryParams('', 'version', version));
    }

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Get specific note version
  ///
  /// Parameters:
  ///
  /// * [num] noteId (required):
  ///
  /// * [num] version:
  Future<NotesGetNoteVersion200Response?> notesGetNoteVersion(num noteId, { num? version, }) async {
    final response = await notesGetNoteVersionWithHttpInfo(noteId,  version: version, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'NotesGetNoteVersion200Response',) as NotesGetNoteVersion200Response;
    
    }
    return null;
  }

  /// Share note internally
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [NotesInternalShareNoteRequest] notesInternalShareNoteRequest (required):
  Future<Response> notesInternalShareNoteWithHttpInfo(NotesInternalShareNoteRequest notesInternalShareNoteRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/note/internal-share';

    // ignore: prefer_final_locals
    Object? postBody = notesInternalShareNoteRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Share note internally
  ///
  /// Parameters:
  ///
  /// * [NotesInternalShareNoteRequest] notesInternalShareNoteRequest (required):
  Future<NotesInternalShareNote200Response?> notesInternalShareNote(NotesInternalShareNoteRequest notesInternalShareNoteRequest,) async {
    final response = await notesInternalShareNoteWithHttpInfo(notesInternalShareNoteRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'NotesInternalShareNote200Response',) as NotesInternalShareNote200Response;
    
    }
    return null;
  }

  /// Get notes shared with me
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [NotesInternalSharedWithMeRequest] notesInternalSharedWithMeRequest (required):
  Future<Response> notesInternalSharedWithMeWithHttpInfo(NotesInternalSharedWithMeRequest notesInternalSharedWithMeRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/note/shared-with-me';

    // ignore: prefer_final_locals
    Object? postBody = notesInternalSharedWithMeRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Get notes shared with me
  ///
  /// Parameters:
  ///
  /// * [NotesInternalSharedWithMeRequest] notesInternalSharedWithMeRequest (required):
  Future<List<NotesInternalSharedWithMe200ResponseInner>?> notesInternalSharedWithMe(NotesInternalSharedWithMeRequest notesInternalSharedWithMeRequest,) async {
    final response = await notesInternalSharedWithMeWithHttpInfo(notesInternalSharedWithMeRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<NotesInternalSharedWithMe200ResponseInner>') as List)
        .cast<NotesInternalSharedWithMe200ResponseInner>()
        .toList(growable: false);

    }
    return null;
  }

  /// Query notes list
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [NotesListRequest] notesListRequest (required):
  Future<Response> notesListWithHttpInfo(NotesListRequest notesListRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/note/list';

    // ignore: prefer_final_locals
    Object? postBody = notesListRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Query notes list
  ///
  /// Parameters:
  ///
  /// * [NotesListRequest] notesListRequest (required):
  Future<List<NotesList200ResponseInner>?> notesList(NotesListRequest notesListRequest,) async {
    final response = await notesListWithHttpInfo(notesListRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<NotesList200ResponseInner>') as List)
        .cast<NotesList200ResponseInner>()
        .toList(growable: false);

    }
    return null;
  }

  /// Query notes list by ids
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [NotesListByIdsRequest] notesListByIdsRequest (required):
  Future<Response> notesListByIdsWithHttpInfo(NotesListByIdsRequest notesListByIdsRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/note/list-by-ids';

    // ignore: prefer_final_locals
    Object? postBody = notesListByIdsRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Query notes list by ids
  ///
  /// Parameters:
  ///
  /// * [NotesListByIdsRequest] notesListByIdsRequest (required):
  Future<List<NotesListByIds200ResponseInner>?> notesListByIds(NotesListByIdsRequest notesListByIdsRequest,) async {
    final response = await notesListByIdsWithHttpInfo(notesListByIdsRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<NotesListByIds200ResponseInner>') as List)
        .cast<NotesListByIds200ResponseInner>()
        .toList(growable: false);

    }
    return null;
  }

  /// Query note references
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [NotesNoteReferenceListRequest] notesNoteReferenceListRequest (required):
  Future<Response> notesNoteReferenceListWithHttpInfo(NotesNoteReferenceListRequest notesNoteReferenceListRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/note/reference-list';

    // ignore: prefer_final_locals
    Object? postBody = notesNoteReferenceListRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Query note references
  ///
  /// Parameters:
  ///
  /// * [NotesNoteReferenceListRequest] notesNoteReferenceListRequest (required):
  Future<List<NotesNoteReferenceList200ResponseInner>?> notesNoteReferenceList(NotesNoteReferenceListRequest notesNoteReferenceListRequest,) async {
    final response = await notesNoteReferenceListWithHttpInfo(notesNoteReferenceListRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<NotesNoteReferenceList200ResponseInner>') as List)
        .cast<NotesNoteReferenceList200ResponseInner>()
        .toList(growable: false);

    }
    return null;
  }

  /// Query share note detail
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [NotesPublicDetailRequest] notesPublicDetailRequest (required):
  Future<Response> notesPublicDetailWithHttpInfo(NotesPublicDetailRequest notesPublicDetailRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/note/public-detail';

    // ignore: prefer_final_locals
    Object? postBody = notesPublicDetailRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Query share note detail
  ///
  /// Parameters:
  ///
  /// * [NotesPublicDetailRequest] notesPublicDetailRequest (required):
  Future<NotesPublicDetail200Response?> notesPublicDetail(NotesPublicDetailRequest notesPublicDetailRequest,) async {
    final response = await notesPublicDetailWithHttpInfo(notesPublicDetailRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'NotesPublicDetail200Response',) as NotesPublicDetail200Response;
    
    }
    return null;
  }

  /// Query share notes list
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [NotesPublicListRequest] notesPublicListRequest (required):
  Future<Response> notesPublicListWithHttpInfo(NotesPublicListRequest notesPublicListRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/note/public-list';

    // ignore: prefer_final_locals
    Object? postBody = notesPublicListRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Query share notes list
  ///
  /// Parameters:
  ///
  /// * [NotesPublicListRequest] notesPublicListRequest (required):
  Future<List<NotesPublicList200ResponseInner>?> notesPublicList(NotesPublicListRequest notesPublicListRequest,) async {
    final response = await notesPublicListWithHttpInfo(notesPublicListRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<NotesPublicList200ResponseInner>') as List)
        .cast<NotesPublicList200ResponseInner>()
        .toList(growable: false);

    }
    return null;
  }

  /// Query random notes for review
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [num] limit:
  Future<Response> notesRandomNoteListWithHttpInfo({ num? limit, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/note/random-list';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (limit != null) {
      queryParams.addAll(_queryParams('', 'limit', limit));
    }

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Query random notes for review
  ///
  /// Parameters:
  ///
  /// * [num] limit:
  Future<List<NotesDailyReviewNoteList200ResponseInner>?> notesRandomNoteList({ num? limit, }) async {
    final response = await notesRandomNoteListWithHttpInfo( limit: limit, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<NotesDailyReviewNoteList200ResponseInner>') as List)
        .cast<NotesDailyReviewNoteList200ResponseInner>()
        .toList(growable: false);

    }
    return null;
  }

  /// Query related notes
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [num] id (required):
  Future<Response> notesRelatedNotesWithHttpInfo(num id,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/note/related-notes';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'id', id));

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Query related notes
  ///
  /// Parameters:
  ///
  /// * [num] id (required):
  Future<List<NotesListByIds200ResponseInner>?> notesRelatedNotes(num id,) async {
    final response = await notesRelatedNotesWithHttpInfo(id,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<NotesListByIds200ResponseInner>') as List)
        .cast<NotesListByIds200ResponseInner>()
        .toList(growable: false);

    }
    return null;
  }

  /// Review a note
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [NotesDetailRequest] notesDetailRequest (required):
  Future<Response> notesReviewNoteWithHttpInfo(NotesDetailRequest notesDetailRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/note/review';

    // ignore: prefer_final_locals
    Object? postBody = notesDetailRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Review a note
  ///
  /// Parameters:
  ///
  /// * [NotesDetailRequest] notesDetailRequest (required):
  Future<NotesReviewNote200Response?> notesReviewNote(NotesDetailRequest notesDetailRequest,) async {
    final response = await notesReviewNoteWithHttpInfo(notesDetailRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'NotesReviewNote200Response',) as NotesReviewNote200Response;
    
    }
    return null;
  }

  /// Share note
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [NotesShareNoteRequest] notesShareNoteRequest (required):
  Future<Response> notesShareNoteWithHttpInfo(NotesShareNoteRequest notesShareNoteRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/note/share';

    // ignore: prefer_final_locals
    Object? postBody = notesShareNoteRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Share note
  ///
  /// Parameters:
  ///
  /// * [NotesShareNoteRequest] notesShareNoteRequest (required):
  Future<NotesShareNote200Response?> notesShareNote(NotesShareNoteRequest notesShareNoteRequest,) async {
    final response = await notesShareNoteWithHttpInfo(notesShareNoteRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'NotesShareNote200Response',) as NotesShareNote200Response;
    
    }
    return null;
  }

  /// Batch trash note
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [NotesListByIdsRequest] notesListByIdsRequest (required):
  Future<Response> notesTrashManyWithHttpInfo(NotesListByIdsRequest notesListByIdsRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/note/batch-trash';

    // ignore: prefer_final_locals
    Object? postBody = notesListByIdsRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Batch trash note
  ///
  /// Parameters:
  ///
  /// * [NotesListByIdsRequest] notesListByIdsRequest (required):
  Future<Object?> notesTrashMany(NotesListByIdsRequest notesListByIdsRequest,) async {
    final response = await notesTrashManyWithHttpInfo(notesListByIdsRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Object',) as Object;
    
    }
    return null;
  }

  /// Update attachments order
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [NotesUpdateAttachmentsOrderRequest] notesUpdateAttachmentsOrderRequest (required):
  Future<Response> notesUpdateAttachmentsOrderWithHttpInfo(NotesUpdateAttachmentsOrderRequest notesUpdateAttachmentsOrderRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/note/update-attachments-order';

    // ignore: prefer_final_locals
    Object? postBody = notesUpdateAttachmentsOrderRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Update attachments order
  ///
  /// Parameters:
  ///
  /// * [NotesUpdateAttachmentsOrderRequest] notesUpdateAttachmentsOrderRequest (required):
  Future<Object?> notesUpdateAttachmentsOrder(NotesUpdateAttachmentsOrderRequest notesUpdateAttachmentsOrderRequest,) async {
    final response = await notesUpdateAttachmentsOrderWithHttpInfo(notesUpdateAttachmentsOrderRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Object',) as Object;
    
    }
    return null;
  }

  /// Batch update note
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [NotesUpdateManyRequest] notesUpdateManyRequest (required):
  Future<Response> notesUpdateManyWithHttpInfo(NotesUpdateManyRequest notesUpdateManyRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/note/batch-update';

    // ignore: prefer_final_locals
    Object? postBody = notesUpdateManyRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Batch update note
  ///
  /// Parameters:
  ///
  /// * [NotesUpdateManyRequest] notesUpdateManyRequest (required):
  Future<Object?> notesUpdateMany(NotesUpdateManyRequest notesUpdateManyRequest,) async {
    final response = await notesUpdateManyWithHttpInfo(notesUpdateManyRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Object',) as Object;
    
    }
    return null;
  }

  /// Update or create note
  ///
  /// The attachments field is an array of objects with the following properties: name, path, and size which get from /api/file/upload
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [NotesUpsertRequest] notesUpsertRequest (required):
  Future<Response> notesUpsertWithHttpInfo(NotesUpsertRequest notesUpsertRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/note/upsert';

    // ignore: prefer_final_locals
    Object? postBody = notesUpsertRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Update or create note
  ///
  /// The attachments field is an array of objects with the following properties: name, path, and size which get from /api/file/upload
  ///
  /// Parameters:
  ///
  /// * [NotesUpsertRequest] notesUpsertRequest (required):
  Future<Object?> notesUpsert(NotesUpsertRequest notesUpsertRequest,) async {
    final response = await notesUpsertWithHttpInfo(notesUpsertRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Object',) as Object;
    
    }
    return null;
  }
}
