# flutter_memos_api.api.WorkspaceSettingServiceApi

## Load the API package
```dart
import 'package:flutter_memos_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**workspaceSettingServiceGetWorkspaceSetting**](WorkspaceSettingServiceApi.md#workspacesettingservicegetworkspacesetting) | **GET** /api/v1/workspace/{name} | GetWorkspaceSetting returns the setting by name.
[**workspaceSettingServiceSetWorkspaceSetting**](WorkspaceSettingServiceApi.md#workspacesettingservicesetworkspacesetting) | **PATCH** /api/v1/workspace/{setting.name} | SetWorkspaceSetting updates the setting.


# **workspaceSettingServiceGetWorkspaceSetting**
> Apiv1WorkspaceSetting workspaceSettingServiceGetWorkspaceSetting(name)

GetWorkspaceSetting returns the setting by name.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = WorkspaceSettingServiceApi();
final name = name_example; // String | The resource name of the workspace setting. Format: settings/{setting}

try {
    final result = api_instance.workspaceSettingServiceGetWorkspaceSetting(name);
    print(result);
} catch (e) {
    print('Exception when calling WorkspaceSettingServiceApi->workspaceSettingServiceGetWorkspaceSetting: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**| The resource name of the workspace setting. Format: settings/{setting} | 

### Return type

[**Apiv1WorkspaceSetting**](Apiv1WorkspaceSetting.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **workspaceSettingServiceSetWorkspaceSetting**
> Apiv1WorkspaceSetting workspaceSettingServiceSetWorkspaceSetting(settingPeriodName, setting)

SetWorkspaceSetting updates the setting.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = WorkspaceSettingServiceApi();
final settingPeriodName = settingPeriodName_example; // String | name is the name of the setting. Format: settings/{setting}
final setting = SettingIsTheSettingToUpdate(); // SettingIsTheSettingToUpdate | setting is the setting to update.

try {
    final result = api_instance.workspaceSettingServiceSetWorkspaceSetting(settingPeriodName, setting);
    print(result);
} catch (e) {
    print('Exception when calling WorkspaceSettingServiceApi->workspaceSettingServiceSetWorkspaceSetting: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **settingPeriodName** | **String**| name is the name of the setting. Format: settings/{setting} | 
 **setting** | [**SettingIsTheSettingToUpdate**](SettingIsTheSettingToUpdate.md)| setting is the setting to update. | 

### Return type

[**Apiv1WorkspaceSetting**](Apiv1WorkspaceSetting.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

