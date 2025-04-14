# todoist_blinko_api.api.FileApi

## Load the API package
```dart
import 'package:todoist_blinko_api/api.dart';
```

All URIs are relative to */api*

Method | HTTP request | Description
------------- | ------------- | -------------
[**deleteFile**](FileApi.md#deletefile) | **POST** /file/delete | Delete File
[**uploadFile**](FileApi.md#uploadfile) | **POST** /file/upload | Upload File
[**uploadFileByUrl**](FileApi.md#uploadfilebyurl) | **POST** /file/upload-by-url | Upload File by URL


# **deleteFile**
> DeleteFile200Response deleteFile(deleteFileRequest)

Delete File

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FileApi();
final deleteFileRequest = DeleteFileRequest(); // DeleteFileRequest | 

try {
    final result = api_instance.deleteFile(deleteFileRequest);
    print(result);
} catch (e) {
    print('Exception when calling FileApi->deleteFile: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **deleteFileRequest** | [**DeleteFileRequest**](DeleteFileRequest.md)|  | 

### Return type

[**DeleteFile200Response**](DeleteFile200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **uploadFile**
> UploadFile200Response uploadFile(file)

Upload File

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FileApi();
final file = BINARY_DATA_HERE; // MultipartFile | Upload File

try {
    final result = api_instance.uploadFile(file);
    print(result);
} catch (e) {
    print('Exception when calling FileApi->uploadFile: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **file** | **MultipartFile**| Upload File | 

### Return type

[**UploadFile200Response**](UploadFile200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **uploadFileByUrl**
> UploadFileByUrl200Response uploadFileByUrl(uploadFileByUrlRequest)

Upload File by URL

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = FileApi();
final uploadFileByUrlRequest = UploadFileByUrlRequest(); // UploadFileByUrlRequest | 

try {
    final result = api_instance.uploadFileByUrl(uploadFileByUrlRequest);
    print(result);
} catch (e) {
    print('Exception when calling FileApi->uploadFileByUrl: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uploadFileByUrlRequest** | [**UploadFileByUrlRequest**](UploadFileByUrlRequest.md)|  | 

### Return type

[**UploadFileByUrl200Response**](UploadFileByUrl200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

