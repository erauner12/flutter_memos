# todoist_flutter_api.model.TodoistAppsApiSyncRestQuickBody

## Load the model package
```dart
import 'package:todoist_flutter_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**text** | **String** | The text of the task that is parsed. It can include a due date in free form text, a project name starting with the `#` character (without spaces), a label starting with the `@` character, an assignee starting with the `+` character, a priority (e.g., `p1`), a deadline between `{}` (e.g. {in 3 days}), or a description starting from `//` until the end of the text. | 
**note** | **String** |  | [optional] 
**reminder** | **String** |  | [optional] 
**autoReminder** | **bool** | When this option is enabled, the default reminder will be added to the new item if it has a due date with time set. See also the [auto_reminder user option](#tag/Sync/User) for more info about the default reminder. | [optional] [default to false]
**meta** | **bool** |  | [optional] [default to false]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


