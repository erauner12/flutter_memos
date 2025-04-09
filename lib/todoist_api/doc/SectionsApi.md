# todoist_flutter_api.api.SectionsApi

## Load the API package
```dart
import 'package:todoist_flutter_api/api.dart';
```

All URIs are relative to *https://api.todoist.com/rest/v2*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createSection**](SectionsApi.md#createsection) | **POST** /sections | Create a new section
[**deleteSection**](SectionsApi.md#deletesection) | **DELETE** /sections/{sectionId} | Delete a section
[**getAllSections**](SectionsApi.md#getallsections) | **GET** /sections | Get all sections
[**getSingleSection**](SectionsApi.md#getsinglesection) | **GET** /sections/{sectionId} | Get single section
[**updateSection**](SectionsApi.md#updatesection) | **POST** /sections/{sectionId} | Update a section name


# **createSection**
> Section createSection(projectId, name, order)

Create a new section

Creates a new section and returns it as a JSON object.  A successful response has 200 OK status and application/json Content-Type. 

### Example
```dart
import 'package:todoist_flutter_api/api.dart';
// TODO Configure HTTP Bearer authorization: api_key
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken(yourTokenGeneratorFunction);

final api_instance = SectionsApi();
final projectId = projectId_example; // String | Project ID this section should belong to
final name = name_example; // String | Section name
final order = 56; // int | Order among other sections in a project

try {
    final result = api_instance.createSection(projectId, name, order);
    print(result);
} catch (e) {
    print('Exception when calling SectionsApi->createSection: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**| Project ID this section should belong to | 
 **name** | **String**| Section name | 
 **order** | **int**| Order among other sections in a project | [optional] 

### Return type

[**Section**](Section.md)

### Authorization

[api_key](../README.md#api_key)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteSection**
> deleteSection(sectionId)

Delete a section

Deletes a section.  A successful response has 204 No Content status and an empty body. 

### Example
```dart
import 'package:todoist_flutter_api/api.dart';
// TODO Configure HTTP Bearer authorization: api_key
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken(yourTokenGeneratorFunction);

final api_instance = SectionsApi();
final sectionId = sectionId_example; // String | Section ID.

try {
    api_instance.deleteSection(sectionId);
} catch (e) {
    print('Exception when calling SectionsApi->deleteSection: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **sectionId** | **String**| Section ID. | 

### Return type

void (empty response body)

### Authorization

[api_key](../README.md#api_key)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllSections**
> List<Section> getAllSections(projectId)

Get all sections

Returns a JSON array of all sections.  A successful response has 200 OK status and application/json Content-Type. 

### Example
```dart
import 'package:todoist_flutter_api/api.dart';
// TODO Configure HTTP Bearer authorization: api_key
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken(yourTokenGeneratorFunction);

final api_instance = SectionsApi();
final projectId = projectId_example; // String | Project ID.

try {
    final result = api_instance.getAllSections(projectId);
    print(result);
} catch (e) {
    print('Exception when calling SectionsApi->getAllSections: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**| Project ID. | [optional] 

### Return type

[**List<Section>**](Section.md)

### Authorization

[api_key](../README.md#api_key)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getSingleSection**
> Section getSingleSection(sectionId)

Get single section

Returns a single section as a JSON object.  A successful response has 200 OK status and application/json Content-Type. 

### Example
```dart
import 'package:todoist_flutter_api/api.dart';
// TODO Configure HTTP Bearer authorization: api_key
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken(yourTokenGeneratorFunction);

final api_instance = SectionsApi();
final sectionId = sectionId_example; // String | Section ID.

try {
    final result = api_instance.getSingleSection(sectionId);
    print(result);
} catch (e) {
    print('Exception when calling SectionsApi->getSingleSection: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **sectionId** | **String**| Section ID. | 

### Return type

[**Section**](Section.md)

### Authorization

[api_key](../README.md#api_key)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateSection**
> Section updateSection(sectionId, name)

Update a section name

Returns the updated section as a JSON object.  A successful response has 200 OK status and application/json Content-Type. 

### Example
```dart
import 'package:todoist_flutter_api/api.dart';
// TODO Configure HTTP Bearer authorization: api_key
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken(yourTokenGeneratorFunction);

final api_instance = SectionsApi();
final sectionId = sectionId_example; // String | Section ID.
final name = name_example; // String | Section name.

try {
    final result = api_instance.updateSection(sectionId, name);
    print(result);
} catch (e) {
    print('Exception when calling SectionsApi->updateSection: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **sectionId** | **String**| Section ID. | 
 **name** | **String**| Section name. | 

### Return type

[**Section**](Section.md)

### Authorization

[api_key](../README.md#api_key)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

