# flutter_memos_api.api.ResourceServiceApi

## Load the API package
```dart
import 'package:flutter_memos_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**resourceServiceCreateResource**](ResourceServiceApi.md#resourceservicecreateresource) | **POST** /api/v1/resources | CreateResource creates a new resource.
[**resourceServiceDeleteResource**](ResourceServiceApi.md#resourceservicedeleteresource) | **DELETE** /api/v1/{name_3} | DeleteResource deletes a resource by name.
[**resourceServiceGetResource**](ResourceServiceApi.md#resourceservicegetresource) | **GET** /api/v1/{name_3} | GetResource returns a resource by name.
[**resourceServiceGetResourceBinary**](ResourceServiceApi.md#resourceservicegetresourcebinary) | **GET** /file/{name}/{filename} | GetResourceBinary returns a resource binary by name.
[**resourceServiceListResources**](ResourceServiceApi.md#resourceservicelistresources) | **GET** /api/v1/resources | ListResources lists all resources.
[**resourceServiceUpdateResource**](ResourceServiceApi.md#resourceserviceupdateresource) | **PATCH** /api/v1/{resource.name} | UpdateResource updates a resource.


# **resourceServiceCreateResource**
> V1Resource resourceServiceCreateResource(resource)

CreateResource creates a new resource.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = ResourceServiceApi();
final resource = V1Resource(); // V1Resource | 

try {
    final result = api_instance.resourceServiceCreateResource(resource);
    print(result);
} catch (e) {
    print('Exception when calling ResourceServiceApi->resourceServiceCreateResource: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **resource** | [**V1Resource**](V1Resource.md)|  | 

### Return type

[**V1Resource**](V1Resource.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **resourceServiceDeleteResource**
> Object resourceServiceDeleteResource(name3)

DeleteResource deletes a resource by name.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = ResourceServiceApi();
final name3 = name3_example; // String | The name of the resource.

try {
    final result = api_instance.resourceServiceDeleteResource(name3);
    print(result);
} catch (e) {
    print('Exception when calling ResourceServiceApi->resourceServiceDeleteResource: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name3** | **String**| The name of the resource. | 

### Return type

[**Object**](Object.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **resourceServiceGetResource**
> V1Resource resourceServiceGetResource(name3)

GetResource returns a resource by name.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = ResourceServiceApi();
final name3 = name3_example; // String | The name of the resource.

try {
    final result = api_instance.resourceServiceGetResource(name3);
    print(result);
} catch (e) {
    print('Exception when calling ResourceServiceApi->resourceServiceGetResource: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name3** | **String**| The name of the resource. | 

### Return type

[**V1Resource**](V1Resource.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **resourceServiceGetResourceBinary**
> ApiHttpBody resourceServiceGetResourceBinary(name, filename, thumbnail)

GetResourceBinary returns a resource binary by name.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = ResourceServiceApi();
final name = name_example; // String | The name of the resource.
final filename = filename_example; // String | The filename of the resource. Mainly used for downloading.
final thumbnail = true; // bool | A flag indicating if the thumbnail version of the resource should be returned

try {
    final result = api_instance.resourceServiceGetResourceBinary(name, filename, thumbnail);
    print(result);
} catch (e) {
    print('Exception when calling ResourceServiceApi->resourceServiceGetResourceBinary: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**| The name of the resource. | 
 **filename** | **String**| The filename of the resource. Mainly used for downloading. | 
 **thumbnail** | **bool**| A flag indicating if the thumbnail version of the resource should be returned | [optional] 

### Return type

[**ApiHttpBody**](ApiHttpBody.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **resourceServiceListResources**
> V1ListResourcesResponse resourceServiceListResources()

ListResources lists all resources.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = ResourceServiceApi();

try {
    final result = api_instance.resourceServiceListResources();
    print(result);
} catch (e) {
    print('Exception when calling ResourceServiceApi->resourceServiceListResources: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**V1ListResourcesResponse**](V1ListResourcesResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **resourceServiceUpdateResource**
> V1Resource resourceServiceUpdateResource(resourcePeriodName, resource)

UpdateResource updates a resource.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = ResourceServiceApi();
final resourcePeriodName = resourcePeriodName_example; // String | The name of the resource. Format: resources/{resource}, resource is the user defined if or uuid.
final resource = ResourceServiceUpdateResourceRequest(); // ResourceServiceUpdateResourceRequest | 

try {
    final result = api_instance.resourceServiceUpdateResource(resourcePeriodName, resource);
    print(result);
} catch (e) {
    print('Exception when calling ResourceServiceApi->resourceServiceUpdateResource: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **resourcePeriodName** | **String**| The name of the resource. Format: resources/{resource}, resource is the user defined if or uuid. | 
 **resource** | [**ResourceServiceUpdateResourceRequest**](ResourceServiceUpdateResourceRequest.md)|  | 

### Return type

[**V1Resource**](V1Resource.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

