//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ConfigUpdate200Response {
  /// Returns a new [ConfigUpdate200Response] instance.
  ConfigUpdate200Response({
    required this.id,
    required this.key,
    this.config,
  });

  int id;

  String key;

  Object? config;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ConfigUpdate200Response &&
    other.id == id &&
    other.key == key &&
    other.config == config;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (key.hashCode) +
    (config == null ? 0 : config!.hashCode);

  @override
  String toString() => 'ConfigUpdate200Response[id=$id, key=$key, config=$config]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'key'] = this.key;
    if (this.config != null) {
      json[r'config'] = this.config;
    } else {
      json[r'config'] = null;
    }
    return json;
  }

  /// Returns a new [ConfigUpdate200Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ConfigUpdate200Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ConfigUpdate200Response[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ConfigUpdate200Response[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ConfigUpdate200Response(
        id: mapValueOfType<int>(json, r'id')!,
        key: mapValueOfType<String>(json, r'key')!,
        config: mapValueOfType<Object>(json, r'config'),
      );
    }
    return null;
  }

  static List<ConfigUpdate200Response> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ConfigUpdate200Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ConfigUpdate200Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ConfigUpdate200Response> mapFromJson(dynamic json) {
    final map = <String, ConfigUpdate200Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ConfigUpdate200Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ConfigUpdate200Response-objects as value to a dart map
  static Map<String, List<ConfigUpdate200Response>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ConfigUpdate200Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ConfigUpdate200Response.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'key',
  };
}

