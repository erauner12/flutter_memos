# todoist_flutter_api.model.WorkspaceProjectView

## Load the model package
```dart
import 'package:todoist_flutter_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**initiatedByUid** | **int** |  | 
**projectId** | **String** |  | 
**workspaceId** | **int** |  | 
**folderId** | **int** |  | [optional] 
**isInviteOnly** | **bool** |  | [optional] 
**isArchived** | **bool** |  | [optional] [default to false]
**archivedTimestamp** | **int** |  | [optional] [default to 0]
**archivedDate** | [**DateTime**](DateTime.md) |  | [optional] 
**isFrozen** | **bool** |  | [optional] [default to false]
**name** | **String** |  | [optional] [default to '']
**color** | **int** |  | [optional] 
**viewStyle** | [**ProjectViewStyle**](ProjectViewStyle.md) |  | [optional] [default to list]
**description** | **String** |  | [optional] [default to '']
**status** | [**ProjectStatus**](ProjectStatus.md) |  | [optional] [default to ProjectStatus.IN_PROGRESS]
**defaultOrder** | **int** |  | [optional] [default to 0]
**v1Id** | **int** |  | [optional] 
**role** | [**Role**](Role.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


