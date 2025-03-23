# flutter_memos_api.api.UserServiceApi

## Load the API package
```dart
import 'package:flutter_memos_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**userServiceCreateShortcut**](UserServiceApi.md#userservicecreateshortcut) | **POST** /api/v1/{parent}/shortcuts | CreateShortcut creates a new shortcut for a user.
[**userServiceCreateUser**](UserServiceApi.md#userservicecreateuser) | **POST** /api/v1/users | CreateUser creates a new user.
[**userServiceCreateUserAccessToken**](UserServiceApi.md#userservicecreateuseraccesstoken) | **POST** /api/v1/{name}/access_tokens | CreateUserAccessToken creates a new access token for a user.
[**userServiceDeleteShortcut**](UserServiceApi.md#userservicedeleteshortcut) | **DELETE** /api/v1/{parent}/shortcuts/{id} | DeleteShortcut deletes a shortcut for a user.
[**userServiceDeleteUser**](UserServiceApi.md#userservicedeleteuser) | **DELETE** /api/v1/{name} | DeleteUser deletes a user.
[**userServiceDeleteUserAccessToken**](UserServiceApi.md#userservicedeleteuseraccesstoken) | **DELETE** /api/v1/{name}/access_tokens/{accessToken} | DeleteUserAccessToken deletes an access token for a user.
[**userServiceGetUser**](UserServiceApi.md#userservicegetuser) | **GET** /api/v1/{name_1} | GetUser gets a user by name.
[**userServiceGetUserAvatarBinary**](UserServiceApi.md#userservicegetuseravatarbinary) | **GET** /file/{name}/avatar | GetUserAvatarBinary gets the avatar of a user.
[**userServiceGetUserByUsername**](UserServiceApi.md#userservicegetuserbyusername) | **GET** /api/v1/users:username | GetUserByUsername gets a user by username.
[**userServiceGetUserSetting**](UserServiceApi.md#userservicegetusersetting) | **GET** /api/v1/{name}/setting | GetUserSetting gets the setting of a user.
[**userServiceGetUserStats**](UserServiceApi.md#userservicegetuserstats) | **GET** /api/v1/{name}/stats | GetUserStats returns the stats of a user.
[**userServiceListAllUserStats**](UserServiceApi.md#userservicelistalluserstats) | **POST** /api/v1/users/-/stats | ListAllUserStats returns all user stats.
[**userServiceListShortcuts**](UserServiceApi.md#userservicelistshortcuts) | **GET** /api/v1/{parent}/shortcuts | ListShortcuts returns a list of shortcuts for a user.
[**userServiceListUserAccessTokens**](UserServiceApi.md#userservicelistuseraccesstokens) | **GET** /api/v1/{name}/access_tokens | ListUserAccessTokens returns a list of access tokens for a user.
[**userServiceListUsers**](UserServiceApi.md#userservicelistusers) | **GET** /api/v1/users | ListUsers returns a list of users.
[**userServiceUpdateShortcut**](UserServiceApi.md#userserviceupdateshortcut) | **PATCH** /api/v1/{parent}/shortcuts/{shortcut.id} | UpdateShortcut updates a shortcut for a user.
[**userServiceUpdateUser**](UserServiceApi.md#userserviceupdateuser) | **PATCH** /api/v1/{user.name} | UpdateUser updates a user.
[**userServiceUpdateUserSetting**](UserServiceApi.md#userserviceupdateusersetting) | **PATCH** /api/v1/{setting.name} | UpdateUserSetting updates the setting of a user.


# **userServiceCreateShortcut**
> Apiv1Shortcut userServiceCreateShortcut(parent, shortcut, validateOnly)

CreateShortcut creates a new shortcut for a user.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = UserServiceApi();
final parent = parent_example; // String | The name of the user.
final shortcut = Apiv1Shortcut(); // Apiv1Shortcut | 
final validateOnly = true; // bool | 

try {
    final result = api_instance.userServiceCreateShortcut(parent, shortcut, validateOnly);
    print(result);
} catch (e) {
    print('Exception when calling UserServiceApi->userServiceCreateShortcut: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **parent** | **String**| The name of the user. | 
 **shortcut** | [**Apiv1Shortcut**](Apiv1Shortcut.md)|  | 
 **validateOnly** | **bool**|  | [optional] 

### Return type

[**Apiv1Shortcut**](Apiv1Shortcut.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **userServiceCreateUser**
> V1User userServiceCreateUser(user)

CreateUser creates a new user.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = UserServiceApi();
final user = V1User(); // V1User | 

try {
    final result = api_instance.userServiceCreateUser(user);
    print(result);
} catch (e) {
    print('Exception when calling UserServiceApi->userServiceCreateUser: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **user** | [**V1User**](V1User.md)|  | 

### Return type

[**V1User**](V1User.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **userServiceCreateUserAccessToken**
> V1UserAccessToken userServiceCreateUserAccessToken(name, body)

CreateUserAccessToken creates a new access token for a user.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = UserServiceApi();
final name = name_example; // String | The name of the user.
final body = UserServiceCreateUserAccessTokenBody(); // UserServiceCreateUserAccessTokenBody | 

try {
    final result = api_instance.userServiceCreateUserAccessToken(name, body);
    print(result);
} catch (e) {
    print('Exception when calling UserServiceApi->userServiceCreateUserAccessToken: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**| The name of the user. | 
 **body** | [**UserServiceCreateUserAccessTokenBody**](UserServiceCreateUserAccessTokenBody.md)|  | 

### Return type

[**V1UserAccessToken**](V1UserAccessToken.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **userServiceDeleteShortcut**
> Object userServiceDeleteShortcut(parent, id)

DeleteShortcut deletes a shortcut for a user.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = UserServiceApi();
final parent = parent_example; // String | The name of the user.
final id = id_example; // String | The id of the shortcut.

try {
    final result = api_instance.userServiceDeleteShortcut(parent, id);
    print(result);
} catch (e) {
    print('Exception when calling UserServiceApi->userServiceDeleteShortcut: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **parent** | **String**| The name of the user. | 
 **id** | **String**| The id of the shortcut. | 

### Return type

[**Object**](Object.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **userServiceDeleteUser**
> Object userServiceDeleteUser(name)

DeleteUser deletes a user.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = UserServiceApi();
final name = name_example; // String | The name of the user.

try {
    final result = api_instance.userServiceDeleteUser(name);
    print(result);
} catch (e) {
    print('Exception when calling UserServiceApi->userServiceDeleteUser: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**| The name of the user. | 

### Return type

[**Object**](Object.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **userServiceDeleteUserAccessToken**
> Object userServiceDeleteUserAccessToken(name, accessToken)

DeleteUserAccessToken deletes an access token for a user.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = UserServiceApi();
final name = name_example; // String | The name of the user.
final accessToken = accessToken_example; // String | access_token is the access token to delete.

try {
    final result = api_instance.userServiceDeleteUserAccessToken(name, accessToken);
    print(result);
} catch (e) {
    print('Exception when calling UserServiceApi->userServiceDeleteUserAccessToken: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**| The name of the user. | 
 **accessToken** | **String**| access_token is the access token to delete. | 

### Return type

[**Object**](Object.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **userServiceGetUser**
> V1User userServiceGetUser(name1)

GetUser gets a user by name.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = UserServiceApi();
final name1 = name1_example; // String | The name of the user.

try {
    final result = api_instance.userServiceGetUser(name1);
    print(result);
} catch (e) {
    print('Exception when calling UserServiceApi->userServiceGetUser: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name1** | **String**| The name of the user. | 

### Return type

[**V1User**](V1User.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **userServiceGetUserAvatarBinary**
> ApiHttpBody userServiceGetUserAvatarBinary(name, httpBodyPeriodContentType, httpBodyPeriodData)

GetUserAvatarBinary gets the avatar of a user.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = UserServiceApi();
final name = name_example; // String | The name of the user.
final httpBodyPeriodContentType = httpBodyPeriodContentType_example; // String | The HTTP Content-Type header value specifying the content type of the body.
final httpBodyPeriodData = BYTE_ARRAY_DATA_HERE; // String | The HTTP request/response body as raw binary.

try {
    final result = api_instance.userServiceGetUserAvatarBinary(name, httpBodyPeriodContentType, httpBodyPeriodData);
    print(result);
} catch (e) {
    print('Exception when calling UserServiceApi->userServiceGetUserAvatarBinary: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**| The name of the user. | 
 **httpBodyPeriodContentType** | **String**| The HTTP Content-Type header value specifying the content type of the body. | [optional] 
 **httpBodyPeriodData** | **String**| The HTTP request/response body as raw binary. | [optional] 

### Return type

[**ApiHttpBody**](ApiHttpBody.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **userServiceGetUserByUsername**
> V1User userServiceGetUserByUsername(username)

GetUserByUsername gets a user by username.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = UserServiceApi();
final username = username_example; // String | The username of the user.

try {
    final result = api_instance.userServiceGetUserByUsername(username);
    print(result);
} catch (e) {
    print('Exception when calling UserServiceApi->userServiceGetUserByUsername: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **username** | **String**| The username of the user. | [optional] 

### Return type

[**V1User**](V1User.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **userServiceGetUserSetting**
> Apiv1UserSetting userServiceGetUserSetting(name)

GetUserSetting gets the setting of a user.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = UserServiceApi();
final name = name_example; // String | The name of the user.

try {
    final result = api_instance.userServiceGetUserSetting(name);
    print(result);
} catch (e) {
    print('Exception when calling UserServiceApi->userServiceGetUserSetting: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**| The name of the user. | 

### Return type

[**Apiv1UserSetting**](Apiv1UserSetting.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **userServiceGetUserStats**
> V1UserStats userServiceGetUserStats(name)

GetUserStats returns the stats of a user.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = UserServiceApi();
final name = name_example; // String | The name of the user.

try {
    final result = api_instance.userServiceGetUserStats(name);
    print(result);
} catch (e) {
    print('Exception when calling UserServiceApi->userServiceGetUserStats: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**| The name of the user. | 

### Return type

[**V1UserStats**](V1UserStats.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **userServiceListAllUserStats**
> V1ListAllUserStatsResponse userServiceListAllUserStats()

ListAllUserStats returns all user stats.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = UserServiceApi();

try {
    final result = api_instance.userServiceListAllUserStats();
    print(result);
} catch (e) {
    print('Exception when calling UserServiceApi->userServiceListAllUserStats: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**V1ListAllUserStatsResponse**](V1ListAllUserStatsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **userServiceListShortcuts**
> V1ListShortcutsResponse userServiceListShortcuts(parent)

ListShortcuts returns a list of shortcuts for a user.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = UserServiceApi();
final parent = parent_example; // String | The name of the user.

try {
    final result = api_instance.userServiceListShortcuts(parent);
    print(result);
} catch (e) {
    print('Exception when calling UserServiceApi->userServiceListShortcuts: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **parent** | **String**| The name of the user. | 

### Return type

[**V1ListShortcutsResponse**](V1ListShortcutsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **userServiceListUserAccessTokens**
> V1ListUserAccessTokensResponse userServiceListUserAccessTokens(name)

ListUserAccessTokens returns a list of access tokens for a user.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = UserServiceApi();
final name = name_example; // String | The name of the user.

try {
    final result = api_instance.userServiceListUserAccessTokens(name);
    print(result);
} catch (e) {
    print('Exception when calling UserServiceApi->userServiceListUserAccessTokens: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**| The name of the user. | 

### Return type

[**V1ListUserAccessTokensResponse**](V1ListUserAccessTokensResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **userServiceListUsers**
> V1ListUsersResponse userServiceListUsers()

ListUsers returns a list of users.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = UserServiceApi();

try {
    final result = api_instance.userServiceListUsers();
    print(result);
} catch (e) {
    print('Exception when calling UserServiceApi->userServiceListUsers: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**V1ListUsersResponse**](V1ListUsersResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **userServiceUpdateShortcut**
> Apiv1Shortcut userServiceUpdateShortcut(parent, shortcutPeriodId, shortcut)

UpdateShortcut updates a shortcut for a user.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = UserServiceApi();
final parent = parent_example; // String | The name of the user.
final shortcutPeriodId = shortcutPeriodId_example; // String | 
final shortcut = UserServiceUpdateShortcutRequest(); // UserServiceUpdateShortcutRequest | 

try {
    final result = api_instance.userServiceUpdateShortcut(parent, shortcutPeriodId, shortcut);
    print(result);
} catch (e) {
    print('Exception when calling UserServiceApi->userServiceUpdateShortcut: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **parent** | **String**| The name of the user. | 
 **shortcutPeriodId** | **String**|  | 
 **shortcut** | [**UserServiceUpdateShortcutRequest**](UserServiceUpdateShortcutRequest.md)|  | 

### Return type

[**Apiv1Shortcut**](Apiv1Shortcut.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **userServiceUpdateUser**
> V1User userServiceUpdateUser(userPeriodName, user)

UpdateUser updates a user.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = UserServiceApi();
final userPeriodName = userPeriodName_example; // String | The name of the user.  Format: users/{id}, id is the system generated auto-incremented id.
final user = UserServiceUpdateUserRequest(); // UserServiceUpdateUserRequest | 

try {
    final result = api_instance.userServiceUpdateUser(userPeriodName, user);
    print(result);
} catch (e) {
    print('Exception when calling UserServiceApi->userServiceUpdateUser: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userPeriodName** | **String**| The name of the user.  Format: users/{id}, id is the system generated auto-incremented id. | 
 **user** | [**UserServiceUpdateUserRequest**](UserServiceUpdateUserRequest.md)|  | 

### Return type

[**V1User**](V1User.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **userServiceUpdateUserSetting**
> Apiv1UserSetting userServiceUpdateUserSetting(settingPeriodName, setting)

UpdateUserSetting updates the setting of a user.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = UserServiceApi();
final settingPeriodName = settingPeriodName_example; // String | The name of the user.
final setting = UserServiceUpdateUserSettingRequest(); // UserServiceUpdateUserSettingRequest | 

try {
    final result = api_instance.userServiceUpdateUserSetting(settingPeriodName, setting);
    print(result);
} catch (e) {
    print('Exception when calling UserServiceApi->userServiceUpdateUserSetting: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **settingPeriodName** | **String**| The name of the user. | 
 **setting** | [**UserServiceUpdateUserSettingRequest**](UserServiceUpdateUserSettingRequest.md)|  | 

### Return type

[**Apiv1UserSetting**](Apiv1UserSetting.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

