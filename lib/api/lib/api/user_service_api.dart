//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class UserServiceApi {
  UserServiceApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// CreateShortcut creates a new shortcut for a user.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] parent (required):
  ///   The name of the user.
  ///
  /// * [Apiv1Shortcut] shortcut (required):
  ///
  /// * [bool] validateOnly:
  Future<Response> userServiceCreateShortcutWithHttpInfo(String parent, Apiv1Shortcut shortcut, { bool? validateOnly, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{parent}/shortcuts'
      .replaceAll('{parent}', parent);

    // ignore: prefer_final_locals
    Object? postBody = shortcut;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (validateOnly != null) {
      queryParams.addAll(_queryParams('', 'validateOnly', validateOnly));
    }

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

  /// CreateShortcut creates a new shortcut for a user.
  ///
  /// Parameters:
  ///
  /// * [String] parent (required):
  ///   The name of the user.
  ///
  /// * [Apiv1Shortcut] shortcut (required):
  ///
  /// * [bool] validateOnly:
  Future<Apiv1Shortcut?> userServiceCreateShortcut(String parent, Apiv1Shortcut shortcut, { bool? validateOnly, }) async {
    final response = await userServiceCreateShortcutWithHttpInfo(parent, shortcut,  validateOnly: validateOnly, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Apiv1Shortcut',) as Apiv1Shortcut;
    
    }
    return null;
  }

  /// CreateUser creates a new user.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [V1User] user (required):
  Future<Response> userServiceCreateUserWithHttpInfo(V1User user,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/users';

    // ignore: prefer_final_locals
    Object? postBody = user;

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

  /// CreateUser creates a new user.
  ///
  /// Parameters:
  ///
  /// * [V1User] user (required):
  Future<V1User?> userServiceCreateUser(V1User user,) async {
    final response = await userServiceCreateUserWithHttpInfo(user,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'V1User',) as V1User;
    
    }
    return null;
  }

  /// CreateUserAccessToken creates a new access token for a user.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The name of the user.
  ///
  /// * [UserServiceCreateUserAccessTokenBody] body (required):
  Future<Response> userServiceCreateUserAccessTokenWithHttpInfo(String name, UserServiceCreateUserAccessTokenBody body,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{name}/access_tokens'
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

  /// CreateUserAccessToken creates a new access token for a user.
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The name of the user.
  ///
  /// * [UserServiceCreateUserAccessTokenBody] body (required):
  Future<V1UserAccessToken?> userServiceCreateUserAccessToken(String name, UserServiceCreateUserAccessTokenBody body,) async {
    final response = await userServiceCreateUserAccessTokenWithHttpInfo(name, body,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'V1UserAccessToken',) as V1UserAccessToken;
    
    }
    return null;
  }

  /// DeleteShortcut deletes a shortcut for a user.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] parent (required):
  ///   The name of the user.
  ///
  /// * [String] id (required):
  ///   The id of the shortcut.
  Future<Response> userServiceDeleteShortcutWithHttpInfo(String parent, String id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{parent}/shortcuts/{id}'
      .replaceAll('{parent}', parent)
      .replaceAll('{id}', id);

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

  /// DeleteShortcut deletes a shortcut for a user.
  ///
  /// Parameters:
  ///
  /// * [String] parent (required):
  ///   The name of the user.
  ///
  /// * [String] id (required):
  ///   The id of the shortcut.
  Future<Object?> userServiceDeleteShortcut(String parent, String id,) async {
    final response = await userServiceDeleteShortcutWithHttpInfo(parent, id,);
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

  /// DeleteUser deletes a user.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The name of the user.
  Future<Response> userServiceDeleteUserWithHttpInfo(String name,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{name}'
      .replaceAll('{name}', name);

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

  /// DeleteUser deletes a user.
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The name of the user.
  Future<Object?> userServiceDeleteUser(String name,) async {
    final response = await userServiceDeleteUserWithHttpInfo(name,);
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

  /// DeleteUserAccessToken deletes an access token for a user.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The name of the user.
  ///
  /// * [String] accessToken (required):
  ///   access_token is the access token to delete.
  Future<Response> userServiceDeleteUserAccessTokenWithHttpInfo(String name, String accessToken,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{name}/access_tokens/{accessToken}'
      .replaceAll('{name}', name)
      .replaceAll('{accessToken}', accessToken);

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

  /// DeleteUserAccessToken deletes an access token for a user.
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The name of the user.
  ///
  /// * [String] accessToken (required):
  ///   access_token is the access token to delete.
  Future<Object?> userServiceDeleteUserAccessToken(String name, String accessToken,) async {
    final response = await userServiceDeleteUserAccessTokenWithHttpInfo(name, accessToken,);
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

  /// GetUser gets a user by name.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] name1 (required):
  ///   The name of the user.
  Future<Response> userServiceGetUserWithHttpInfo(String name1,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{name_1}'
      .replaceAll('{name_1}', name1);

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

  /// GetUser gets a user by name.
  ///
  /// Parameters:
  ///
  /// * [String] name1 (required):
  ///   The name of the user.
  Future<V1User?> userServiceGetUser(String name1,) async {
    final response = await userServiceGetUserWithHttpInfo(name1,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'V1User',) as V1User;
    
    }
    return null;
  }

  /// GetUserAvatarBinary gets the avatar of a user.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The name of the user.
  ///
  /// * [String] httpBodyPeriodContentType:
  ///   The HTTP Content-Type header value specifying the content type of the body.
  ///
  /// * [String] httpBodyPeriodData:
  ///   The HTTP request/response body as raw binary.
  Future<Response> userServiceGetUserAvatarBinaryWithHttpInfo(String name, { String? httpBodyPeriodContentType, String? httpBodyPeriodData, }) async {
    // ignore: prefer_const_declarations
    final path = r'/file/{name}/avatar'
      .replaceAll('{name}', name);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (httpBodyPeriodContentType != null) {
      queryParams.addAll(_queryParams('', 'httpBody.contentType', httpBodyPeriodContentType));
    }
    if (httpBodyPeriodData != null) {
      queryParams.addAll(_queryParams('', 'httpBody.data', httpBodyPeriodData));
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

  /// GetUserAvatarBinary gets the avatar of a user.
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The name of the user.
  ///
  /// * [String] httpBodyPeriodContentType:
  ///   The HTTP Content-Type header value specifying the content type of the body.
  ///
  /// * [String] httpBodyPeriodData:
  ///   The HTTP request/response body as raw binary.
  Future<ApiHttpBody?> userServiceGetUserAvatarBinary(String name, { String? httpBodyPeriodContentType, String? httpBodyPeriodData, }) async {
    final response = await userServiceGetUserAvatarBinaryWithHttpInfo(name,  httpBodyPeriodContentType: httpBodyPeriodContentType, httpBodyPeriodData: httpBodyPeriodData, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiHttpBody',) as ApiHttpBody;
    
    }
    return null;
  }

  /// GetUserByUsername gets a user by username.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] username:
  ///   The username of the user.
  Future<Response> userServiceGetUserByUsernameWithHttpInfo({ String? username, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/users:username';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (username != null) {
      queryParams.addAll(_queryParams('', 'username', username));
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

  /// GetUserByUsername gets a user by username.
  ///
  /// Parameters:
  ///
  /// * [String] username:
  ///   The username of the user.
  Future<V1User?> userServiceGetUserByUsername({ String? username, }) async {
    final response = await userServiceGetUserByUsernameWithHttpInfo( username: username, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'V1User',) as V1User;
    
    }
    return null;
  }

  /// GetUserSetting gets the setting of a user.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The name of the user.
  Future<Response> userServiceGetUserSettingWithHttpInfo(String name,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{name}/setting'
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

  /// GetUserSetting gets the setting of a user.
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The name of the user.
  Future<Apiv1UserSetting?> userServiceGetUserSetting(String name,) async {
    final response = await userServiceGetUserSettingWithHttpInfo(name,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Apiv1UserSetting',) as Apiv1UserSetting;
    
    }
    return null;
  }

  /// GetUserStats returns the stats of a user.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The name of the user.
  Future<Response> userServiceGetUserStatsWithHttpInfo(String name,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{name}/stats'
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

  /// GetUserStats returns the stats of a user.
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The name of the user.
  Future<V1UserStats?> userServiceGetUserStats(String name,) async {
    final response = await userServiceGetUserStatsWithHttpInfo(name,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'V1UserStats',) as V1UserStats;
    
    }
    return null;
  }

  /// ListAllUserStats returns all user stats.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> userServiceListAllUserStatsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/users/-/stats';

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

  /// ListAllUserStats returns all user stats.
  Future<V1ListAllUserStatsResponse?> userServiceListAllUserStats() async {
    final response = await userServiceListAllUserStatsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'V1ListAllUserStatsResponse',) as V1ListAllUserStatsResponse;
    
    }
    return null;
  }

  /// ListShortcuts returns a list of shortcuts for a user.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] parent (required):
  ///   The name of the user.
  Future<Response> userServiceListShortcutsWithHttpInfo(String parent,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{parent}/shortcuts'
      .replaceAll('{parent}', parent);

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

  /// ListShortcuts returns a list of shortcuts for a user.
  ///
  /// Parameters:
  ///
  /// * [String] parent (required):
  ///   The name of the user.
  Future<V1ListShortcutsResponse?> userServiceListShortcuts(String parent,) async {
    final response = await userServiceListShortcutsWithHttpInfo(parent,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'V1ListShortcutsResponse',) as V1ListShortcutsResponse;
    
    }
    return null;
  }

  /// ListUserAccessTokens returns a list of access tokens for a user.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The name of the user.
  Future<Response> userServiceListUserAccessTokensWithHttpInfo(String name,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{name}/access_tokens'
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

  /// ListUserAccessTokens returns a list of access tokens for a user.
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The name of the user.
  Future<V1ListUserAccessTokensResponse?> userServiceListUserAccessTokens(String name,) async {
    final response = await userServiceListUserAccessTokensWithHttpInfo(name,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'V1ListUserAccessTokensResponse',) as V1ListUserAccessTokensResponse;
    
    }
    return null;
  }

  /// ListUsers returns a list of users.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> userServiceListUsersWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/users';

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

  /// ListUsers returns a list of users.
  Future<V1ListUsersResponse?> userServiceListUsers() async {
    final response = await userServiceListUsersWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'V1ListUsersResponse',) as V1ListUsersResponse;
    
    }
    return null;
  }

  /// UpdateShortcut updates a shortcut for a user.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] parent (required):
  ///   The name of the user.
  ///
  /// * [String] shortcutPeriodId (required):
  ///
  /// * [UserServiceUpdateShortcutRequest] shortcut (required):
  Future<Response> userServiceUpdateShortcutWithHttpInfo(String parent, String shortcutPeriodId, UserServiceUpdateShortcutRequest shortcut,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{parent}/shortcuts/{shortcut.id}'
      .replaceAll('{parent}', parent)
      .replaceAll('{shortcut.id}', shortcutPeriodId);

    // ignore: prefer_final_locals
    Object? postBody = shortcut;

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

  /// UpdateShortcut updates a shortcut for a user.
  ///
  /// Parameters:
  ///
  /// * [String] parent (required):
  ///   The name of the user.
  ///
  /// * [String] shortcutPeriodId (required):
  ///
  /// * [UserServiceUpdateShortcutRequest] shortcut (required):
  Future<Apiv1Shortcut?> userServiceUpdateShortcut(String parent, String shortcutPeriodId, UserServiceUpdateShortcutRequest shortcut,) async {
    final response = await userServiceUpdateShortcutWithHttpInfo(parent, shortcutPeriodId, shortcut,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Apiv1Shortcut',) as Apiv1Shortcut;
    
    }
    return null;
  }

  /// UpdateUser updates a user.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] userPeriodName (required):
  ///   The name of the user.  Format: users/{id}, id is the system generated auto-incremented id.
  ///
  /// * [UserServiceUpdateUserRequest] user (required):
  Future<Response> userServiceUpdateUserWithHttpInfo(String userPeriodName, UserServiceUpdateUserRequest user,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{user.name}'
      .replaceAll('{user.name}', userPeriodName);

    // ignore: prefer_final_locals
    Object? postBody = user;

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

  /// UpdateUser updates a user.
  ///
  /// Parameters:
  ///
  /// * [String] userPeriodName (required):
  ///   The name of the user.  Format: users/{id}, id is the system generated auto-incremented id.
  ///
  /// * [UserServiceUpdateUserRequest] user (required):
  Future<V1User?> userServiceUpdateUser(String userPeriodName, UserServiceUpdateUserRequest user,) async {
    final response = await userServiceUpdateUserWithHttpInfo(userPeriodName, user,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'V1User',) as V1User;
    
    }
    return null;
  }

  /// UpdateUserSetting updates the setting of a user.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] settingPeriodName (required):
  ///   The name of the user.
  ///
  /// * [UserServiceUpdateUserSettingRequest] setting (required):
  Future<Response> userServiceUpdateUserSettingWithHttpInfo(String settingPeriodName, UserServiceUpdateUserSettingRequest setting,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{setting.name}'
      .replaceAll('{setting.name}', settingPeriodName);

    // ignore: prefer_final_locals
    Object? postBody = setting;

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

  /// UpdateUserSetting updates the setting of a user.
  ///
  /// Parameters:
  ///
  /// * [String] settingPeriodName (required):
  ///   The name of the user.
  ///
  /// * [UserServiceUpdateUserSettingRequest] setting (required):
  Future<Apiv1UserSetting?> userServiceUpdateUserSetting(String settingPeriodName, UserServiceUpdateUserSettingRequest setting,) async {
    final response = await userServiceUpdateUserSettingWithHttpInfo(settingPeriodName, setting,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Apiv1UserSetting',) as Apiv1UserSetting;
    
    }
    return null;
  }
}
