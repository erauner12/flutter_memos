# todoist_flutter_api.api.CommentsApi

## Load the API package
```dart
import 'package:todoist_flutter_api/api.dart';
```

All URIs are relative to *https://api.todoist.com/rest/v2*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createComment**](CommentsApi.md#createcomment) | **POST** /comments | Create a new comment
[**deleteComment**](CommentsApi.md#deletecomment) | **DELETE** /comments/{comment_id} | Delete a comment
[**getAllComments**](CommentsApi.md#getallcomments) | **GET** /comments | Get all comments
[**getComment**](CommentsApi.md#getcomment) | **GET** /comments/{comment_id} | Get a comment
[**updateComment**](CommentsApi.md#updatecomment) | **POST** /comments/{comment_id} | Update a comment


# **createComment**
> Comment createComment(content, taskId, projectId, attachment)

Create a new comment

Creates a new comment on a project or task and returns it as a JSON object. Note that one of task_id or project_id arguments is required.  A successful response has 200 OK status and application/json Content-Type. 

### Example
```dart
import 'package:todoist_flutter_api/api.dart';
// TODO Configure HTTP Bearer authorization: api_key
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CommentsApi();
final content = content_example; // String | Comment content. This value may contain markdown-formatted text and hyperlinks.
final taskId = taskId_example; // String | Comment's task ID (for task comments). task_id or project_id required
final projectId = projectId_example; // String | Comment's project ID (for project comments). task_id or project_id required
final attachment = ; // CreateCommentAttachmentParameter | Object for attachment object.

try {
    final result = api_instance.createComment(content, taskId, projectId, attachment);
    print(result);
} catch (e) {
    print('Exception when calling CommentsApi->createComment: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **content** | **String**| Comment content. This value may contain markdown-formatted text and hyperlinks. | 
 **taskId** | **String**| Comment's task ID (for task comments). task_id or project_id required | [optional] 
 **projectId** | **String**| Comment's project ID (for project comments). task_id or project_id required | [optional] 
 **attachment** | [**CreateCommentAttachmentParameter**](.md)| Object for attachment object. | [optional] 

### Return type

[**Comment**](Comment.md)

### Authorization

[api_key](../README.md#api_key)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteComment**
> deleteComment(commentId)

Delete a comment

Deletes a comment.  A successful response has 204 No Content status and an empty body. 

### Example
```dart
import 'package:todoist_flutter_api/api.dart';
// TODO Configure HTTP Bearer authorization: api_key
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CommentsApi();
final commentId = 56; // int | The ID of the comment to delete.

try {
    api_instance.deleteComment(commentId);
} catch (e) {
    print('Exception when calling CommentsApi->deleteComment: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **commentId** | **int**| The ID of the comment to delete. | 

### Return type

void (empty response body)

### Authorization

[api_key](../README.md#api_key)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllComments**
> List<Comment> getAllComments(projectId, taskId)

Get all comments

Returns a JSON-encoded array of all comments for a given task_id or project_id. Note that one of task_id or project_id arguments is required.  A successful response has 200 OK status and application/json Content-Type. 

### Example
```dart
import 'package:todoist_flutter_api/api.dart';
// TODO Configure HTTP Bearer authorization: api_key
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CommentsApi();
final projectId = projectId_example; // String | ID of the project used to filter comments. task_id or project_id required
final taskId = taskId_example; // String | ID of the task used to filter comments. task_id or project_id required

try {
    final result = api_instance.getAllComments(projectId, taskId);
    print(result);
} catch (e) {
    print('Exception when calling CommentsApi->getAllComments: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**| ID of the project used to filter comments. task_id or project_id required | [optional] 
 **taskId** | **String**| ID of the task used to filter comments. task_id or project_id required | [optional] 

### Return type

[**List<Comment>**](Comment.md)

### Authorization

[api_key](../README.md#api_key)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getComment**
> Comment getComment(commentId)

Get a comment

Returns a single comment as a JSON object.  A successful response has 200 OK status and application/json Content-Type. 

### Example
```dart
import 'package:todoist_flutter_api/api.dart';
// TODO Configure HTTP Bearer authorization: api_key
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CommentsApi();
final commentId = 56; // int | The ID of the comment to retrieve.

try {
    final result = api_instance.getComment(commentId);
    print(result);
} catch (e) {
    print('Exception when calling CommentsApi->getComment: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **commentId** | **int**| The ID of the comment to retrieve. | 

### Return type

[**Comment**](Comment.md)

### Authorization

[api_key](../README.md#api_key)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateComment**
> Comment updateComment(commentId, content)

Update a comment

Updates a comment and returns it as a JSON object.  A successful response has 200 OK status and application/json Content-Type. 

### Example
```dart
import 'package:todoist_flutter_api/api.dart';
// TODO Configure HTTP Bearer authorization: api_key
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken(yourTokenGeneratorFunction);

final api_instance = CommentsApi();
final commentId = commentId_example; // String | The ID of the comment to update.
final content = content_example; // String | New content for the comment. This value may contain markdown-formatted text and hyperlinks.

try {
    final result = api_instance.updateComment(commentId, content);
    print(result);
} catch (e) {
    print('Exception when calling CommentsApi->updateComment: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **commentId** | **String**| The ID of the comment to update. | 
 **content** | **String**| New content for the comment. This value may contain markdown-formatted text and hyperlinks. | 

### Return type

[**Comment**](Comment.md)

### Authorization

[api_key](../README.md#api_key)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

