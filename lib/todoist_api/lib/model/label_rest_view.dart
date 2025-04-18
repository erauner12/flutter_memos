//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LabelRestView {
  /// Returns a new [LabelRestView] instance.
  LabelRestView({
    required this.id,
    required this.name,
    required this.color,
    required this.order,
    required this.isFavorite,
  });

  String id;

  String name;

  String color;

  int? order;

  bool isFavorite;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LabelRestView &&
    other.id == id &&
    other.name == name &&
    other.color == color &&
    other.order == order &&
    other.isFavorite == isFavorite;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (color.hashCode) +
    (order == null ? 0 : order!.hashCode) +
    (isFavorite.hashCode);

  @override
  String toString() => 'LabelRestView[id=$id, name=$name, color=$color, order=$order, isFavorite=$isFavorite]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'color'] = this.color;
    if (this.order != null) {
      json[r'order'] = this.order;
    } else {
      json[r'order'] = null;
    }
      json[r'is_favorite'] = this.isFavorite;
    return json;
  }

  /// Returns a new [LabelRestView] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LabelRestView? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "LabelRestView[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "LabelRestView[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return LabelRestView(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        color: mapValueOfType<String>(json, r'color')!,
        order: mapValueOfType<int>(json, r'order'),
        isFavorite: mapValueOfType<bool>(json, r'is_favorite')!,
      );
    }
    return null;
  }

  static List<LabelRestView> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LabelRestView>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LabelRestView.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LabelRestView> mapFromJson(dynamic json) {
    final map = <String, LabelRestView>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LabelRestView.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LabelRestView-objects as value to a dart map
  static Map<String, List<LabelRestView>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LabelRestView>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LabelRestView.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'color',
    'order',
    'is_favorite',
  };
}

