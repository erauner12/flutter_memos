//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TodoistAppsApiSyncRestWorkspacesBody2 {
  /// Returns a new [TodoistAppsApiSyncRestWorkspacesBody2] instance.
  TodoistAppsApiSyncRestWorkspacesBody2({
    this.inviteCode,
    this.workspaceId,
  });

  String? inviteCode;

  int? workspaceId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TodoistAppsApiSyncRestWorkspacesBody2 &&
    other.inviteCode == inviteCode &&
    other.workspaceId == workspaceId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (inviteCode == null ? 0 : inviteCode!.hashCode) +
    (workspaceId == null ? 0 : workspaceId!.hashCode);

  @override
  String toString() => 'TodoistAppsApiSyncRestWorkspacesBody2[inviteCode=$inviteCode, workspaceId=$workspaceId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.inviteCode != null) {
      json[r'invite_code'] = this.inviteCode;
    } else {
      json[r'invite_code'] = null;
    }
    if (this.workspaceId != null) {
      json[r'workspace_id'] = this.workspaceId;
    } else {
      json[r'workspace_id'] = null;
    }
    return json;
  }

  /// Returns a new [TodoistAppsApiSyncRestWorkspacesBody2] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TodoistAppsApiSyncRestWorkspacesBody2? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "TodoistAppsApiSyncRestWorkspacesBody2[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "TodoistAppsApiSyncRestWorkspacesBody2[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return TodoistAppsApiSyncRestWorkspacesBody2(
        inviteCode: mapValueOfType<String>(json, r'invite_code'),
        workspaceId: mapValueOfType<int>(json, r'workspace_id'),
      );
    }
    return null;
  }

  static List<TodoistAppsApiSyncRestWorkspacesBody2> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TodoistAppsApiSyncRestWorkspacesBody2>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TodoistAppsApiSyncRestWorkspacesBody2.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TodoistAppsApiSyncRestWorkspacesBody2> mapFromJson(dynamic json) {
    final map = <String, TodoistAppsApiSyncRestWorkspacesBody2>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TodoistAppsApiSyncRestWorkspacesBody2.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TodoistAppsApiSyncRestWorkspacesBody2-objects as value to a dart map
  static Map<String, List<TodoistAppsApiSyncRestWorkspacesBody2>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TodoistAppsApiSyncRestWorkspacesBody2>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TodoistAppsApiSyncRestWorkspacesBody2.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

