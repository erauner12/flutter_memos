//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class TagApi {
  TagApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Only delete tag name
  ///
  /// Only delete tag name and remove tag from notes, but not delete notes
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [NotesDetailRequest] notesDetailRequest (required):
  Future<Response> tagsDeleteOnlyTagWithHttpInfo(NotesDetailRequest notesDetailRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/tags/delete-only-tag';

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

  /// Only delete tag name
  ///
  /// Only delete tag name and remove tag from notes, but not delete notes
  ///
  /// Parameters:
  ///
  /// * [NotesDetailRequest] notesDetailRequest (required):
  Future<bool?> tagsDeleteOnlyTag(NotesDetailRequest notesDetailRequest,) async {
    final response = await tagsDeleteOnlyTagWithHttpInfo(notesDetailRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'bool',) as bool;
    
    }
    return null;
  }

  /// Delete tag and delete notes
  ///
  /// Delete tag and delete notes
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [NotesDetailRequest] notesDetailRequest (required):
  Future<Response> tagsDeleteTagWithAllNoteWithHttpInfo(NotesDetailRequest notesDetailRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/tags/delete-tag-with-notes';

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

  /// Delete tag and delete notes
  ///
  /// Delete tag and delete notes
  ///
  /// Parameters:
  ///
  /// * [NotesDetailRequest] notesDetailRequest (required):
  Future<bool?> tagsDeleteTagWithAllNote(NotesDetailRequest notesDetailRequest,) async {
    final response = await tagsDeleteTagWithAllNoteWithHttpInfo(notesDetailRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'bool',) as bool;
    
    }
    return null;
  }

  /// Get user tags
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> tagsListWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/tags/list';

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

  /// Get user tags
  Future<List<NotesList200ResponseInnerTagsInnerTag>?> tagsList() async {
    final response = await tagsListWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<NotesList200ResponseInnerTagsInnerTag>') as List)
        .cast<NotesList200ResponseInnerTagsInnerTag>()
        .toList(growable: false);

    }
    return null;
  }

  /// Update tag icon
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [TagsUpdateTagIconRequest] tagsUpdateTagIconRequest (required):
  Future<Response> tagsUpdateTagIconWithHttpInfo(TagsUpdateTagIconRequest tagsUpdateTagIconRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/tags/update-icon';

    // ignore: prefer_final_locals
    Object? postBody = tagsUpdateTagIconRequest;

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

  /// Update tag icon
  ///
  /// Parameters:
  ///
  /// * [TagsUpdateTagIconRequest] tagsUpdateTagIconRequest (required):
  Future<NotesList200ResponseInnerTagsInnerTag?> tagsUpdateTagIcon(TagsUpdateTagIconRequest tagsUpdateTagIconRequest,) async {
    final response = await tagsUpdateTagIconWithHttpInfo(tagsUpdateTagIconRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'NotesList200ResponseInnerTagsInnerTag',) as NotesList200ResponseInnerTagsInnerTag;
    
    }
    return null;
  }

  /// Batch update tags
  ///
  /// Batch update tags and add tag to notes
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [TagsUpdateTagManyRequest] tagsUpdateTagManyRequest (required):
  Future<Response> tagsUpdateTagManyWithHttpInfo(TagsUpdateTagManyRequest tagsUpdateTagManyRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/tags/batch-update';

    // ignore: prefer_final_locals
    Object? postBody = tagsUpdateTagManyRequest;

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

  /// Batch update tags
  ///
  /// Batch update tags and add tag to notes
  ///
  /// Parameters:
  ///
  /// * [TagsUpdateTagManyRequest] tagsUpdateTagManyRequest (required):
  Future<bool?> tagsUpdateTagMany(TagsUpdateTagManyRequest tagsUpdateTagManyRequest,) async {
    final response = await tagsUpdateTagManyWithHttpInfo(tagsUpdateTagManyRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'bool',) as bool;
    
    }
    return null;
  }

  /// Update tag name
  ///
  /// Update tag name and update tag to notes
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [TagsUpdateTagNameRequest] tagsUpdateTagNameRequest (required):
  Future<Response> tagsUpdateTagNameWithHttpInfo(TagsUpdateTagNameRequest tagsUpdateTagNameRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/tags/update-name';

    // ignore: prefer_final_locals
    Object? postBody = tagsUpdateTagNameRequest;

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

  /// Update tag name
  ///
  /// Update tag name and update tag to notes
  ///
  /// Parameters:
  ///
  /// * [TagsUpdateTagNameRequest] tagsUpdateTagNameRequest (required):
  Future<bool?> tagsUpdateTagName(TagsUpdateTagNameRequest tagsUpdateTagNameRequest,) async {
    final response = await tagsUpdateTagNameWithHttpInfo(tagsUpdateTagNameRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'bool',) as bool;
    
    }
    return null;
  }
}
