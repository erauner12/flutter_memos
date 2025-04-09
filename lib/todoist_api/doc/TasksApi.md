# todoist_flutter_api.api.TasksApi

## Load the API package
```dart
import 'package:todoist_flutter_api/api.dart';
```

All URIs are relative to *https://api.todoist.com/rest/v2*

Method | HTTP request | Description
------------- | ------------- | -------------
[**closeTask**](TasksApi.md#closetask) | **POST** /tasks/{taskId}/close | Close a task
[**createTask**](TasksApi.md#createtask) | **POST** /tasks | Create a new task
[**deleteTask**](TasksApi.md#deletetask) | **DELETE** /tasks/{taskId} | Delete a task
[**getActiveTask**](TasksApi.md#getactivetask) | **GET** /tasks/{taskId} | Get an active task
[**getActiveTasks**](TasksApi.md#getactivetasks) | **GET** /tasks | Get active tasks
[**reopenTask**](TasksApi.md#reopentask) | **POST** /tasks/{taskId}/reopen | Reopen a task
[**updateTask**](TasksApi.md#updatetask) | **POST** /tasks/{taskId} | Update a task


# **closeTask**
> closeTask(taskId)

Close a task

Closes a task. Regular tasks are marked complete and moved to history, along with their subtasks. Tasks with recurring due dates will be scheduled to their next occurrence.  A successful response has 204 No Content status and an empty body. 

### Example
```dart
import 'package:todoist_flutter_api/api.dart';
// TODO Configure HTTP Bearer authorization: api_key
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken(yourTokenGeneratorFunction);

final api_instance = TasksApi();
final taskId = 56; // int | The ID of the task to close.

try {
    api_instance.closeTask(taskId);
} catch (e) {
    print('Exception when calling TasksApi->closeTask: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **taskId** | **int**| The ID of the task to close. | 

### Return type

void (empty response body)

### Authorization

[api_key](../README.md#api_key)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createTask**
> Task createTask(createTaskRequest)

Create a new task

Creates a new task and returns it as a JSON object. 

### Example
```dart
import 'package:todoist_flutter_api/api.dart';
// TODO Configure HTTP Bearer authorization: api_key
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken(yourTokenGeneratorFunction);

final api_instance = TasksApi();
final createTaskRequest = CreateTaskRequest(); // CreateTaskRequest | 

try {
    final result = api_instance.createTask(createTaskRequest);
    print(result);
} catch (e) {
    print('Exception when calling TasksApi->createTask: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createTaskRequest** | [**CreateTaskRequest**](CreateTaskRequest.md)|  | 

### Return type

[**Task**](Task.md)

### Authorization

[api_key](../README.md#api_key)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteTask**
> deleteTask(taskId)

Delete a task

Deletes a task.   A successful response has 204 No Content status and an empty body. 

### Example
```dart
import 'package:todoist_flutter_api/api.dart';
// TODO Configure HTTP Bearer authorization: api_key
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken(yourTokenGeneratorFunction);

final api_instance = TasksApi();
final taskId = 56; // int | The ID of the task to delete.

try {
    api_instance.deleteTask(taskId);
} catch (e) {
    print('Exception when calling TasksApi->deleteTask: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **taskId** | **int**| The ID of the task to delete. | 

### Return type

void (empty response body)

### Authorization

[api_key](../README.md#api_key)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getActiveTask**
> Task getActiveTask(taskId)

Get an active task

Returns a single active (non-completed) task by ID as a JSON object.  A successful response has 200 OK status and application/json Content-Type. 

### Example
```dart
import 'package:todoist_flutter_api/api.dart';
// TODO Configure HTTP Bearer authorization: api_key
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken(yourTokenGeneratorFunction);

final api_instance = TasksApi();
final taskId = 56; // int | The ID of the task to retrieve.

try {
    final result = api_instance.getActiveTask(taskId);
    print(result);
} catch (e) {
    print('Exception when calling TasksApi->getActiveTask: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **taskId** | **int**| The ID of the task to retrieve. | 

### Return type

[**Task**](Task.md)

### Authorization

[api_key](../README.md#api_key)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getActiveTasks**
> List<Task> getActiveTasks(projectId, sectionId, label, filter, lang, ids)

Get active tasks

Returns a JSON-encoded array containing all active tasks.  A successful response has 200 OK status and application/json Content-Type. 

### Example
```dart
import 'package:todoist_flutter_api/api.dart';
// TODO Configure HTTP Bearer authorization: api_key
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken(yourTokenGeneratorFunction);

final api_instance = TasksApi();
final projectId = projectId_example; // String | Filter tasks by project ID.
final sectionId = sectionId_example; // String | Filter tasks by section ID.
final label = label_example; // String | Filter tasks by label name.
final filter = filter_example; // String | Filter by any supported filter.
final lang = lang_example; // String | IETF language tag defining what language the filter is written in, if it differs from the default English.
final ids = []; // List<int> | A list of the task IDs to retrieve, this should be a comma-separated list.

try {
    final result = api_instance.getActiveTasks(projectId, sectionId, label, filter, lang, ids);
    print(result);
} catch (e) {
    print('Exception when calling TasksApi->getActiveTasks: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**| Filter tasks by project ID. | [optional] 
 **sectionId** | **String**| Filter tasks by section ID. | [optional] 
 **label** | **String**| Filter tasks by label name. | [optional] 
 **filter** | **String**| Filter by any supported filter. | [optional] 
 **lang** | **String**| IETF language tag defining what language the filter is written in, if it differs from the default English. | [optional] 
 **ids** | [**List<int>**](int.md)| A list of the task IDs to retrieve, this should be a comma-separated list. | [optional] [default to const []]

### Return type

[**List<Task>**](Task.md)

### Authorization

[api_key](../README.md#api_key)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **reopenTask**
> reopenTask(taskId)

Reopen a task

Reopens a task. Any ancestor items or sections will also be marked as uncomplete and restored from history. The reinstated items and sections will appear at the end of the list within their parent, after any previously active items.  A successful response has 204 No Content status... 

### Example
```dart
import 'package:todoist_flutter_api/api.dart';
// TODO Configure HTTP Bearer authorization: api_key
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken(yourTokenGeneratorFunction);

final api_instance = TasksApi();
final taskId = 56; // int | The ID of the task to reopen.

try {
    api_instance.reopenTask(taskId);
} catch (e) {
    print('Exception when calling TasksApi->reopenTask: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **taskId** | **int**| The ID of the task to reopen. | 

### Return type

void (empty response body)

### Authorization

[api_key](../README.md#api_key)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateTask**
> Task updateTask(taskId, updateTaskRequest)

Update a task

Updates a specified task and returns it as a JSON object. 

### Example
```dart
import 'package:todoist_flutter_api/api.dart';
// TODO Configure HTTP Bearer authorization: api_key
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken(yourTokenGeneratorFunction);

final api_instance = TasksApi();
final taskId = taskId_example; // String | The ID of the task to update.
final updateTaskRequest = UpdateTaskRequest(); // UpdateTaskRequest | 

try {
    final result = api_instance.updateTask(taskId, updateTaskRequest);
    print(result);
} catch (e) {
    print('Exception when calling TasksApi->updateTask: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **taskId** | **String**| The ID of the task to update. | 
 **updateTaskRequest** | [**UpdateTaskRequest**](UpdateTaskRequest.md)|  | 

### Return type

[**Task**](Task.md)

### Authorization

[api_key](../README.md#api_key)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

