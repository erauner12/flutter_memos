//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class AuthServiceApi {
  AuthServiceApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// GetAuthStatus returns the current auth status of the user.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> authServiceGetAuthStatusWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/auth/status';

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

  /// GetAuthStatus returns the current auth status of the user.
  Future<V1User?> authServiceGetAuthStatus() async {
    final response = await authServiceGetAuthStatusWithHttpInfo();
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

  /// SignIn signs in the user with the given username and password.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] username:
  ///   The username to sign in with.
  ///
  /// * [String] password:
  ///   The password to sign in with.
  ///
  /// * [bool] neverExpire:
  ///   Whether the session should never expire.
  Future<Response> authServiceSignInWithHttpInfo({ String? username, String? password, bool? neverExpire, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/auth/signin';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (username != null) {
      queryParams.addAll(_queryParams('', 'username', username));
    }
    if (password != null) {
      queryParams.addAll(_queryParams('', 'password', password));
    }
    if (neverExpire != null) {
      queryParams.addAll(_queryParams('', 'neverExpire', neverExpire));
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

  /// SignIn signs in the user with the given username and password.
  ///
  /// Parameters:
  ///
  /// * [String] username:
  ///   The username to sign in with.
  ///
  /// * [String] password:
  ///   The password to sign in with.
  ///
  /// * [bool] neverExpire:
  ///   Whether the session should never expire.
  Future<V1User?> authServiceSignIn({ String? username, String? password, bool? neverExpire, }) async {
    final response = await authServiceSignInWithHttpInfo( username: username, password: password, neverExpire: neverExpire, );
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

  /// SignInWithSSO signs in the user with the given SSO code.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] idpId:
  ///   The ID of the SSO provider.
  ///
  /// * [String] code:
  ///   The code to sign in with.
  ///
  /// * [String] redirectUri:
  ///   The redirect URI.
  Future<Response> authServiceSignInWithSSOWithHttpInfo({ int? idpId, String? code, String? redirectUri, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/auth/signin/sso';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (idpId != null) {
      queryParams.addAll(_queryParams('', 'idpId', idpId));
    }
    if (code != null) {
      queryParams.addAll(_queryParams('', 'code', code));
    }
    if (redirectUri != null) {
      queryParams.addAll(_queryParams('', 'redirectUri', redirectUri));
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

  /// SignInWithSSO signs in the user with the given SSO code.
  ///
  /// Parameters:
  ///
  /// * [int] idpId:
  ///   The ID of the SSO provider.
  ///
  /// * [String] code:
  ///   The code to sign in with.
  ///
  /// * [String] redirectUri:
  ///   The redirect URI.
  Future<V1User?> authServiceSignInWithSSO({ int? idpId, String? code, String? redirectUri, }) async {
    final response = await authServiceSignInWithSSOWithHttpInfo( idpId: idpId, code: code, redirectUri: redirectUri, );
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

  /// SignOut signs out the user.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> authServiceSignOutWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/auth/signout';

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

  /// SignOut signs out the user.
  Future<Object?> authServiceSignOut() async {
    final response = await authServiceSignOutWithHttpInfo();
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

  /// SignUp signs up the user with the given username and password.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] username:
  ///   The username to sign up with.
  ///
  /// * [String] password:
  ///   The password to sign up with.
  Future<Response> authServiceSignUpWithHttpInfo({ String? username, String? password, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/auth/signup';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (username != null) {
      queryParams.addAll(_queryParams('', 'username', username));
    }
    if (password != null) {
      queryParams.addAll(_queryParams('', 'password', password));
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

  /// SignUp signs up the user with the given username and password.
  ///
  /// Parameters:
  ///
  /// * [String] username:
  ///   The username to sign up with.
  ///
  /// * [String] password:
  ///   The password to sign up with.
  Future<V1User?> authServiceSignUp({ String? username, String? password, }) async {
    final response = await authServiceSignUpWithHttpInfo( username: username, password: password, );
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
}
