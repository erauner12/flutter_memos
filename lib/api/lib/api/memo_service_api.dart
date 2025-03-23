//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class MemoServiceApi {
  MemoServiceApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// CreateMemo creates a memo.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [Apiv1Memo] memo (required):
  ///   The memo to create.
  Future<Response> memoServiceCreateMemoWithHttpInfo(Apiv1Memo memo,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/memos';

    // ignore: prefer_final_locals
    Object? postBody = memo;

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

  /// CreateMemo creates a memo.
  ///
  /// Parameters:
  ///
  /// * [Apiv1Memo] memo (required):
  ///   The memo to create.
  Future<Apiv1Memo?> memoServiceCreateMemo(Apiv1Memo memo,) async {
    final response = await memoServiceCreateMemoWithHttpInfo(memo,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Apiv1Memo',) as Apiv1Memo;
    
    }
    return null;
  }

  /// CreateMemoComment creates a comment for a memo.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The name of the memo.
  ///
  /// * [Apiv1Memo] comment (required):
  ///   The comment to create.
  Future<Response> memoServiceCreateMemoCommentWithHttpInfo(String name, Apiv1Memo comment,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{name}/comments'
      .replaceAll('{name}', name);

    // ignore: prefer_final_locals
    Object? postBody = comment;

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

  /// CreateMemoComment creates a comment for a memo.
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The name of the memo.
  ///
  /// * [Apiv1Memo] comment (required):
  ///   The comment to create.
  Future<Apiv1Memo?> memoServiceCreateMemoComment(String name, Apiv1Memo comment,) async {
    final response = await memoServiceCreateMemoCommentWithHttpInfo(name, comment,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Apiv1Memo',) as Apiv1Memo;
    
    }
    return null;
  }

  /// DeleteMemo deletes a memo.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] name4 (required):
  ///   The name of the memo.
  Future<Response> memoServiceDeleteMemoWithHttpInfo(String name4,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{name_4}'
      .replaceAll('{name_4}', name4);

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

  /// DeleteMemo deletes a memo.
  ///
  /// Parameters:
  ///
  /// * [String] name4 (required):
  ///   The name of the memo.
  Future<Object?> memoServiceDeleteMemo(String name4,) async {
    final response = await memoServiceDeleteMemoWithHttpInfo(name4,);
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

  /// DeleteMemoReaction deletes a reaction for a memo.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] id (required):
  ///   The id of the reaction.  Refer to the `Reaction.id`.
  Future<Response> memoServiceDeleteMemoReactionWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/reactions/{id}'
      .replaceAll('{id}', id.toString());

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

  /// DeleteMemoReaction deletes a reaction for a memo.
  ///
  /// Parameters:
  ///
  /// * [int] id (required):
  ///   The id of the reaction.  Refer to the `Reaction.id`.
  Future<Object?> memoServiceDeleteMemoReaction(int id,) async {
    final response = await memoServiceDeleteMemoReactionWithHttpInfo(id,);
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

  /// DeleteMemoTag deletes a tag for a memo.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] parent (required):
  ///   The parent, who owns the tags.  Format: memos/{id}. Use \"memos/-\" to delete all tags.
  ///
  /// * [String] tag (required):
  ///
  /// * [bool] deleteRelatedMemos:
  Future<Response> memoServiceDeleteMemoTagWithHttpInfo(String parent, String tag, { bool? deleteRelatedMemos, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{parent}/tags/{tag}'
      .replaceAll('{parent}', parent)
      .replaceAll('{tag}', tag);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (deleteRelatedMemos != null) {
      queryParams.addAll(_queryParams('', 'deleteRelatedMemos', deleteRelatedMemos));
    }

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

  /// DeleteMemoTag deletes a tag for a memo.
  ///
  /// Parameters:
  ///
  /// * [String] parent (required):
  ///   The parent, who owns the tags.  Format: memos/{id}. Use \"memos/-\" to delete all tags.
  ///
  /// * [String] tag (required):
  ///
  /// * [bool] deleteRelatedMemos:
  Future<Object?> memoServiceDeleteMemoTag(String parent, String tag, { bool? deleteRelatedMemos, }) async {
    final response = await memoServiceDeleteMemoTagWithHttpInfo(parent, tag,  deleteRelatedMemos: deleteRelatedMemos, );
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

  /// GetMemo gets a memo.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] name4 (required):
  ///   The name of the memo.
  Future<Response> memoServiceGetMemoWithHttpInfo(String name4,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{name_4}'
      .replaceAll('{name_4}', name4);

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

  /// GetMemo gets a memo.
  ///
  /// Parameters:
  ///
  /// * [String] name4 (required):
  ///   The name of the memo.
  Future<Apiv1Memo?> memoServiceGetMemo(String name4,) async {
    final response = await memoServiceGetMemoWithHttpInfo(name4,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Apiv1Memo',) as Apiv1Memo;
    
    }
    return null;
  }

  /// ListMemoComments lists comments for a memo.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The name of the memo.
  Future<Response> memoServiceListMemoCommentsWithHttpInfo(String name,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{name}/comments'
      .replaceAll('{name}', name);

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

  /// ListMemoComments lists comments for a memo.
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The name of the memo.
  Future<V1ListMemoCommentsResponse?> memoServiceListMemoComments(String name,) async {
    final response = await memoServiceListMemoCommentsWithHttpInfo(name,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'V1ListMemoCommentsResponse',) as V1ListMemoCommentsResponse;
    
    }
    return null;
  }

  /// ListMemoReactions lists reactions for a memo.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The name of the memo.
  Future<Response> memoServiceListMemoReactionsWithHttpInfo(String name,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{name}/reactions'
      .replaceAll('{name}', name);

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

  /// ListMemoReactions lists reactions for a memo.
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The name of the memo.
  Future<V1ListMemoReactionsResponse?> memoServiceListMemoReactions(String name,) async {
    final response = await memoServiceListMemoReactionsWithHttpInfo(name,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'V1ListMemoReactionsResponse',) as V1ListMemoReactionsResponse;
    
    }
    return null;
  }

  /// ListMemoRelations lists relations for a memo.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The name of the memo.
  Future<Response> memoServiceListMemoRelationsWithHttpInfo(String name,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{name}/relations'
      .replaceAll('{name}', name);

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

  /// ListMemoRelations lists relations for a memo.
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The name of the memo.
  Future<V1ListMemoRelationsResponse?> memoServiceListMemoRelations(String name,) async {
    final response = await memoServiceListMemoRelationsWithHttpInfo(name,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'V1ListMemoRelationsResponse',) as V1ListMemoRelationsResponse;
    
    }
    return null;
  }

  /// ListMemoResources lists resources for a memo.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The name of the memo.
  Future<Response> memoServiceListMemoResourcesWithHttpInfo(String name,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{name}/resources'
      .replaceAll('{name}', name);

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

  /// ListMemoResources lists resources for a memo.
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The name of the memo.
  Future<V1ListMemoResourcesResponse?> memoServiceListMemoResources(String name,) async {
    final response = await memoServiceListMemoResourcesWithHttpInfo(name,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'V1ListMemoResourcesResponse',) as V1ListMemoResourcesResponse;
    
    }
    return null;
  }

  /// ListMemos lists memos with pagination and filter.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] parent:
  ///   The parent is the owner of the memos.  If not specified or `users/-`, it will list all memos.
  ///
  /// * [int] pageSize:
  ///   The maximum number of memos to return.
  ///
  /// * [String] pageToken:
  ///   A page token, received from a previous `ListMemos` call.  Provide this to retrieve the subsequent page.
  ///
  /// * [String] state:
  ///   The state of the memos to list.  Default to `NORMAL`. Set to `ARCHIVED` to list archived memos.
  ///
  /// * [String] sort:
  ///   What field to sort the results by.  Default to display_time.
  ///
  /// * [String] direction:
  ///   The direction to sort the results by.  Default to DESC.
  ///
  /// * [String] filter:
  ///   Filter is a CEL expression to filter memos.  Refer to `Shortcut.filter`.
  ///
  /// * [String] oldFilter:
  ///   [Deprecated] Old filter contains some specific conditions to filter memos.  Format: \"creator == 'users/{user}' && visibilities == ['PUBLIC', 'PROTECTED']\"
  Future<Response> memoServiceListMemosWithHttpInfo({ String? parent, int? pageSize, String? pageToken, String? state, String? sort, String? direction, String? filter, String? oldFilter, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/memos';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (parent != null) {
      queryParams.addAll(_queryParams('', 'parent', parent));
    }
    if (pageSize != null) {
      queryParams.addAll(_queryParams('', 'pageSize', pageSize));
    }
    if (pageToken != null) {
      queryParams.addAll(_queryParams('', 'pageToken', pageToken));
    }
    if (state != null) {
      queryParams.addAll(_queryParams('', 'state', state));
    }
    if (sort != null) {
      queryParams.addAll(_queryParams('', 'sort', sort));
    }
    if (direction != null) {
      queryParams.addAll(_queryParams('', 'direction', direction));
    }
    if (filter != null) {
      queryParams.addAll(_queryParams('', 'filter', filter));
    }
    if (oldFilter != null) {
      queryParams.addAll(_queryParams('', 'oldFilter', oldFilter));
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

  /// ListMemos lists memos with pagination and filter.
  ///
  /// Parameters:
  ///
  /// * [String] parent:
  ///   The parent is the owner of the memos.  If not specified or `users/-`, it will list all memos.
  ///
  /// * [int] pageSize:
  ///   The maximum number of memos to return.
  ///
  /// * [String] pageToken:
  ///   A page token, received from a previous `ListMemos` call.  Provide this to retrieve the subsequent page.
  ///
  /// * [String] state:
  ///   The state of the memos to list.  Default to `NORMAL`. Set to `ARCHIVED` to list archived memos.
  ///
  /// * [String] sort:
  ///   What field to sort the results by.  Default to display_time.
  ///
  /// * [String] direction:
  ///   The direction to sort the results by.  Default to DESC.
  ///
  /// * [String] filter:
  ///   Filter is a CEL expression to filter memos.  Refer to `Shortcut.filter`.
  ///
  /// * [String] oldFilter:
  ///   [Deprecated] Old filter contains some specific conditions to filter memos.  Format: \"creator == 'users/{user}' && visibilities == ['PUBLIC', 'PROTECTED']\"
  Future<V1ListMemosResponse?> memoServiceListMemos({ String? parent, int? pageSize, String? pageToken, String? state, String? sort, String? direction, String? filter, String? oldFilter, }) async {
    final response = await memoServiceListMemosWithHttpInfo( parent: parent, pageSize: pageSize, pageToken: pageToken, state: state, sort: sort, direction: direction, filter: filter, oldFilter: oldFilter, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'V1ListMemosResponse',) as V1ListMemosResponse;
    
    }
    return null;
  }

  /// ListMemos lists memos with pagination and filter.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] parent (required):
  ///   The parent is the owner of the memos.  If not specified or `users/-`, it will list all memos.
  ///
  /// * [int] pageSize:
  ///   The maximum number of memos to return.
  ///
  /// * [String] pageToken:
  ///   A page token, received from a previous `ListMemos` call.  Provide this to retrieve the subsequent page.
  ///
  /// * [String] state:
  ///   The state of the memos to list.  Default to `NORMAL`. Set to `ARCHIVED` to list archived memos.
  ///
  /// * [String] sort:
  ///   What field to sort the results by.  Default to display_time.
  ///
  /// * [String] direction:
  ///   The direction to sort the results by.  Default to DESC.
  ///
  /// * [String] filter:
  ///   Filter is a CEL expression to filter memos.  Refer to `Shortcut.filter`.
  ///
  /// * [String] oldFilter:
  ///   [Deprecated] Old filter contains some specific conditions to filter memos.  Format: \"creator == 'users/{user}' && visibilities == ['PUBLIC', 'PROTECTED']\"
  Future<Response> memoServiceListMemos2WithHttpInfo(String parent, { int? pageSize, String? pageToken, String? state, String? sort, String? direction, String? filter, String? oldFilter, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{parent}/memos'
      .replaceAll('{parent}', parent);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (pageSize != null) {
      queryParams.addAll(_queryParams('', 'pageSize', pageSize));
    }
    if (pageToken != null) {
      queryParams.addAll(_queryParams('', 'pageToken', pageToken));
    }
    if (state != null) {
      queryParams.addAll(_queryParams('', 'state', state));
    }
    if (sort != null) {
      queryParams.addAll(_queryParams('', 'sort', sort));
    }
    if (direction != null) {
      queryParams.addAll(_queryParams('', 'direction', direction));
    }
    if (filter != null) {
      queryParams.addAll(_queryParams('', 'filter', filter));
    }
    if (oldFilter != null) {
      queryParams.addAll(_queryParams('', 'oldFilter', oldFilter));
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

  /// ListMemos lists memos with pagination and filter.
  ///
  /// Parameters:
  ///
  /// * [String] parent (required):
  ///   The parent is the owner of the memos.  If not specified or `users/-`, it will list all memos.
  ///
  /// * [int] pageSize:
  ///   The maximum number of memos to return.
  ///
  /// * [String] pageToken:
  ///   A page token, received from a previous `ListMemos` call.  Provide this to retrieve the subsequent page.
  ///
  /// * [String] state:
  ///   The state of the memos to list.  Default to `NORMAL`. Set to `ARCHIVED` to list archived memos.
  ///
  /// * [String] sort:
  ///   What field to sort the results by.  Default to display_time.
  ///
  /// * [String] direction:
  ///   The direction to sort the results by.  Default to DESC.
  ///
  /// * [String] filter:
  ///   Filter is a CEL expression to filter memos.  Refer to `Shortcut.filter`.
  ///
  /// * [String] oldFilter:
  ///   [Deprecated] Old filter contains some specific conditions to filter memos.  Format: \"creator == 'users/{user}' && visibilities == ['PUBLIC', 'PROTECTED']\"
  Future<V1ListMemosResponse?> memoServiceListMemos2(String parent, { int? pageSize, String? pageToken, String? state, String? sort, String? direction, String? filter, String? oldFilter, }) async {
    final response = await memoServiceListMemos2WithHttpInfo(parent,  pageSize: pageSize, pageToken: pageToken, state: state, sort: sort, direction: direction, filter: filter, oldFilter: oldFilter, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'V1ListMemosResponse',) as V1ListMemosResponse;
    
    }
    return null;
  }

  /// RenameMemoTag renames a tag for a memo.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] parent (required):
  ///   The parent, who owns the tags.  Format: memos/{id}. Use \"memos/-\" to rename all tags.
  ///
  /// * [MemoServiceRenameMemoTagBody] body (required):
  Future<Response> memoServiceRenameMemoTagWithHttpInfo(String parent, MemoServiceRenameMemoTagBody body,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{parent}/tags:rename'
      .replaceAll('{parent}', parent);

    // ignore: prefer_final_locals
    Object? postBody = body;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PATCH',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// RenameMemoTag renames a tag for a memo.
  ///
  /// Parameters:
  ///
  /// * [String] parent (required):
  ///   The parent, who owns the tags.  Format: memos/{id}. Use \"memos/-\" to rename all tags.
  ///
  /// * [MemoServiceRenameMemoTagBody] body (required):
  Future<Object?> memoServiceRenameMemoTag(String parent, MemoServiceRenameMemoTagBody body,) async {
    final response = await memoServiceRenameMemoTagWithHttpInfo(parent, body,);
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

  /// SetMemoRelations sets relations for a memo.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The name of the memo.
  ///
  /// * [MemoServiceSetMemoRelationsBody] body (required):
  Future<Response> memoServiceSetMemoRelationsWithHttpInfo(String name, MemoServiceSetMemoRelationsBody body,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{name}/relations'
      .replaceAll('{name}', name);

    // ignore: prefer_final_locals
    Object? postBody = body;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PATCH',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// SetMemoRelations sets relations for a memo.
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The name of the memo.
  ///
  /// * [MemoServiceSetMemoRelationsBody] body (required):
  Future<Object?> memoServiceSetMemoRelations(String name, MemoServiceSetMemoRelationsBody body,) async {
    final response = await memoServiceSetMemoRelationsWithHttpInfo(name, body,);
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

  /// SetMemoResources sets resources for a memo.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The name of the memo.
  ///
  /// * [MemoServiceSetMemoResourcesBody] body (required):
  Future<Response> memoServiceSetMemoResourcesWithHttpInfo(String name, MemoServiceSetMemoResourcesBody body,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{name}/resources'
      .replaceAll('{name}', name);

    // ignore: prefer_final_locals
    Object? postBody = body;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PATCH',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// SetMemoResources sets resources for a memo.
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The name of the memo.
  ///
  /// * [MemoServiceSetMemoResourcesBody] body (required):
  Future<Object?> memoServiceSetMemoResources(String name, MemoServiceSetMemoResourcesBody body,) async {
    final response = await memoServiceSetMemoResourcesWithHttpInfo(name, body,);
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

  /// UpdateMemo updates a memo.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] memoPeriodName (required):
  ///   The name of the memo.  Format: memos/{memo}, memo is the user defined id or uuid.
  ///
  /// * [TheMemoToUpdateTheNameFieldIsRequired] memo (required):
  ///   The memo to update.  The `name` field is required.
  Future<Response> memoServiceUpdateMemoWithHttpInfo(String memoPeriodName, TheMemoToUpdateTheNameFieldIsRequired memo,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{memo.name}'
      .replaceAll('{memo.name}', memoPeriodName);

    // ignore: prefer_final_locals
    Object? postBody = memo;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PATCH',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// UpdateMemo updates a memo.
  ///
  /// Parameters:
  ///
  /// * [String] memoPeriodName (required):
  ///   The name of the memo.  Format: memos/{memo}, memo is the user defined id or uuid.
  ///
  /// * [TheMemoToUpdateTheNameFieldIsRequired] memo (required):
  ///   The memo to update.  The `name` field is required.
  Future<Apiv1Memo?> memoServiceUpdateMemo(String memoPeriodName, TheMemoToUpdateTheNameFieldIsRequired memo,) async {
    final response = await memoServiceUpdateMemoWithHttpInfo(memoPeriodName, memo,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Apiv1Memo',) as Apiv1Memo;
    
    }
    return null;
  }

  /// UpsertMemoReaction upserts a reaction for a memo.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The name of the memo.
  ///
  /// * [MemoServiceUpsertMemoReactionBody] body (required):
  Future<Response> memoServiceUpsertMemoReactionWithHttpInfo(String name, MemoServiceUpsertMemoReactionBody body,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{name}/reactions'
      .replaceAll('{name}', name);

    // ignore: prefer_final_locals
    Object? postBody = body;

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

  /// UpsertMemoReaction upserts a reaction for a memo.
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The name of the memo.
  ///
  /// * [MemoServiceUpsertMemoReactionBody] body (required):
  Future<V1Reaction?> memoServiceUpsertMemoReaction(String name, MemoServiceUpsertMemoReactionBody body,) async {
    final response = await memoServiceUpsertMemoReactionWithHttpInfo(name, body,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'V1Reaction',) as V1Reaction;
    
    }
    return null;
  }
}
