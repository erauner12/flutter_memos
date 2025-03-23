//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class WebhookServiceApi {
  WebhookServiceApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// CreateWebhook creates a new webhook.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [V1CreateWebhookRequest] body (required):
  Future<Response> webhookServiceCreateWebhookWithHttpInfo(V1CreateWebhookRequest body,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/webhooks';

    // ignore: prefer_final_locals
    Object? postBody = body;

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

  /// CreateWebhook creates a new webhook.
  ///
  /// Parameters:
  ///
  /// * [V1CreateWebhookRequest] body (required):
  Future<V1Webhook?> webhookServiceCreateWebhook(V1CreateWebhookRequest body,) async {
    final response = await webhookServiceCreateWebhookWithHttpInfo(body,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'V1Webhook',) as V1Webhook;
    
    }
    return null;
  }

  /// DeleteWebhook deletes a webhook by id.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> webhookServiceDeleteWebhookWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/webhooks/{id}'
      .replaceAll('{id}', id.toString());

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

  /// DeleteWebhook deletes a webhook by id.
  ///
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Object?> webhookServiceDeleteWebhook(int id,) async {
    final response = await webhookServiceDeleteWebhookWithHttpInfo(id,);
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

  /// GetWebhook returns a webhook by id.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> webhookServiceGetWebhookWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/webhooks/{id}'
      .replaceAll('{id}', id.toString());

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

  /// GetWebhook returns a webhook by id.
  ///
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<V1Webhook?> webhookServiceGetWebhook(int id,) async {
    final response = await webhookServiceGetWebhookWithHttpInfo(id,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'V1Webhook',) as V1Webhook;
    
    }
    return null;
  }

  /// ListWebhooks returns a list of webhooks.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] creator:
  ///   The name of the creator.
  Future<Response> webhookServiceListWebhooksWithHttpInfo({ String? creator, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/webhooks';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (creator != null) {
      queryParams.addAll(_queryParams('', 'creator', creator));
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

  /// ListWebhooks returns a list of webhooks.
  ///
  /// Parameters:
  ///
  /// * [String] creator:
  ///   The name of the creator.
  Future<V1ListWebhooksResponse?> webhookServiceListWebhooks({ String? creator, }) async {
    final response = await webhookServiceListWebhooksWithHttpInfo( creator: creator, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'V1ListWebhooksResponse',) as V1ListWebhooksResponse;
    
    }
    return null;
  }

  /// UpdateWebhook updates a webhook.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] webhookPeriodId (required):
  ///
  /// * [WebhookServiceUpdateWebhookRequest] webhook (required):
  Future<Response> webhookServiceUpdateWebhookWithHttpInfo(int webhookPeriodId, WebhookServiceUpdateWebhookRequest webhook,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/webhooks/{webhook.id}'
      .replaceAll('{webhook.id}', webhookPeriodId.toString());

    // ignore: prefer_final_locals
    Object? postBody = webhook;

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

  /// UpdateWebhook updates a webhook.
  ///
  /// Parameters:
  ///
  /// * [int] webhookPeriodId (required):
  ///
  /// * [WebhookServiceUpdateWebhookRequest] webhook (required):
  Future<V1Webhook?> webhookServiceUpdateWebhook(int webhookPeriodId, WebhookServiceUpdateWebhookRequest webhook,) async {
    final response = await webhookServiceUpdateWebhookWithHttpInfo(webhookPeriodId, webhook,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'V1Webhook',) as V1Webhook;
    
    }
    return null;
  }
}
