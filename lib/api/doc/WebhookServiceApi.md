# flutter_memos_api.api.WebhookServiceApi

## Load the API package
```dart
import 'package:flutter_memos_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**webhookServiceCreateWebhook**](WebhookServiceApi.md#webhookservicecreatewebhook) | **POST** /api/v1/webhooks | CreateWebhook creates a new webhook.
[**webhookServiceDeleteWebhook**](WebhookServiceApi.md#webhookservicedeletewebhook) | **DELETE** /api/v1/webhooks/{id} | DeleteWebhook deletes a webhook by id.
[**webhookServiceGetWebhook**](WebhookServiceApi.md#webhookservicegetwebhook) | **GET** /api/v1/webhooks/{id} | GetWebhook returns a webhook by id.
[**webhookServiceListWebhooks**](WebhookServiceApi.md#webhookservicelistwebhooks) | **GET** /api/v1/webhooks | ListWebhooks returns a list of webhooks.
[**webhookServiceUpdateWebhook**](WebhookServiceApi.md#webhookserviceupdatewebhook) | **PATCH** /api/v1/webhooks/{webhook.id} | UpdateWebhook updates a webhook.


# **webhookServiceCreateWebhook**
> V1Webhook webhookServiceCreateWebhook(body)

CreateWebhook creates a new webhook.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = WebhookServiceApi();
final body = V1CreateWebhookRequest(); // V1CreateWebhookRequest | 

try {
    final result = api_instance.webhookServiceCreateWebhook(body);
    print(result);
} catch (e) {
    print('Exception when calling WebhookServiceApi->webhookServiceCreateWebhook: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **body** | [**V1CreateWebhookRequest**](V1CreateWebhookRequest.md)|  | 

### Return type

[**V1Webhook**](V1Webhook.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **webhookServiceDeleteWebhook**
> Object webhookServiceDeleteWebhook(id)

DeleteWebhook deletes a webhook by id.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = WebhookServiceApi();
final id = 56; // int | 

try {
    final result = api_instance.webhookServiceDeleteWebhook(id);
    print(result);
} catch (e) {
    print('Exception when calling WebhookServiceApi->webhookServiceDeleteWebhook: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**Object**](Object.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **webhookServiceGetWebhook**
> V1Webhook webhookServiceGetWebhook(id)

GetWebhook returns a webhook by id.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = WebhookServiceApi();
final id = 56; // int | 

try {
    final result = api_instance.webhookServiceGetWebhook(id);
    print(result);
} catch (e) {
    print('Exception when calling WebhookServiceApi->webhookServiceGetWebhook: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**V1Webhook**](V1Webhook.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **webhookServiceListWebhooks**
> V1ListWebhooksResponse webhookServiceListWebhooks(creator)

ListWebhooks returns a list of webhooks.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = WebhookServiceApi();
final creator = creator_example; // String | The name of the creator.

try {
    final result = api_instance.webhookServiceListWebhooks(creator);
    print(result);
} catch (e) {
    print('Exception when calling WebhookServiceApi->webhookServiceListWebhooks: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **creator** | **String**| The name of the creator. | [optional] 

### Return type

[**V1ListWebhooksResponse**](V1ListWebhooksResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **webhookServiceUpdateWebhook**
> V1Webhook webhookServiceUpdateWebhook(webhookPeriodId, webhook)

UpdateWebhook updates a webhook.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = WebhookServiceApi();
final webhookPeriodId = 56; // int | 
final webhook = WebhookServiceUpdateWebhookRequest(); // WebhookServiceUpdateWebhookRequest | 

try {
    final result = api_instance.webhookServiceUpdateWebhook(webhookPeriodId, webhook);
    print(result);
} catch (e) {
    print('Exception when calling WebhookServiceApi->webhookServiceUpdateWebhook: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **webhookPeriodId** | **int**|  | 
 **webhook** | [**WebhookServiceUpdateWebhookRequest**](WebhookServiceUpdateWebhookRequest.md)|  | 

### Return type

[**V1Webhook**](V1Webhook.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

