# todoist_flutter_api.model.Task

## Load the model package
```dart
import 'package:todoist_flutter_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** | Task ID. | [optional] 
**projectId** | **String** | Task's project ID (read-only). | [optional] 
**sectionId** | **String** | ID of section task belongs to (read-only, will be null when the task has no parent section). | [optional] 
**content** | **String** | Task content. This value may contain markdown-formatted text and hyperlinks. Details on markdown support can be found in the Text Formatting article in the Help Center. | [optional] 
**description** | **String** | A description for the task. This value may contain markdown-formatted text and hyperlinks. Details on markdown support can be found in the Text Formatting article in the Help Center. | [optional] 
**isCompleted** | **bool** | Flag to mark completed tasks. | [optional] 
**labels** | **List<String>** |  | [optional] [default to const []]
**parentId** | **String** | ID of parent task (read-only, will be null for top-level tasks). | [optional] 
**order** | **int** | Position under the same parent or project for top-level tasks (read-only). | [optional] 
**priority** | **int** | Task priority from 1 (normal, default value) to 4 (urgent). | [optional] 
**due** | [**TaskDue**](TaskDue.md) |  | [optional] 
**url** | **String** | URL to access this task in the Todoist web or mobile applications (read-only). | [optional] 
**commentCount** | **int** | Number of task comments (read-only). | [optional] 
**createdAt** | **String** | The date when the task was created (read-only). | [optional] 
**creatorId** | **String** | The ID of the user who created the task (read-only). | [optional] 
**assigneeId** | **String** | The responsible user ID (will be null if the task is unassigned). | [optional] 
**assignerId** | **String** | The ID of the user who assigned the task (read-only, will be null if the task is unassigned). | [optional] 
**duration** | [**TaskDuration**](TaskDuration.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


