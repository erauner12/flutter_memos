# todoist_flutter_api.model.UpdateTaskRequest

## Load the model package
```dart
import 'package:todoist_flutter_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**content** | **String** | Task content. This value may contain markdown-formatted text and hyperlinks. | [optional] 
**description** | **String** | A description for the task. This value may contain markdown-formatted text and hyperlinks. | [optional] 
**labels** | **List<String>** | The task's labels (a list of names that may represent either personal or shared labels). | [optional] [default to const []]
**priority** | **int** | Task priority from 1 (normal) to 4 (urgent). | [optional] 
**dueString** | **String** | Human-defined task due date (ex. \"next Monday,\" \"Tomorrow\"). Value is set using local (not UTC) time. | [optional] 
**dueDate** | **String** | Specific date in YYYY-MM-DD format relative to the user's timezone. | [optional] 
**dueDatetime** | **String** | Specific date and time in RFC3339 format in UTC. | [optional] 
**dueLang** | **String** | 2-letter code specifying the language in case due_string is not written in English. | [optional] 
**assigneeId** | **String** | The responsible user ID or null to unset (for shared tasks). | [optional] 
**duration** | **int** | A positive integer for the task duration, or null to unset. If specified, you must define a duration_unit. | [optional] 
**durationUnit** | **String** | The unit of time for the duration. Must be either 'minute' or 'day'. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


