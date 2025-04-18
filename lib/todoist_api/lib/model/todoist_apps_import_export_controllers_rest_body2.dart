//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TodoistAppsImportExportControllersRestBody2 {
  /// Returns a new [TodoistAppsImportExportControllersRestBody2] instance.
  TodoistAppsImportExportControllersRestBody2({
    required this.projectId,
  });

  ProjectId4 projectId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TodoistAppsImportExportControllersRestBody2 &&
    other.projectId == projectId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (projectId.hashCode);

  @override
  String toString() => 'TodoistAppsImportExportControllersRestBody2[projectId=$projectId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'project_id'] = this.projectId;
    return json;
  }

  /// Returns a new [TodoistAppsImportExportControllersRestBody2] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TodoistAppsImportExportControllersRestBody2? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "TodoistAppsImportExportControllersRestBody2[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "TodoistAppsImportExportControllersRestBody2[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return TodoistAppsImportExportControllersRestBody2(
        projectId: ProjectId4.fromJson(json[r'project_id'])!,
      );
    }
    return null;
  }

  static List<TodoistAppsImportExportControllersRestBody2> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TodoistAppsImportExportControllersRestBody2>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TodoistAppsImportExportControllersRestBody2.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TodoistAppsImportExportControllersRestBody2> mapFromJson(dynamic json) {
    final map = <String, TodoistAppsImportExportControllersRestBody2>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TodoistAppsImportExportControllersRestBody2.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TodoistAppsImportExportControllersRestBody2-objects as value to a dart map
  static Map<String, List<TodoistAppsImportExportControllersRestBody2>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TodoistAppsImportExportControllersRestBody2>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TodoistAppsImportExportControllersRestBody2.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'project_id',
  };
}

