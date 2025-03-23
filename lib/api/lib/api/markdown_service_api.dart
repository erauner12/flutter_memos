//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class MarkdownServiceApi {
  MarkdownServiceApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// GetLinkMetadata returns metadata for a given link.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] link:
  Future<Response> markdownServiceGetLinkMetadataWithHttpInfo({ String? link, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/markdown/link:metadata';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (link != null) {
      queryParams.addAll(_queryParams('', 'link', link));
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

  /// GetLinkMetadata returns metadata for a given link.
  ///
  /// Parameters:
  ///
  /// * [String] link:
  Future<V1LinkMetadata?> markdownServiceGetLinkMetadata({ String? link, }) async {
    final response = await markdownServiceGetLinkMetadataWithHttpInfo( link: link, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'V1LinkMetadata',) as V1LinkMetadata;
    
    }
    return null;
  }

  /// ParseMarkdown parses the given markdown content and returns a list of nodes.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [V1ParseMarkdownRequest] body (required):
  Future<Response> markdownServiceParseMarkdownWithHttpInfo(V1ParseMarkdownRequest body,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/markdown:parse';

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

  /// ParseMarkdown parses the given markdown content and returns a list of nodes.
  ///
  /// Parameters:
  ///
  /// * [V1ParseMarkdownRequest] body (required):
  Future<V1ParseMarkdownResponse?> markdownServiceParseMarkdown(V1ParseMarkdownRequest body,) async {
    final response = await markdownServiceParseMarkdownWithHttpInfo(body,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'V1ParseMarkdownResponse',) as V1ParseMarkdownResponse;
    
    }
    return null;
  }

  /// RestoreMarkdownNodes restores the given nodes to markdown content.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [V1RestoreMarkdownNodesRequest] body (required):
  Future<Response> markdownServiceRestoreMarkdownNodesWithHttpInfo(V1RestoreMarkdownNodesRequest body,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/markdown/node:restore';

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

  /// RestoreMarkdownNodes restores the given nodes to markdown content.
  ///
  /// Parameters:
  ///
  /// * [V1RestoreMarkdownNodesRequest] body (required):
  Future<V1RestoreMarkdownNodesResponse?> markdownServiceRestoreMarkdownNodes(V1RestoreMarkdownNodesRequest body,) async {
    final response = await markdownServiceRestoreMarkdownNodesWithHttpInfo(body,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'V1RestoreMarkdownNodesResponse',) as V1RestoreMarkdownNodesResponse;
    
    }
    return null;
  }

  /// StringifyMarkdownNodes stringify the given nodes to plain text content.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [V1StringifyMarkdownNodesRequest] body (required):
  Future<Response> markdownServiceStringifyMarkdownNodesWithHttpInfo(V1StringifyMarkdownNodesRequest body,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/markdown/node:stringify';

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

  /// StringifyMarkdownNodes stringify the given nodes to plain text content.
  ///
  /// Parameters:
  ///
  /// * [V1StringifyMarkdownNodesRequest] body (required):
  Future<V1StringifyMarkdownNodesResponse?> markdownServiceStringifyMarkdownNodes(V1StringifyMarkdownNodesRequest body,) async {
    final response = await markdownServiceStringifyMarkdownNodesWithHttpInfo(body,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'V1StringifyMarkdownNodesResponse',) as V1StringifyMarkdownNodesResponse;
    
    }
    return null;
  }
}
