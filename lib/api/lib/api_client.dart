//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ApiClient {
  ApiClient({this.basePath = 'http://localhost', this.authentication,});

  final String basePath;
  final Authentication? authentication;

  var _client = Client();
  final _defaultHeaderMap = <String, String>{};

  /// Returns the current HTTP [Client] instance to use in this class.
  ///
  /// The return value is guaranteed to never be null.
  Client get client => _client;

  /// Requests to use a new HTTP [Client] in this class.
  set client(Client newClient) {
    _client = newClient;
  }

  Map<String, String> get defaultHeaderMap => _defaultHeaderMap;

  void addDefaultHeader(String key, String value) {
     _defaultHeaderMap[key] = value;
  }

  // We don't use a Map<String, String> for queryParams.
  // If collectionFormat is 'multi', a key might appear multiple times.
  Future<Response> invokeAPI(
    String path,
    String method,
    List<QueryParam> queryParams,
    Object? body,
    Map<String, String> headerParams,
    Map<String, String> formParams,
    String? contentType,
  ) async {
    await authentication?.applyToParams(queryParams, headerParams);

    headerParams.addAll(_defaultHeaderMap);
    if (contentType != null) {
      headerParams['Content-Type'] = contentType;
    }

    final urlEncodedQueryParams = queryParams.map((param) => '$param');
    final queryString = urlEncodedQueryParams.isNotEmpty ? '?${urlEncodedQueryParams.join('&')}' : '';
    final uri = Uri.parse('$basePath$path$queryString');

    try {
      // Special case for uploading a single file which isn't a 'multipart/form-data'.
      if (
        body is MultipartFile && (contentType == null ||
        !contentType.toLowerCase().startsWith('multipart/form-data'))
      ) {
        final request = StreamedRequest(method, uri);
        request.headers.addAll(headerParams);
        request.contentLength = body.length;
        body.finalize().listen(
          request.sink.add,
          onDone: request.sink.close,
          // ignore: avoid_types_on_closure_parameters
          onError: (Object error, StackTrace trace) => request.sink.close(),
          cancelOnError: true,
        );
        final response = await _client.send(request);
        return Response.fromStream(response);
      }

      if (body is MultipartRequest) {
        final request = MultipartRequest(method, uri);
        request.fields.addAll(body.fields);
        request.files.addAll(body.files);
        request.headers.addAll(body.headers);
        request.headers.addAll(headerParams);
        final response = await _client.send(request);
        return Response.fromStream(response);
      }

      final msgBody = contentType == 'application/x-www-form-urlencoded'
        ? formParams
        : await serializeAsync(body);
      final nullableHeaderParams = headerParams.isEmpty ? null : headerParams;

      switch(method) {
        case 'POST': return await _client.post(uri, headers: nullableHeaderParams, body: msgBody,);
        case 'PUT': return await _client.put(uri, headers: nullableHeaderParams, body: msgBody,);
        case 'DELETE': return await _client.delete(uri, headers: nullableHeaderParams, body: msgBody,);
        case 'PATCH': return await _client.patch(uri, headers: nullableHeaderParams, body: msgBody,);
        case 'HEAD': return await _client.head(uri, headers: nullableHeaderParams,);
        case 'GET': return await _client.get(uri, headers: nullableHeaderParams,);
      }
    } on SocketException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'Socket operation failed: $method $path',
        error,
        trace,
      );
    } on TlsException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'TLS/SSL communication failed: $method $path',
        error,
        trace,
      );
    } on IOException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'I/O operation failed: $method $path',
        error,
        trace,
      );
    } on ClientException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'HTTP connection failed: $method $path',
        error,
        trace,
      );
    } on Exception catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'Exception occurred: $method $path',
        error,
        trace,
      );
    }

    throw ApiException(
      HttpStatus.badRequest,
      'Invalid HTTP operation: $method $path',
    );
  }

  Future<dynamic> deserializeAsync(String value, String targetType, {bool growable = false,}) async =>
    // ignore: deprecated_member_use_from_same_package
    deserialize(value, targetType, growable: growable);

  @Deprecated('Scheduled for removal in OpenAPI Generator 6.x. Use deserializeAsync() instead.')
  dynamic deserialize(String value, String targetType, {bool growable = false,}) {
    // Remove all spaces. Necessary for regular expressions as well.
    targetType = targetType.replaceAll(' ', ''); // ignore: parameter_assignments

    // If the expected target type is String, nothing to do...
    return targetType == 'String'
      ? value
      : fromJson(json.decode(value), targetType, growable: growable);
  }

  // ignore: deprecated_member_use_from_same_package
  Future<String> serializeAsync(Object? value) async => serialize(value);

  @Deprecated('Scheduled for removal in OpenAPI Generator 6.x. Use serializeAsync() instead.')
  String serialize(Object? value) => value == null ? '' : json.encode(value);

  /// Returns a native instance of an OpenAPI class matching the [specified type][targetType].
  static dynamic fromJson(dynamic value, String targetType, {bool growable = false,}) {
    try {
      switch (targetType) {
        case 'String':
          return value is String ? value : value.toString();
        case 'int':
          return value is int ? value : int.parse('$value');
        case 'double':
          return value is double ? value : double.parse('$value');
        case 'bool':
          if (value is bool) {
            return value;
          }
          final valueString = '$value'.toLowerCase();
          return valueString == 'true' || valueString == '1';
        case 'DateTime':
          return value is DateTime ? value : DateTime.tryParse(value);
        case 'ApiHttpBody':
          return ApiHttpBody.fromJson(value);
        case 'Apiv1ActivityMemoCommentPayload':
          return Apiv1ActivityMemoCommentPayload.fromJson(value);
        case 'Apiv1ActivityPayload':
          return Apiv1ActivityPayload.fromJson(value);
        case 'Apiv1ActivityVersionUpdatePayload':
          return Apiv1ActivityVersionUpdatePayload.fromJson(value);
        case 'Apiv1FieldMapping':
          return Apiv1FieldMapping.fromJson(value);
        case 'Apiv1IdentityProvider':
          return Apiv1IdentityProvider.fromJson(value);
        case 'Apiv1IdentityProviderConfig':
          return Apiv1IdentityProviderConfig.fromJson(value);
        case 'Apiv1IdentityProviderType':
          return Apiv1IdentityProviderTypeTypeTransformer().decode(value);
        case 'Apiv1Location':
          return Apiv1Location.fromJson(value);
        case 'Apiv1Memo':
          return Apiv1Memo.fromJson(value);
        case 'Apiv1OAuth2Config':
          return Apiv1OAuth2Config.fromJson(value);
        case 'Apiv1Shortcut':
          return Apiv1Shortcut.fromJson(value);
        case 'Apiv1UserSetting':
          return Apiv1UserSetting.fromJson(value);
        case 'Apiv1WorkspaceCustomProfile':
          return Apiv1WorkspaceCustomProfile.fromJson(value);
        case 'Apiv1WorkspaceGeneralSetting':
          return Apiv1WorkspaceGeneralSetting.fromJson(value);
        case 'Apiv1WorkspaceMemoRelatedSetting':
          return Apiv1WorkspaceMemoRelatedSetting.fromJson(value);
        case 'Apiv1WorkspaceSetting':
          return Apiv1WorkspaceSetting.fromJson(value);
        case 'Apiv1WorkspaceStorageSetting':
          return Apiv1WorkspaceStorageSetting.fromJson(value);
        case 'Apiv1WorkspaceStorageSettingStorageType':
          return Apiv1WorkspaceStorageSettingStorageTypeTypeTransformer().decode(value);
        case 'GooglerpcStatus':
          return GooglerpcStatus.fromJson(value);
        case 'InboxServiceUpdateInboxRequest':
          return InboxServiceUpdateInboxRequest.fromJson(value);
        case 'ListNodeKind':
          return ListNodeKindTypeTransformer().decode(value);
        case 'MemoServiceRenameMemoTagBody':
          return MemoServiceRenameMemoTagBody.fromJson(value);
        case 'MemoServiceSetMemoRelationsBody':
          return MemoServiceSetMemoRelationsBody.fromJson(value);
        case 'MemoServiceSetMemoResourcesBody':
          return MemoServiceSetMemoResourcesBody.fromJson(value);
        case 'MemoServiceUpsertMemoReactionBody':
          return MemoServiceUpsertMemoReactionBody.fromJson(value);
        case 'ProtobufAny':
          return ProtobufAny.fromJson(value);
        case 'ResourceServiceUpdateResourceRequest':
          return ResourceServiceUpdateResourceRequest.fromJson(value);
        case 'SettingIsTheSettingToUpdate':
          return SettingIsTheSettingToUpdate.fromJson(value);
        case 'TableNodeRow':
          return TableNodeRow.fromJson(value);
        case 'TheIdentityProviderToUpdate':
          return TheIdentityProviderToUpdate.fromJson(value);
        case 'TheMemoToUpdateTheNameFieldIsRequired':
          return TheMemoToUpdateTheNameFieldIsRequired.fromJson(value);
        case 'UserRole':
          return UserRoleTypeTransformer().decode(value);
        case 'UserServiceCreateUserAccessTokenBody':
          return UserServiceCreateUserAccessTokenBody.fromJson(value);
        case 'UserServiceUpdateShortcutRequest':
          return UserServiceUpdateShortcutRequest.fromJson(value);
        case 'UserServiceUpdateUserRequest':
          return UserServiceUpdateUserRequest.fromJson(value);
        case 'UserServiceUpdateUserSettingRequest':
          return UserServiceUpdateUserSettingRequest.fromJson(value);
        case 'UserStatsMemoTypeStats':
          return UserStatsMemoTypeStats.fromJson(value);
        case 'V1Activity':
          return V1Activity.fromJson(value);
        case 'V1AutoLinkNode':
          return V1AutoLinkNode.fromJson(value);
        case 'V1BlockquoteNode':
          return V1BlockquoteNode.fromJson(value);
        case 'V1BoldItalicNode':
          return V1BoldItalicNode.fromJson(value);
        case 'V1BoldNode':
          return V1BoldNode.fromJson(value);
        case 'V1CodeBlockNode':
          return V1CodeBlockNode.fromJson(value);
        case 'V1CodeNode':
          return V1CodeNode.fromJson(value);
        case 'V1CreateWebhookRequest':
          return V1CreateWebhookRequest.fromJson(value);
        case 'V1Direction':
          return V1DirectionTypeTransformer().decode(value);
        case 'V1EmbeddedContentNode':
          return V1EmbeddedContentNode.fromJson(value);
        case 'V1EscapingCharacterNode':
          return V1EscapingCharacterNode.fromJson(value);
        case 'V1HTMLElementNode':
          return V1HTMLElementNode.fromJson(value);
        case 'V1HeadingNode':
          return V1HeadingNode.fromJson(value);
        case 'V1HighlightNode':
          return V1HighlightNode.fromJson(value);
        case 'V1HorizontalRuleNode':
          return V1HorizontalRuleNode.fromJson(value);
        case 'V1ImageNode':
          return V1ImageNode.fromJson(value);
        case 'V1Inbox':
          return V1Inbox.fromJson(value);
        case 'V1InboxStatus':
          return V1InboxStatusTypeTransformer().decode(value);
        case 'V1InboxType':
          return V1InboxTypeTypeTransformer().decode(value);
        case 'V1ItalicNode':
          return V1ItalicNode.fromJson(value);
        case 'V1LinkMetadata':
          return V1LinkMetadata.fromJson(value);
        case 'V1LinkNode':
          return V1LinkNode.fromJson(value);
        case 'V1ListAllUserStatsResponse':
          return V1ListAllUserStatsResponse.fromJson(value);
        case 'V1ListIdentityProvidersResponse':
          return V1ListIdentityProvidersResponse.fromJson(value);
        case 'V1ListInboxesResponse':
          return V1ListInboxesResponse.fromJson(value);
        case 'V1ListMemoCommentsResponse':
          return V1ListMemoCommentsResponse.fromJson(value);
        case 'V1ListMemoReactionsResponse':
          return V1ListMemoReactionsResponse.fromJson(value);
        case 'V1ListMemoRelationsResponse':
          return V1ListMemoRelationsResponse.fromJson(value);
        case 'V1ListMemoResourcesResponse':
          return V1ListMemoResourcesResponse.fromJson(value);
        case 'V1ListMemosResponse':
          return V1ListMemosResponse.fromJson(value);
        case 'V1ListNode':
          return V1ListNode.fromJson(value);
        case 'V1ListResourcesResponse':
          return V1ListResourcesResponse.fromJson(value);
        case 'V1ListShortcutsResponse':
          return V1ListShortcutsResponse.fromJson(value);
        case 'V1ListUserAccessTokensResponse':
          return V1ListUserAccessTokensResponse.fromJson(value);
        case 'V1ListUsersResponse':
          return V1ListUsersResponse.fromJson(value);
        case 'V1ListWebhooksResponse':
          return V1ListWebhooksResponse.fromJson(value);
        case 'V1MathBlockNode':
          return V1MathBlockNode.fromJson(value);
        case 'V1MathNode':
          return V1MathNode.fromJson(value);
        case 'V1MemoProperty':
          return V1MemoProperty.fromJson(value);
        case 'V1MemoRelation':
          return V1MemoRelation.fromJson(value);
        case 'V1MemoRelationMemo':
          return V1MemoRelationMemo.fromJson(value);
        case 'V1MemoRelationType':
          return V1MemoRelationTypeTypeTransformer().decode(value);
        case 'V1Node':
          return V1Node.fromJson(value);
        case 'V1NodeType':
          return V1NodeTypeTypeTransformer().decode(value);
        case 'V1OrderedListItemNode':
          return V1OrderedListItemNode.fromJson(value);
        case 'V1ParagraphNode':
          return V1ParagraphNode.fromJson(value);
        case 'V1ParseMarkdownRequest':
          return V1ParseMarkdownRequest.fromJson(value);
        case 'V1ParseMarkdownResponse':
          return V1ParseMarkdownResponse.fromJson(value);
        case 'V1Reaction':
          return V1Reaction.fromJson(value);
        case 'V1ReferencedContentNode':
          return V1ReferencedContentNode.fromJson(value);
        case 'V1Resource':
          return V1Resource.fromJson(value);
        case 'V1RestoreMarkdownNodesRequest':
          return V1RestoreMarkdownNodesRequest.fromJson(value);
        case 'V1RestoreMarkdownNodesResponse':
          return V1RestoreMarkdownNodesResponse.fromJson(value);
        case 'V1SpoilerNode':
          return V1SpoilerNode.fromJson(value);
        case 'V1State':
          return V1StateTypeTransformer().decode(value);
        case 'V1StrikethroughNode':
          return V1StrikethroughNode.fromJson(value);
        case 'V1StringifyMarkdownNodesRequest':
          return V1StringifyMarkdownNodesRequest.fromJson(value);
        case 'V1StringifyMarkdownNodesResponse':
          return V1StringifyMarkdownNodesResponse.fromJson(value);
        case 'V1SubscriptNode':
          return V1SubscriptNode.fromJson(value);
        case 'V1SuperscriptNode':
          return V1SuperscriptNode.fromJson(value);
        case 'V1TableNode':
          return V1TableNode.fromJson(value);
        case 'V1TagNode':
          return V1TagNode.fromJson(value);
        case 'V1TaskListItemNode':
          return V1TaskListItemNode.fromJson(value);
        case 'V1TextNode':
          return V1TextNode.fromJson(value);
        case 'V1UnorderedListItemNode':
          return V1UnorderedListItemNode.fromJson(value);
        case 'V1User':
          return V1User.fromJson(value);
        case 'V1UserAccessToken':
          return V1UserAccessToken.fromJson(value);
        case 'V1UserStats':
          return V1UserStats.fromJson(value);
        case 'V1Visibility':
          return V1VisibilityTypeTransformer().decode(value);
        case 'V1Webhook':
          return V1Webhook.fromJson(value);
        case 'V1WorkspaceProfile':
          return V1WorkspaceProfile.fromJson(value);
        case 'WebhookServiceUpdateWebhookRequest':
          return WebhookServiceUpdateWebhookRequest.fromJson(value);
        case 'WorkspaceStorageSettingS3Config':
          return WorkspaceStorageSettingS3Config.fromJson(value);
        default:
          dynamic match;
          if (value is List && (match = _regList.firstMatch(targetType)?.group(1)) != null) {
            return value
              .map<dynamic>((dynamic v) => fromJson(v, match, growable: growable,))
              .toList(growable: growable);
          }
          if (value is Set && (match = _regSet.firstMatch(targetType)?.group(1)) != null) {
            return value
              .map<dynamic>((dynamic v) => fromJson(v, match, growable: growable,))
              .toSet();
          }
          if (value is Map && (match = _regMap.firstMatch(targetType)?.group(1)) != null) {
            return Map<String, dynamic>.fromIterables(
              value.keys.cast<String>(),
              value.values.map<dynamic>((dynamic v) => fromJson(v, match, growable: growable,)),
            );
          }
      }
    } on Exception catch (error, trace) {
      throw ApiException.withInner(HttpStatus.internalServerError, 'Exception during deserialization.', error, trace,);
    }
    throw ApiException(HttpStatus.internalServerError, 'Could not find a suitable class for deserialization',);
  }
}

