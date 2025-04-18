//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ProjectId4 {
  /// Returns a new [ProjectId4] instance.
  ProjectId4({
  });

  @override
  bool operator ==(Object other) => identical(this, other) || other is ProjectId4 &&

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis

  @override
  String toString() => 'ProjectId4[]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    return json;
  }

  /// Returns a new [ProjectId4] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ProjectId4? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ProjectId4[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ProjectId4[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ProjectId4(
      );
    }
    return null;
  }

  static List<ProjectId4> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ProjectId4>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ProjectId4.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ProjectId4> mapFromJson(dynamic json) {
    final map = <String, ProjectId4>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ProjectId4.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ProjectId4-objects as value to a dart map
  static Map<String, List<ProjectId4>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ProjectId4>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ProjectId4.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

