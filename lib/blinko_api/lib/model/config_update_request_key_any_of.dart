//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ConfigUpdateRequestKeyAnyOf {
  /// Returns a new [ConfigUpdateRequestKeyAnyOf] instance.
  ConfigUpdateRequestKeyAnyOf();

  @override
  bool operator ==(Object other) => identical(this, other) || other is ConfigUpdateRequestKeyAnyOf;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'ConfigUpdateRequestKeyAnyOf[]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    return json;
  }

  /// Returns a new [ConfigUpdateRequestKeyAnyOf] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ConfigUpdateRequestKeyAnyOf? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ConfigUpdateRequestKeyAnyOf[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ConfigUpdateRequestKeyAnyOf[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ConfigUpdateRequestKeyAnyOf(
      );
    }
    return null;
  }

  static List<ConfigUpdateRequestKeyAnyOf> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ConfigUpdateRequestKeyAnyOf>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ConfigUpdateRequestKeyAnyOf.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ConfigUpdateRequestKeyAnyOf> mapFromJson(dynamic json) {
    final map = <String, ConfigUpdateRequestKeyAnyOf>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ConfigUpdateRequestKeyAnyOf.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ConfigUpdateRequestKeyAnyOf-objects as value to a dart map
  static Map<String, List<ConfigUpdateRequestKeyAnyOf>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ConfigUpdateRequestKeyAnyOf>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ConfigUpdateRequestKeyAnyOf.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}