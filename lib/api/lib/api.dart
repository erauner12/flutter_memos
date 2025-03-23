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

import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

part 'api_client.dart';
part 'api_helper.dart';
part 'api_exception.dart';
part 'auth/authentication.dart';
part 'auth/api_key_auth.dart';
part 'auth/oauth.dart';
part 'auth/http_basic_auth.dart';
part 'auth/http_bearer_auth.dart';

part 'api/activity_service_api.dart';
part 'api/auth_service_api.dart';
part 'api/identity_provider_service_api.dart';
part 'api/inbox_service_api.dart';
part 'api/markdown_service_api.dart';
part 'api/memo_service_api.dart';
part 'api/resource_service_api.dart';
part 'api/user_service_api.dart';
part 'api/webhook_service_api.dart';
part 'api/workspace_service_api.dart';
part 'api/workspace_setting_service_api.dart';

part 'model/api_http_body.dart';
part 'model/apiv1_activity_memo_comment_payload.dart';
part 'model/apiv1_activity_payload.dart';
part 'model/apiv1_activity_version_update_payload.dart';
part 'model/apiv1_field_mapping.dart';
part 'model/apiv1_identity_provider.dart';
part 'model/apiv1_identity_provider_config.dart';
part 'model/apiv1_identity_provider_type.dart';
part 'model/apiv1_location.dart';
part 'model/apiv1_memo.dart';
part 'model/apiv1_o_auth2_config.dart';
part 'model/apiv1_shortcut.dart';
part 'model/apiv1_user_setting.dart';
part 'model/apiv1_workspace_custom_profile.dart';
part 'model/apiv1_workspace_general_setting.dart';
part 'model/apiv1_workspace_memo_related_setting.dart';
part 'model/apiv1_workspace_setting.dart';
part 'model/apiv1_workspace_storage_setting.dart';
part 'model/apiv1_workspace_storage_setting_storage_type.dart';
part 'model/googlerpc_status.dart';
part 'model/inbox_service_update_inbox_request.dart';
part 'model/list_node_kind.dart';
part 'model/memo_service_rename_memo_tag_body.dart';
part 'model/memo_service_set_memo_relations_body.dart';
part 'model/memo_service_set_memo_resources_body.dart';
part 'model/memo_service_upsert_memo_reaction_body.dart';
part 'model/protobuf_any.dart';
part 'model/resource_service_update_resource_request.dart';
part 'model/setting_is_the_setting_to_update.dart';
part 'model/table_node_row.dart';
part 'model/the_identity_provider_to_update.dart';
part 'model/the_memo_to_update_the_name_field_is_required.dart';
part 'model/user_role.dart';
part 'model/user_service_create_user_access_token_body.dart';
part 'model/user_service_update_shortcut_request.dart';
part 'model/user_service_update_user_request.dart';
part 'model/user_service_update_user_setting_request.dart';
part 'model/user_stats_memo_type_stats.dart';
part 'model/v1_activity.dart';
part 'model/v1_auto_link_node.dart';
part 'model/v1_blockquote_node.dart';
part 'model/v1_bold_italic_node.dart';
part 'model/v1_bold_node.dart';
part 'model/v1_code_block_node.dart';
part 'model/v1_code_node.dart';
part 'model/v1_create_webhook_request.dart';
part 'model/v1_direction.dart';
part 'model/v1_embedded_content_node.dart';
part 'model/v1_escaping_character_node.dart';
part 'model/v1_html_element_node.dart';
part 'model/v1_heading_node.dart';
part 'model/v1_highlight_node.dart';
part 'model/v1_horizontal_rule_node.dart';
part 'model/v1_image_node.dart';
part 'model/v1_inbox.dart';
part 'model/v1_inbox_status.dart';
part 'model/v1_inbox_type.dart';
part 'model/v1_italic_node.dart';
part 'model/v1_link_metadata.dart';
part 'model/v1_link_node.dart';
part 'model/v1_list_all_user_stats_response.dart';
part 'model/v1_list_identity_providers_response.dart';
part 'model/v1_list_inboxes_response.dart';
part 'model/v1_list_memo_comments_response.dart';
part 'model/v1_list_memo_reactions_response.dart';
part 'model/v1_list_memo_relations_response.dart';
part 'model/v1_list_memo_resources_response.dart';
part 'model/v1_list_memos_response.dart';
part 'model/v1_list_node.dart';
part 'model/v1_list_resources_response.dart';
part 'model/v1_list_shortcuts_response.dart';
part 'model/v1_list_user_access_tokens_response.dart';
part 'model/v1_list_users_response.dart';
part 'model/v1_list_webhooks_response.dart';
part 'model/v1_math_block_node.dart';
part 'model/v1_math_node.dart';
part 'model/v1_memo_property.dart';
part 'model/v1_memo_relation.dart';
part 'model/v1_memo_relation_memo.dart';
part 'model/v1_memo_relation_type.dart';
part 'model/v1_node.dart';
part 'model/v1_node_type.dart';
part 'model/v1_ordered_list_item_node.dart';
part 'model/v1_paragraph_node.dart';
part 'model/v1_parse_markdown_request.dart';
part 'model/v1_parse_markdown_response.dart';
part 'model/v1_reaction.dart';
part 'model/v1_referenced_content_node.dart';
part 'model/v1_resource.dart';
part 'model/v1_restore_markdown_nodes_request.dart';
part 'model/v1_restore_markdown_nodes_response.dart';
part 'model/v1_spoiler_node.dart';
part 'model/v1_state.dart';
part 'model/v1_strikethrough_node.dart';
part 'model/v1_stringify_markdown_nodes_request.dart';
part 'model/v1_stringify_markdown_nodes_response.dart';
part 'model/v1_subscript_node.dart';
part 'model/v1_superscript_node.dart';
part 'model/v1_table_node.dart';
part 'model/v1_tag_node.dart';
part 'model/v1_task_list_item_node.dart';
part 'model/v1_text_node.dart';
part 'model/v1_unordered_list_item_node.dart';
part 'model/v1_user.dart';
part 'model/v1_user_access_token.dart';
part 'model/v1_user_stats.dart';
part 'model/v1_visibility.dart';
part 'model/v1_webhook.dart';
part 'model/v1_workspace_profile.dart';
part 'model/webhook_service_update_webhook_request.dart';
part 'model/workspace_storage_setting_s3_config.dart';


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
