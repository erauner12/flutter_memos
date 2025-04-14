//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ConfigSetPluginConfigRequest {
  /// Returns a new [ConfigSetPluginConfigRequest] instance.
  ConfigSetPluginConfigRequest({
    required this.pluginName,
    required this.key,
    this.value,
  });

  String pluginName;

  String key;

  Object? value;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ConfigSetPluginConfigRequest &&
    other.pluginName == pluginName &&
    other.key == key &&
    other.value == value;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (pluginName.hashCode) +
    (key.hashCode) +
    (value == null ? 0 : value!.hashCode);

  @override
  String toString() => 'ConfigSetPluginConfigRequest[pluginName=$pluginName, key=$key, value=$value]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'pluginName'] = this.pluginName;
      json[r'key'] = this.key;
    if (this.value != null) {
      json[r'value'] = this.value;
    } else {
      json[r'value'] = null;
    }
    return json;
  }

  /// Returns a new [ConfigSetPluginConfigRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ConfigSetPluginConfigRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ConfigSetPluginConfigRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ConfigSetPluginConfigRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ConfigSetPluginConfigRequest(
        pluginName: mapValueOfType<String>(json, r'pluginName')!,
        key: mapValueOfType<String>(json, r'key')!,
        value: mapValueOfType<Object>(json, r'value'),
      );
    }
    return null;
  }

  static List<ConfigSetPluginConfigRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ConfigSetPluginConfigRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ConfigSetPluginConfigRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ConfigSetPluginConfigRequest> mapFromJson(dynamic json) {
    final map = <String, ConfigSetPluginConfigRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ConfigSetPluginConfigRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ConfigSetPluginConfigRequest-objects as value to a dart map
  static Map<String, List<ConfigSetPluginConfigRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ConfigSetPluginConfigRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ConfigSetPluginConfigRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'pluginName',
    'key',
  };
}

