//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class IdentityProviderServiceApi {
  IdentityProviderServiceApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// CreateIdentityProvider creates an identity provider.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [Apiv1IdentityProvider] identityProvider (required):
  ///   The identityProvider to create.
  Future<Response> identityProviderServiceCreateIdentityProviderWithHttpInfo(Apiv1IdentityProvider identityProvider,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/identityProviders';

    // ignore: prefer_final_locals
    Object? postBody = identityProvider;

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

  /// CreateIdentityProvider creates an identity provider.
  ///
  /// Parameters:
  ///
  /// * [Apiv1IdentityProvider] identityProvider (required):
  ///   The identityProvider to create.
  Future<Apiv1IdentityProvider?> identityProviderServiceCreateIdentityProvider(Apiv1IdentityProvider identityProvider,) async {
    final response = await identityProviderServiceCreateIdentityProviderWithHttpInfo(identityProvider,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Apiv1IdentityProvider',) as Apiv1IdentityProvider;
    
    }
    return null;
  }

  /// DeleteIdentityProvider deletes an identity provider.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] name1 (required):
  ///   The name of the identityProvider to delete.
  Future<Response> identityProviderServiceDeleteIdentityProviderWithHttpInfo(String name1,) async {
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
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// DeleteIdentityProvider deletes an identity provider.
  ///
  /// Parameters:
  ///
  /// * [String] name1 (required):
  ///   The name of the identityProvider to delete.
  Future<Object?> identityProviderServiceDeleteIdentityProvider(String name1,) async {
    final response = await identityProviderServiceDeleteIdentityProviderWithHttpInfo(name1,);
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

  /// GetIdentityProvider gets an identity provider.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] name2 (required):
  ///   The name of the identityProvider to get.
  Future<Response> identityProviderServiceGetIdentityProviderWithHttpInfo(String name2,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{name_2}'
      .replaceAll('{name_2}', name2);

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

  /// GetIdentityProvider gets an identity provider.
  ///
  /// Parameters:
  ///
  /// * [String] name2 (required):
  ///   The name of the identityProvider to get.
  Future<Apiv1IdentityProvider?> identityProviderServiceGetIdentityProvider(String name2,) async {
    final response = await identityProviderServiceGetIdentityProviderWithHttpInfo(name2,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Apiv1IdentityProvider',) as Apiv1IdentityProvider;
    
    }
    return null;
  }

  /// ListIdentityProviders lists identity providers.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> identityProviderServiceListIdentityProvidersWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/identityProviders';

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

  /// ListIdentityProviders lists identity providers.
  Future<V1ListIdentityProvidersResponse?> identityProviderServiceListIdentityProviders() async {
    final response = await identityProviderServiceListIdentityProvidersWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'V1ListIdentityProvidersResponse',) as V1ListIdentityProvidersResponse;
    
    }
    return null;
  }

  /// UpdateIdentityProvider updates an identity provider.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] identityProviderPeriodName (required):
  ///   The name of the identityProvider. Format: identityProviders/{id}, id is the system generated auto-incremented id.
  ///
  /// * [TheIdentityProviderToUpdate] identityProvider (required):
  ///   The identityProvider to update.
  Future<Response> identityProviderServiceUpdateIdentityProviderWithHttpInfo(String identityProviderPeriodName, TheIdentityProviderToUpdate identityProvider,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{identityProvider.name}'
      .replaceAll('{identityProvider.name}', identityProviderPeriodName);

    // ignore: prefer_final_locals
    Object? postBody = identityProvider;

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

  /// UpdateIdentityProvider updates an identity provider.
  ///
  /// Parameters:
  ///
  /// * [String] identityProviderPeriodName (required):
  ///   The name of the identityProvider. Format: identityProviders/{id}, id is the system generated auto-incremented id.
  ///
  /// * [TheIdentityProviderToUpdate] identityProvider (required):
  ///   The identityProvider to update.
  Future<Apiv1IdentityProvider?> identityProviderServiceUpdateIdentityProvider(String identityProviderPeriodName, TheIdentityProviderToUpdate identityProvider,) async {
    final response = await identityProviderServiceUpdateIdentityProviderWithHttpInfo(identityProviderPeriodName, identityProvider,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Apiv1IdentityProvider',) as Apiv1IdentityProvider;
    
    }
    return null;
  }
}
