//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TodoistAppsApiRestLabelsBody4 {
  /// Returns a new [TodoistAppsApiRestLabelsBody4] instance.
  TodoistAppsApiRestLabelsBody4({
    required this.name,
    this.order,
    this.color,
    this.isFavorite = false,
  });

  String name;

  /// Minimum value: -32768
  /// Maximum value: 32767
  int? order;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  TodoistAppsApiRestLabelsBody4Color? color;

  bool isFavorite;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TodoistAppsApiRestLabelsBody4 &&
    other.name == name &&
    other.order == order &&
    other.color == color &&
    other.isFavorite == isFavorite;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (order == null ? 0 : order!.hashCode) +
    (color == null ? 0 : color!.hashCode) +
    (isFavorite.hashCode);

  @override
  String toString() => 'TodoistAppsApiRestLabelsBody4[name=$name, order=$order, color=$color, isFavorite=$isFavorite]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'name'] = this.name;
    if (this.order != null) {
      json[r'order'] = this.order;
    } else {
      json[r'order'] = null;
    }
    if (this.color != null) {
      json[r'color'] = this.color;
    } else {
      json[r'color'] = null;
    }
      json[r'is_favorite'] = this.isFavorite;
    return json;
  }

  /// Returns a new [TodoistAppsApiRestLabelsBody4] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TodoistAppsApiRestLabelsBody4? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "TodoistAppsApiRestLabelsBody4[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "TodoistAppsApiRestLabelsBody4[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return TodoistAppsApiRestLabelsBody4(
        name: mapValueOfType<String>(json, r'name')!,
        order: mapValueOfType<int>(json, r'order'),
        color: TodoistAppsApiRestLabelsBody4Color.fromJson(json[r'color']),
        isFavorite: mapValueOfType<bool>(json, r'is_favorite') ?? false,
      );
    }
    return null;
  }

  static List<TodoistAppsApiRestLabelsBody4> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TodoistAppsApiRestLabelsBody4>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TodoistAppsApiRestLabelsBody4.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TodoistAppsApiRestLabelsBody4> mapFromJson(dynamic json) {
    final map = <String, TodoistAppsApiRestLabelsBody4>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TodoistAppsApiRestLabelsBody4.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TodoistAppsApiRestLabelsBody4-objects as value to a dart map
  static Map<String, List<TodoistAppsApiRestLabelsBody4>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TodoistAppsApiRestLabelsBody4>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TodoistAppsApiRestLabelsBody4.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
  };
}

