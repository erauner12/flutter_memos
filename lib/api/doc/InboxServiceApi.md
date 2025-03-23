# flutter_memos_api.api.InboxServiceApi

## Load the API package
```dart
import 'package:flutter_memos_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**inboxServiceDeleteInbox**](InboxServiceApi.md#inboxservicedeleteinbox) | **DELETE** /api/v1/{name_2} | DeleteInbox deletes an inbox.
[**inboxServiceListInboxes**](InboxServiceApi.md#inboxservicelistinboxes) | **GET** /api/v1/inboxes | ListInboxes lists inboxes for a user.
[**inboxServiceUpdateInbox**](InboxServiceApi.md#inboxserviceupdateinbox) | **PATCH** /api/v1/{inbox.name} | UpdateInbox updates an inbox.


# **inboxServiceDeleteInbox**
> Object inboxServiceDeleteInbox(name2)

DeleteInbox deletes an inbox.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = InboxServiceApi();
final name2 = name2_example; // String | The name of the inbox to delete.

try {
    final result = api_instance.inboxServiceDeleteInbox(name2);
    print(result);
} catch (e) {
    print('Exception when calling InboxServiceApi->inboxServiceDeleteInbox: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name2** | **String**| The name of the inbox to delete. | 

### Return type

[**Object**](Object.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **inboxServiceListInboxes**
> V1ListInboxesResponse inboxServiceListInboxes(user, pageSize, pageToken)

ListInboxes lists inboxes for a user.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = InboxServiceApi();
final user = user_example; // String | Format: users/{user}
final pageSize = 56; // int | The maximum number of inbox to return.
final pageToken = pageToken_example; // String | Provide this to retrieve the subsequent page.

try {
    final result = api_instance.inboxServiceListInboxes(user, pageSize, pageToken);
    print(result);
} catch (e) {
    print('Exception when calling InboxServiceApi->inboxServiceListInboxes: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **user** | **String**| Format: users/{user} | [optional] 
 **pageSize** | **int**| The maximum number of inbox to return. | [optional] 
 **pageToken** | **String**| Provide this to retrieve the subsequent page. | [optional] 

### Return type

[**V1ListInboxesResponse**](V1ListInboxesResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **inboxServiceUpdateInbox**
> V1Inbox inboxServiceUpdateInbox(inboxPeriodName, inbox)

UpdateInbox updates an inbox.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = InboxServiceApi();
final inboxPeriodName = inboxPeriodName_example; // String | The name of the inbox. Format: inboxes/{id}, id is the system generated auto-incremented id.
final inbox = InboxServiceUpdateInboxRequest(); // InboxServiceUpdateInboxRequest | 

try {
    final result = api_instance.inboxServiceUpdateInbox(inboxPeriodName, inbox);
    print(result);
} catch (e) {
    print('Exception when calling InboxServiceApi->inboxServiceUpdateInbox: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **inboxPeriodName** | **String**| The name of the inbox. Format: inboxes/{id}, id is the system generated auto-incremented id. | 
 **inbox** | [**InboxServiceUpdateInboxRequest**](InboxServiceUpdateInboxRequest.md)|  | 

### Return type

[**V1Inbox**](V1Inbox.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

