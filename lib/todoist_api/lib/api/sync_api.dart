//
// PLACEHOLDER FILE - DO NOT MODIFY MANUALLY IF USING CODE GENERATION!
// This file simulates the existence of a SyncApi class generated from an OpenAPI spec.
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

// Placeholder class simulating the generated Sync API endpoints
class SyncApi {
  SyncApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Placeholder for fetching full data via Sync API.
  /// Corresponds to an endpoint like GET /sync/v9/projects/get_data
  /// The actual parameters and return type depend on the real API spec.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getDataV2WithHttpInfo({ String? projectId /* Example param */ }) async {
    // ignore: prefer_const_declarations
    final path = r'/sync/v9/projects/get_data'; // Example path, adjust as needed

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (projectId != null) {
      queryParams.addAll(_queryParams('', 'project_id', projectId)); // Example query param
    }

    const contentTypes = <String>[];

    // This would typically be a GET request based on the name
    return apiClient.invokeAPI(
      path,
      'GET', // Assuming GET, adjust if it's POST
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Placeholder for fetching full data via Sync API.
  /// Returns a [GetDataV2Response] object.
  Future<GetDataV2Response?> getDataV2({ String? projectId /* Example param */ }) async {
    final response = await getDataV2WithHttpInfo( projectId: projectId );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      // Ensure the type matches the actual generated model name
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'GetDataV2Response',) as GetDataV2Response?;
    }
    return null;
  }


  /// Placeholder for fetching activity events via Sync API.
  /// Corresponds to an endpoint like GET /sync/v9/activity/get
  /// The actual parameters and return type depend on the real API spec.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getActivityEventsWithHttpInfo({
      int? limit,
      String? cursor,
      String? since,
      String? until,
      String? objectType,
      String? eventType,
      /* Add other potential filters based on API spec */
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/sync/v9/activity/get'; // Example path, adjust as needed

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    // Add query parameters based on the actual API spec
    if (limit != null) queryParams.addAll(_queryParams('', 'limit', limit));
    if (cursor != null) queryParams.addAll(_queryParams('', 'cursor', cursor));
    if (since != null) queryParams.addAll(_queryParams('', 'since', since));
    if (until != null) queryParams.addAll(_queryParams('', 'until', until));
    if (objectType != null) queryParams.addAll(_queryParams('', 'object_type', objectType));
    if (eventType != null) queryParams.addAll(_queryParams('', 'event_type', eventType));

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET', // Assuming GET
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Placeholder for fetching activity events via Sync API.
  /// Returns a [PaginatedListActivityEvents] object (or similar based on spec).
  Future<PaginatedListActivityEvents?> getActivityEvents({
      int? limit,
      String? cursor,
      String? since,
      String? until,
      String? objectType,
      String? eventType,
  }) async {
    final response = await getActivityEventsWithHttpInfo(
        limit: limit, cursor: cursor, since: since, until: until, objectType: objectType, eventType: eventType
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      // Ensure the type matches the actual generated model name for pagination
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PaginatedListActivityEvents',) as PaginatedListActivityEvents?;
    }
    return null;
  }

  // Add other Sync API methods here as needed based on the specification...

}

// Helper function (should ideally be part of ApiClient or ApiHelper in generated code)
Future<Uint8List> _decodeBodyBytes(Response response) async => response.bodyBytes;
List<QueryParam> _queryParams(String collectionFormat, String name, dynamic value) =>
    ApiHelper.convertParametersForCollectionFormat(collectionFormat, name, value);

```
