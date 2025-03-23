# flutter_memos_api.api.MarkdownServiceApi

## Load the API package
```dart
import 'package:flutter_memos_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**markdownServiceGetLinkMetadata**](MarkdownServiceApi.md#markdownservicegetlinkmetadata) | **GET** /api/v1/markdown/link:metadata | GetLinkMetadata returns metadata for a given link.
[**markdownServiceParseMarkdown**](MarkdownServiceApi.md#markdownserviceparsemarkdown) | **POST** /api/v1/markdown:parse | ParseMarkdown parses the given markdown content and returns a list of nodes.
[**markdownServiceRestoreMarkdownNodes**](MarkdownServiceApi.md#markdownservicerestoremarkdownnodes) | **POST** /api/v1/markdown/node:restore | RestoreMarkdownNodes restores the given nodes to markdown content.
[**markdownServiceStringifyMarkdownNodes**](MarkdownServiceApi.md#markdownservicestringifymarkdownnodes) | **POST** /api/v1/markdown/node:stringify | StringifyMarkdownNodes stringify the given nodes to plain text content.


# **markdownServiceGetLinkMetadata**
> V1LinkMetadata markdownServiceGetLinkMetadata(link)

GetLinkMetadata returns metadata for a given link.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = MarkdownServiceApi();
final link = link_example; // String | 

try {
    final result = api_instance.markdownServiceGetLinkMetadata(link);
    print(result);
} catch (e) {
    print('Exception when calling MarkdownServiceApi->markdownServiceGetLinkMetadata: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **link** | **String**|  | [optional] 

### Return type

[**V1LinkMetadata**](V1LinkMetadata.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **markdownServiceParseMarkdown**
> V1ParseMarkdownResponse markdownServiceParseMarkdown(body)

ParseMarkdown parses the given markdown content and returns a list of nodes.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = MarkdownServiceApi();
final body = V1ParseMarkdownRequest(); // V1ParseMarkdownRequest | 

try {
    final result = api_instance.markdownServiceParseMarkdown(body);
    print(result);
} catch (e) {
    print('Exception when calling MarkdownServiceApi->markdownServiceParseMarkdown: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **body** | [**V1ParseMarkdownRequest**](V1ParseMarkdownRequest.md)|  | 

### Return type

[**V1ParseMarkdownResponse**](V1ParseMarkdownResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **markdownServiceRestoreMarkdownNodes**
> V1RestoreMarkdownNodesResponse markdownServiceRestoreMarkdownNodes(body)

RestoreMarkdownNodes restores the given nodes to markdown content.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = MarkdownServiceApi();
final body = V1RestoreMarkdownNodesRequest(); // V1RestoreMarkdownNodesRequest | 

try {
    final result = api_instance.markdownServiceRestoreMarkdownNodes(body);
    print(result);
} catch (e) {
    print('Exception when calling MarkdownServiceApi->markdownServiceRestoreMarkdownNodes: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **body** | [**V1RestoreMarkdownNodesRequest**](V1RestoreMarkdownNodesRequest.md)|  | 

### Return type

[**V1RestoreMarkdownNodesResponse**](V1RestoreMarkdownNodesResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **markdownServiceStringifyMarkdownNodes**
> V1StringifyMarkdownNodesResponse markdownServiceStringifyMarkdownNodes(body)

StringifyMarkdownNodes stringify the given nodes to plain text content.

### Example
```dart
import 'package:flutter_memos_api/api.dart';

final api_instance = MarkdownServiceApi();
final body = V1StringifyMarkdownNodesRequest(); // V1StringifyMarkdownNodesRequest | 

try {
    final result = api_instance.markdownServiceStringifyMarkdownNodes(body);
    print(result);
} catch (e) {
    print('Exception when calling MarkdownServiceApi->markdownServiceStringifyMarkdownNodes: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **body** | [**V1StringifyMarkdownNodesRequest**](V1StringifyMarkdownNodesRequest.md)|  | 

### Return type

[**V1StringifyMarkdownNodesResponse**](V1StringifyMarkdownNodesResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

