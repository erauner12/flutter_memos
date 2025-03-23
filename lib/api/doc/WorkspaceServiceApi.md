# flutter_memos_api.api.WorkspaceServiceApi

## Load the API package
```dart
import 'package:flutter_memos_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**workspaceServiceGetWorkspaceProfile**](WorkspaceServiceApi.md#workspaceservicegetworkspaceprofile) | **GET** /api/v1/workspace/profile | GetWorkspaceProfile returns the workspace profile.


# **workspaceServiceGetWorkspaceProfile**
> V1WorkspaceProfile workspaceServiceGetWorkspaceProfile()

GetWorkspaceProfile returns the workspace profile.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = WorkspaceServiceApi();

try {
    final result = api_instance.workspaceServiceGetWorkspaceProfile();
    print(result);
} catch (e) {
    print('Exception when calling WorkspaceServiceApi->workspaceServiceGetWorkspaceProfile: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**V1WorkspaceProfile**](V1WorkspaceProfile.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

