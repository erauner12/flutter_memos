//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TodoistAppsApiRestSectionsBody1 {
  /// Returns a new [TodoistAppsApiRestSectionsBody1] instance.
  TodoistAppsApiRestSectionsBody1({
    required this.name,
    required this.projectId,
    this.order,
  });

  String name;

  ProjectId4 projectId;

  int? order;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TodoistAppsApiRestSectionsBody1 &&
    other.name == name &&
    other.projectId == projectId &&
    other.order == order;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (projectId.hashCode) +
    (order == null ? 0 : order!.hashCode);

  @override
  String toString() => 'TodoistAppsApiRestSectionsBody1[name=$name, projectId=$projectId, order=$order]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'name'] = this.name;
      json[r'project_id'] = this.projectId;
    if (this.order != null) {
      json[r'order'] = this.order;
    } else {
      json[r'order'] = null;
    }
    return json;
  }

  /// Returns a new [TodoistAppsApiRestSectionsBody1] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TodoistAppsApiRestSectionsBody1? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "TodoistAppsApiRestSectionsBody1[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "TodoistAppsApiRestSectionsBody1[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return TodoistAppsApiRestSectionsBody1(
        name: mapValueOfType<String>(json, r'name')!,
        projectId: ProjectId4.fromJson(json[r'project_id'])!,
        order: mapValueOfType<int>(json, r'order'),
      );
    }
    return null;
  }

  static List<TodoistAppsApiRestSectionsBody1> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TodoistAppsApiRestSectionsBody1>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TodoistAppsApiRestSectionsBody1.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TodoistAppsApiRestSectionsBody1> mapFromJson(dynamic json) {
    final map = <String, TodoistAppsApiRestSectionsBody1>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TodoistAppsApiRestSectionsBody1.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TodoistAppsApiRestSectionsBody1-objects as value to a dart map
  static Map<String, List<TodoistAppsApiRestSectionsBody1>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TodoistAppsApiRestSectionsBody1>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TodoistAppsApiRestSectionsBody1.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'project_id',
  };
}

