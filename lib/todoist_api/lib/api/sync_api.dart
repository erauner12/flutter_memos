//
// PLACEHOLDER FILE - DO NOT MODIFY MANUALLY IF USING CODE GENERATION!
// This file simulates the existence of a SyncApi class generated from an OpenAPI spec,
// adapted to match the documented behavior of the main /sync endpoint.
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

// Placeholder class simulating the generated Sync API endpoint
class SyncApi {
  SyncApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs a sync operation.
  ///
  /// Retrieves user resources based on the provided sync token and resource types.
  /// Use syncToken = '*' for the initial full sync. Subsequent calls should use
  /// the syncToken received from the previous response for incremental updates.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] syncToken (required):
  ///   Use '*' for initial sync, or the token from the last sync response.
  ///
  /// * [List<String>] resourceTypes (required):
  ///   JSON array (as string) of resource types to sync (e.g., '["all"]', '["items", "projects"]').
  Future<Response> syncWithHttpInfo({
    required String syncToken,
    required List<String> resourceTypes,
    // Add other potential Sync API parameters if needed (e.g., commands for writing data)
  }) async {
    // ignore: prefer_const_declarations
    // Assuming the endpoint path is /sync relative to the base sync URL
    // The documentation example uses /api/v1/sync, but our base is /sync/v9.
    // Adjust if the actual endpoint is different (e.g., just /sync or /sync/v9/sync)
    final path =
        r'/sync'; // Or potentially '/sync/v9/sync' - needs verification

    // ignore: prefer_final_locals
    Object?
        postBody; // Body is sent via formParams for application/x-www-form-urlencoded

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    // Add required form parameters
    formParams[r'sync_token'] = parameterToString(syncToken);
    // Encode the list of strings as a JSON array string
    formParams[r'resource_types'] = jsonEncode(resourceTypes);

    // Add other form parameters if implementing write commands

    // Set the Content-Type for form data
    const contentTypes = <String>['application/x-www-form-urlencoded'];


    return apiClient.invokeAPI(
      path,
      'POST', // Sync API uses POST
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.first, // Specify content type
    );
  }

  /// Performs a sync operation.
  ///
  /// Retrieves user resources based on the provided sync token and resource types.
  /// Use syncToken = '*' for the initial full sync. Subsequent calls should use
  /// the syncToken received from the previous response for incremental updates.
  /// Returns a [SyncResponse] object.
  ///
  /// Parameters:
  ///
  /// * [String] syncToken (required):
  ///   Use '*' for initial sync, or the token from the last sync response.
  ///
  /// * [List<String>] resourceTypes (required):
  ///   List of resource types to sync (e.g., ['all'], ['items', 'projects']).
  Future<SyncResponse?> sync({
    required String syncToken,
    required List<String> resourceTypes,
  }) async {
    final response = await syncWithHttpInfo(
      syncToken: syncToken,
      resourceTypes: resourceTypes,
    );

    final responseBodyBytes = await _decodeBodyBytes(response);
    final responseBodyString =
        utf8.decode(responseBodyBytes as List<int>); // Decode bytes to string

    if (response.statusCode >= HttpStatus.badRequest) {
      // Pass the decoded string to ApiException
      throw ApiException(response.statusCode, responseBodyString);
    }

    if (responseBodyString.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      // Pass the decoded string to deserializeAsync
      return await apiClient.deserializeAsync(
        responseBodyString,
        'SyncResponse',
      ) as SyncResponse?;
    }
    return null;
  }
}

// Basic ApiHelper implementation (should be part of generated code)
class ApiHelper {
  static String parameterToString(dynamic value) {
    return value.toString();
  }
}
