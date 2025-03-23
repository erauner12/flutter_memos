# flutter_memos_api.model.V1UserStats

## Load the model package
```dart
import 'package:flutter_memos_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**name** | **String** | The name of the user. | [optional] 
**memoDisplayTimestamps** | [**List<DateTime>**](DateTime.md) | The timestamps when the memos were displayed.  We should return raw data to the client, and let the client format the data with the user's timezone. | [optional] [default to const []]
**memoTypeStats** | [**UserStatsMemoTypeStats**](UserStatsMemoTypeStats.md) |  | [optional] 
**tagCount** | **Map<String, int>** |  | [optional] [default to const {}]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


