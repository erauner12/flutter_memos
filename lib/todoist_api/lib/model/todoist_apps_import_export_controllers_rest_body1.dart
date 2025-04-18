//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TodoistAppsImportExportControllersRestBody1 {
  /// Returns a new [TodoistAppsImportExportControllersRestBody1] instance.
  TodoistAppsImportExportControllersRestBody1({
    required this.projectId,
    this.locale = 'en',
  });

  ProjectId4 projectId;

  String locale;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TodoistAppsImportExportControllersRestBody1 &&
    other.projectId == projectId &&
    other.locale == locale;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (projectId.hashCode) +
    (locale.hashCode);

  @override
  String toString() => 'TodoistAppsImportExportControllersRestBody1[projectId=$projectId, locale=$locale]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'project_id'] = this.projectId;
      json[r'locale'] = this.locale;
    return json;
  }

  /// Returns a new [TodoistAppsImportExportControllersRestBody1] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TodoistAppsImportExportControllersRestBody1? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "TodoistAppsImportExportControllersRestBody1[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "TodoistAppsImportExportControllersRestBody1[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return TodoistAppsImportExportControllersRestBody1(
        projectId: ProjectId4.fromJson(json[r'project_id'])!,
        locale: mapValueOfType<String>(json, r'locale') ?? 'en',
      );
    }
    return null;
  }

  static List<TodoistAppsImportExportControllersRestBody1> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TodoistAppsImportExportControllersRestBody1>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TodoistAppsImportExportControllersRestBody1.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TodoistAppsImportExportControllersRestBody1> mapFromJson(dynamic json) {
    final map = <String, TodoistAppsImportExportControllersRestBody1>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TodoistAppsImportExportControllersRestBody1.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TodoistAppsImportExportControllersRestBody1-objects as value to a dart map
  static Map<String, List<TodoistAppsImportExportControllersRestBody1>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TodoistAppsImportExportControllersRestBody1>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TodoistAppsImportExportControllersRestBody1.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'project_id',
  };
}

