# todoist_blinko_api.model.NotesListRequest

## Load the model package
```dart
import 'package:todoist_blinko_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**tagId** | **num** |  | [optional] 
**page** | **num** |  | [optional] [default to 1]
**size** | **num** |  | [optional] [default to 30]
**orderBy** | **String** |  | [optional] [default to 'desc']
**type** | [**NotesListRequestType**](NotesListRequestType.md) |  | [optional] 
**isArchived** | **bool** |  | [optional] 
**isShare** | **bool** |  | [optional] 
**isRecycle** | **bool** |  | [optional] [default to false]
**searchText** | **String** |  | [optional] [default to '']
**withoutTag** | **bool** |  | [optional] [default to false]
**withFile** | **bool** |  | [optional] [default to false]
**withLink** | **bool** |  | [optional] [default to false]
**isUseAiQuery** | **bool** |  | [optional] [default to false]
**startDate** | [**NotesListRequestStartDate**](NotesListRequestStartDate.md) |  | [optional] 
**endDate** | [**NotesListRequestStartDate**](NotesListRequestStartDate.md) |  | [optional] 
**hasTodo** | **bool** |  | [optional] [default to false]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


