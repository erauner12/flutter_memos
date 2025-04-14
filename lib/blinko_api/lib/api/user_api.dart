//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class UserApi {
  UserApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Check if can register admin
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> usersCanRegisterWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/user/can-register';

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

  /// Check if can register admin
  Future<bool?> usersCanRegister() async {
    final response = await usersCanRegisterWithHttpInfo();
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

  /// Delete user
  ///
  /// Delete user and all related data, need super admin permission
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [num] id (required):
  Future<Response> usersDeleteUserWithHttpInfo(num id,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/user/delete';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'id', id));

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

  /// Delete user
  ///
  /// Delete user and all related data, need super admin permission
  ///
  /// Parameters:
  ///
  /// * [num] id (required):
  Future<bool?> usersDeleteUser(num id,) async {
    final response = await usersDeleteUserWithHttpInfo(id,);
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

  /// Find user detail from user id
  ///
  /// Find user detail from user id, need login
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [num] id:
  Future<Response> usersDetailWithHttpInfo({ num? id, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/user/detail';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (id != null) {
      queryParams.addAll(_queryParams('', 'id', id));
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

  /// Find user detail from user id
  ///
  /// Find user detail from user id, need login
  ///
  /// Parameters:
  ///
  /// * [num] id:
  Future<UsersDetail200Response?> usersDetail({ num? id, }) async {
    final response = await usersDetailWithHttpInfo( id: id, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'UsersDetail200Response',) as UsersDetail200Response;
    
    }
    return null;
  }

  /// Generate low permission token
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> usersGenLowPermTokenWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/user/gen-low-perm-token';

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

  /// Generate low permission token
  Future<UsersGenLowPermToken200Response?> usersGenLowPermToken() async {
    final response = await usersGenLowPermTokenWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'UsersGenLowPermToken200Response',) as UsersGenLowPermToken200Response;
    
    }
    return null;
  }

  /// Link account
  ///
  /// Link account
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [UsersLinkAccountRequest] usersLinkAccountRequest (required):
  Future<Response> usersLinkAccountWithHttpInfo(UsersLinkAccountRequest usersLinkAccountRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/user/link-account';

    // ignore: prefer_final_locals
    Object? postBody = usersLinkAccountRequest;

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

  /// Link account
  ///
  /// Link account
  ///
  /// Parameters:
  ///
  /// * [UsersLinkAccountRequest] usersLinkAccountRequest (required):
  Future<bool?> usersLinkAccount(UsersLinkAccountRequest usersLinkAccountRequest,) async {
    final response = await usersLinkAccountWithHttpInfo(usersLinkAccountRequest,);
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

  /// Find user list
  ///
  /// Find user list, need super admin permission
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> usersListWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/user/list';

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

  /// Find user list
  ///
  /// Find user list, need super admin permission
  Future<List<UsersList200ResponseInner>?> usersList() async {
    final response = await usersListWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<UsersList200ResponseInner>') as List)
        .cast<UsersList200ResponseInner>()
        .toList(growable: false);

    }
    return null;
  }

  /// user login
  ///
  /// user login, return user basic info and token
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [UsersRegisterRequest] usersRegisterRequest (required):
  Future<Response> usersLoginWithHttpInfo(UsersRegisterRequest usersRegisterRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/user/login';

    // ignore: prefer_final_locals
    Object? postBody = usersRegisterRequest;

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

  /// user login
  ///
  /// user login, return user basic info and token
  ///
  /// Parameters:
  ///
  /// * [UsersRegisterRequest] usersRegisterRequest (required):
  Future<UsersLogin200Response?> usersLogin(UsersRegisterRequest usersRegisterRequest,) async {
    final response = await usersLoginWithHttpInfo(usersRegisterRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'UsersLogin200Response',) as UsersLogin200Response;
    
    }
    return null;
  }

  /// Find native account list
  ///
  /// find native account list which use username and password to login
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> usersNativeAccountListWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/user/native-account-list';

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

  /// Find native account list
  ///
  /// find native account list which use username and password to login
  Future<List<UsersNativeAccountList200ResponseInner>?> usersNativeAccountList() async {
    final response = await usersNativeAccountListWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<UsersNativeAccountList200ResponseInner>') as List)
        .cast<UsersNativeAccountList200ResponseInner>()
        .toList(growable: false);

    }
    return null;
  }

  /// Find public user list
  ///
  /// Find public user list without admin permission
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> usersPublicUserListWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/user/public-user-list';

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

  /// Find public user list
  ///
  /// Find public user list without admin permission
  Future<List<UsersPublicUserList200ResponseInner>?> usersPublicUserList() async {
    final response = await usersPublicUserListWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<UsersPublicUserList200ResponseInner>') as List)
        .cast<UsersPublicUserList200ResponseInner>()
        .toList(growable: false);

    }
    return null;
  }

  /// Regen token
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> usersRegenTokenWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/user/regen-token';

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

  /// Regen token
  Future<bool?> usersRegenToken() async {
    final response = await usersRegenTokenWithHttpInfo();
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

  /// Register user or admin
  ///
  /// Register user or admin
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [UsersRegisterRequest] usersRegisterRequest (required):
  Future<Response> usersRegisterWithHttpInfo(UsersRegisterRequest usersRegisterRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/user/register';

    // ignore: prefer_final_locals
    Object? postBody = usersRegisterRequest;

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

  /// Register user or admin
  ///
  /// Register user or admin
  ///
  /// Parameters:
  ///
  /// * [UsersRegisterRequest] usersRegisterRequest (required):
  Future<bool?> usersRegister(UsersRegisterRequest usersRegisterRequest,) async {
    final response = await usersRegisterWithHttpInfo(usersRegisterRequest,);
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

  /// Unlink account
  ///
  /// Unlink account
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [NotesDetailRequest] notesDetailRequest (required):
  Future<Response> usersUnlinkAccountWithHttpInfo(NotesDetailRequest notesDetailRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/user/unlink-account';

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

  /// Unlink account
  ///
  /// Unlink account
  ///
  /// Parameters:
  ///
  /// * [NotesDetailRequest] notesDetailRequest (required):
  Future<bool?> usersUnlinkAccount(NotesDetailRequest notesDetailRequest,) async {
    final response = await usersUnlinkAccountWithHttpInfo(notesDetailRequest,);
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

  /// Update or create user
  ///
  /// Update or create user, need login
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [UsersUpsertUserRequest] usersUpsertUserRequest (required):
  Future<Response> usersUpsertUserWithHttpInfo(UsersUpsertUserRequest usersUpsertUserRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/user/upsert';

    // ignore: prefer_final_locals
    Object? postBody = usersUpsertUserRequest;

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

  /// Update or create user
  ///
  /// Update or create user, need login
  ///
  /// Parameters:
  ///
  /// * [UsersUpsertUserRequest] usersUpsertUserRequest (required):
  Future<bool?> usersUpsertUser(UsersUpsertUserRequest usersUpsertUserRequest,) async {
    final response = await usersUpsertUserWithHttpInfo(usersUpsertUserRequest,);
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

  /// Update or create user by admin
  ///
  /// Update or create user by admin, need super admin permission
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [UsersUpsertUserByAdminRequest] usersUpsertUserByAdminRequest (required):
  Future<Response> usersUpsertUserByAdminWithHttpInfo(UsersUpsertUserByAdminRequest usersUpsertUserByAdminRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/user/upsert-by-admin';

    // ignore: prefer_final_locals
    Object? postBody = usersUpsertUserByAdminRequest;

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

  /// Update or create user by admin
  ///
  /// Update or create user by admin, need super admin permission
  ///
  /// Parameters:
  ///
  /// * [UsersUpsertUserByAdminRequest] usersUpsertUserByAdminRequest (required):
  Future<bool?> usersUpsertUserByAdmin(UsersUpsertUserByAdminRequest usersUpsertUserByAdminRequest,) async {
    final response = await usersUpsertUserByAdminWithHttpInfo(usersUpsertUserByAdminRequest,);
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
