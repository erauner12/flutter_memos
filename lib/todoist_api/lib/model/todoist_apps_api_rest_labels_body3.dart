//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TodoistAppsApiRestLabelsBody3 {
  /// Returns a new [TodoistAppsApiRestLabelsBody3] instance.
  TodoistAppsApiRestLabelsBody3({
    this.name,
    this.order,
    this.color,
    this.isFavorite,
  });

  String? name;

  /// Minimum value: -32768
  /// Maximum value: 32767
  int? order;

  TodoistAppsApiRestLabelsBody3Color? color;

  bool? isFavorite;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TodoistAppsApiRestLabelsBody3 &&
    other.name == name &&
    other.order == order &&
    other.color == color &&
    other.isFavorite == isFavorite;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name == null ? 0 : name!.hashCode) +
    (order == null ? 0 : order!.hashCode) +
    (color == null ? 0 : color!.hashCode) +
    (isFavorite == null ? 0 : isFavorite!.hashCode);

  @override
  String toString() => 'TodoistAppsApiRestLabelsBody3[name=$name, order=$order, color=$color, isFavorite=$isFavorite]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
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
    if (this.isFavorite != null) {
      json[r'is_favorite'] = this.isFavorite;
    } else {
      json[r'is_favorite'] = null;
    }
    return json;
  }

  /// Returns a new [TodoistAppsApiRestLabelsBody3] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TodoistAppsApiRestLabelsBody3? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "TodoistAppsApiRestLabelsBody3[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "TodoistAppsApiRestLabelsBody3[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return TodoistAppsApiRestLabelsBody3(
        name: mapValueOfType<String>(json, r'name'),
        order: mapValueOfType<int>(json, r'order'),
        color: TodoistAppsApiRestLabelsBody3Color.fromJson(json[r'color']),
        isFavorite: mapValueOfType<bool>(json, r'is_favorite'),
      );
    }
    return null;
  }

  static List<TodoistAppsApiRestLabelsBody3> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TodoistAppsApiRestLabelsBody3>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TodoistAppsApiRestLabelsBody3.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TodoistAppsApiRestLabelsBody3> mapFromJson(dynamic json) {
    final map = <String, TodoistAppsApiRestLabelsBody3>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TodoistAppsApiRestLabelsBody3.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TodoistAppsApiRestLabelsBody3-objects as value to a dart map
  static Map<String, List<TodoistAppsApiRestLabelsBody3>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TodoistAppsApiRestLabelsBody3>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TodoistAppsApiRestLabelsBody3.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

