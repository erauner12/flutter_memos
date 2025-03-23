# flutter_memos_api.api.IdentityProviderServiceApi

## Load the API package
```dart
import 'package:flutter_memos_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**identityProviderServiceCreateIdentityProvider**](IdentityProviderServiceApi.md#identityproviderservicecreateidentityprovider) | **POST** /api/v1/identityProviders | CreateIdentityProvider creates an identity provider.
[**identityProviderServiceDeleteIdentityProvider**](IdentityProviderServiceApi.md#identityproviderservicedeleteidentityprovider) | **DELETE** /api/v1/{name_1} | DeleteIdentityProvider deletes an identity provider.
[**identityProviderServiceGetIdentityProvider**](IdentityProviderServiceApi.md#identityproviderservicegetidentityprovider) | **GET** /api/v1/{name_2} | GetIdentityProvider gets an identity provider.
[**identityProviderServiceListIdentityProviders**](IdentityProviderServiceApi.md#identityproviderservicelistidentityproviders) | **GET** /api/v1/identityProviders | ListIdentityProviders lists identity providers.
[**identityProviderServiceUpdateIdentityProvider**](IdentityProviderServiceApi.md#identityproviderserviceupdateidentityprovider) | **PATCH** /api/v1/{identityProvider.name} | UpdateIdentityProvider updates an identity provider.


# **identityProviderServiceCreateIdentityProvider**
> Apiv1IdentityProvider identityProviderServiceCreateIdentityProvider(identityProvider)

CreateIdentityProvider creates an identity provider.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = IdentityProviderServiceApi();
final identityProvider = Apiv1IdentityProvider(); // Apiv1IdentityProvider | The identityProvider to create.

try {
    final result = api_instance.identityProviderServiceCreateIdentityProvider(identityProvider);
    print(result);
} catch (e) {
    print('Exception when calling IdentityProviderServiceApi->identityProviderServiceCreateIdentityProvider: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **identityProvider** | [**Apiv1IdentityProvider**](Apiv1IdentityProvider.md)| The identityProvider to create. | 

### Return type

[**Apiv1IdentityProvider**](Apiv1IdentityProvider.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **identityProviderServiceDeleteIdentityProvider**
> Object identityProviderServiceDeleteIdentityProvider(name1)

DeleteIdentityProvider deletes an identity provider.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = IdentityProviderServiceApi();
final name1 = name1_example; // String | The name of the identityProvider to delete.

try {
    final result = api_instance.identityProviderServiceDeleteIdentityProvider(name1);
    print(result);
} catch (e) {
    print('Exception when calling IdentityProviderServiceApi->identityProviderServiceDeleteIdentityProvider: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name1** | **String**| The name of the identityProvider to delete. | 

### Return type

[**Object**](Object.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **identityProviderServiceGetIdentityProvider**
> Apiv1IdentityProvider identityProviderServiceGetIdentityProvider(name2)

GetIdentityProvider gets an identity provider.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = IdentityProviderServiceApi();
final name2 = name2_example; // String | The name of the identityProvider to get.

try {
    final result = api_instance.identityProviderServiceGetIdentityProvider(name2);
    print(result);
} catch (e) {
    print('Exception when calling IdentityProviderServiceApi->identityProviderServiceGetIdentityProvider: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name2** | **String**| The name of the identityProvider to get. | 

### Return type

[**Apiv1IdentityProvider**](Apiv1IdentityProvider.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **identityProviderServiceListIdentityProviders**
> V1ListIdentityProvidersResponse identityProviderServiceListIdentityProviders()

ListIdentityProviders lists identity providers.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = IdentityProviderServiceApi();

try {
    final result = api_instance.identityProviderServiceListIdentityProviders();
    print(result);
} catch (e) {
    print('Exception when calling IdentityProviderServiceApi->identityProviderServiceListIdentityProviders: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**V1ListIdentityProvidersResponse**](V1ListIdentityProvidersResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **identityProviderServiceUpdateIdentityProvider**
> Apiv1IdentityProvider identityProviderServiceUpdateIdentityProvider(identityProviderPeriodName, identityProvider)

UpdateIdentityProvider updates an identity provider.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = IdentityProviderServiceApi();
final identityProviderPeriodName = identityProviderPeriodName_example; // String | The name of the identityProvider. Format: identityProviders/{id}, id is the system generated auto-incremented id.
final identityProvider = TheIdentityProviderToUpdate(); // TheIdentityProviderToUpdate | The identityProvider to update.

try {
    final result = api_instance.identityProviderServiceUpdateIdentityProvider(identityProviderPeriodName, identityProvider);
    print(result);
} catch (e) {
    print('Exception when calling IdentityProviderServiceApi->identityProviderServiceUpdateIdentityProvider: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **identityProviderPeriodName** | **String**| The name of the identityProvider. Format: identityProviders/{id}, id is the system generated auto-incremented id. | 
 **identityProvider** | [**TheIdentityProviderToUpdate**](TheIdentityProviderToUpdate.md)| The identityProvider to update. | 

### Return type

[**Apiv1IdentityProvider**](Apiv1IdentityProvider.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

