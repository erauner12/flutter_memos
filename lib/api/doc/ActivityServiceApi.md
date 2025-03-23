# flutter_memos_api.api.ActivityServiceApi

## Load the API package
```dart
import 'package:flutter_memos_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**activityServiceGetActivity**](ActivityServiceApi.md#activityservicegetactivity) | **GET** /api/v1/{name} | GetActivity returns the activity with the given id.


# **activityServiceGetActivity**
> V1Activity activityServiceGetActivity(name)

GetActivity returns the activity with the given id.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = ActivityServiceApi();
final name = name_example; // String | The name of the activity. Format: activities/{id}, id is the system generated auto-incremented id.

try {
    final result = api_instance.activityServiceGetActivity(name);
    print(result);
} catch (e) {
    print('Exception when calling ActivityServiceApi->activityServiceGetActivity: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**| The name of the activity. Format: activities/{id}, id is the system generated auto-incremented id. | 

### Return type

[**V1Activity**](V1Activity.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

