# todoist_blinko_api.api.ConfigApi

## Load the API package
```dart
import 'package:todoist_blinko_api/api.dart';
```

All URIs are relative to */api*

Method | HTTP request | Description
------------- | ------------- | -------------
[**configGetPluginConfig**](ConfigApi.md#configgetpluginconfig) | **GET** /v1/config/getPluginConfig | Get plugin config
[**configList**](ConfigApi.md#configlist) | **GET** /v1/config/list | Query user config list
[**configSetPluginConfig**](ConfigApi.md#configsetpluginconfig) | **POST** /v1/config/setPluginConfig | Set plugin config
[**configUpdate**](ConfigApi.md#configupdate) | **POST** /v1/config/update | Update user config


# **configGetPluginConfig**
> Object configGetPluginConfig(pluginName)

Get plugin config

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ConfigApi();
final pluginName = pluginName_example; // String | 

try {
    final result = api_instance.configGetPluginConfig(pluginName);
    print(result);
} catch (e) {
    print('Exception when calling ConfigApi->configGetPluginConfig: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **pluginName** | **String**|  | 

### Return type

[**Object**](Object.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **configList**
> ConfigList200Response configList()

Query user config list

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ConfigApi();

try {
    final result = api_instance.configList();
    print(result);
} catch (e) {
    print('Exception when calling ConfigApi->configList: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ConfigList200Response**](ConfigList200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **configSetPluginConfig**
> Object configSetPluginConfig(configSetPluginConfigRequest)

Set plugin config

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ConfigApi();
final configSetPluginConfigRequest = ConfigSetPluginConfigRequest(); // ConfigSetPluginConfigRequest | 

try {
    final result = api_instance.configSetPluginConfig(configSetPluginConfigRequest);
    print(result);
} catch (e) {
    print('Exception when calling ConfigApi->configSetPluginConfig: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **configSetPluginConfigRequest** | [**ConfigSetPluginConfigRequest**](ConfigSetPluginConfigRequest.md)|  | 

### Return type

[**Object**](Object.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **configUpdate**
> ConfigUpdate200Response configUpdate(configUpdateRequest)

Update user config

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ConfigApi();
final configUpdateRequest = ConfigUpdateRequest(); // ConfigUpdateRequest | 

try {
    final result = api_instance.configUpdate(configUpdateRequest);
    print(result);
} catch (e) {
    print('Exception when calling ConfigApi->configUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **configUpdateRequest** | [**ConfigUpdateRequest**](ConfigUpdateRequest.md)|  | 

### Return type

[**ConfigUpdate200Response**](ConfigUpdate200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

