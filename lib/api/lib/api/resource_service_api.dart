//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class ResourceServiceApi {
  ResourceServiceApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// CreateResource creates a new resource.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [V1Resource] resource (required):
  Future<Response> resourceServiceCreateResourceWithHttpInfo(V1Resource resource,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/resources';

    // ignore: prefer_final_locals
    Object? postBody = resource;

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

  /// CreateResource creates a new resource.
  ///
  /// Parameters:
  ///
  /// * [V1Resource] resource (required):
  Future<V1Resource?> resourceServiceCreateResource(V1Resource resource,) async {
    final response = await resourceServiceCreateResourceWithHttpInfo(resource,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'V1Resource',) as V1Resource;
    
    }
    return null;
  }

  /// DeleteResource deletes a resource by name.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] name3 (required):
  ///   The name of the resource.
  Future<Response> resourceServiceDeleteResourceWithHttpInfo(String name3,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{name_3}'
      .replaceAll('{name_3}', name3);

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

  /// DeleteResource deletes a resource by name.
  ///
  /// Parameters:
  ///
  /// * [String] name3 (required):
  ///   The name of the resource.
  Future<Object?> resourceServiceDeleteResource(String name3,) async {
    final response = await resourceServiceDeleteResourceWithHttpInfo(name3,);
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

  /// GetResource returns a resource by name.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] name3 (required):
  ///   The name of the resource.
  Future<Response> resourceServiceGetResourceWithHttpInfo(String name3,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{name_3}'
      .replaceAll('{name_3}', name3);

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

  /// GetResource returns a resource by name.
  ///
  /// Parameters:
  ///
  /// * [String] name3 (required):
  ///   The name of the resource.
  Future<V1Resource?> resourceServiceGetResource(String name3,) async {
    final response = await resourceServiceGetResourceWithHttpInfo(name3,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'V1Resource',) as V1Resource;
    
    }
    return null;
  }

  /// GetResourceBinary returns a resource binary by name.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The name of the resource.
  ///
  /// * [String] filename (required):
  ///   The filename of the resource. Mainly used for downloading.
  ///
  /// * [bool] thumbnail:
  ///   A flag indicating if the thumbnail version of the resource should be returned
  Future<Response> resourceServiceGetResourceBinaryWithHttpInfo(String name, String filename, { bool? thumbnail, }) async {
    // ignore: prefer_const_declarations
    final path = r'/file/{name}/{filename}'
      .replaceAll('{name}', name)
      .replaceAll('{filename}', filename);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (thumbnail != null) {
      queryParams.addAll(_queryParams('', 'thumbnail', thumbnail));
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

  /// GetResourceBinary returns a resource binary by name.
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The name of the resource.
  ///
  /// * [String] filename (required):
  ///   The filename of the resource. Mainly used for downloading.
  ///
  /// * [bool] thumbnail:
  ///   A flag indicating if the thumbnail version of the resource should be returned
  Future<ApiHttpBody?> resourceServiceGetResourceBinary(String name, String filename, { bool? thumbnail, }) async {
    final response = await resourceServiceGetResourceBinaryWithHttpInfo(name, filename,  thumbnail: thumbnail, );
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

  /// ListResources lists all resources.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> resourceServiceListResourcesWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/resources';

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

  /// ListResources lists all resources.
  Future<V1ListResourcesResponse?> resourceServiceListResources() async {
    final response = await resourceServiceListResourcesWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'V1ListResourcesResponse',) as V1ListResourcesResponse;
    
    }
    return null;
  }

  /// UpdateResource updates a resource.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] resourcePeriodName (required):
  ///   The name of the resource. Format: resources/{resource}, resource is the user defined if or uuid.
  ///
  /// * [ResourceServiceUpdateResourceRequest] resource (required):
  Future<Response> resourceServiceUpdateResourceWithHttpInfo(String resourcePeriodName, ResourceServiceUpdateResourceRequest resource,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{resource.name}'
      .replaceAll('{resource.name}', resourcePeriodName);

    // ignore: prefer_final_locals
    Object? postBody = resource;

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

  /// UpdateResource updates a resource.
  ///
  /// Parameters:
  ///
  /// * [String] resourcePeriodName (required):
  ///   The name of the resource. Format: resources/{resource}, resource is the user defined if or uuid.
  ///
  /// * [ResourceServiceUpdateResourceRequest] resource (required):
  Future<V1Resource?> resourceServiceUpdateResource(String resourcePeriodName, ResourceServiceUpdateResourceRequest resource,) async {
    final response = await resourceServiceUpdateResourceWithHttpInfo(resourcePeriodName, resource,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'V1Resource',) as V1Resource;
    
    }
    return null;
  }
}
