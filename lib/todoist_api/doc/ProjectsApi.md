# todoist_flutter_api.api.ProjectsApi

## Load the API package
```dart
import 'package:todoist_flutter_api/api.dart';
```

All URIs are relative to *https://api.todoist.com/rest/v2*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createProject**](ProjectsApi.md#createproject) | **POST** /projects | Create a new project
[**deleteProject**](ProjectsApi.md#deleteproject) | **DELETE** /projects/{projectId} | Delete a project
[**getAllCollaborators**](ProjectsApi.md#getallcollaborators) | **GET** /projects/{projectId}/collaborators | Get all project collaborators
[**getAllProjects**](ProjectsApi.md#getallprojects) | **GET** /projects | Get all projects
[**getProject**](ProjectsApi.md#getproject) | **GET** /projects/{projectId} | Get a project
[**updateProject**](ProjectsApi.md#updateproject) | **POST** /projects/{projectId} | Update a project


# **createProject**
> Project createProject(name, parentId, color, isFavorite, viewStyle)

Create a new project

Creates a new project and returns it as a JSON object.  A successful response has 200 OK status and application/json Content-Type. 

### Example
```dart
import 'package:todoist_flutter_api/api.dart';
// TODO Configure HTTP Bearer authorization: api_key
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ProjectsApi();
final name = name_example; // String | Name of the project
final parentId = parentId_example; // String | Parent project ID
final color = color_example; // String | The color of the project icon. Refer to the name column in the Colors guide for more info. https://developer.todoist.com/guides/#colors
final isFavorite = true; // bool | Whether the project is a favorite (a true or false value).
final viewStyle = viewStyle_example; // String | A string value (either list or board, default is list). This determines the way the project is displayed within the Todoist clients.

try {
    final result = api_instance.createProject(name, parentId, color, isFavorite, viewStyle);
    print(result);
} catch (e) {
    print('Exception when calling ProjectsApi->createProject: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**| Name of the project | 
 **parentId** | **String**| Parent project ID | [optional] 
 **color** | **String**| The color of the project icon. Refer to the name column in the Colors guide for more info. https://developer.todoist.com/guides/#colors | [optional] 
 **isFavorite** | **bool**| Whether the project is a favorite (a true or false value). | [optional] 
 **viewStyle** | **String**| A string value (either list or board, default is list). This determines the way the project is displayed within the Todoist clients. | [optional] 

### Return type

[**Project**](Project.md)

### Authorization

[api_key](../README.md#api_key)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteProject**
> deleteProject(projectId)

Delete a project

Deletes a project.  A successful response has 204 No Content status and an empty body. 

### Example
```dart
import 'package:todoist_flutter_api/api.dart';
// TODO Configure HTTP Bearer authorization: api_key
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ProjectsApi();
final projectId = projectId_example; // String | Project ID.

try {
    api_instance.deleteProject(projectId);
} catch (e) {
    print('Exception when calling ProjectsApi->deleteProject: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**| Project ID. | 

### Return type

void (empty response body)

### Authorization

[api_key](../README.md#api_key)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllCollaborators**
> List<Collaborator> getAllCollaborators(projectId)

Get all project collaborators

Returns JSON-encoded array containing all collaborators of a shared project.  A successful response has 200 OK status and application/json Content-Type. 

### Example
```dart
import 'package:todoist_flutter_api/api.dart';
// TODO Configure HTTP Bearer authorization: api_key
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ProjectsApi();
final projectId = projectId_example; // String | Project ID.

try {
    final result = api_instance.getAllCollaborators(projectId);
    print(result);
} catch (e) {
    print('Exception when calling ProjectsApi->getAllCollaborators: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**| Project ID. | 

### Return type

[**List<Collaborator>**](Collaborator.md)

### Authorization

[api_key](../README.md#api_key)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllProjects**
> List<Project> getAllProjects()

Get all projects

Returns JSON-encoded array containing all user projects.  A successful response has 200 OK status and application/json Content-Type. 

### Example
```dart
import 'package:todoist_flutter_api/api.dart';
// TODO Configure HTTP Bearer authorization: api_key
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ProjectsApi();

try {
    final result = api_instance.getAllProjects();
    print(result);
} catch (e) {
    print('Exception when calling ProjectsApi->getAllProjects: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<Project>**](Project.md)

### Authorization

[api_key](../README.md#api_key)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getProject**
> Project getProject(projectId)

Get a project

Returns a JSON object containing a project object related to the given ID.  A successful response has 200 OK status and application/json Content-Type. 

### Example
```dart
import 'package:todoist_flutter_api/api.dart';
// TODO Configure HTTP Bearer authorization: api_key
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ProjectsApi();
final projectId = projectId_example; // String | Project ID.

try {
    final result = api_instance.getProject(projectId);
    print(result);
} catch (e) {
    print('Exception when calling ProjectsApi->getProject: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**| Project ID. | 

### Return type

[**Project**](Project.md)

### Authorization

[api_key](../README.md#api_key)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateProject**
> Project updateProject(projectId, name, color, isFavorite, viewStyle)

Update a project

Returns a JSON object containing the updated project object.  A successful response has 200 OK status and application/json Content-Type. 

### Example
```dart
import 'package:todoist_flutter_api/api.dart';
// TODO Configure HTTP Bearer authorization: api_key
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ProjectsApi();
final projectId = projectId_example; // String | Project ID.
final name = name_example; // String | Name of the project
final color = color_example; // String | The color of the project icon. Refer to the name column in the Colors guide for more info. https://developer.todoist.com/guides/#colors
final isFavorite = true; // bool | Whether the project is a favorite (a true or false value).
final viewStyle = viewStyle_example; // String | A string value (either list or board, default is list). This determines the way the project is displayed within the Todoist clients.

try {
    final result = api_instance.updateProject(projectId, name, color, isFavorite, viewStyle);
    print(result);
} catch (e) {
    print('Exception when calling ProjectsApi->updateProject: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**| Project ID. | 
 **name** | **String**| Name of the project | [optional] 
 **color** | **String**| The color of the project icon. Refer to the name column in the Colors guide for more info. https://developer.todoist.com/guides/#colors | [optional] 
 **isFavorite** | **bool**| Whether the project is a favorite (a true or false value). | [optional] 
 **viewStyle** | **String**| A string value (either list or board, default is list). This determines the way the project is displayed within the Todoist clients. | [optional] 

### Return type

[**Project**](Project.md)

### Authorization

[api_key](../README.md#api_key)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

