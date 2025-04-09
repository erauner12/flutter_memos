# todoist_flutter_api.model.Project

## Load the model package
```dart
import 'package:todoist_flutter_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** | Project ID. | [optional] 
**name** | **String** | Project name. | [optional] 
**color** | **String** | The color of the project icon. Refer to the name column in the Colors guide for more info. | [optional] 
**parentId** | **String** | ID of parent project (will be null for top-level projects). | [optional] 
**order** | **int** | Project position under the same parent (read-only, will be 0 for inbox and team inbox projects). | [optional] 
**commentCount** | **int** | Number of project comments. | [optional] 
**isShared** | **bool** | Whether the project is shared (read-only, a true or false value). | [optional] 
**isFavorite** | **bool** | Whether the project is a favorite (a true or false value). | [optional] 
**isInboxProject** | **bool** | Whether the project is the user's Inbox (read-only). | [optional] 
**isTeamInbox** | **bool** | Whether the project is the Team Inbox (read-only). | [optional] 
**viewStyle** | **String** | A string value (either list or board). This determines the way the project is displayed within the Todoist clients. | [optional] 
**url** | **String** | URL to access this project in the Todoist web or mobile applications. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


