# todoist_blinko_api.api.NoteApi

## Load the API package
```dart
import 'package:todoist_blinko_api/api.dart';
```

All URIs are relative to */api*

Method | HTTP request | Description
------------- | ------------- | -------------
[**notesAddReference**](NoteApi.md#notesaddreference) | **POST** /v1/note/add-reference | Add note reference
[**notesClearRecycleBin**](NoteApi.md#notesclearrecyclebin) | **POST** /v1/note/clear-recycle-bin | Clear recycle bin
[**notesDailyReviewNoteList**](NoteApi.md#notesdailyreviewnotelist) | **GET** /v1/note/daily-review-list | Query daily review note list
[**notesDeleteMany**](NoteApi.md#notesdeletemany) | **POST** /v1/note/batch-delete | Batch delete note
[**notesDetail**](NoteApi.md#notesdetail) | **POST** /v1/note/detail | Query note detail
[**notesGetInternalSharedUsers**](NoteApi.md#notesgetinternalsharedusers) | **POST** /v1/note/internal-shared-users | Get users with internal access to note
[**notesGetNoteHistory**](NoteApi.md#notesgetnotehistory) | **GET** /v1/note/history | Get note history
[**notesGetNoteVersion**](NoteApi.md#notesgetnoteversion) | **GET** /v1/note/version | Get specific note version
[**notesInternalShareNote**](NoteApi.md#notesinternalsharenote) | **POST** /v1/note/internal-share | Share note internally
[**notesInternalSharedWithMe**](NoteApi.md#notesinternalsharedwithme) | **POST** /v1/note/shared-with-me | Get notes shared with me
[**notesList**](NoteApi.md#noteslist) | **POST** /v1/note/list | Query notes list
[**notesListByIds**](NoteApi.md#noteslistbyids) | **POST** /v1/note/list-by-ids | Query notes list by ids
[**notesNoteReferenceList**](NoteApi.md#notesnotereferencelist) | **POST** /v1/note/reference-list | Query note references
[**notesPublicDetail**](NoteApi.md#notespublicdetail) | **POST** /v1/note/public-detail | Query share note detail
[**notesPublicList**](NoteApi.md#notespubliclist) | **POST** /v1/note/public-list | Query share notes list
[**notesRandomNoteList**](NoteApi.md#notesrandomnotelist) | **GET** /v1/note/random-list | Query random notes for review
[**notesRelatedNotes**](NoteApi.md#notesrelatednotes) | **GET** /v1/note/related-notes | Query related notes
[**notesReviewNote**](NoteApi.md#notesreviewnote) | **POST** /v1/note/review | Review a note
[**notesShareNote**](NoteApi.md#notessharenote) | **POST** /v1/note/share | Share note
[**notesTrashMany**](NoteApi.md#notestrashmany) | **POST** /v1/note/batch-trash | Batch trash note
[**notesUpdateAttachmentsOrder**](NoteApi.md#notesupdateattachmentsorder) | **POST** /v1/note/update-attachments-order | Update attachments order
[**notesUpdateMany**](NoteApi.md#notesupdatemany) | **POST** /v1/note/batch-update | Batch update note
[**notesUpsert**](NoteApi.md#notesupsert) | **POST** /v1/note/upsert | Update or create note


# **notesAddReference**
> Object notesAddReference(notesAddReferenceRequest)

Add note reference

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NoteApi();
final notesAddReferenceRequest = NotesAddReferenceRequest(); // NotesAddReferenceRequest | 

try {
    final result = api_instance.notesAddReference(notesAddReferenceRequest);
    print(result);
} catch (e) {
    print('Exception when calling NoteApi->notesAddReference: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **notesAddReferenceRequest** | [**NotesAddReferenceRequest**](NotesAddReferenceRequest.md)|  | 

### Return type

[**Object**](Object.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notesClearRecycleBin**
> Object notesClearRecycleBin()

Clear recycle bin

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NoteApi();

try {
    final result = api_instance.notesClearRecycleBin();
    print(result);
} catch (e) {
    print('Exception when calling NoteApi->notesClearRecycleBin: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**Object**](Object.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notesDailyReviewNoteList**
> List<NotesDailyReviewNoteList200ResponseInner> notesDailyReviewNoteList()

Query daily review note list

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NoteApi();

try {
    final result = api_instance.notesDailyReviewNoteList();
    print(result);
} catch (e) {
    print('Exception when calling NoteApi->notesDailyReviewNoteList: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<NotesDailyReviewNoteList200ResponseInner>**](NotesDailyReviewNoteList200ResponseInner.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notesDeleteMany**
> Object notesDeleteMany(notesListByIdsRequest)

Batch delete note

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NoteApi();
final notesListByIdsRequest = NotesListByIdsRequest(); // NotesListByIdsRequest | 

try {
    final result = api_instance.notesDeleteMany(notesListByIdsRequest);
    print(result);
} catch (e) {
    print('Exception when calling NoteApi->notesDeleteMany: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **notesListByIdsRequest** | [**NotesListByIdsRequest**](NotesListByIdsRequest.md)|  | 

### Return type

[**Object**](Object.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notesDetail**
> NotesDetail200Response notesDetail(notesDetailRequest)

Query note detail

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NoteApi();
final notesDetailRequest = NotesDetailRequest(); // NotesDetailRequest | 

try {
    final result = api_instance.notesDetail(notesDetailRequest);
    print(result);
} catch (e) {
    print('Exception when calling NoteApi->notesDetail: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **notesDetailRequest** | [**NotesDetailRequest**](NotesDetailRequest.md)|  | 

### Return type

[**NotesDetail200Response**](NotesDetail200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notesGetInternalSharedUsers**
> List<NotesGetInternalSharedUsers200ResponseInner> notesGetInternalSharedUsers(notesDetailRequest)

Get users with internal access to note

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NoteApi();
final notesDetailRequest = NotesDetailRequest(); // NotesDetailRequest | 

try {
    final result = api_instance.notesGetInternalSharedUsers(notesDetailRequest);
    print(result);
} catch (e) {
    print('Exception when calling NoteApi->notesGetInternalSharedUsers: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **notesDetailRequest** | [**NotesDetailRequest**](NotesDetailRequest.md)|  | 

### Return type

[**List<NotesGetInternalSharedUsers200ResponseInner>**](NotesGetInternalSharedUsers200ResponseInner.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notesGetNoteHistory**
> List<NotesGetNoteHistory200ResponseInner> notesGetNoteHistory(noteId)

Get note history

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NoteApi();
final noteId = 8.14; // num | 

try {
    final result = api_instance.notesGetNoteHistory(noteId);
    print(result);
} catch (e) {
    print('Exception when calling NoteApi->notesGetNoteHistory: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **noteId** | **num**|  | 

### Return type

[**List<NotesGetNoteHistory200ResponseInner>**](NotesGetNoteHistory200ResponseInner.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notesGetNoteVersion**
> NotesGetNoteVersion200Response notesGetNoteVersion(noteId, version)

Get specific note version

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NoteApi();
final noteId = 8.14; // num | 
final version = 8.14; // num | 

try {
    final result = api_instance.notesGetNoteVersion(noteId, version);
    print(result);
} catch (e) {
    print('Exception when calling NoteApi->notesGetNoteVersion: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **noteId** | **num**|  | 
 **version** | **num**|  | [optional] 

### Return type

[**NotesGetNoteVersion200Response**](NotesGetNoteVersion200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notesInternalShareNote**
> NotesInternalShareNote200Response notesInternalShareNote(notesInternalShareNoteRequest)

Share note internally

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NoteApi();
final notesInternalShareNoteRequest = NotesInternalShareNoteRequest(); // NotesInternalShareNoteRequest | 

try {
    final result = api_instance.notesInternalShareNote(notesInternalShareNoteRequest);
    print(result);
} catch (e) {
    print('Exception when calling NoteApi->notesInternalShareNote: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **notesInternalShareNoteRequest** | [**NotesInternalShareNoteRequest**](NotesInternalShareNoteRequest.md)|  | 

### Return type

[**NotesInternalShareNote200Response**](NotesInternalShareNote200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notesInternalSharedWithMe**
> List<NotesInternalSharedWithMe200ResponseInner> notesInternalSharedWithMe(notesInternalSharedWithMeRequest)

Get notes shared with me

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NoteApi();
final notesInternalSharedWithMeRequest = NotesInternalSharedWithMeRequest(); // NotesInternalSharedWithMeRequest | 

try {
    final result = api_instance.notesInternalSharedWithMe(notesInternalSharedWithMeRequest);
    print(result);
} catch (e) {
    print('Exception when calling NoteApi->notesInternalSharedWithMe: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **notesInternalSharedWithMeRequest** | [**NotesInternalSharedWithMeRequest**](NotesInternalSharedWithMeRequest.md)|  | 

### Return type

[**List<NotesInternalSharedWithMe200ResponseInner>**](NotesInternalSharedWithMe200ResponseInner.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notesList**
> List<NotesList200ResponseInner> notesList(notesListRequest)

Query notes list

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NoteApi();
final notesListRequest = NotesListRequest(); // NotesListRequest | 

try {
    final result = api_instance.notesList(notesListRequest);
    print(result);
} catch (e) {
    print('Exception when calling NoteApi->notesList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **notesListRequest** | [**NotesListRequest**](NotesListRequest.md)|  | 

### Return type

[**List<NotesList200ResponseInner>**](NotesList200ResponseInner.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notesListByIds**
> List<NotesListByIds200ResponseInner> notesListByIds(notesListByIdsRequest)

Query notes list by ids

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NoteApi();
final notesListByIdsRequest = NotesListByIdsRequest(); // NotesListByIdsRequest | 

try {
    final result = api_instance.notesListByIds(notesListByIdsRequest);
    print(result);
} catch (e) {
    print('Exception when calling NoteApi->notesListByIds: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **notesListByIdsRequest** | [**NotesListByIdsRequest**](NotesListByIdsRequest.md)|  | 

### Return type

[**List<NotesListByIds200ResponseInner>**](NotesListByIds200ResponseInner.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notesNoteReferenceList**
> List<NotesNoteReferenceList200ResponseInner> notesNoteReferenceList(notesNoteReferenceListRequest)

Query note references

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NoteApi();
final notesNoteReferenceListRequest = NotesNoteReferenceListRequest(); // NotesNoteReferenceListRequest | 

try {
    final result = api_instance.notesNoteReferenceList(notesNoteReferenceListRequest);
    print(result);
} catch (e) {
    print('Exception when calling NoteApi->notesNoteReferenceList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **notesNoteReferenceListRequest** | [**NotesNoteReferenceListRequest**](NotesNoteReferenceListRequest.md)|  | 

### Return type

[**List<NotesNoteReferenceList200ResponseInner>**](NotesNoteReferenceList200ResponseInner.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notesPublicDetail**
> NotesPublicDetail200Response notesPublicDetail(notesPublicDetailRequest)

Query share note detail

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NoteApi();
final notesPublicDetailRequest = NotesPublicDetailRequest(); // NotesPublicDetailRequest | 

try {
    final result = api_instance.notesPublicDetail(notesPublicDetailRequest);
    print(result);
} catch (e) {
    print('Exception when calling NoteApi->notesPublicDetail: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **notesPublicDetailRequest** | [**NotesPublicDetailRequest**](NotesPublicDetailRequest.md)|  | 

### Return type

[**NotesPublicDetail200Response**](NotesPublicDetail200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notesPublicList**
> List<NotesPublicList200ResponseInner> notesPublicList(notesPublicListRequest)

Query share notes list

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NoteApi();
final notesPublicListRequest = NotesPublicListRequest(); // NotesPublicListRequest | 

try {
    final result = api_instance.notesPublicList(notesPublicListRequest);
    print(result);
} catch (e) {
    print('Exception when calling NoteApi->notesPublicList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **notesPublicListRequest** | [**NotesPublicListRequest**](NotesPublicListRequest.md)|  | 

### Return type

[**List<NotesPublicList200ResponseInner>**](NotesPublicList200ResponseInner.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notesRandomNoteList**
> List<NotesDailyReviewNoteList200ResponseInner> notesRandomNoteList(limit)

Query random notes for review

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NoteApi();
final limit = 8.14; // num | 

try {
    final result = api_instance.notesRandomNoteList(limit);
    print(result);
} catch (e) {
    print('Exception when calling NoteApi->notesRandomNoteList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **limit** | **num**|  | [optional] [default to 30]

### Return type

[**List<NotesDailyReviewNoteList200ResponseInner>**](NotesDailyReviewNoteList200ResponseInner.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notesRelatedNotes**
> List<NotesListByIds200ResponseInner> notesRelatedNotes(id)

Query related notes

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NoteApi();
final id = 8.14; // num | 

try {
    final result = api_instance.notesRelatedNotes(id);
    print(result);
} catch (e) {
    print('Exception when calling NoteApi->notesRelatedNotes: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **num**|  | 

### Return type

[**List<NotesListByIds200ResponseInner>**](NotesListByIds200ResponseInner.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notesReviewNote**
> NotesReviewNote200Response notesReviewNote(notesDetailRequest)

Review a note

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NoteApi();
final notesDetailRequest = NotesDetailRequest(); // NotesDetailRequest | 

try {
    final result = api_instance.notesReviewNote(notesDetailRequest);
    print(result);
} catch (e) {
    print('Exception when calling NoteApi->notesReviewNote: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **notesDetailRequest** | [**NotesDetailRequest**](NotesDetailRequest.md)|  | 

### Return type

[**NotesReviewNote200Response**](NotesReviewNote200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notesShareNote**
> NotesShareNote200Response notesShareNote(notesShareNoteRequest)

Share note

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NoteApi();
final notesShareNoteRequest = NotesShareNoteRequest(); // NotesShareNoteRequest | 

try {
    final result = api_instance.notesShareNote(notesShareNoteRequest);
    print(result);
} catch (e) {
    print('Exception when calling NoteApi->notesShareNote: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **notesShareNoteRequest** | [**NotesShareNoteRequest**](NotesShareNoteRequest.md)|  | 

### Return type

[**NotesShareNote200Response**](NotesShareNote200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notesTrashMany**
> Object notesTrashMany(notesListByIdsRequest)

Batch trash note

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NoteApi();
final notesListByIdsRequest = NotesListByIdsRequest(); // NotesListByIdsRequest | 

try {
    final result = api_instance.notesTrashMany(notesListByIdsRequest);
    print(result);
} catch (e) {
    print('Exception when calling NoteApi->notesTrashMany: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **notesListByIdsRequest** | [**NotesListByIdsRequest**](NotesListByIdsRequest.md)|  | 

### Return type

[**Object**](Object.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notesUpdateAttachmentsOrder**
> Object notesUpdateAttachmentsOrder(notesUpdateAttachmentsOrderRequest)

Update attachments order

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NoteApi();
final notesUpdateAttachmentsOrderRequest = NotesUpdateAttachmentsOrderRequest(); // NotesUpdateAttachmentsOrderRequest | 

try {
    final result = api_instance.notesUpdateAttachmentsOrder(notesUpdateAttachmentsOrderRequest);
    print(result);
} catch (e) {
    print('Exception when calling NoteApi->notesUpdateAttachmentsOrder: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **notesUpdateAttachmentsOrderRequest** | [**NotesUpdateAttachmentsOrderRequest**](NotesUpdateAttachmentsOrderRequest.md)|  | 

### Return type

[**Object**](Object.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notesUpdateMany**
> Object notesUpdateMany(notesUpdateManyRequest)

Batch update note

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NoteApi();
final notesUpdateManyRequest = NotesUpdateManyRequest(); // NotesUpdateManyRequest | 

try {
    final result = api_instance.notesUpdateMany(notesUpdateManyRequest);
    print(result);
} catch (e) {
    print('Exception when calling NoteApi->notesUpdateMany: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **notesUpdateManyRequest** | [**NotesUpdateManyRequest**](NotesUpdateManyRequest.md)|  | 

### Return type

[**Object**](Object.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notesUpsert**
> Object notesUpsert(notesUpsertRequest)

Update or create note

The attachments field is an array of objects with the following properties: name, path, and size which get from /api/file/upload

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = NoteApi();
final notesUpsertRequest = NotesUpsertRequest(); // NotesUpsertRequest | 

try {
    final result = api_instance.notesUpsert(notesUpsertRequest);
    print(result);
} catch (e) {
    print('Exception when calling NoteApi->notesUpsert: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **notesUpsertRequest** | [**NotesUpsertRequest**](NotesUpsertRequest.md)|  | 

### Return type

[**Object**](Object.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

