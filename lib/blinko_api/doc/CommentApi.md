# todoist_blinko_api.api.CommentApi

## Load the API package
```dart
import 'package:todoist_blinko_api/api.dart';
```

All URIs are relative to */api*

Method | HTTP request | Description
------------- | ------------- | -------------
[**commentsCreate**](CommentApi.md#commentscreate) | **POST** /v1/comment/create | Create a comment
[**commentsDelete**](CommentApi.md#commentsdelete) | **POST** /v1/comment/delete | Delete a comment
[**commentsList**](CommentApi.md#commentslist) | **POST** /v1/comment/list | Get comments list
[**commentsUpdate**](CommentApi.md#commentsupdate) | **POST** /v1/comment/update | Update a comment


# **commentsCreate**
> bool commentsCreate(commentsCreateRequest)

Create a comment

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CommentApi();
final commentsCreateRequest = CommentsCreateRequest(); // CommentsCreateRequest | 

try {
    final result = api_instance.commentsCreate(commentsCreateRequest);
    print(result);
} catch (e) {
    print('Exception when calling CommentApi->commentsCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **commentsCreateRequest** | [**CommentsCreateRequest**](CommentsCreateRequest.md)|  | 

### Return type

**bool**

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **commentsDelete**
> CommentsDelete200Response commentsDelete(notesDetailRequest)

Delete a comment

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CommentApi();
final notesDetailRequest = NotesDetailRequest(); // NotesDetailRequest | 

try {
    final result = api_instance.commentsDelete(notesDetailRequest);
    print(result);
} catch (e) {
    print('Exception when calling CommentApi->commentsDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **notesDetailRequest** | [**NotesDetailRequest**](NotesDetailRequest.md)|  | 

### Return type

[**CommentsDelete200Response**](CommentsDelete200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **commentsList**
> CommentsList200Response commentsList(commentsListRequest)

Get comments list

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CommentApi();
final commentsListRequest = CommentsListRequest(); // CommentsListRequest | 

try {
    final result = api_instance.commentsList(commentsListRequest);
    print(result);
} catch (e) {
    print('Exception when calling CommentApi->commentsList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **commentsListRequest** | [**CommentsListRequest**](CommentsListRequest.md)|  | 

### Return type

[**CommentsList200Response**](CommentsList200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **commentsUpdate**
> CommentsList200ResponseItemsInner commentsUpdate(commentsUpdateRequest)

Update a comment

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CommentApi();
final commentsUpdateRequest = CommentsUpdateRequest(); // CommentsUpdateRequest | 

try {
    final result = api_instance.commentsUpdate(commentsUpdateRequest);
    print(result);
} catch (e) {
    print('Exception when calling CommentApi->commentsUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **commentsUpdateRequest** | [**CommentsUpdateRequest**](CommentsUpdateRequest.md)|  | 

### Return type

[**CommentsList200ResponseItemsInner**](CommentsList200ResponseItemsInner.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

