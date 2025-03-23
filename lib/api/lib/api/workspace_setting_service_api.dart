//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class WorkspaceSettingServiceApi {
  WorkspaceSettingServiceApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// GetWorkspaceSetting returns the setting by name.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The resource name of the workspace setting. Format: settings/{setting}
  Future<Response> workspaceSettingServiceGetWorkspaceSettingWithHttpInfo(String name,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/workspace/{name}'
      .replaceAll('{name}', name);

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

  /// GetWorkspaceSetting returns the setting by name.
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   The resource name of the workspace setting. Format: settings/{setting}
  Future<Apiv1WorkspaceSetting?> workspaceSettingServiceGetWorkspaceSetting(String name,) async {
    final response = await workspaceSettingServiceGetWorkspaceSettingWithHttpInfo(name,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Apiv1WorkspaceSetting',) as Apiv1WorkspaceSetting;
    
    }
    return null;
  }

  /// SetWorkspaceSetting updates the setting.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] settingPeriodName (required):
  ///   name is the name of the setting. Format: settings/{setting}
  ///
  /// * [SettingIsTheSettingToUpdate] setting (required):
  ///   setting is the setting to update.
  Future<Response> workspaceSettingServiceSetWorkspaceSettingWithHttpInfo(String settingPeriodName, SettingIsTheSettingToUpdate setting,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/workspace/{setting.name}'
      .replaceAll('{setting.name}', settingPeriodName);

    // ignore: prefer_final_locals
    Object? postBody = setting;

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

  /// SetWorkspaceSetting updates the setting.
  ///
  /// Parameters:
  ///
  /// * [String] settingPeriodName (required):
  ///   name is the name of the setting. Format: settings/{setting}
  ///
  /// * [SettingIsTheSettingToUpdate] setting (required):
  ///   setting is the setting to update.
  Future<Apiv1WorkspaceSetting?> workspaceSettingServiceSetWorkspaceSetting(String settingPeriodName, SettingIsTheSettingToUpdate setting,) async {
    final response = await workspaceSettingServiceSetWorkspaceSettingWithHttpInfo(settingPeriodName, setting,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Apiv1WorkspaceSetting',) as Apiv1WorkspaceSetting;
    
    }
    return null;
  }
}
