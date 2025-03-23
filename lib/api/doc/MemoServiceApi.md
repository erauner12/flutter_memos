# flutter_memos_api.api.MemoServiceApi

## Load the API package
```dart
import 'package:flutter_memos_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**memoServiceCreateMemo**](MemoServiceApi.md#memoservicecreatememo) | **POST** /api/v1/memos | CreateMemo creates a memo.
[**memoServiceCreateMemoComment**](MemoServiceApi.md#memoservicecreatememocomment) | **POST** /api/v1/{name}/comments | CreateMemoComment creates a comment for a memo.
[**memoServiceDeleteMemo**](MemoServiceApi.md#memoservicedeletememo) | **DELETE** /api/v1/{name_4} | DeleteMemo deletes a memo.
[**memoServiceDeleteMemoReaction**](MemoServiceApi.md#memoservicedeletememoreaction) | **DELETE** /api/v1/reactions/{id} | DeleteMemoReaction deletes a reaction for a memo.
[**memoServiceDeleteMemoTag**](MemoServiceApi.md#memoservicedeletememotag) | **DELETE** /api/v1/{parent}/tags/{tag} | DeleteMemoTag deletes a tag for a memo.
[**memoServiceGetMemo**](MemoServiceApi.md#memoservicegetmemo) | **GET** /api/v1/{name_4} | GetMemo gets a memo.
[**memoServiceListMemoComments**](MemoServiceApi.md#memoservicelistmemocomments) | **GET** /api/v1/{name}/comments | ListMemoComments lists comments for a memo.
[**memoServiceListMemoReactions**](MemoServiceApi.md#memoservicelistmemoreactions) | **GET** /api/v1/{name}/reactions | ListMemoReactions lists reactions for a memo.
[**memoServiceListMemoRelations**](MemoServiceApi.md#memoservicelistmemorelations) | **GET** /api/v1/{name}/relations | ListMemoRelations lists relations for a memo.
[**memoServiceListMemoResources**](MemoServiceApi.md#memoservicelistmemoresources) | **GET** /api/v1/{name}/resources | ListMemoResources lists resources for a memo.
[**memoServiceListMemos**](MemoServiceApi.md#memoservicelistmemos) | **GET** /api/v1/memos | ListMemos lists memos with pagination and filter.
[**memoServiceListMemos2**](MemoServiceApi.md#memoservicelistmemos2) | **GET** /api/v1/{parent}/memos | ListMemos lists memos with pagination and filter.
[**memoServiceRenameMemoTag**](MemoServiceApi.md#memoservicerenamememotag) | **PATCH** /api/v1/{parent}/tags:rename | RenameMemoTag renames a tag for a memo.
[**memoServiceSetMemoRelations**](MemoServiceApi.md#memoservicesetmemorelations) | **PATCH** /api/v1/{name}/relations | SetMemoRelations sets relations for a memo.
[**memoServiceSetMemoResources**](MemoServiceApi.md#memoservicesetmemoresources) | **PATCH** /api/v1/{name}/resources | SetMemoResources sets resources for a memo.
[**memoServiceUpdateMemo**](MemoServiceApi.md#memoserviceupdatememo) | **PATCH** /api/v1/{memo.name} | UpdateMemo updates a memo.
[**memoServiceUpsertMemoReaction**](MemoServiceApi.md#memoserviceupsertmemoreaction) | **POST** /api/v1/{name}/reactions | UpsertMemoReaction upserts a reaction for a memo.


# **memoServiceCreateMemo**
> Apiv1Memo memoServiceCreateMemo(memo)

CreateMemo creates a memo.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = MemoServiceApi();
final memo = Apiv1Memo(); // Apiv1Memo | The memo to create.

try {
    final result = api_instance.memoServiceCreateMemo(memo);
    print(result);
} catch (e) {
    print('Exception when calling MemoServiceApi->memoServiceCreateMemo: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **memo** | [**Apiv1Memo**](Apiv1Memo.md)| The memo to create. | 

### Return type

[**Apiv1Memo**](Apiv1Memo.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **memoServiceCreateMemoComment**
> Apiv1Memo memoServiceCreateMemoComment(name, comment)

CreateMemoComment creates a comment for a memo.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = MemoServiceApi();
final name = name_example; // String | The name of the memo.
final comment = Apiv1Memo(); // Apiv1Memo | The comment to create.

try {
    final result = api_instance.memoServiceCreateMemoComment(name, comment);
    print(result);
} catch (e) {
    print('Exception when calling MemoServiceApi->memoServiceCreateMemoComment: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**| The name of the memo. | 
 **comment** | [**Apiv1Memo**](Apiv1Memo.md)| The comment to create. | 

### Return type

[**Apiv1Memo**](Apiv1Memo.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **memoServiceDeleteMemo**
> Object memoServiceDeleteMemo(name4)

DeleteMemo deletes a memo.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = MemoServiceApi();
final name4 = name4_example; // String | The name of the memo.

try {
    final result = api_instance.memoServiceDeleteMemo(name4);
    print(result);
} catch (e) {
    print('Exception when calling MemoServiceApi->memoServiceDeleteMemo: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name4** | **String**| The name of the memo. | 

### Return type

[**Object**](Object.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **memoServiceDeleteMemoReaction**
> Object memoServiceDeleteMemoReaction(id)

DeleteMemoReaction deletes a reaction for a memo.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = MemoServiceApi();
final id = 56; // int | The id of the reaction.  Refer to the `Reaction.id`.

try {
    final result = api_instance.memoServiceDeleteMemoReaction(id);
    print(result);
} catch (e) {
    print('Exception when calling MemoServiceApi->memoServiceDeleteMemoReaction: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**| The id of the reaction.  Refer to the `Reaction.id`. | 

### Return type

[**Object**](Object.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **memoServiceDeleteMemoTag**
> Object memoServiceDeleteMemoTag(parent, tag, deleteRelatedMemos)

DeleteMemoTag deletes a tag for a memo.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = MemoServiceApi();
final parent = parent_example; // String | The parent, who owns the tags.  Format: memos/{id}. Use \"memos/-\" to delete all tags.
final tag = tag_example; // String | 
final deleteRelatedMemos = true; // bool | 

try {
    final result = api_instance.memoServiceDeleteMemoTag(parent, tag, deleteRelatedMemos);
    print(result);
} catch (e) {
    print('Exception when calling MemoServiceApi->memoServiceDeleteMemoTag: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **parent** | **String**| The parent, who owns the tags.  Format: memos/{id}. Use \"memos/-\" to delete all tags. | 
 **tag** | **String**|  | 
 **deleteRelatedMemos** | **bool**|  | [optional] 

### Return type

[**Object**](Object.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **memoServiceGetMemo**
> Apiv1Memo memoServiceGetMemo(name4)

GetMemo gets a memo.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = MemoServiceApi();
final name4 = name4_example; // String | The name of the memo.

try {
    final result = api_instance.memoServiceGetMemo(name4);
    print(result);
} catch (e) {
    print('Exception when calling MemoServiceApi->memoServiceGetMemo: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name4** | **String**| The name of the memo. | 

### Return type

[**Apiv1Memo**](Apiv1Memo.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **memoServiceListMemoComments**
> V1ListMemoCommentsResponse memoServiceListMemoComments(name)

ListMemoComments lists comments for a memo.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = MemoServiceApi();
final name = name_example; // String | The name of the memo.

try {
    final result = api_instance.memoServiceListMemoComments(name);
    print(result);
} catch (e) {
    print('Exception when calling MemoServiceApi->memoServiceListMemoComments: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**| The name of the memo. | 

### Return type

[**V1ListMemoCommentsResponse**](V1ListMemoCommentsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **memoServiceListMemoReactions**
> V1ListMemoReactionsResponse memoServiceListMemoReactions(name)

ListMemoReactions lists reactions for a memo.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = MemoServiceApi();
final name = name_example; // String | The name of the memo.

try {
    final result = api_instance.memoServiceListMemoReactions(name);
    print(result);
} catch (e) {
    print('Exception when calling MemoServiceApi->memoServiceListMemoReactions: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**| The name of the memo. | 

### Return type

[**V1ListMemoReactionsResponse**](V1ListMemoReactionsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **memoServiceListMemoRelations**
> V1ListMemoRelationsResponse memoServiceListMemoRelations(name)

ListMemoRelations lists relations for a memo.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = MemoServiceApi();
final name = name_example; // String | The name of the memo.

try {
    final result = api_instance.memoServiceListMemoRelations(name);
    print(result);
} catch (e) {
    print('Exception when calling MemoServiceApi->memoServiceListMemoRelations: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**| The name of the memo. | 

### Return type

[**V1ListMemoRelationsResponse**](V1ListMemoRelationsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **memoServiceListMemoResources**
> V1ListMemoResourcesResponse memoServiceListMemoResources(name)

ListMemoResources lists resources for a memo.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = MemoServiceApi();
final name = name_example; // String | The name of the memo.

try {
    final result = api_instance.memoServiceListMemoResources(name);
    print(result);
} catch (e) {
    print('Exception when calling MemoServiceApi->memoServiceListMemoResources: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**| The name of the memo. | 

### Return type

[**V1ListMemoResourcesResponse**](V1ListMemoResourcesResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **memoServiceListMemos**
> V1ListMemosResponse memoServiceListMemos(parent, pageSize, pageToken, state, sort, direction, filter, oldFilter)

ListMemos lists memos with pagination and filter.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = MemoServiceApi();
final parent = parent_example; // String | The parent is the owner of the memos.  If not specified or `users/-`, it will list all memos.
final pageSize = 56; // int | The maximum number of memos to return.
final pageToken = pageToken_example; // String | A page token, received from a previous `ListMemos` call.  Provide this to retrieve the subsequent page.
final state = state_example; // String | The state of the memos to list.  Default to `NORMAL`. Set to `ARCHIVED` to list archived memos.
final sort = sort_example; // String | What field to sort the results by.  Default to display_time.
final direction = direction_example; // String | The direction to sort the results by.  Default to DESC.
final filter = filter_example; // String | Filter is a CEL expression to filter memos.  Refer to `Shortcut.filter`.
final oldFilter = oldFilter_example; // String | [Deprecated] Old filter contains some specific conditions to filter memos.  Format: \"creator == 'users/{user}' && visibilities == ['PUBLIC', 'PROTECTED']\"

try {
    final result = api_instance.memoServiceListMemos(parent, pageSize, pageToken, state, sort, direction, filter, oldFilter);
    print(result);
} catch (e) {
    print('Exception when calling MemoServiceApi->memoServiceListMemos: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **parent** | **String**| The parent is the owner of the memos.  If not specified or `users/-`, it will list all memos. | [optional] 
 **pageSize** | **int**| The maximum number of memos to return. | [optional] 
 **pageToken** | **String**| A page token, received from a previous `ListMemos` call.  Provide this to retrieve the subsequent page. | [optional] 
 **state** | **String**| The state of the memos to list.  Default to `NORMAL`. Set to `ARCHIVED` to list archived memos. | [optional] [default to 'STATE_UNSPECIFIED']
 **sort** | **String**| What field to sort the results by.  Default to display_time. | [optional] 
 **direction** | **String**| The direction to sort the results by.  Default to DESC. | [optional] [default to 'DIRECTION_UNSPECIFIED']
 **filter** | **String**| Filter is a CEL expression to filter memos.  Refer to `Shortcut.filter`. | [optional] 
 **oldFilter** | **String**| [Deprecated] Old filter contains some specific conditions to filter memos.  Format: \"creator == 'users/{user}' && visibilities == ['PUBLIC', 'PROTECTED']\" | [optional] 

### Return type

[**V1ListMemosResponse**](V1ListMemosResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **memoServiceListMemos2**
> V1ListMemosResponse memoServiceListMemos2(parent, pageSize, pageToken, state, sort, direction, filter, oldFilter)

ListMemos lists memos with pagination and filter.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = MemoServiceApi();
final parent = parent_example; // String | The parent is the owner of the memos.  If not specified or `users/-`, it will list all memos.
final pageSize = 56; // int | The maximum number of memos to return.
final pageToken = pageToken_example; // String | A page token, received from a previous `ListMemos` call.  Provide this to retrieve the subsequent page.
final state = state_example; // String | The state of the memos to list.  Default to `NORMAL`. Set to `ARCHIVED` to list archived memos.
final sort = sort_example; // String | What field to sort the results by.  Default to display_time.
final direction = direction_example; // String | The direction to sort the results by.  Default to DESC.
final filter = filter_example; // String | Filter is a CEL expression to filter memos.  Refer to `Shortcut.filter`.
final oldFilter = oldFilter_example; // String | [Deprecated] Old filter contains some specific conditions to filter memos.  Format: \"creator == 'users/{user}' && visibilities == ['PUBLIC', 'PROTECTED']\"

try {
    final result = api_instance.memoServiceListMemos2(parent, pageSize, pageToken, state, sort, direction, filter, oldFilter);
    print(result);
} catch (e) {
    print('Exception when calling MemoServiceApi->memoServiceListMemos2: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **parent** | **String**| The parent is the owner of the memos.  If not specified or `users/-`, it will list all memos. | 
 **pageSize** | **int**| The maximum number of memos to return. | [optional] 
 **pageToken** | **String**| A page token, received from a previous `ListMemos` call.  Provide this to retrieve the subsequent page. | [optional] 
 **state** | **String**| The state of the memos to list.  Default to `NORMAL`. Set to `ARCHIVED` to list archived memos. | [optional] [default to 'STATE_UNSPECIFIED']
 **sort** | **String**| What field to sort the results by.  Default to display_time. | [optional] 
 **direction** | **String**| The direction to sort the results by.  Default to DESC. | [optional] [default to 'DIRECTION_UNSPECIFIED']
 **filter** | **String**| Filter is a CEL expression to filter memos.  Refer to `Shortcut.filter`. | [optional] 
 **oldFilter** | **String**| [Deprecated] Old filter contains some specific conditions to filter memos.  Format: \"creator == 'users/{user}' && visibilities == ['PUBLIC', 'PROTECTED']\" | [optional] 

### Return type

[**V1ListMemosResponse**](V1ListMemosResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **memoServiceRenameMemoTag**
> Object memoServiceRenameMemoTag(parent, body)

RenameMemoTag renames a tag for a memo.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = MemoServiceApi();
final parent = parent_example; // String | The parent, who owns the tags.  Format: memos/{id}. Use \"memos/-\" to rename all tags.
final body = MemoServiceRenameMemoTagBody(); // MemoServiceRenameMemoTagBody | 

try {
    final result = api_instance.memoServiceRenameMemoTag(parent, body);
    print(result);
} catch (e) {
    print('Exception when calling MemoServiceApi->memoServiceRenameMemoTag: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **parent** | **String**| The parent, who owns the tags.  Format: memos/{id}. Use \"memos/-\" to rename all tags. | 
 **body** | [**MemoServiceRenameMemoTagBody**](MemoServiceRenameMemoTagBody.md)|  | 

### Return type

[**Object**](Object.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **memoServiceSetMemoRelations**
> Object memoServiceSetMemoRelations(name, body)

SetMemoRelations sets relations for a memo.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = MemoServiceApi();
final name = name_example; // String | The name of the memo.
final body = MemoServiceSetMemoRelationsBody(); // MemoServiceSetMemoRelationsBody | 

try {
    final result = api_instance.memoServiceSetMemoRelations(name, body);
    print(result);
} catch (e) {
    print('Exception when calling MemoServiceApi->memoServiceSetMemoRelations: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**| The name of the memo. | 
 **body** | [**MemoServiceSetMemoRelationsBody**](MemoServiceSetMemoRelationsBody.md)|  | 

### Return type

[**Object**](Object.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **memoServiceSetMemoResources**
> Object memoServiceSetMemoResources(name, body)

SetMemoResources sets resources for a memo.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = MemoServiceApi();
final name = name_example; // String | The name of the memo.
final body = MemoServiceSetMemoResourcesBody(); // MemoServiceSetMemoResourcesBody | 

try {
    final result = api_instance.memoServiceSetMemoResources(name, body);
    print(result);
} catch (e) {
    print('Exception when calling MemoServiceApi->memoServiceSetMemoResources: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**| The name of the memo. | 
 **body** | [**MemoServiceSetMemoResourcesBody**](MemoServiceSetMemoResourcesBody.md)|  | 

### Return type

[**Object**](Object.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **memoServiceUpdateMemo**
> Apiv1Memo memoServiceUpdateMemo(memoPeriodName, memo)

UpdateMemo updates a memo.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = MemoServiceApi();
final memoPeriodName = memoPeriodName_example; // String | The name of the memo.  Format: memos/{memo}, memo is the user defined id or uuid.
final memo = TheMemoToUpdateTheNameFieldIsRequired(); // TheMemoToUpdateTheNameFieldIsRequired | The memo to update.  The `name` field is required.

try {
    final result = api_instance.memoServiceUpdateMemo(memoPeriodName, memo);
    print(result);
} catch (e) {
    print('Exception when calling MemoServiceApi->memoServiceUpdateMemo: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **memoPeriodName** | **String**| The name of the memo.  Format: memos/{memo}, memo is the user defined id or uuid. | 
 **memo** | [**TheMemoToUpdateTheNameFieldIsRequired**](TheMemoToUpdateTheNameFieldIsRequired.md)| The memo to update.  The `name` field is required. | 

### Return type

[**Apiv1Memo**](Apiv1Memo.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **memoServiceUpsertMemoReaction**
> V1Reaction memoServiceUpsertMemoReaction(name, body)

UpsertMemoReaction upserts a reaction for a memo.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = MemoServiceApi();
final name = name_example; // String | The name of the memo.
final body = MemoServiceUpsertMemoReactionBody(); // MemoServiceUpsertMemoReactionBody | 

try {
    final result = api_instance.memoServiceUpsertMemoReaction(name, body);
    print(result);
} catch (e) {
    print('Exception when calling MemoServiceApi->memoServiceUpsertMemoReaction: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**| The name of the memo. | 
 **body** | [**MemoServiceUpsertMemoReactionBody**](MemoServiceUpsertMemoReactionBody.md)|  | 

### Return type

[**V1Reaction**](V1Reaction.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

