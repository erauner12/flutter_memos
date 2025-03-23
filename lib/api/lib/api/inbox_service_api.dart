//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class InboxServiceApi {
  InboxServiceApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// DeleteInbox deletes an inbox.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] name2 (required):
  ///   The name of the inbox to delete.
  Future<Response> inboxServiceDeleteInboxWithHttpInfo(String name2,) async {
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
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// DeleteInbox deletes an inbox.
  ///
  /// Parameters:
  ///
  /// * [String] name2 (required):
  ///   The name of the inbox to delete.
  Future<Object?> inboxServiceDeleteInbox(String name2,) async {
    final response = await inboxServiceDeleteInboxWithHttpInfo(name2,);
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

  /// ListInboxes lists inboxes for a user.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] user:
  ///   Format: users/{user}
  ///
  /// * [int] pageSize:
  ///   The maximum number of inbox to return.
  ///
  /// * [String] pageToken:
  ///   Provide this to retrieve the subsequent page.
  Future<Response> inboxServiceListInboxesWithHttpInfo({ String? user, int? pageSize, String? pageToken, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/inboxes';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (user != null) {
      queryParams.addAll(_queryParams('', 'user', user));
    }
    if (pageSize != null) {
      queryParams.addAll(_queryParams('', 'pageSize', pageSize));
    }
    if (pageToken != null) {
      queryParams.addAll(_queryParams('', 'pageToken', pageToken));
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

  /// ListInboxes lists inboxes for a user.
  ///
  /// Parameters:
  ///
  /// * [String] user:
  ///   Format: users/{user}
  ///
  /// * [int] pageSize:
  ///   The maximum number of inbox to return.
  ///
  /// * [String] pageToken:
  ///   Provide this to retrieve the subsequent page.
  Future<V1ListInboxesResponse?> inboxServiceListInboxes({ String? user, int? pageSize, String? pageToken, }) async {
    final response = await inboxServiceListInboxesWithHttpInfo( user: user, pageSize: pageSize, pageToken: pageToken, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'V1ListInboxesResponse',) as V1ListInboxesResponse;
    
    }
    return null;
  }

  /// UpdateInbox updates an inbox.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] inboxPeriodName (required):
  ///   The name of the inbox. Format: inboxes/{id}, id is the system generated auto-incremented id.
  ///
  /// * [InboxServiceUpdateInboxRequest] inbox (required):
  Future<Response> inboxServiceUpdateInboxWithHttpInfo(String inboxPeriodName, InboxServiceUpdateInboxRequest inbox,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/{inbox.name}'
      .replaceAll('{inbox.name}', inboxPeriodName);

    // ignore: prefer_final_locals
    Object? postBody = inbox;

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

  /// UpdateInbox updates an inbox.
  ///
  /// Parameters:
  ///
  /// * [String] inboxPeriodName (required):
  ///   The name of the inbox. Format: inboxes/{id}, id is the system generated auto-incremented id.
  ///
  /// * [InboxServiceUpdateInboxRequest] inbox (required):
  Future<V1Inbox?> inboxServiceUpdateInbox(String inboxPeriodName, InboxServiceUpdateInboxRequest inbox,) async {
    final response = await inboxServiceUpdateInboxWithHttpInfo(inboxPeriodName, inbox,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'V1Inbox',) as V1Inbox;
    
    }
    return null;
  }
}
