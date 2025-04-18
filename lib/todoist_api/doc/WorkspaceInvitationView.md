# todoist_flutter_api.model.WorkspaceInvitationView

## Load the model package
```dart
import 'package:todoist_flutter_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**inviterId** | **String** | ID of the user user who sent the invitation | 
**userEmail** | **String** | The invited person's email. | 
**workspaceId** | **String** | ID of the workspace | 
**role** | [**WorkspaceRole**](WorkspaceRole.md) |  | 
**id** | **String** | The ID of the invitation | [optional] [default to '0']
**isExistingUser** | **bool** | Returns true if the user is already created in the system, and false otherwise | [readonly] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


