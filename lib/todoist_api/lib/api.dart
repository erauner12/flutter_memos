//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

library openapi.api;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // Added for _decodeBodyBytes usage in placeholder SyncApi

import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

// REST API Parts
part 'api/comments_api.dart';
part 'api/labels_api.dart';
part 'api/projects_api.dart';
part 'api/sections_api.dart';
// Sync API Part (Placeholder)
part 'api/sync_api.dart';
part 'api/tasks_api.dart';
part 'api_client.dart';
part 'api_exception.dart';
part 'api_helper.dart';
part 'auth/api_key_auth.dart';
part 'auth/authentication.dart';
part 'auth/http_basic_auth.dart';
part 'auth/http_bearer_auth.dart';
part 'auth/oauth.dart';
// Model Parts (Ensure all needed models are included)
part 'model/activity_events.dart'; // Sync model
part 'model/collaborator.dart'; // REST model (used by ProjectsApi)
part 'model/comment.dart'; // REST model
part 'model/create_comment_attachment_parameter.dart'; // REST model
part 'model/create_task_request.dart'; // REST model
part 'model/due.dart'; // REST model (part of Task)
part 'model/duration.dart'; // REST model (part of TaskDuration) - Renamed to TodoistDuration
part 'model/error_model.dart'; // Common model
part 'model/exposed_collaborator_sync_view.dart'; // Sync model
part 'model/folder_view.dart'; // Sync model (part of GetDataV2Response) - Assuming this exists
part 'model/get_data_v2_response.dart'; // Sync model
part 'model/item_sync_view.dart'; // Sync model (part of PaginatedListItemSyncView) - Assuming this exists
part 'model/label.dart'; // REST model
part 'model/paginated_list_activity_events.dart'; // Sync model
part 'model/paginated_list_item_sync_view.dart'; // Sync model - Assuming this exists
part 'model/project.dart'; // REST model
part 'model/section.dart'; // REST model
part 'model/task.dart'; // REST model
part 'model/task_due.dart'; // REST model (wrapper for Due)
part 'model/task_duration.dart'; // REST model (wrapper for Duration)
part 'model/update_task_request.dart'; // REST model

/// An [ApiClient] instance that uses the default values obtained from
/// the OpenAPI specification file.
var defaultApiClient = ApiClient();

const _delimiters = {'csv': ',', 'ssv': ' ', 'tsv': '\t', 'pipes': '|'};
const _dateEpochMarker = 'epoch';
const _deepEquality = DeepCollectionEquality();
final _dateFormatter = DateFormat('yyyy-MM-dd');
final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

bool _isEpochMarker(String? pattern) => pattern == _dateEpochMarker || pattern == '/$_dateEpochMarker/';
