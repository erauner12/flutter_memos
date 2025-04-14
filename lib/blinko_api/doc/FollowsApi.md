# todoist_blinko_api.api.FollowsApi

## Load the API package
```dart
import 'package:todoist_blinko_api/api.dart';
```

All URIs are relative to */api*

Method | HTTP request | Description
------------- | ------------- | -------------
[**followsFollow**](FollowsApi.md#followsfollow) | **POST** /v1/follows/follow | Follow a user
[**followsFollowFrom**](FollowsApi.md#followsfollowfrom) | **POST** /v1/follows/follow-from | Some site wants to follow me
[**followsFollowList**](FollowsApi.md#followsfollowlist) | **GET** /v1/follows/follow-list | Get following list
[**followsFollowerList**](FollowsApi.md#followsfollowerlist) | **GET** /v1/follows/followers | Get followers list
[**followsIsFollowing**](FollowsApi.md#followsisfollowing) | **GET** /v1/follows/is-following | Check if following a user
[**followsRecommandList**](FollowsApi.md#followsrecommandlist) | **GET** /v1/follows/recommand-list | Get recommand list by following users
[**followsUnfollow**](FollowsApi.md#followsunfollow) | **POST** /v1/follows/unfollow | Unfollow a user
[**followsUnfollowFrom**](FollowsApi.md#followsunfollowfrom) | **POST** /v1/follows/unfollow-from | Some site wants to unfollow me


# **followsFollow**
> PublicTestWebhook200Response followsFollow(followsFollowRequest)

Follow a user

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FollowsApi();
final followsFollowRequest = FollowsFollowRequest(); // FollowsFollowRequest | 

try {
    final result = api_instance.followsFollow(followsFollowRequest);
    print(result);
} catch (e) {
    print('Exception when calling FollowsApi->followsFollow: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **followsFollowRequest** | [**FollowsFollowRequest**](FollowsFollowRequest.md)|  | 

### Return type

[**PublicTestWebhook200Response**](PublicTestWebhook200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **followsFollowFrom**
> PublicTestWebhook200Response followsFollowFrom(followsFollowFromRequest)

Some site wants to follow me

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FollowsApi();
final followsFollowFromRequest = FollowsFollowFromRequest(); // FollowsFollowFromRequest | 

try {
    final result = api_instance.followsFollowFrom(followsFollowFromRequest);
    print(result);
} catch (e) {
    print('Exception when calling FollowsApi->followsFollowFrom: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **followsFollowFromRequest** | [**FollowsFollowFromRequest**](FollowsFollowFromRequest.md)|  | 

### Return type

[**PublicTestWebhook200Response**](PublicTestWebhook200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **followsFollowList**
> List<FollowsFollowList200ResponseInner> followsFollowList(userId)

Get following list

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FollowsApi();
final userId = 8.14; // num | 

try {
    final result = api_instance.followsFollowList(userId);
    print(result);
} catch (e) {
    print('Exception when calling FollowsApi->followsFollowList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **num**|  | [optional] 

### Return type

[**List<FollowsFollowList200ResponseInner>**](FollowsFollowList200ResponseInner.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **followsFollowerList**
> List<FollowsFollowList200ResponseInner> followsFollowerList(userId)

Get followers list

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FollowsApi();
final userId = 8.14; // num | 

try {
    final result = api_instance.followsFollowerList(userId);
    print(result);
} catch (e) {
    print('Exception when calling FollowsApi->followsFollowerList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **num**|  | [optional] 

### Return type

[**List<FollowsFollowList200ResponseInner>**](FollowsFollowList200ResponseInner.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **followsIsFollowing**
> FollowsIsFollowing200Response followsIsFollowing(siteUrl)

Check if following a user

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FollowsApi();
final siteUrl = siteUrl_example; // String | 

try {
    final result = api_instance.followsIsFollowing(siteUrl);
    print(result);
} catch (e) {
    print('Exception when calling FollowsApi->followsIsFollowing: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **siteUrl** | **String**|  | 

### Return type

[**FollowsIsFollowing200Response**](FollowsIsFollowing200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **followsRecommandList**
> List<FollowsRecommandList200ResponseInner> followsRecommandList(searchText)

Get recommand list by following users

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FollowsApi();
final searchText = searchText_example; // String | 

try {
    final result = api_instance.followsRecommandList(searchText);
    print(result);
} catch (e) {
    print('Exception when calling FollowsApi->followsRecommandList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **searchText** | **String**|  | [optional] [default to '']

### Return type

[**List<FollowsRecommandList200ResponseInner>**](FollowsRecommandList200ResponseInner.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **followsUnfollow**
> bool followsUnfollow(followsFollowRequest)

Unfollow a user

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FollowsApi();
final followsFollowRequest = FollowsFollowRequest(); // FollowsFollowRequest | 

try {
    final result = api_instance.followsUnfollow(followsFollowRequest);
    print(result);
} catch (e) {
    print('Exception when calling FollowsApi->followsUnfollow: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **followsFollowRequest** | [**FollowsFollowRequest**](FollowsFollowRequest.md)|  | 

### Return type

**bool**

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **followsUnfollowFrom**
> bool followsUnfollowFrom(followsUnfollowFromRequest)

Some site wants to unfollow me

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FollowsApi();
final followsUnfollowFromRequest = FollowsUnfollowFromRequest(); // FollowsUnfollowFromRequest | 

try {
    final result = api_instance.followsUnfollowFrom(followsUnfollowFromRequest);
    print(result);
} catch (e) {
    print('Exception when calling FollowsApi->followsUnfollowFrom: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **followsUnfollowFromRequest** | [**FollowsUnfollowFromRequest**](FollowsUnfollowFromRequest.md)|  | 

### Return type

**bool**

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

