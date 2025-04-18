//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TodoistAppsApiSyncRestWorkspacesBody1 {
  /// Returns a new [TodoistAppsApiSyncRestWorkspacesBody1] instance.
  TodoistAppsApiSyncRestWorkspacesBody1({
    required this.workspaceId,
    required this.userEmail,
  });

  int workspaceId;

  String userEmail;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TodoistAppsApiSyncRestWorkspacesBody1 &&
    other.workspaceId == workspaceId &&
    other.userEmail == userEmail;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (workspaceId.hashCode) +
    (userEmail.hashCode);

  @override
  String toString() => 'TodoistAppsApiSyncRestWorkspacesBody1[workspaceId=$workspaceId, userEmail=$userEmail]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'workspace_id'] = this.workspaceId;
      json[r'user_email'] = this.userEmail;
    return json;
  }

  /// Returns a new [TodoistAppsApiSyncRestWorkspacesBody1] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TodoistAppsApiSyncRestWorkspacesBody1? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "TodoistAppsApiSyncRestWorkspacesBody1[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "TodoistAppsApiSyncRestWorkspacesBody1[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return TodoistAppsApiSyncRestWorkspacesBody1(
        workspaceId: mapValueOfType<int>(json, r'workspace_id')!,
        userEmail: mapValueOfType<String>(json, r'user_email')!,
      );
    }
    return null;
  }

  static List<TodoistAppsApiSyncRestWorkspacesBody1> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TodoistAppsApiSyncRestWorkspacesBody1>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TodoistAppsApiSyncRestWorkspacesBody1.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TodoistAppsApiSyncRestWorkspacesBody1> mapFromJson(dynamic json) {
    final map = <String, TodoistAppsApiSyncRestWorkspacesBody1>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TodoistAppsApiSyncRestWorkspacesBody1.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TodoistAppsApiSyncRestWorkspacesBody1-objects as value to a dart map
  static Map<String, List<TodoistAppsApiSyncRestWorkspacesBody1>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TodoistAppsApiSyncRestWorkspacesBody1>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TodoistAppsApiSyncRestWorkspacesBody1.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'workspace_id',
    'user_email',
  };
}

