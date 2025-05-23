//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class AnalyticsApi {
  AnalyticsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Query daily note count
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> analyticsDailyNoteCountWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/v1/analytics/daily-note-count';

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

  /// Query daily note count
  Future<List<AnalyticsDailyNoteCount200ResponseInner>?> analyticsDailyNoteCount() async {
    final response = await analyticsDailyNoteCountWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<AnalyticsDailyNoteCount200ResponseInner>') as List)
        .cast<AnalyticsDailyNoteCount200ResponseInner>()
        .toList(growable: false);

    }
    return null;
  }

  /// Query monthly statistics
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [AnalyticsMonthlyStatsRequest] analyticsMonthlyStatsRequest (required):
  Future<Response> analyticsMonthlyStatsWithHttpInfo(AnalyticsMonthlyStatsRequest analyticsMonthlyStatsRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/analytics/monthly-stats';

    // ignore: prefer_final_locals
    Object? postBody = analyticsMonthlyStatsRequest;

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

  /// Query monthly statistics
  ///
  /// Parameters:
  ///
  /// * [AnalyticsMonthlyStatsRequest] analyticsMonthlyStatsRequest (required):
  Future<AnalyticsMonthlyStats200Response?> analyticsMonthlyStats(AnalyticsMonthlyStatsRequest analyticsMonthlyStatsRequest,) async {
    final response = await analyticsMonthlyStatsWithHttpInfo(analyticsMonthlyStatsRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AnalyticsMonthlyStats200Response',) as AnalyticsMonthlyStats200Response;
    
    }
    return null;
  }
}
