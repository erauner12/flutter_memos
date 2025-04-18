//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TodoistAppsApiRestProjectsBody2 {
  /// Returns a new [TodoistAppsApiRestProjectsBody2] instance.
  TodoistAppsApiRestProjectsBody2({
    this.name,
    this.description,
    this.color,
    this.isFavorite,
    this.viewStyle,
  });

  String? name;

  String? description;

  TodoistAppsApiRestLabelsBody3Color? color;

  bool? isFavorite;

  String? viewStyle;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TodoistAppsApiRestProjectsBody2 &&
    other.name == name &&
    other.description == description &&
    other.color == color &&
    other.isFavorite == isFavorite &&
    other.viewStyle == viewStyle;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name == null ? 0 : name!.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (color == null ? 0 : color!.hashCode) +
    (isFavorite == null ? 0 : isFavorite!.hashCode) +
    (viewStyle == null ? 0 : viewStyle!.hashCode);

  @override
  String toString() => 'TodoistAppsApiRestProjectsBody2[name=$name, description=$description, color=$color, isFavorite=$isFavorite, viewStyle=$viewStyle]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
    if (this.color != null) {
      json[r'color'] = this.color;
    } else {
      json[r'color'] = null;
    }
    if (this.isFavorite != null) {
      json[r'is_favorite'] = this.isFavorite;
    } else {
      json[r'is_favorite'] = null;
    }
    if (this.viewStyle != null) {
      json[r'view_style'] = this.viewStyle;
    } else {
      json[r'view_style'] = null;
    }
    return json;
  }

  /// Returns a new [TodoistAppsApiRestProjectsBody2] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TodoistAppsApiRestProjectsBody2? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "TodoistAppsApiRestProjectsBody2[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "TodoistAppsApiRestProjectsBody2[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return TodoistAppsApiRestProjectsBody2(
        name: mapValueOfType<String>(json, r'name'),
        description: mapValueOfType<String>(json, r'description'),
        color: TodoistAppsApiRestLabelsBody3Color.fromJson(json[r'color']),
        isFavorite: mapValueOfType<bool>(json, r'is_favorite'),
        viewStyle: mapValueOfType<String>(json, r'view_style'),
      );
    }
    return null;
  }

  static List<TodoistAppsApiRestProjectsBody2> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TodoistAppsApiRestProjectsBody2>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TodoistAppsApiRestProjectsBody2.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TodoistAppsApiRestProjectsBody2> mapFromJson(dynamic json) {
    final map = <String, TodoistAppsApiRestProjectsBody2>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TodoistAppsApiRestProjectsBody2.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TodoistAppsApiRestProjectsBody2-objects as value to a dart map
  static Map<String, List<TodoistAppsApiRestProjectsBody2>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TodoistAppsApiRestProjectsBody2>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TodoistAppsApiRestProjectsBody2.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

