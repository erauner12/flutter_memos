# todoist_blinko_api.api.NotificationApi

## Load the API package
```dart
import 'package:todoist_blinko_api/api.dart';
```

All URIs are relative to */api*

Method | HTTP request | Description
------------- | ------------- | -------------
[**notificationsCreate**](NotificationApi.md#notificationscreate) | **POST** /v1/notification/create | Create notification
[**notificationsList**](NotificationApi.md#notificationslist) | **GET** /v1/notification/list | Query notifications list


# **notificationsCreate**
> bool notificationsCreate(notificationsCreateRequest)

Create notification

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NotificationApi();
final notificationsCreateRequest = NotificationsCreateRequest(); // NotificationsCreateRequest | 

try {
    final result = api_instance.notificationsCreate(notificationsCreateRequest);
    print(result);
} catch (e) {
    print('Exception when calling NotificationApi->notificationsCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **notificationsCreateRequest** | [**NotificationsCreateRequest**](NotificationsCreateRequest.md)|  | 

### Return type

**bool**

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notificationsList**
> List<NotificationsList200ResponseInner> notificationsList(page, size)

Query notifications list

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NotificationApi();
final page = 8.14; // num | 
final size = 8.14; // num | 

try {
    final result = api_instance.notificationsList(page, size);
    print(result);
} catch (e) {
    print('Exception when calling NotificationApi->notificationsList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | **num**|  | [optional] [default to 1]
 **size** | **num**|  | [optional] [default to 30]

### Return type

[**List<NotificationsList200ResponseInner>**](NotificationsList200ResponseInner.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

