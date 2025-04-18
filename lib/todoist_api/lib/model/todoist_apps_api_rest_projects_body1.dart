//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TodoistAppsApiRestProjectsBody1 {
  /// Returns a new [TodoistAppsApiRestProjectsBody1] instance.
  TodoistAppsApiRestProjectsBody1({
    required this.name,
    this.description,
    this.parentId,
    this.color,
    this.isFavorite = false,
    this.viewStyle,
  });

  String? name;

  String? description;

  ParentId? parentId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  TodoistAppsApiRestLabelsBody4Color? color;

  bool isFavorite;

  String? viewStyle;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TodoistAppsApiRestProjectsBody1 &&
    other.name == name &&
    other.description == description &&
    other.parentId == parentId &&
    other.color == color &&
    other.isFavorite == isFavorite &&
    other.viewStyle == viewStyle;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name == null ? 0 : name!.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (parentId == null ? 0 : parentId!.hashCode) +
    (color == null ? 0 : color!.hashCode) +
    (isFavorite.hashCode) +
    (viewStyle == null ? 0 : viewStyle!.hashCode);

  @override
  String toString() => 'TodoistAppsApiRestProjectsBody1[name=$name, description=$description, parentId=$parentId, color=$color, isFavorite=$isFavorite, viewStyle=$viewStyle]';

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
    if (this.parentId != null) {
      json[r'parent_id'] = this.parentId;
    } else {
      json[r'parent_id'] = null;
    }
    if (this.color != null) {
      json[r'color'] = this.color;
    } else {
      json[r'color'] = null;
    }
      json[r'is_favorite'] = this.isFavorite;
    if (this.viewStyle != null) {
      json[r'view_style'] = this.viewStyle;
    } else {
      json[r'view_style'] = null;
    }
    return json;
  }

  /// Returns a new [TodoistAppsApiRestProjectsBody1] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TodoistAppsApiRestProjectsBody1? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "TodoistAppsApiRestProjectsBody1[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "TodoistAppsApiRestProjectsBody1[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return TodoistAppsApiRestProjectsBody1(
        name: mapValueOfType<String>(json, r'name'),
        description: mapValueOfType<String>(json, r'description'),
        parentId: ParentId.fromJson(json[r'parent_id']),
        color: TodoistAppsApiRestLabelsBody4Color.fromJson(json[r'color']),
        isFavorite: mapValueOfType<bool>(json, r'is_favorite') ?? false,
        viewStyle: mapValueOfType<String>(json, r'view_style'),
      );
    }
    return null;
  }

  static List<TodoistAppsApiRestProjectsBody1> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TodoistAppsApiRestProjectsBody1>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TodoistAppsApiRestProjectsBody1.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TodoistAppsApiRestProjectsBody1> mapFromJson(dynamic json) {
    final map = <String, TodoistAppsApiRestProjectsBody1>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TodoistAppsApiRestProjectsBody1.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TodoistAppsApiRestProjectsBody1-objects as value to a dart map
  static Map<String, List<TodoistAppsApiRestProjectsBody1>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TodoistAppsApiRestProjectsBody1>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TodoistAppsApiRestProjectsBody1.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
  };
}

