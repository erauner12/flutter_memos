# todoist_blinko_api.api.TagApi

## Load the API package
```dart
import 'package:todoist_blinko_api/api.dart';
```

All URIs are relative to */api*

Method | HTTP request | Description
------------- | ------------- | -------------
[**tagsDeleteOnlyTag**](TagApi.md#tagsdeleteonlytag) | **POST** /v1/tags/delete-only-tag | Only delete tag name
[**tagsDeleteTagWithAllNote**](TagApi.md#tagsdeletetagwithallnote) | **POST** /v1/tags/delete-tag-with-notes | Delete tag and delete notes
[**tagsList**](TagApi.md#tagslist) | **GET** /v1/tags/list | Get user tags
[**tagsUpdateTagIcon**](TagApi.md#tagsupdatetagicon) | **POST** /v1/tags/update-icon | Update tag icon
[**tagsUpdateTagMany**](TagApi.md#tagsupdatetagmany) | **POST** /v1/tags/batch-update | Batch update tags
[**tagsUpdateTagName**](TagApi.md#tagsupdatetagname) | **POST** /v1/tags/update-name | Update tag name


# **tagsDeleteOnlyTag**
> bool tagsDeleteOnlyTag(notesDetailRequest)

Only delete tag name

Only delete tag name and remove tag from notes, but not delete notes

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = TagApi();
final notesDetailRequest = NotesDetailRequest(); // NotesDetailRequest | 

try {
    final result = api_instance.tagsDeleteOnlyTag(notesDetailRequest);
    print(result);
} catch (e) {
    print('Exception when calling TagApi->tagsDeleteOnlyTag: $e\n');
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

# **tagsDeleteTagWithAllNote**
> bool tagsDeleteTagWithAllNote(notesDetailRequest)

Delete tag and delete notes

Delete tag and delete notes

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = TagApi();
final notesDetailRequest = NotesDetailRequest(); // NotesDetailRequest | 

try {
    final result = api_instance.tagsDeleteTagWithAllNote(notesDetailRequest);
    print(result);
} catch (e) {
    print('Exception when calling TagApi->tagsDeleteTagWithAllNote: $e\n');
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

# **tagsList**
> List<NotesList200ResponseInnerTagsInnerTag> tagsList()

Get user tags

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = TagApi();

try {
    final result = api_instance.tagsList();
    print(result);
} catch (e) {
    print('Exception when calling TagApi->tagsList: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<NotesList200ResponseInnerTagsInnerTag>**](NotesList200ResponseInnerTagsInnerTag.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **tagsUpdateTagIcon**
> NotesList200ResponseInnerTagsInnerTag tagsUpdateTagIcon(tagsUpdateTagIconRequest)

Update tag icon

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = TagApi();
final tagsUpdateTagIconRequest = TagsUpdateTagIconRequest(); // TagsUpdateTagIconRequest | 

try {
    final result = api_instance.tagsUpdateTagIcon(tagsUpdateTagIconRequest);
    print(result);
} catch (e) {
    print('Exception when calling TagApi->tagsUpdateTagIcon: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **tagsUpdateTagIconRequest** | [**TagsUpdateTagIconRequest**](TagsUpdateTagIconRequest.md)|  | 

### Return type

[**NotesList200ResponseInnerTagsInnerTag**](NotesList200ResponseInnerTagsInnerTag.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **tagsUpdateTagMany**
> bool tagsUpdateTagMany(tagsUpdateTagManyRequest)

Batch update tags

Batch update tags and add tag to notes

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = TagApi();
final tagsUpdateTagManyRequest = TagsUpdateTagManyRequest(); // TagsUpdateTagManyRequest | 

try {
    final result = api_instance.tagsUpdateTagMany(tagsUpdateTagManyRequest);
    print(result);
} catch (e) {
    print('Exception when calling TagApi->tagsUpdateTagMany: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **tagsUpdateTagManyRequest** | [**TagsUpdateTagManyRequest**](TagsUpdateTagManyRequest.md)|  | 

### Return type

**bool**

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **tagsUpdateTagName**
> bool tagsUpdateTagName(tagsUpdateTagNameRequest)

Update tag name

Update tag name and update tag to notes

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = TagApi();
final tagsUpdateTagNameRequest = TagsUpdateTagNameRequest(); // TagsUpdateTagNameRequest | 

try {
    final result = api_instance.tagsUpdateTagName(tagsUpdateTagNameRequest);
    print(result);
} catch (e) {
    print('Exception when calling TagApi->tagsUpdateTagName: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **tagsUpdateTagNameRequest** | [**TagsUpdateTagNameRequest**](TagsUpdateTagNameRequest.md)|  | 

### Return type

**bool**

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

