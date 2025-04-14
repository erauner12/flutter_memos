# todoist_blinko_api.api.PublicApi

## Load the API package
```dart
import 'package:todoist_blinko_api/api.dart';
```

All URIs are relative to */api*

Method | HTTP request | Description
------------- | ------------- | -------------
[**publicHubList**](PublicApi.md#publichublist) | **GET** /v1/public/hub-list | Get hub list
[**publicHubSiteList**](PublicApi.md#publichubsitelist) | **GET** /v1/public/hub-site-list | Get hub site list from GitHub
[**publicLatestVersion**](PublicApi.md#publiclatestversion) | **GET** /v1/public/latest-version | Get a new version
[**publicLinkPreview**](PublicApi.md#publiclinkpreview) | **GET** /v1/public/link-preview | Get a link preview info
[**publicMusicMetadata**](PublicApi.md#publicmusicmetadata) | **GET** /v1/public/music-metadata | Get music metadata
[**publicOauthProviders**](PublicApi.md#publicoauthproviders) | **GET** /v1/public/oauth-providers | Get OAuth providers info
[**publicSiteInfo**](PublicApi.md#publicsiteinfo) | **GET** /v1/public/site-info | Get site info
[**publicTestHttpProxy**](PublicApi.md#publictesthttpproxy) | **POST** /v1/public/test-http-proxy | Test HTTP proxy configuration
[**publicTestWebhook**](PublicApi.md#publictestwebhook) | **POST** /v1/public/test-webhook | Test webhook
[**publicVersion**](PublicApi.md#publicversion) | **GET** /v1/public/version | Update user config


# **publicHubList**
> List<PublicHubList200ResponseInner> publicHubList()

Get hub list

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PublicApi();

try {
    final result = api_instance.publicHubList();
    print(result);
} catch (e) {
    print('Exception when calling PublicApi->publicHubList: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<PublicHubList200ResponseInner>**](PublicHubList200ResponseInner.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **publicHubSiteList**
> List<PublicHubSiteList200ResponseInner> publicHubSiteList(search, refresh)

Get hub site list from GitHub

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PublicApi();
final search = search_example; // String | 
final refresh = true; // bool | 

try {
    final result = api_instance.publicHubSiteList(search, refresh);
    print(result);
} catch (e) {
    print('Exception when calling PublicApi->publicHubSiteList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **search** | **String**|  | [optional] 
 **refresh** | **bool**|  | [optional] 

### Return type

[**List<PublicHubSiteList200ResponseInner>**](PublicHubSiteList200ResponseInner.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **publicLatestVersion**
> String publicLatestVersion()

Get a new version

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PublicApi();

try {
    final result = api_instance.publicLatestVersion();
    print(result);
} catch (e) {
    print('Exception when calling PublicApi->publicLatestVersion: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**String**

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **publicLinkPreview**
> PublicLinkPreview200Response publicLinkPreview(url)

Get a link preview info

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PublicApi();
final url = url_example; // String | 

try {
    final result = api_instance.publicLinkPreview(url);
    print(result);
} catch (e) {
    print('Exception when calling PublicApi->publicLinkPreview: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **url** | **String**|  | 

### Return type

[**PublicLinkPreview200Response**](PublicLinkPreview200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **publicMusicMetadata**
> PublicMusicMetadata200Response publicMusicMetadata(filePath)

Get music metadata

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PublicApi();
final filePath = filePath_example; // String | 

try {
    final result = api_instance.publicMusicMetadata(filePath);
    print(result);
} catch (e) {
    print('Exception when calling PublicApi->publicMusicMetadata: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **filePath** | **String**|  | 

### Return type

[**PublicMusicMetadata200Response**](PublicMusicMetadata200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **publicOauthProviders**
> List<PublicOauthProviders200ResponseInner> publicOauthProviders()

Get OAuth providers info

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PublicApi();

try {
    final result = api_instance.publicOauthProviders();
    print(result);
} catch (e) {
    print('Exception when calling PublicApi->publicOauthProviders: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<PublicOauthProviders200ResponseInner>**](PublicOauthProviders200ResponseInner.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **publicSiteInfo**
> PublicSiteInfo200Response publicSiteInfo(id)

Get site info

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PublicApi();
final id = 8.14; // num | 

try {
    final result = api_instance.publicSiteInfo(id);
    print(result);
} catch (e) {
    print('Exception when calling PublicApi->publicSiteInfo: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **num**|  | [optional] 

### Return type

[**PublicSiteInfo200Response**](PublicSiteInfo200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **publicTestHttpProxy**
> PublicTestHttpProxy200Response publicTestHttpProxy(publicTestHttpProxyRequest)

Test HTTP proxy configuration

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PublicApi();
final publicTestHttpProxyRequest = PublicTestHttpProxyRequest(); // PublicTestHttpProxyRequest | 

try {
    final result = api_instance.publicTestHttpProxy(publicTestHttpProxyRequest);
    print(result);
} catch (e) {
    print('Exception when calling PublicApi->publicTestHttpProxy: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **publicTestHttpProxyRequest** | [**PublicTestHttpProxyRequest**](PublicTestHttpProxyRequest.md)|  | 

### Return type

[**PublicTestHttpProxy200Response**](PublicTestHttpProxy200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **publicTestWebhook**
> PublicTestWebhook200Response publicTestWebhook(publicTestWebhookRequest)

Test webhook

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PublicApi();
final publicTestWebhookRequest = PublicTestWebhookRequest(); // PublicTestWebhookRequest | 

try {
    final result = api_instance.publicTestWebhook(publicTestWebhookRequest);
    print(result);
} catch (e) {
    print('Exception when calling PublicApi->publicTestWebhook: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **publicTestWebhookRequest** | [**PublicTestWebhookRequest**](PublicTestWebhookRequest.md)|  | 

### Return type

[**PublicTestWebhook200Response**](PublicTestWebhook200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **publicVersion**
> String publicVersion()

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

final api_instance = PublicApi();

try {
    final result = api_instance.publicVersion();
    print(result);
} catch (e) {
    print('Exception when calling PublicApi->publicVersion: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**String**

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

