//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class PublicApi {
  PublicApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Get hub list
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> publicHubListWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/public/hub-list';

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

  /// Get hub list
  Future<List<PublicHubList200ResponseInner>?> publicHubList() async {
    final response = await publicHubListWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<PublicHubList200ResponseInner>') as List)
        .cast<PublicHubList200ResponseInner>()
        .toList(growable: false);

    }
    return null;
  }

  /// Get hub site list from GitHub
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] search:
  ///
  /// * [bool] refresh:
  Future<Response> publicHubSiteListWithHttpInfo({ String? search, bool? refresh, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/public/hub-site-list';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (search != null) {
      queryParams.addAll(_queryParams('', 'search', search));
    }
    if (refresh != null) {
      queryParams.addAll(_queryParams('', 'refresh', refresh));
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

  /// Get hub site list from GitHub
  ///
  /// Parameters:
  ///
  /// * [String] search:
  ///
  /// * [bool] refresh:
  Future<List<PublicHubSiteList200ResponseInner>?> publicHubSiteList({ String? search, bool? refresh, }) async {
    final response = await publicHubSiteListWithHttpInfo( search: search, refresh: refresh, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<PublicHubSiteList200ResponseInner>') as List)
        .cast<PublicHubSiteList200ResponseInner>()
        .toList(growable: false);

    }
    return null;
  }

  /// Get a new version
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> publicLatestVersionWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/public/latest-version';

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

  /// Get a new version
  Future<String?> publicLatestVersion() async {
    final response = await publicLatestVersionWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'String',) as String;
    
    }
    return null;
  }

  /// Get a link preview info
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] url (required):
  Future<Response> publicLinkPreviewWithHttpInfo(String url,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/public/link-preview';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'url', url));

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

  /// Get a link preview info
  ///
  /// Parameters:
  ///
  /// * [String] url (required):
  Future<PublicLinkPreview200Response?> publicLinkPreview(String url,) async {
    final response = await publicLinkPreviewWithHttpInfo(url,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PublicLinkPreview200Response',) as PublicLinkPreview200Response;
    
    }
    return null;
  }

  /// Get music metadata
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] filePath (required):
  Future<Response> publicMusicMetadataWithHttpInfo(String filePath,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/public/music-metadata';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'filePath', filePath));

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

  /// Get music metadata
  ///
  /// Parameters:
  ///
  /// * [String] filePath (required):
  Future<PublicMusicMetadata200Response?> publicMusicMetadata(String filePath,) async {
    final response = await publicMusicMetadataWithHttpInfo(filePath,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PublicMusicMetadata200Response',) as PublicMusicMetadata200Response;
    
    }
    return null;
  }

  /// Get OAuth providers info
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> publicOauthProvidersWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/public/oauth-providers';

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

  /// Get OAuth providers info
  Future<List<PublicOauthProviders200ResponseInner>?> publicOauthProviders() async {
    final response = await publicOauthProvidersWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<PublicOauthProviders200ResponseInner>') as List)
        .cast<PublicOauthProviders200ResponseInner>()
        .toList(growable: false);

    }
    return null;
  }

  /// Get site info
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [num] id:
  Future<Response> publicSiteInfoWithHttpInfo({ num? id, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/public/site-info';

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

  /// Get site info
  ///
  /// Parameters:
  ///
  /// * [num] id:
  Future<PublicSiteInfo200Response?> publicSiteInfo({ num? id, }) async {
    final response = await publicSiteInfoWithHttpInfo( id: id, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PublicSiteInfo200Response',) as PublicSiteInfo200Response;
    
    }
    return null;
  }

  /// Test HTTP proxy configuration
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [PublicTestHttpProxyRequest] publicTestHttpProxyRequest (required):
  Future<Response> publicTestHttpProxyWithHttpInfo(PublicTestHttpProxyRequest publicTestHttpProxyRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/public/test-http-proxy';

    // ignore: prefer_final_locals
    Object? postBody = publicTestHttpProxyRequest;

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

  /// Test HTTP proxy configuration
  ///
  /// Parameters:
  ///
  /// * [PublicTestHttpProxyRequest] publicTestHttpProxyRequest (required):
  Future<PublicTestHttpProxy200Response?> publicTestHttpProxy(PublicTestHttpProxyRequest publicTestHttpProxyRequest,) async {
    final response = await publicTestHttpProxyWithHttpInfo(publicTestHttpProxyRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PublicTestHttpProxy200Response',) as PublicTestHttpProxy200Response;
    
    }
    return null;
  }

  /// Test webhook
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [PublicTestWebhookRequest] publicTestWebhookRequest (required):
  Future<Response> publicTestWebhookWithHttpInfo(PublicTestWebhookRequest publicTestWebhookRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/public/test-webhook';

    // ignore: prefer_final_locals
    Object? postBody = publicTestWebhookRequest;

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

  /// Test webhook
  ///
  /// Parameters:
  ///
  /// * [PublicTestWebhookRequest] publicTestWebhookRequest (required):
  Future<PublicTestWebhook200Response?> publicTestWebhook(PublicTestWebhookRequest publicTestWebhookRequest,) async {
    final response = await publicTestWebhookWithHttpInfo(publicTestWebhookRequest,);
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

  /// Update user config
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> publicVersionWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/public/version';

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

  /// Update user config
  Future<String?> publicVersion() async {
    final response = await publicVersionWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'String',) as String;
    
    }
    return null;
  }
}
