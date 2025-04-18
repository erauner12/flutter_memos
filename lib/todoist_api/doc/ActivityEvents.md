# todoist_flutter_api.model.ActivityEvents

## Load the model package
```dart
import 'package:todoist_flutter_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**objectType** | **String** |  | 
**objectId** | **String** |  | 
**v2ObjectId** | **String** |  | 
**eventType** | **String** |  | 
**eventDate** | [**DateTime**](DateTime.md) |  | 
**id** | **int** |  | [optional] 
**parentProjectId** | **String** |  | [optional] 
**v2ParentProjectId** | **String** |  | [optional] 
**parentItemId** | **String** |  | [optional] 
**v2ParentItemId** | **String** |  | [optional] 
**initiatorId** | **String** | The ID of the user who is responsible for the event, which only makes sense in shared projects, items and notes, and is null for non-shared objects | [optional] 
**extraDataId** | **int** |  | [optional] 
**extraData** | [**Map<String, Object>**](Object.md) |  | [optional] [default to const {}]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


