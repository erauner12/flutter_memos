//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class FollowsApi {
  FollowsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Follow a user
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [FollowsFollowRequest] followsFollowRequest (required):
  Future<Response> followsFollowWithHttpInfo(FollowsFollowRequest followsFollowRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/follows/follow';

    // ignore: prefer_final_locals
    Object? postBody = followsFollowRequest;

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

  /// Follow a user
  ///
  /// Parameters:
  ///
  /// * [FollowsFollowRequest] followsFollowRequest (required):
  Future<PublicTestWebhook200Response?> followsFollow(FollowsFollowRequest followsFollowRequest,) async {
    final response = await followsFollowWithHttpInfo(followsFollowRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PublicTestWebhook200Response',) as PublicTestWebhook200Response;
    
    }
    return null;
  }

  /// Some site wants to follow me
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [FollowsFollowFromRequest] followsFollowFromRequest (required):
  Future<Response> followsFollowFromWithHttpInfo(FollowsFollowFromRequest followsFollowFromRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/follows/follow-from';

    // ignore: prefer_final_locals
    Object? postBody = followsFollowFromRequest;

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

  /// Some site wants to follow me
  ///
  /// Parameters:
  ///
  /// * [FollowsFollowFromRequest] followsFollowFromRequest (required):
  Future<PublicTestWebhook200Response?> followsFollowFrom(FollowsFollowFromRequest followsFollowFromRequest,) async {
    final response = await followsFollowFromWithHttpInfo(followsFollowFromRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PublicTestWebhook200Response',) as PublicTestWebhook200Response;
    
    }
    return null;
  }

  /// Get following list
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [num] userId:
  Future<Response> followsFollowListWithHttpInfo({ num? userId, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/follows/follow-list';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (userId != null) {
      queryParams.addAll(_queryParams('', 'userId', userId));
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

  /// Get following list
  ///
  /// Parameters:
  ///
  /// * [num] userId:
  Future<List<FollowsFollowList200ResponseInner>?> followsFollowList({ num? userId, }) async {
    final response = await followsFollowListWithHttpInfo( userId: userId, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<FollowsFollowList200ResponseInner>') as List)
        .cast<FollowsFollowList200ResponseInner>()
        .toList(growable: false);

    }
    return null;
  }

  /// Get followers list
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [num] userId:
  Future<Response> followsFollowerListWithHttpInfo({ num? userId, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/follows/followers';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (userId != null) {
      queryParams.addAll(_queryParams('', 'userId', userId));
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

  /// Get followers list
  ///
  /// Parameters:
  ///
  /// * [num] userId:
  Future<List<FollowsFollowList200ResponseInner>?> followsFollowerList({ num? userId, }) async {
    final response = await followsFollowerListWithHttpInfo( userId: userId, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<FollowsFollowList200ResponseInner>') as List)
        .cast<FollowsFollowList200ResponseInner>()
        .toList(growable: false);

    }
    return null;
  }

  /// Check if following a user
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] siteUrl (required):
  Future<Response> followsIsFollowingWithHttpInfo(String siteUrl,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/follows/is-following';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'siteUrl', siteUrl));

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

  /// Check if following a user
  ///
  /// Parameters:
  ///
  /// * [String] siteUrl (required):
  Future<FollowsIsFollowing200Response?> followsIsFollowing(String siteUrl,) async {
    final response = await followsIsFollowingWithHttpInfo(siteUrl,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'FollowsIsFollowing200Response',) as FollowsIsFollowing200Response;
    
    }
    return null;
  }

  /// Get recommand list by following users
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] searchText:
  Future<Response> followsRecommandListWithHttpInfo({ String? searchText, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/follows/recommand-list';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (searchText != null) {
      queryParams.addAll(_queryParams('', 'searchText', searchText));
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

  /// Get recommand list by following users
  ///
  /// Parameters:
  ///
  /// * [String] searchText:
  Future<List<FollowsRecommandList200ResponseInner>?> followsRecommandList({ String? searchText, }) async {
    final response = await followsRecommandListWithHttpInfo( searchText: searchText, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<FollowsRecommandList200ResponseInner>') as List)
        .cast<FollowsRecommandList200ResponseInner>()
        .toList(growable: false);

    }
    return null;
  }

  /// Unfollow a user
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [FollowsFollowRequest] followsFollowRequest (required):
  Future<Response> followsUnfollowWithHttpInfo(FollowsFollowRequest followsFollowRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/follows/unfollow';

    // ignore: prefer_final_locals
    Object? postBody = followsFollowRequest;

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

  /// Unfollow a user
  ///
  /// Parameters:
  ///
  /// * [FollowsFollowRequest] followsFollowRequest (required):
  Future<bool?> followsUnfollow(FollowsFollowRequest followsFollowRequest,) async {
    final response = await followsUnfollowWithHttpInfo(followsFollowRequest,);
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

  /// Some site wants to unfollow me
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [FollowsUnfollowFromRequest] followsUnfollowFromRequest (required):
  Future<Response> followsUnfollowFromWithHttpInfo(FollowsUnfollowFromRequest followsUnfollowFromRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/follows/unfollow-from';

    // ignore: prefer_final_locals
    Object? postBody = followsUnfollowFromRequest;

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

  /// Some site wants to unfollow me
  ///
  /// Parameters:
  ///
  /// * [FollowsUnfollowFromRequest] followsUnfollowFromRequest (required):
  Future<bool?> followsUnfollowFrom(FollowsUnfollowFromRequest followsUnfollowFromRequest,) async {
    final response = await followsUnfollowFromWithHttpInfo(followsUnfollowFromRequest,);
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
