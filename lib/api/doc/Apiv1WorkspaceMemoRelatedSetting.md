# flutter_memos_api.model.Apiv1WorkspaceMemoRelatedSetting

## Load the model package
```dart
import 'package:flutter_memos_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**disallowPublicVisibility** | **bool** | disallow_public_visibility disallows set memo as public visibility. | [optional] 
**displayWithUpdateTime** | **bool** | display_with_update_time orders and displays memo with update time. | [optional] 
**contentLengthLimit** | **int** | content_length_limit is the limit of content length. Unit is byte. | [optional] 
**enableAutoCompact** | **bool** | enable_auto_compact enables auto compact for large content. | [optional] 
**enableDoubleClickEdit** | **bool** | enable_double_click_edit enables editing on double click. | [optional] 
**enableLinkPreview** | **bool** | enable_link_preview enables links preview. | [optional] 
**enableComment** | **bool** | enable_comment enables comment. | [optional] 
**enableLocation** | **bool** | enable_location enables setting location for memo. | [optional] 
**defaultVisibility** | **String** | default_visibility set the global memos default visibility. | [optional] 
**reactions** | **List<String>** | reactions is the list of reactions. | [optional] [default to const []]
**disableMarkdownShortcuts** | **bool** | disable_markdown_shortcuts disallow the registration of markdown shortcuts. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


