# todoist_flutter_api.model.Due

## Load the model package
```dart
import 'package:todoist_flutter_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**string** | **String** | Human defined date in arbitrary format. | 
**date** | [**DateTime**](DateTime.md) | Date in format YYYY-MM-DD corrected to user's timezone. | 
**isRecurring** | **bool** | Whether the task has a recurring due date. | 
**datetime** | [**DateTime**](DateTime.md) | Only returned if exact due time set (i.e. it's not a whole-day task), date and time in RFC3339 format in UTC. | [optional] 
**timezone** | **String** | Only returned if exact due time set, user's timezone definition either in tzdata-compatible format (\"Europe/Berlin\") or as a string specifying east of UTC offset as \"UTC±HH:MM\" (i.e. \"UTC-01:00\"). | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