/// Primarily intended for use in an isolate.
class DeserializationMessage {
  const DeserializationMessage({
    required this.json,
    required this.targetType,
    this.growable = false,
  });

  /// The JSON value to deserialize.
  final String json;

  /// Target type to deserialize to.
  final String targetType;

  /// Whether to make deserialized lists or maps growable.
  final bool growable;
}

/// Primarily intended for use in an isolate.
Future<dynamic> decodeAsync(DeserializationMessage message) async {
  // Remove all spaces. Necessary for regular expressions as well.
  final targetType = message.targetType.replaceAll(' ', '');

  // If the expected target type is String, nothing to do...
  return targetType == 'String'
    ? message.json
    : json.decode(message.json);
}

/// Primarily intended for use in an isolate.
Future<dynamic> deserializeAsync(DeserializationMessage message) async {
  // Remove all spaces. Necessary for regular expressions as well.
  final targetType = message.targetType.replaceAll(' ', '');

  // If the expected target type is String, nothing to do...
  return targetType == 'String'
    ? message.json
    : ApiClient.fromJson(
        json.decode(message.json),
        targetType,
        growable: message.growable,
      );
}

/// Primarily intended for use in an isolate.
Future<String> serializeAsync(Object? value) async => value == null ? '' : json.encode(value);
