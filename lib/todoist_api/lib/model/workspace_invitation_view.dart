//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class WorkspaceInvitationView {
  /// Returns a new [WorkspaceInvitationView] instance.
  WorkspaceInvitationView({
    required this.inviterId,
    required this.userEmail,
    required this.workspaceId,
    required this.role,
    this.id = '0',
    required this.isExistingUser,
  });

  /// ID of the user user who sent the invitation
  String inviterId;

  /// The invited person's email.
  String userEmail;

  /// ID of the workspace
  String workspaceId;

  WorkspaceRole role;

  /// The ID of the invitation
  String id;

  /// Returns true if the user is already created in the system, and false otherwise
  bool isExistingUser;

  @override
  bool operator ==(Object other) => identical(this, other) || other is WorkspaceInvitationView &&
    other.inviterId == inviterId &&
    other.userEmail == userEmail &&
    other.workspaceId == workspaceId &&
    other.role == role &&
    other.id == id &&
    other.isExistingUser == isExistingUser;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (inviterId.hashCode) +
    (userEmail.hashCode) +
    (workspaceId.hashCode) +
    (role.hashCode) +
    (id.hashCode) +
    (isExistingUser.hashCode);

  @override
  String toString() => 'WorkspaceInvitationView[inviterId=$inviterId, userEmail=$userEmail, workspaceId=$workspaceId, role=$role, id=$id, isExistingUser=$isExistingUser]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'inviter_id'] = this.inviterId;
      json[r'user_email'] = this.userEmail;
      json[r'workspace_id'] = this.workspaceId;
      json[r'role'] = this.role;
      json[r'id'] = this.id;
      json[r'is_existing_user'] = this.isExistingUser;
    return json;
  }

  /// Returns a new [WorkspaceInvitationView] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static WorkspaceInvitationView? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "WorkspaceInvitationView[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "WorkspaceInvitationView[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return WorkspaceInvitationView(
        inviterId: mapValueOfType<String>(json, r'inviter_id')!,
        userEmail: mapValueOfType<String>(json, r'user_email')!,
        workspaceId: mapValueOfType<String>(json, r'workspace_id')!,
        role: WorkspaceRole.fromJson(json[r'role'])!,
        id: mapValueOfType<String>(json, r'id') ?? '0',
        isExistingUser: mapValueOfType<bool>(json, r'is_existing_user')!,
      );
    }
    return null;
  }

  static List<WorkspaceInvitationView> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <WorkspaceInvitationView>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WorkspaceInvitationView.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, WorkspaceInvitationView> mapFromJson(dynamic json) {
    final map = <String, WorkspaceInvitationView>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = WorkspaceInvitationView.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of WorkspaceInvitationView-objects as value to a dart map
  static Map<String, List<WorkspaceInvitationView>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<WorkspaceInvitationView>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = WorkspaceInvitationView.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'inviter_id',
    'user_email',
    'workspace_id',
    'role',
    'is_existing_user',
  };
}

