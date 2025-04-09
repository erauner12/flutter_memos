# todoist_flutter_api.model.CreateTaskRequest

## Load the model package
```dart
import 'package:todoist_flutter_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**content** | **String** | Task content. This value may contain markdown-formatted text and hyperlinks. | [optional] 
**description** | **String** | A description for the task. This value may contain markdown-formatted text and hyperlinks. | [optional] 
**projectId** | **String** | Task project ID. If not set, the task is put in the user's Inbox. | [optional] 
**sectionId** | **String** | ID of the section to put the task into. | [optional] 
**parentId** | **String** | Parent task ID. | [optional] 
**order** | **int** | Non-zero integer value used by clients to sort tasks under the same parent. | [optional] 
**labels** | **List<String>** | The task's labels (a list of names that may represent either personal or shared labels). | [optional] [default to const []]
**priority** | **int** | Task priority from 1 (normal) to 4 (urgent). | [optional] 
**dueString** | **String** | Human-defined task due date (ex. \"next Monday,\" \"Tomorrow\"). Value is set using local (not UTC) time. | [optional] 
**dueDate** | **String** | Specific date in YYYY-MM-DD format relative to the user's timezone. | [optional] 
**dueDatetime** | **String** | Specific date and time in RFC3339 format in UTC. | [optional] 
**dueLang** | **String** | 2-letter code specifying the language in case due_string is not written in English. | [optional] 
**assigneeId** | **String** | The responsible user ID (only applies to shared tasks). | [optional] 
**duration** | **int** | A positive (greater than zero) integer for the amount of duration_unit the task will take. If specified, you must define a duration_unit. | [optional] 
**durationUnit** | **String** | The unit of time that the duration field above represents. Must be either minute or day. If specified, duration must be defined as well. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


