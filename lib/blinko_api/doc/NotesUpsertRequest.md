# todoist_blinko_api.model.NotesUpsertRequest

## Load the model package
```dart
import 'package:todoist_blinko_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**content** | **String** |  | [optional] 
**type** | [**NotesListRequestType**](NotesListRequestType.md) |  | [optional] 
**attachments** | [**List<NotesUpsertRequestAttachmentsInner>**](NotesUpsertRequestAttachmentsInner.md) |  | [optional] [default to const []]
**id** | **num** |  | [optional] 
**isArchived** | **bool** |  | [optional] 
**isTop** | **bool** |  | [optional] 
**isShare** | **bool** |  | [optional] 
**isRecycle** | **bool** |  | [optional] 
**references** | **List<num>** |  | [optional] [default to const []]
**createdAt** | **String** |  | [optional] 
**updatedAt** | **String** |  | [optional] 
**metadata** | [**Object**](.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


