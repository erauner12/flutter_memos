//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class ConfigApi {
  ConfigApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Get plugin config
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] pluginName (required):
  Future<Response> configGetPluginConfigWithHttpInfo(String pluginName,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/config/getPluginConfig';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'pluginName', pluginName));

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

  /// Get plugin config
  ///
  /// Parameters:
  ///
  /// * [String] pluginName (required):
  Future<Object?> configGetPluginConfig(String pluginName,) async {
    final response = await configGetPluginConfigWithHttpInfo(pluginName,);
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

  /// Query user config list
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> configListWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/config/list';

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

  /// Query user config list
  Future<ConfigList200Response?> configList() async {
    final response = await configListWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ConfigList200Response',) as ConfigList200Response;
    
    }
    return null;
  }

  /// Set plugin config
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [ConfigSetPluginConfigRequest] configSetPluginConfigRequest (required):
  Future<Response> configSetPluginConfigWithHttpInfo(ConfigSetPluginConfigRequest configSetPluginConfigRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/config/setPluginConfig';

    // ignore: prefer_final_locals
    Object? postBody = configSetPluginConfigRequest;

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

  /// Set plugin config
  ///
  /// Parameters:
  ///
  /// * [ConfigSetPluginConfigRequest] configSetPluginConfigRequest (required):
  Future<Object?> configSetPluginConfig(ConfigSetPluginConfigRequest configSetPluginConfigRequest,) async {
    final response = await configSetPluginConfigWithHttpInfo(configSetPluginConfigRequest,);
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

  /// Update user config
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [ConfigUpdateRequest] configUpdateRequest (required):
  Future<Response> configUpdateWithHttpInfo(ConfigUpdateRequest configUpdateRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/config/update';

    // ignore: prefer_final_locals
    Object? postBody = configUpdateRequest;

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

  /// Update user config
  ///
  /// Parameters:
  ///
  /// * [ConfigUpdateRequest] configUpdateRequest (required):
  Future<ConfigUpdate200Response?> configUpdate(ConfigUpdateRequest configUpdateRequest,) async {
    final response = await configUpdateWithHttpInfo(configUpdateRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ConfigUpdate200Response',) as ConfigUpdate200Response;
    
    }
    return null;
  }
}
