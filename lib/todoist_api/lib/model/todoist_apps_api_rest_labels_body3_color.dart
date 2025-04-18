//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TodoistAppsApiRestLabelsBody3Color {
  /// Returns a new [TodoistAppsApiRestLabelsBody3Color] instance.
  TodoistAppsApiRestLabelsBody3Color({
  });

  @override
  bool operator ==(Object other) => identical(this, other) || other is TodoistAppsApiRestLabelsBody3Color &&

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis

  @override
  String toString() => 'TodoistAppsApiRestLabelsBody3Color[]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    return json;
  }

  /// Returns a new [TodoistAppsApiRestLabelsBody3Color] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TodoistAppsApiRestLabelsBody3Color? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "TodoistAppsApiRestLabelsBody3Color[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "TodoistAppsApiRestLabelsBody3Color[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return TodoistAppsApiRestLabelsBody3Color(
      );
    }
    return null;
  }

  static List<TodoistAppsApiRestLabelsBody3Color> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TodoistAppsApiRestLabelsBody3Color>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TodoistAppsApiRestLabelsBody3Color.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TodoistAppsApiRestLabelsBody3Color> mapFromJson(dynamic json) {
    final map = <String, TodoistAppsApiRestLabelsBody3Color>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TodoistAppsApiRestLabelsBody3Color.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TodoistAppsApiRestLabelsBody3Color-objects as value to a dart map
  static Map<String, List<TodoistAppsApiRestLabelsBody3Color>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TodoistAppsApiRestLabelsBody3Color>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TodoistAppsApiRestLabelsBody3Color.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

