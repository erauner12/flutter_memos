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
  ApiClient({this.basePath = '/api', this.authentication,});

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
        case 'AnalyticsDailyNoteCount200ResponseInner':
          return AnalyticsDailyNoteCount200ResponseInner.fromJson(value);
        case 'AnalyticsMonthlyStats200Response':
          return AnalyticsMonthlyStats200Response.fromJson(value);
        case 'AnalyticsMonthlyStats200ResponseTagStatsInner':
          return AnalyticsMonthlyStats200ResponseTagStatsInner.fromJson(value);
        case 'AnalyticsMonthlyStatsRequest':
          return AnalyticsMonthlyStatsRequest.fromJson(value);
        case 'CommentsCreateRequest':
          return CommentsCreateRequest.fromJson(value);
        case 'CommentsDelete200Response':
          return CommentsDelete200Response.fromJson(value);
        case 'CommentsList200Response':
          return CommentsList200Response.fromJson(value);
        case 'CommentsList200ResponseItemsInner':
          return CommentsList200ResponseItemsInner.fromJson(value);
        case 'CommentsList200ResponseItemsInnerAccount':
          return CommentsList200ResponseItemsInnerAccount.fromJson(value);
        case 'CommentsList200ResponseItemsInnerNote':
          return CommentsList200ResponseItemsInnerNote.fromJson(value);
        case 'CommentsList200ResponseItemsInnerNoteAccount':
          return CommentsList200ResponseItemsInnerNoteAccount.fromJson(value);
        case 'CommentsList200ResponseItemsInnerRepliesInner':
          return CommentsList200ResponseItemsInnerRepliesInner.fromJson(value);
        case 'CommentsListRequest':
          return CommentsListRequest.fromJson(value);
        case 'CommentsUpdateRequest':
          return CommentsUpdateRequest.fromJson(value);
        case 'ConfigList200Response':
          return ConfigList200Response.fromJson(value);
        case 'ConfigList200ResponseOauth2ProvidersInner':
          return ConfigList200ResponseOauth2ProvidersInner.fromJson(value);
        case 'ConfigSetPluginConfigRequest':
          return ConfigSetPluginConfigRequest.fromJson(value);
        case 'ConfigUpdate200Response':
          return ConfigUpdate200Response.fromJson(value);
        case 'ConfigUpdateRequest':
          return ConfigUpdateRequest.fromJson(value);
        case 'ConfigUpdateRequestKey':
          return ConfigUpdateRequestKey.fromJson(value);
        case 'ConfigUpdateRequestKeyAnyOf':
          return ConfigUpdateRequestKeyAnyOf.fromJson(value);
        case 'DeleteFile200Response':
          return DeleteFile200Response.fromJson(value);
        case 'DeleteFileRequest':
          return DeleteFileRequest.fromJson(value);
        case 'ErrorBADREQUEST':
          return ErrorBADREQUEST.fromJson(value);
        case 'ErrorBADREQUESTIssuesInner':
          return ErrorBADREQUESTIssuesInner.fromJson(value);
        case 'ErrorFORBIDDEN':
          return ErrorFORBIDDEN.fromJson(value);
        case 'ErrorINTERNALSERVERERROR':
          return ErrorINTERNALSERVERERROR.fromJson(value);
        case 'ErrorNOTFOUND':
          return ErrorNOTFOUND.fromJson(value);
        case 'ErrorUNAUTHORIZED':
          return ErrorUNAUTHORIZED.fromJson(value);
        case 'FollowsFollowFromRequest':
          return FollowsFollowFromRequest.fromJson(value);
        case 'FollowsFollowList200ResponseInner':
          return FollowsFollowList200ResponseInner.fromJson(value);
        case 'FollowsFollowRequest':
          return FollowsFollowRequest.fromJson(value);
        case 'FollowsIsFollowing200Response':
          return FollowsIsFollowing200Response.fromJson(value);
        case 'FollowsRecommandList200ResponseInner':
          return FollowsRecommandList200ResponseInner.fromJson(value);
        case 'FollowsUnfollowFromRequest':
          return FollowsUnfollowFromRequest.fromJson(value);
        case 'NotesAddReferenceRequest':
          return NotesAddReferenceRequest.fromJson(value);
        case 'NotesDailyReviewNoteList200ResponseInner':
          return NotesDailyReviewNoteList200ResponseInner.fromJson(value);
        case 'NotesDetail200Response':
          return NotesDetail200Response.fromJson(value);
        case 'NotesDetailRequest':
          return NotesDetailRequest.fromJson(value);
        case 'NotesGetInternalSharedUsers200ResponseInner':
          return NotesGetInternalSharedUsers200ResponseInner.fromJson(value);
        case 'NotesGetNoteHistory200ResponseInner':
          return NotesGetNoteHistory200ResponseInner.fromJson(value);
        case 'NotesGetNoteVersion200Response':
          return NotesGetNoteVersion200Response.fromJson(value);
        case 'NotesInternalShareNote200Response':
          return NotesInternalShareNote200Response.fromJson(value);
        case 'NotesInternalShareNoteRequest':
          return NotesInternalShareNoteRequest.fromJson(value);
        case 'NotesInternalSharedWithMe200ResponseInner':
          return NotesInternalSharedWithMe200ResponseInner.fromJson(value);
        case 'NotesInternalSharedWithMeRequest':
          return NotesInternalSharedWithMeRequest.fromJson(value);
        case 'NotesList200ResponseInner':
          return NotesList200ResponseInner.fromJson(value);
        case 'NotesList200ResponseInnerAttachmentsInner':
          return NotesList200ResponseInnerAttachmentsInner.fromJson(value);
        case 'NotesList200ResponseInnerAttachmentsInnerSize':
          return NotesList200ResponseInnerAttachmentsInnerSize.fromJson(value);
        case 'NotesList200ResponseInnerCount':
          return NotesList200ResponseInnerCount.fromJson(value);
        case 'NotesList200ResponseInnerOwner':
          return NotesList200ResponseInnerOwner.fromJson(value);
        case 'NotesList200ResponseInnerReferencedByInner':
          return NotesList200ResponseInnerReferencedByInner.fromJson(value);
        case 'NotesList200ResponseInnerReferencesInner':
          return NotesList200ResponseInnerReferencesInner.fromJson(value);
        case 'NotesList200ResponseInnerReferencesInnerToNote':
          return NotesList200ResponseInnerReferencesInnerToNote.fromJson(value);
        case 'NotesList200ResponseInnerTagsInner':
          return NotesList200ResponseInnerTagsInner.fromJson(value);
        case 'NotesList200ResponseInnerTagsInnerTag':
          return NotesList200ResponseInnerTagsInnerTag.fromJson(value);
        case 'NotesListByIds200ResponseInner':
          return NotesListByIds200ResponseInner.fromJson(value);
        case 'NotesListByIdsRequest':
          return NotesListByIdsRequest.fromJson(value);
        case 'NotesListRequest':
          return NotesListRequest.fromJson(value);
        case 'NotesListRequestStartDate':
          return NotesListRequestStartDate.fromJson(value);
        case 'NotesListRequestType':
          return NotesListRequestType.fromJson(value);
        case 'NotesNoteReferenceList200ResponseInner':
          return NotesNoteReferenceList200ResponseInner.fromJson(value);
        case 'NotesNoteReferenceListRequest':
          return NotesNoteReferenceListRequest.fromJson(value);
        case 'NotesPublicDetail200Response':
          return NotesPublicDetail200Response.fromJson(value);
        case 'NotesPublicDetail200ResponseData':
          return NotesPublicDetail200ResponseData.fromJson(value);
        case 'NotesPublicDetailRequest':
          return NotesPublicDetailRequest.fromJson(value);
        case 'NotesPublicList200ResponseInner':
          return NotesPublicList200ResponseInner.fromJson(value);
        case 'NotesPublicList200ResponseInnerAccount':
          return NotesPublicList200ResponseInnerAccount.fromJson(value);
        case 'NotesPublicList200ResponseInnerCount':
          return NotesPublicList200ResponseInnerCount.fromJson(value);
        case 'NotesPublicListRequest':
          return NotesPublicListRequest.fromJson(value);
        case 'NotesReviewNote200Response':
          return NotesReviewNote200Response.fromJson(value);
        case 'NotesShareNote200Response':
          return NotesShareNote200Response.fromJson(value);
        case 'NotesShareNoteRequest':
          return NotesShareNoteRequest.fromJson(value);
        case 'NotesUpdateAttachmentsOrderRequest':
          return NotesUpdateAttachmentsOrderRequest.fromJson(value);
        case 'NotesUpdateAttachmentsOrderRequestAttachmentsInner':
          return NotesUpdateAttachmentsOrderRequestAttachmentsInner.fromJson(value);
        case 'NotesUpdateManyRequest':
          return NotesUpdateManyRequest.fromJson(value);
        case 'NotesUpsertRequest':
          return NotesUpsertRequest.fromJson(value);
        case 'NotesUpsertRequestAttachmentsInner':
          return NotesUpsertRequestAttachmentsInner.fromJson(value);
        case 'NotesUpsertRequestAttachmentsInnerSize':
          return NotesUpsertRequestAttachmentsInnerSize.fromJson(value);
        case 'NotificationsCreateRequest':
          return NotificationsCreateRequest.fromJson(value);
        case 'NotificationsList200ResponseInner':
          return NotificationsList200ResponseInner.fromJson(value);
        case 'NotificationsList200ResponseInnerType':
          return NotificationsList200ResponseInnerType.fromJson(value);
        case 'PublicHubList200ResponseInner':
          return PublicHubList200ResponseInner.fromJson(value);
        case 'PublicHubSiteList200ResponseInner':
          return PublicHubSiteList200ResponseInner.fromJson(value);
        case 'PublicLinkPreview200Response':
          return PublicLinkPreview200Response.fromJson(value);
        case 'PublicMusicMetadata200Response':
          return PublicMusicMetadata200Response.fromJson(value);
        case 'PublicOauthProviders200ResponseInner':
          return PublicOauthProviders200ResponseInner.fromJson(value);
        case 'PublicSiteInfo200Response':
          return PublicSiteInfo200Response.fromJson(value);
        case 'PublicTestHttpProxy200Response':
          return PublicTestHttpProxy200Response.fromJson(value);
        case 'PublicTestHttpProxyRequest':
          return PublicTestHttpProxyRequest.fromJson(value);
        case 'PublicTestWebhook200Response':
          return PublicTestWebhook200Response.fromJson(value);
        case 'PublicTestWebhookRequest':
          return PublicTestWebhookRequest.fromJson(value);
        case 'TagsUpdateTagIconRequest':
          return TagsUpdateTagIconRequest.fromJson(value);
        case 'TagsUpdateTagManyRequest':
          return TagsUpdateTagManyRequest.fromJson(value);
        case 'TagsUpdateTagNameRequest':
          return TagsUpdateTagNameRequest.fromJson(value);
        case 'UploadFile200Response':
          return UploadFile200Response.fromJson(value);
        case 'UploadFile401Response':
          return UploadFile401Response.fromJson(value);
        case 'UploadFileByUrl200Response':
          return UploadFileByUrl200Response.fromJson(value);
        case 'UploadFileByUrlRequest':
          return UploadFileByUrlRequest.fromJson(value);
        case 'UsersDetail200Response':
          return UsersDetail200Response.fromJson(value);
        case 'UsersGenLowPermToken200Response':
          return UsersGenLowPermToken200Response.fromJson(value);
        case 'UsersLinkAccountRequest':
          return UsersLinkAccountRequest.fromJson(value);
        case 'UsersList200ResponseInner':
          return UsersList200ResponseInner.fromJson(value);
        case 'UsersLogin200Response':
          return UsersLogin200Response.fromJson(value);
        case 'UsersNativeAccountList200ResponseInner':
          return UsersNativeAccountList200ResponseInner.fromJson(value);
        case 'UsersPublicUserList200ResponseInner':
          return UsersPublicUserList200ResponseInner.fromJson(value);
        case 'UsersRegisterRequest':
          return UsersRegisterRequest.fromJson(value);
        case 'UsersUpsertUserByAdminRequest':
          return UsersUpsertUserByAdminRequest.fromJson(value);
        case 'UsersUpsertUserRequest':
          return UsersUpsertUserRequest.fromJson(value);
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
