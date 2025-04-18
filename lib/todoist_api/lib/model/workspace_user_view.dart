//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class WorkspaceUserView {
  /// Returns a new [WorkspaceUserView] instance.
  WorkspaceUserView({
    required this.userId,
    required this.workspaceId,
    this.role = WorkspaceRole.MEMBER,
    this.customSortingApplied = false,
  });

  String userId;

  String workspaceId;

  WorkspaceRole role;

  bool customSortingApplied;

  @override
  bool operator ==(Object other) => identical(this, other) || other is WorkspaceUserView &&
    other.userId == userId &&
    other.workspaceId == workspaceId &&
    other.role == role &&
    other.customSortingApplied == customSortingApplied;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (userId.hashCode) +
    (workspaceId.hashCode) +
    (role.hashCode) +
    (customSortingApplied.hashCode);

  @override
  String toString() => 'WorkspaceUserView[userId=$userId, workspaceId=$workspaceId, role=$role, customSortingApplied=$customSortingApplied]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'user_id'] = this.userId;
      json[r'workspace_id'] = this.workspaceId;
      json[r'role'] = this.role;
      json[r'custom_sorting_applied'] = this.customSortingApplied;
    return json;
  }

  /// Returns a new [WorkspaceUserView] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static WorkspaceUserView? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "WorkspaceUserView[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "WorkspaceUserView[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return WorkspaceUserView(
        userId: mapValueOfType<String>(json, r'user_id')!,
        workspaceId: mapValueOfType<String>(json, r'workspace_id')!,
        role: WorkspaceRole.fromJson(json[r'role']) ?? WorkspaceRole.MEMBER,
        customSortingApplied: mapValueOfType<bool>(json, r'custom_sorting_applied') ?? false,
      );
    }
    return null;
  }

  static List<WorkspaceUserView> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <WorkspaceUserView>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WorkspaceUserView.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, WorkspaceUserView> mapFromJson(dynamic json) {
    final map = <String, WorkspaceUserView>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = WorkspaceUserView.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of WorkspaceUserView-objects as value to a dart map
  static Map<String, List<WorkspaceUserView>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<WorkspaceUserView>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = WorkspaceUserView.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'user_id',
    'workspace_id',
  };
}

