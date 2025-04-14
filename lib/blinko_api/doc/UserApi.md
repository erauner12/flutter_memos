# todoist_blinko_api.api.UserApi

## Load the API package
```dart
import 'package:todoist_blinko_api/api.dart';
```

All URIs are relative to */api*

Method | HTTP request | Description
------------- | ------------- | -------------
[**usersCanRegister**](UserApi.md#userscanregister) | **POST** /v1/user/can-register | Check if can register admin
[**usersDeleteUser**](UserApi.md#usersdeleteuser) | **DELETE** /v1/user/delete | Delete user
[**usersDetail**](UserApi.md#usersdetail) | **GET** /v1/user/detail | Find user detail from user id
[**usersGenLowPermToken**](UserApi.md#usersgenlowpermtoken) | **POST** /v1/user/gen-low-perm-token | Generate low permission token
[**usersLinkAccount**](UserApi.md#userslinkaccount) | **POST** /v1/user/link-account | Link account
[**usersList**](UserApi.md#userslist) | **GET** /v1/user/list | Find user list
[**usersLogin**](UserApi.md#userslogin) | **POST** /v1/user/login | user login
[**usersNativeAccountList**](UserApi.md#usersnativeaccountlist) | **GET** /v1/user/native-account-list | Find native account list
[**usersPublicUserList**](UserApi.md#userspublicuserlist) | **GET** /v1/user/public-user-list | Find public user list
[**usersRegenToken**](UserApi.md#usersregentoken) | **POST** /v1/user/regen-token | Regen token
[**usersRegister**](UserApi.md#usersregister) | **POST** /v1/user/register | Register user or admin
[**usersUnlinkAccount**](UserApi.md#usersunlinkaccount) | **POST** /v1/user/unlink-account | Unlink account
[**usersUpsertUser**](UserApi.md#usersupsertuser) | **POST** /v1/user/upsert | Update or create user
[**usersUpsertUserByAdmin**](UserApi.md#usersupsertuserbyadmin) | **POST** /v1/user/upsert-by-admin | Update or create user by admin


# **usersCanRegister**
> bool usersCanRegister()

Check if can register admin

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = UserApi();

try {
    final result = api_instance.usersCanRegister();
    print(result);
} catch (e) {
    print('Exception when calling UserApi->usersCanRegister: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**bool**

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **usersDeleteUser**
> bool usersDeleteUser(id)

Delete user

Delete user and all related data, need super admin permission

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = UserApi();
final id = 8.14; // num | 

try {
    final result = api_instance.usersDeleteUser(id);
    print(result);
} catch (e) {
    print('Exception when calling UserApi->usersDeleteUser: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **num**|  | 

### Return type

**bool**

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **usersDetail**
> UsersDetail200Response usersDetail(id)

Find user detail from user id

Find user detail from user id, need login

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = UserApi();
final id = 8.14; // num | 

try {
    final result = api_instance.usersDetail(id);
    print(result);
} catch (e) {
    print('Exception when calling UserApi->usersDetail: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **num**|  | [optional] 

### Return type

[**UsersDetail200Response**](UsersDetail200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **usersGenLowPermToken**
> UsersGenLowPermToken200Response usersGenLowPermToken()

Generate low permission token

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = UserApi();

try {
    final result = api_instance.usersGenLowPermToken();
    print(result);
} catch (e) {
    print('Exception when calling UserApi->usersGenLowPermToken: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**UsersGenLowPermToken200Response**](UsersGenLowPermToken200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **usersLinkAccount**
> bool usersLinkAccount(usersLinkAccountRequest)

Link account

Link account

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = UserApi();
final usersLinkAccountRequest = UsersLinkAccountRequest(); // UsersLinkAccountRequest | 

try {
    final result = api_instance.usersLinkAccount(usersLinkAccountRequest);
    print(result);
} catch (e) {
    print('Exception when calling UserApi->usersLinkAccount: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **usersLinkAccountRequest** | [**UsersLinkAccountRequest**](UsersLinkAccountRequest.md)|  | 

### Return type

**bool**

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **usersList**
> List<UsersList200ResponseInner> usersList()

Find user list

Find user list, need super admin permission

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = UserApi();

try {
    final result = api_instance.usersList();
    print(result);
} catch (e) {
    print('Exception when calling UserApi->usersList: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<UsersList200ResponseInner>**](UsersList200ResponseInner.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **usersLogin**
> UsersLogin200Response usersLogin(usersRegisterRequest)

user login

user login, return user basic info and token

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = UserApi();
final usersRegisterRequest = UsersRegisterRequest(); // UsersRegisterRequest | 

try {
    final result = api_instance.usersLogin(usersRegisterRequest);
    print(result);
} catch (e) {
    print('Exception when calling UserApi->usersLogin: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **usersRegisterRequest** | [**UsersRegisterRequest**](UsersRegisterRequest.md)|  | 

### Return type

[**UsersLogin200Response**](UsersLogin200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **usersNativeAccountList**
> List<UsersNativeAccountList200ResponseInner> usersNativeAccountList()

Find native account list

find native account list which use username and password to login

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = UserApi();

try {
    final result = api_instance.usersNativeAccountList();
    print(result);
} catch (e) {
    print('Exception when calling UserApi->usersNativeAccountList: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<UsersNativeAccountList200ResponseInner>**](UsersNativeAccountList200ResponseInner.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **usersPublicUserList**
> List<UsersPublicUserList200ResponseInner> usersPublicUserList()

Find public user list

Find public user list without admin permission

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = UserApi();

try {
    final result = api_instance.usersPublicUserList();
    print(result);
} catch (e) {
    print('Exception when calling UserApi->usersPublicUserList: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<UsersPublicUserList200ResponseInner>**](UsersPublicUserList200ResponseInner.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **usersRegenToken**
> bool usersRegenToken()

Regen token

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = UserApi();

try {
    final result = api_instance.usersRegenToken();
    print(result);
} catch (e) {
    print('Exception when calling UserApi->usersRegenToken: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**bool**

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **usersRegister**
> bool usersRegister(usersRegisterRequest)

Register user or admin

Register user or admin

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = UserApi();
final usersRegisterRequest = UsersRegisterRequest(); // UsersRegisterRequest | 

try {
    final result = api_instance.usersRegister(usersRegisterRequest);
    print(result);
} catch (e) {
    print('Exception when calling UserApi->usersRegister: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **usersRegisterRequest** | [**UsersRegisterRequest**](UsersRegisterRequest.md)|  | 

### Return type

**bool**

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **usersUnlinkAccount**
> bool usersUnlinkAccount(notesDetailRequest)

Unlink account

Unlink account

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = UserApi();
final notesDetailRequest = NotesDetailRequest(); // NotesDetailRequest | 

try {
    final result = api_instance.usersUnlinkAccount(notesDetailRequest);
    print(result);
} catch (e) {
    print('Exception when calling UserApi->usersUnlinkAccount: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **notesDetailRequest** | [**NotesDetailRequest**](NotesDetailRequest.md)|  | 

### Return type

**bool**

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **usersUpsertUser**
> bool usersUpsertUser(usersUpsertUserRequest)

Update or create user

Update or create user, need login

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = UserApi();
final usersUpsertUserRequest = UsersUpsertUserRequest(); // UsersUpsertUserRequest | 

try {
    final result = api_instance.usersUpsertUser(usersUpsertUserRequest);
    print(result);
} catch (e) {
    print('Exception when calling UserApi->usersUpsertUser: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **usersUpsertUserRequest** | [**UsersUpsertUserRequest**](UsersUpsertUserRequest.md)|  | 

### Return type

**bool**

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **usersUpsertUserByAdmin**
> bool usersUpsertUserByAdmin(usersUpsertUserByAdminRequest)

Update or create user by admin

Update or create user by admin, need super admin permission

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = UserApi();
final usersUpsertUserByAdminRequest = UsersUpsertUserByAdminRequest(); // UsersUpsertUserByAdminRequest | 

try {
    final result = api_instance.usersUpsertUserByAdmin(usersUpsertUserByAdminRequest);
    print(result);
} catch (e) {
    print('Exception when calling UserApi->usersUpsertUserByAdmin: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **usersUpsertUserByAdminRequest** | [**UsersUpsertUserByAdminRequest**](UsersUpsertUserByAdminRequest.md)|  | 

### Return type

**bool**

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

