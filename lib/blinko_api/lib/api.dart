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

part 'api/analytics_api.dart';
part 'api/comment_api.dart';
part 'api/config_api.dart';
part 'api/file_api.dart';
part 'api/follows_api.dart';
part 'api/note_api.dart';
part 'api/notification_api.dart';
part 'api/public_api.dart';
part 'api/tag_api.dart';
part 'api/user_api.dart';

part 'model/analytics_daily_note_count200_response_inner.dart';
part 'model/analytics_monthly_stats200_response.dart';
part 'model/analytics_monthly_stats200_response_tag_stats_inner.dart';
part 'model/analytics_monthly_stats_request.dart';
part 'model/comments_create_request.dart';
part 'model/comments_delete200_response.dart';
part 'model/comments_list200_response.dart';
part 'model/comments_list200_response_items_inner.dart';
part 'model/comments_list200_response_items_inner_account.dart';
part 'model/comments_list200_response_items_inner_note.dart';
part 'model/comments_list200_response_items_inner_note_account.dart';
part 'model/comments_list200_response_items_inner_replies_inner.dart';
part 'model/comments_list_request.dart';
part 'model/comments_update_request.dart';
part 'model/config_list200_response.dart';
part 'model/config_list200_response_oauth2_providers_inner.dart';
part 'model/config_set_plugin_config_request.dart';
part 'model/config_update200_response.dart';
part 'model/config_update_request.dart';
part 'model/config_update_request_key.dart';
part 'model/config_update_request_key_any_of.dart';
part 'model/delete_file200_response.dart';
part 'model/delete_file_request.dart';
part 'model/error_badrequest.dart';
part 'model/error_badrequest_issues_inner.dart';
part 'model/error_forbidden.dart';
part 'model/error_internalservererror.dart';
part 'model/error_notfound.dart';
part 'model/error_unauthorized.dart';
part 'model/follows_follow_from_request.dart';
part 'model/follows_follow_list200_response_inner.dart';
part 'model/follows_follow_request.dart';
part 'model/follows_is_following200_response.dart';
part 'model/follows_recommand_list200_response_inner.dart';
part 'model/follows_unfollow_from_request.dart';
part 'model/notes_add_reference_request.dart';
part 'model/notes_daily_review_note_list200_response_inner.dart';
part 'model/notes_detail200_response.dart';
part 'model/notes_detail_request.dart';
part 'model/notes_get_internal_shared_users200_response_inner.dart';
part 'model/notes_get_note_history200_response_inner.dart';
part 'model/notes_get_note_version200_response.dart';
part 'model/notes_internal_share_note200_response.dart';
part 'model/notes_internal_share_note_request.dart';
part 'model/notes_internal_shared_with_me200_response_inner.dart';
part 'model/notes_internal_shared_with_me_request.dart';
part 'model/notes_list200_response_inner.dart';
part 'model/notes_list200_response_inner_attachments_inner.dart';
part 'model/notes_list200_response_inner_attachments_inner_size.dart';
part 'model/notes_list200_response_inner_count.dart';
part 'model/notes_list200_response_inner_owner.dart';
part 'model/notes_list200_response_inner_referenced_by_inner.dart';
part 'model/notes_list200_response_inner_references_inner.dart';
part 'model/notes_list200_response_inner_references_inner_to_note.dart';
part 'model/notes_list200_response_inner_tags_inner.dart';
part 'model/notes_list200_response_inner_tags_inner_tag.dart';
part 'model/notes_list_by_ids200_response_inner.dart';
part 'model/notes_list_by_ids_request.dart';
part 'model/notes_list_request.dart';
part 'model/notes_list_request_start_date.dart';
part 'model/notes_list_request_type.dart';
part 'model/notes_note_reference_list200_response_inner.dart';
part 'model/notes_note_reference_list_request.dart';
part 'model/notes_public_detail200_response.dart';
part 'model/notes_public_detail200_response_data.dart';
part 'model/notes_public_detail_request.dart';
part 'model/notes_public_list200_response_inner.dart';
part 'model/notes_public_list200_response_inner_account.dart';
part 'model/notes_public_list200_response_inner_count.dart';
part 'model/notes_public_list_request.dart';
part 'model/notes_review_note200_response.dart';
part 'model/notes_share_note200_response.dart';
part 'model/notes_share_note_request.dart';
part 'model/notes_update_attachments_order_request.dart';
part 'model/notes_update_attachments_order_request_attachments_inner.dart';
part 'model/notes_update_many_request.dart';
part 'model/notes_upsert_request.dart';
part 'model/notes_upsert_request_attachments_inner.dart';
part 'model/notes_upsert_request_attachments_inner_size.dart';
part 'model/notifications_create_request.dart';
part 'model/notifications_list200_response_inner.dart';
part 'model/notifications_list200_response_inner_type.dart';
part 'model/public_hub_list200_response_inner.dart';
part 'model/public_hub_site_list200_response_inner.dart';
part 'model/public_link_preview200_response.dart';
part 'model/public_music_metadata200_response.dart';
part 'model/public_oauth_providers200_response_inner.dart';
part 'model/public_site_info200_response.dart';
part 'model/public_test_http_proxy200_response.dart';
part 'model/public_test_http_proxy_request.dart';
part 'model/public_test_webhook200_response.dart';
part 'model/public_test_webhook_request.dart';
part 'model/tags_update_tag_icon_request.dart';
part 'model/tags_update_tag_many_request.dart';
part 'model/tags_update_tag_name_request.dart';
part 'model/upload_file200_response.dart';
part 'model/upload_file401_response.dart';
part 'model/upload_file_by_url200_response.dart';
part 'model/upload_file_by_url_request.dart';
part 'model/users_detail200_response.dart';
part 'model/users_gen_low_perm_token200_response.dart';
part 'model/users_link_account_request.dart';
part 'model/users_list200_response_inner.dart';
part 'model/users_login200_response.dart';
part 'model/users_native_account_list200_response_inner.dart';
part 'model/users_public_user_list200_response_inner.dart';
part 'model/users_register_request.dart';
part 'model/users_upsert_user_by_admin_request.dart';
part 'model/users_upsert_user_request.dart';


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
