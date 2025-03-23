# flutter_memos_api.api.AuthServiceApi

## Load the API package
```dart
import 'package:flutter_memos_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**authServiceGetAuthStatus**](AuthServiceApi.md#authservicegetauthstatus) | **POST** /api/v1/auth/status | GetAuthStatus returns the current auth status of the user.
[**authServiceSignIn**](AuthServiceApi.md#authservicesignin) | **POST** /api/v1/auth/signin | SignIn signs in the user with the given username and password.
[**authServiceSignInWithSSO**](AuthServiceApi.md#authservicesigninwithsso) | **POST** /api/v1/auth/signin/sso | SignInWithSSO signs in the user with the given SSO code.
[**authServiceSignOut**](AuthServiceApi.md#authservicesignout) | **POST** /api/v1/auth/signout | SignOut signs out the user.
[**authServiceSignUp**](AuthServiceApi.md#authservicesignup) | **POST** /api/v1/auth/signup | SignUp signs up the user with the given username and password.


# **authServiceGetAuthStatus**
> V1User authServiceGetAuthStatus()

GetAuthStatus returns the current auth status of the user.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = AuthServiceApi();

try {
    final result = api_instance.authServiceGetAuthStatus();
    print(result);
} catch (e) {
    print('Exception when calling AuthServiceApi->authServiceGetAuthStatus: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**V1User**](V1User.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authServiceSignIn**
> V1User authServiceSignIn(username, password, neverExpire)

SignIn signs in the user with the given username and password.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = AuthServiceApi();
final username = username_example; // String | The username to sign in with.
final password = password_example; // String | The password to sign in with.
final neverExpire = true; // bool | Whether the session should never expire.

try {
    final result = api_instance.authServiceSignIn(username, password, neverExpire);
    print(result);
} catch (e) {
    print('Exception when calling AuthServiceApi->authServiceSignIn: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **username** | **String**| The username to sign in with. | [optional] 
 **password** | **String**| The password to sign in with. | [optional] 
 **neverExpire** | **bool**| Whether the session should never expire. | [optional] 

### Return type

[**V1User**](V1User.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authServiceSignInWithSSO**
> V1User authServiceSignInWithSSO(idpId, code, redirectUri)

SignInWithSSO signs in the user with the given SSO code.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = AuthServiceApi();
final idpId = 56; // int | The ID of the SSO provider.
final code = code_example; // String | The code to sign in with.
final redirectUri = redirectUri_example; // String | The redirect URI.

try {
    final result = api_instance.authServiceSignInWithSSO(idpId, code, redirectUri);
    print(result);
} catch (e) {
    print('Exception when calling AuthServiceApi->authServiceSignInWithSSO: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idpId** | **int**| The ID of the SSO provider. | [optional] 
 **code** | **String**| The code to sign in with. | [optional] 
 **redirectUri** | **String**| The redirect URI. | [optional] 

### Return type

[**V1User**](V1User.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authServiceSignOut**
> Object authServiceSignOut()

SignOut signs out the user.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = AuthServiceApi();

try {
    final result = api_instance.authServiceSignOut();
    print(result);
} catch (e) {
    print('Exception when calling AuthServiceApi->authServiceSignOut: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**Object**](Object.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authServiceSignUp**
> V1User authServiceSignUp(username, password)

SignUp signs up the user with the given username and password.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = AuthServiceApi();
final username = username_example; // String | The username to sign up with.
final password = password_example; // String | The password to sign up with.

try {
    final result = api_instance.authServiceSignUp(username, password);
    print(result);
} catch (e) {
    print('Exception when calling AuthServiceApi->authServiceSignUp: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **username** | **String**| The username to sign up with. | [optional] 
 **password** | **String**| The password to sign up with. | [optional] 

### Return type

[**V1User**](V1User.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

