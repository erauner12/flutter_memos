//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class CommentApi {
  CommentApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Create a comment
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [CommentsCreateRequest] commentsCreateRequest (required):
  Future<Response> commentsCreateWithHttpInfo(CommentsCreateRequest commentsCreateRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/comment/create';

    // ignore: prefer_final_locals
    Object? postBody = commentsCreateRequest;

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

  /// Create a comment
  ///
  /// Parameters:
  ///
  /// * [CommentsCreateRequest] commentsCreateRequest (required):
  Future<bool?> commentsCreate(CommentsCreateRequest commentsCreateRequest,) async {
    final response = await commentsCreateWithHttpInfo(commentsCreateRequest,);
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

  /// Delete a comment
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [NotesDetailRequest] notesDetailRequest (required):
  Future<Response> commentsDeleteWithHttpInfo(NotesDetailRequest notesDetailRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/comment/delete';

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

  /// Delete a comment
  ///
  /// Parameters:
  ///
  /// * [NotesDetailRequest] notesDetailRequest (required):
  Future<CommentsDelete200Response?> commentsDelete(NotesDetailRequest notesDetailRequest,) async {
    final response = await commentsDeleteWithHttpInfo(notesDetailRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'CommentsDelete200Response',) as CommentsDelete200Response;
    
    }
    return null;
  }

  /// Get comments list
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [CommentsListRequest] commentsListRequest (required):
  Future<Response> commentsListWithHttpInfo(CommentsListRequest commentsListRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/comment/list';

    // ignore: prefer_final_locals
    Object? postBody = commentsListRequest;

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

  /// Get comments list
  ///
  /// Parameters:
  ///
  /// * [CommentsListRequest] commentsListRequest (required):
  Future<CommentsList200Response?> commentsList(CommentsListRequest commentsListRequest,) async {
    final response = await commentsListWithHttpInfo(commentsListRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'CommentsList200Response',) as CommentsList200Response;
    
    }
    return null;
  }

  /// Update a comment
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [CommentsUpdateRequest] commentsUpdateRequest (required):
  Future<Response> commentsUpdateWithHttpInfo(CommentsUpdateRequest commentsUpdateRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/comment/update';

    // ignore: prefer_final_locals
    Object? postBody = commentsUpdateRequest;

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

  /// Update a comment
  ///
  /// Parameters:
  ///
  /// * [CommentsUpdateRequest] commentsUpdateRequest (required):
  Future<CommentsList200ResponseItemsInner?> commentsUpdate(CommentsUpdateRequest commentsUpdateRequest,) async {
    final response = await commentsUpdateWithHttpInfo(commentsUpdateRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'CommentsList200ResponseItemsInner',) as CommentsList200ResponseItemsInner;
    
    }
    return null;
  }
}
