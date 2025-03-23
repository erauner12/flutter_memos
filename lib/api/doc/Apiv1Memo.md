# flutter_memos_api.model.Apiv1Memo

## Load the model package
```dart
import 'package:flutter_memos_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**name** | **String** | The name of the memo.  Format: memos/{memo}, memo is the user defined id or uuid. | [optional] [readonly] 
**state** | [**V1State**](V1State.md) |  | [optional] 
**creator** | **String** |  | [optional] 
**createTime** | [**DateTime**](DateTime.md) |  | [optional] 
**updateTime** | [**DateTime**](DateTime.md) |  | [optional] 
**displayTime** | [**DateTime**](DateTime.md) |  | [optional] 
**content** | **String** |  | [optional] 
**nodes** | [**List<V1Node>**](V1Node.md) |  | [optional] [readonly] [default to const []]
**visibility** | [**V1Visibility**](V1Visibility.md) |  | [optional] 
**tags** | **List<String>** |  | [optional] [readonly] [default to const []]
**pinned** | **bool** |  | [optional] 
**resources** | [**List<V1Resource>**](V1Resource.md) |  | [optional] [default to const []]
**relations** | [**List<V1MemoRelation>**](V1MemoRelation.md) |  | [optional] [default to const []]
**reactions** | [**List<V1Reaction>**](V1Reaction.md) |  | [optional] [readonly] [default to const []]
**property** | [**V1MemoProperty**](V1MemoProperty.md) |  | [optional] 
**parent** | **String** |  | [optional] [readonly] 
**snippet** | **String** | The snippet of the memo content. Plain text only. | [optional] [readonly] 
**location** | [**Apiv1Location**](Apiv1Location.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


