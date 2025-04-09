//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class CommentsApi {
  CommentsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Create a new comment
  ///
  /// Creates a new comment on a project or task and returns it as a JSON object. Note that one of task_id or project_id arguments is required.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] content (required):
  ///   Comment content. This value may contain markdown-formatted text and hyperlinks.
  ///
  /// * [String] taskId:
  ///   Comment's task ID (for task comments). task_id or project_id required
  ///
  /// * [String] projectId:
  ///   Comment's project ID (for project comments). task_id or project_id required
  ///
  /// * [CreateCommentAttachmentParameter] attachment:
  ///   Object for attachment object.
  Future<Response> createCommentWithHttpInfo(String content, { String? taskId, String? projectId, CreateCommentAttachmentParameter? attachment, }) async {
    // ignore: prefer_const_declarations
    final path = r'/comments';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (taskId != null) {
      queryParams.addAll(_queryParams('', 'task_id', taskId));
    }
    if (projectId != null) {
      queryParams.addAll(_queryParams('', 'project_id', projectId));
    }
      queryParams.addAll(_queryParams('', 'content', content));
    if (attachment != null) {
      queryParams.addAll(_queryParams('', 'attachment', attachment));
    }

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

  /// Create a new comment
  ///
  /// Creates a new comment on a project or task and returns it as a JSON object. Note that one of task_id or project_id arguments is required.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Parameters:
  ///
  /// * [String] content (required):
  ///   Comment content. This value may contain markdown-formatted text and hyperlinks.
  ///
  /// * [String] taskId:
  ///   Comment's task ID (for task comments). task_id or project_id required
  ///
  /// * [String] projectId:
  ///   Comment's project ID (for project comments). task_id or project_id required
  ///
  /// * [CreateCommentAttachmentParameter] attachment:
  ///   Object for attachment object.
  Future<Comment?> createComment(String content, { String? taskId, String? projectId, CreateCommentAttachmentParameter? attachment, }) async {
    final response = await createCommentWithHttpInfo(content,  taskId: taskId, projectId: projectId, attachment: attachment, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Comment',) as Comment;
    
    }
    return null;
  }

  /// Delete a comment
  ///
  /// Deletes a comment.  A successful response has 204 No Content status and an empty body. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] commentId (required):
  ///   The ID of the comment to delete.
  Future<Response> deleteCommentWithHttpInfo(int commentId,) async {
    // ignore: prefer_const_declarations
    final path = r'/comments/{comment_id}'
      .replaceAll('{comment_id}', commentId.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Delete a comment
  ///
  /// Deletes a comment.  A successful response has 204 No Content status and an empty body. 
  ///
  /// Parameters:
  ///
  /// * [int] commentId (required):
  ///   The ID of the comment to delete.
  Future<void> deleteComment(int commentId,) async {
    final response = await deleteCommentWithHttpInfo(commentId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Get all comments
  ///
  /// Returns a JSON-encoded array of all comments for a given task_id or project_id. Note that one of task_id or project_id arguments is required.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] projectId:
  ///   ID of the project used to filter comments. task_id or project_id required
  ///
  /// * [String] taskId:
  ///   ID of the task used to filter comments. task_id or project_id required
  Future<Response> getAllCommentsWithHttpInfo({ String? projectId, String? taskId, }) async {
    // ignore: prefer_const_declarations
    final path = r'/comments';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (projectId != null) {
      queryParams.addAll(_queryParams('', 'project_id', projectId));
    }
    if (taskId != null) {
      queryParams.addAll(_queryParams('', 'task_id', taskId));
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

  /// Get all comments
  ///
  /// Returns a JSON-encoded array of all comments for a given task_id or project_id. Note that one of task_id or project_id arguments is required.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Parameters:
  ///
  /// * [String] projectId:
  ///   ID of the project used to filter comments. task_id or project_id required
  ///
  /// * [String] taskId:
  ///   ID of the task used to filter comments. task_id or project_id required
  Future<List<Comment>?> getAllComments({ String? projectId, String? taskId, }) async {
    final response = await getAllCommentsWithHttpInfo( projectId: projectId, taskId: taskId, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<Comment>') as List)
        .cast<Comment>()
        .toList(growable: false);

    }
    return null;
  }

  /// Get a comment
  ///
  /// Returns a single comment as a JSON object.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] commentId (required):
  ///   The ID of the comment to retrieve.
  Future<Response> getCommentWithHttpInfo(int commentId,) async {
    // ignore: prefer_const_declarations
    final path = r'/comments/{comment_id}'
      .replaceAll('{comment_id}', commentId.toString());

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

  /// Get a comment
  ///
  /// Returns a single comment as a JSON object.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Parameters:
  ///
  /// * [int] commentId (required):
  ///   The ID of the comment to retrieve.
  Future<Comment?> getComment(int commentId,) async {
    final response = await getCommentWithHttpInfo(commentId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Comment',) as Comment;
    
    }
    return null;
  }

  /// Update a comment
  ///
  /// Updates a comment and returns it as a JSON object.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] commentId (required):
  ///   The ID of the comment to update.
  ///
  /// * [String] content (required):
  ///   New content for the comment. This value may contain markdown-formatted text and hyperlinks.
  Future<Response> updateCommentWithHttpInfo(String commentId, String content,) async {
    // ignore: prefer_const_declarations
    final path = r'/comments/{comment_id}'
      .replaceAll('{comment_id}', commentId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'content', content));

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

  /// Update a comment
  ///
  /// Updates a comment and returns it as a JSON object.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Parameters:
  ///
  /// * [String] commentId (required):
  ///   The ID of the comment to update.
  ///
  /// * [String] content (required):
  ///   New content for the comment. This value may contain markdown-formatted text and hyperlinks.
  Future<Comment?> updateComment(String commentId, String content,) async {
    final response = await updateCommentWithHttpInfo(commentId, content,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Comment',) as Comment;
    
    }
    return null;
  }
}
