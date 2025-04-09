# todoist_flutter_api.api.LabelsApi

## Load the API package
```dart
import 'package:todoist_flutter_api/api.dart';
```

All URIs are relative to *https://api.todoist.com/rest/v2*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createPersonalLabel**](LabelsApi.md#createpersonallabel) | **POST** /labels | Create a new personal label
[**deletePersonalLabel**](LabelsApi.md#deletepersonallabel) | **DELETE** /labels/{label_id} | Delete a personal label
[**getAllPersonalLabels**](LabelsApi.md#getallpersonallabels) | **GET** /labels | Get all personal labels
[**getPersonalLabel**](LabelsApi.md#getpersonallabel) | **GET** /labels/{label_id} | Get a personal label
[**updatePersonalLabel**](LabelsApi.md#updatepersonallabel) | **POST** /labels/{label_id} | Update a personal label


# **createPersonalLabel**
> Label createPersonalLabel(name, order, color, isFavorite)

Create a new personal label

Creates a new personal label and returns its object as JSON.  A successful response has 200 OK status and application/json Content-Type. 

### Example
```dart
import 'package:todoist_flutter_api/api.dart';
// TODO Configure HTTP Bearer authorization: api_key
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken(yourTokenGeneratorFunction);

final api_instance = LabelsApi();
final name = name_example; // String | Name of the label.
final order = 56; // int | Label order.
final color = color_example; // String | The color of the label icon. Refer to the name column in the Colors guide for more info.
final isFavorite = true; // bool | Whether the label is a favorite (a true or false value).

try {
    final result = api_instance.createPersonalLabel(name, order, color, isFavorite);
    print(result);
} catch (e) {
    print('Exception when calling LabelsApi->createPersonalLabel: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**| Name of the label. | 
 **order** | **int**| Label order. | [optional] 
 **color** | **String**| The color of the label icon. Refer to the name column in the Colors guide for more info. | [optional] 
 **isFavorite** | **bool**| Whether the label is a favorite (a true or false value). | [optional] 

### Return type

[**Label**](Label.md)

### Authorization

[api_key](../README.md#api_key)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deletePersonalLabel**
> deletePersonalLabel(labelId)

Delete a personal label

Deletes a personal label, all instances of the label will be removed from tasks.  A successful response has 204 No Content status and an empty body. 

### Example
```dart
import 'package:todoist_flutter_api/api.dart';
// TODO Configure HTTP Bearer authorization: api_key
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken(yourTokenGeneratorFunction);

final api_instance = LabelsApi();
final labelId = 56; // int | The ID of the label to delete.

try {
    api_instance.deletePersonalLabel(labelId);
} catch (e) {
    print('Exception when calling LabelsApi->deletePersonalLabel: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **labelId** | **int**| The ID of the label to delete. | 

### Return type

void (empty response body)

### Authorization

[api_key](../README.md#api_key)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllPersonalLabels**
> List<Label> getAllPersonalLabels()

Get all personal labels

Returns a JSON-encoded array containing all user labels.  A successful response has 200 OK status and application/json Content-Type. 

### Example
```dart
import 'package:todoist_flutter_api/api.dart';
// TODO Configure HTTP Bearer authorization: api_key
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken(yourTokenGeneratorFunction);

final api_instance = LabelsApi();

try {
    final result = api_instance.getAllPersonalLabels();
    print(result);
} catch (e) {
    print('Exception when calling LabelsApi->getAllPersonalLabels: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<Label>**](Label.md)

### Authorization

[api_key](../README.md#api_key)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPersonalLabel**
> Label getPersonalLabel(labelId)

Get a personal label

Returns a personal label by ID.  A successful response has 200 OK status and application/json Content-Type. 

### Example
```dart
import 'package:todoist_flutter_api/api.dart';
// TODO Configure HTTP Bearer authorization: api_key
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken(yourTokenGeneratorFunction);

final api_instance = LabelsApi();
final labelId = 56; // int | The ID of the label to retrieve.

try {
    final result = api_instance.getPersonalLabel(labelId);
    print(result);
} catch (e) {
    print('Exception when calling LabelsApi->getPersonalLabel: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **labelId** | **int**| The ID of the label to retrieve. | 

### Return type

[**Label**](Label.md)

### Authorization

[api_key](../README.md#api_key)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updatePersonalLabel**
> Label updatePersonalLabel(labelId, name, order, color, isFavorite)

Update a personal label

Returns the updated label.  A successful response has 200 OK status and application/json Content-Type. 

### Example
```dart
import 'package:todoist_flutter_api/api.dart';
// TODO Configure HTTP Bearer authorization: api_key
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('api_key').setAccessToken(yourTokenGeneratorFunction);

final api_instance = LabelsApi();
final labelId = labelId_example; // String | The ID of the label to update.
final name = name_example; // String | New name of the label.
final order = 56; // int | Number that is used by clients to sort the list of labels.
final color = color_example; // String | The color of the label icon. Refer to the name column in the Colors guide for more info.
final isFavorite = true; // bool | Whether the label is a favorite (a true or false value).

try {
    final result = api_instance.updatePersonalLabel(labelId, name, order, color, isFavorite);
    print(result);
} catch (e) {
    print('Exception when calling LabelsApi->updatePersonalLabel: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **labelId** | **String**| The ID of the label to update. | 
 **name** | **String**| New name of the label. | [optional] 
 **order** | **int**| Number that is used by clients to sort the list of labels. | [optional] 
 **color** | **String**| The color of the label icon. Refer to the name column in the Colors guide for more info. | [optional] 
 **isFavorite** | **bool**| Whether the label is a favorite (a true or false value). | [optional] 

### Return type

[**Label**](Label.md)

### Authorization

[api_key](../README.md#api_key)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

