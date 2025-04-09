# todoist_flutter_api.model.Comment

## Load the model package
```dart
import 'package:todoist_flutter_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** | Comment ID. | [optional] 
**taskId** | **String** | Comment's task ID (will be null if the comment belongs to a project). | [optional] 
**projectId** | **String** | Comment's project ID (will be null if the comment belongs to a task). | [optional] 
**postedAt** | [**DateTime**](DateTime.md) | Date and time when comment was added, in RFC3339 format in UTC. | [optional] 
**content** | **String** | Comment content. This value may contain markdown-formatted text and hyperlinks. Details on markdown support can be found in the Text Formatting article in the Help Center. | [optional] 
**attachment** | [**Object**](.md) | Attachment file metadata (will be null if there is no attachment). Format varies depending on the type of attachment, as detailed in the Sync API documentation. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


