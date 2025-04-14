//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ConfigList200ResponseOauth2ProvidersInner {
  /// Returns a new [ConfigList200ResponseOauth2ProvidersInner] instance.
  ConfigList200ResponseOauth2ProvidersInner({
    required this.id,
    required this.name,
    this.icon,
    this.wellKnown,
    this.scope,
    this.authorizationUrl,
    required this.tokenUrl,
    required this.userinfoUrl,
    required this.clientId,
    required this.clientSecret,
  });

  String id;

  String name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? icon;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? wellKnown;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? scope;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? authorizationUrl;

  String tokenUrl;

  String userinfoUrl;

  String clientId;

  String clientSecret;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ConfigList200ResponseOauth2ProvidersInner &&
    other.id == id &&
    other.name == name &&
    other.icon == icon &&
    other.wellKnown == wellKnown &&
    other.scope == scope &&
    other.authorizationUrl == authorizationUrl &&
    other.tokenUrl == tokenUrl &&
    other.userinfoUrl == userinfoUrl &&
    other.clientId == clientId &&
    other.clientSecret == clientSecret;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (icon == null ? 0 : icon!.hashCode) +
    (wellKnown == null ? 0 : wellKnown!.hashCode) +
    (scope == null ? 0 : scope!.hashCode) +
    (authorizationUrl == null ? 0 : authorizationUrl!.hashCode) +
    (tokenUrl.hashCode) +
    (userinfoUrl.hashCode) +
    (clientId.hashCode) +
    (clientSecret.hashCode);

  @override
  String toString() => 'ConfigList200ResponseOauth2ProvidersInner[id=$id, name=$name, icon=$icon, wellKnown=$wellKnown, scope=$scope, authorizationUrl=$authorizationUrl, tokenUrl=$tokenUrl, userinfoUrl=$userinfoUrl, clientId=$clientId, clientSecret=$clientSecret]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
    if (this.icon != null) {
      json[r'icon'] = this.icon;
    } else {
      json[r'icon'] = null;
    }
    if (this.wellKnown != null) {
      json[r'wellKnown'] = this.wellKnown;
    } else {
      json[r'wellKnown'] = null;
    }
    if (this.scope != null) {
      json[r'scope'] = this.scope;
    } else {
      json[r'scope'] = null;
    }
    if (this.authorizationUrl != null) {
      json[r'authorizationUrl'] = this.authorizationUrl;
    } else {
      json[r'authorizationUrl'] = null;
    }
      json[r'tokenUrl'] = this.tokenUrl;
      json[r'userinfoUrl'] = this.userinfoUrl;
      json[r'clientId'] = this.clientId;
      json[r'clientSecret'] = this.clientSecret;
    return json;
  }

  /// Returns a new [ConfigList200ResponseOauth2ProvidersInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ConfigList200ResponseOauth2ProvidersInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ConfigList200ResponseOauth2ProvidersInner[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ConfigList200ResponseOauth2ProvidersInner[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ConfigList200ResponseOauth2ProvidersInner(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        icon: mapValueOfType<String>(json, r'icon'),
        wellKnown: mapValueOfType<String>(json, r'wellKnown'),
        scope: mapValueOfType<String>(json, r'scope'),
        authorizationUrl: mapValueOfType<String>(json, r'authorizationUrl'),
        tokenUrl: mapValueOfType<String>(json, r'tokenUrl')!,
        userinfoUrl: mapValueOfType<String>(json, r'userinfoUrl')!,
        clientId: mapValueOfType<String>(json, r'clientId')!,
        clientSecret: mapValueOfType<String>(json, r'clientSecret')!,
      );
    }
    return null;
  }

  static List<ConfigList200ResponseOauth2ProvidersInner> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ConfigList200ResponseOauth2ProvidersInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ConfigList200ResponseOauth2ProvidersInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ConfigList200ResponseOauth2ProvidersInner> mapFromJson(dynamic json) {
    final map = <String, ConfigList200ResponseOauth2ProvidersInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ConfigList200ResponseOauth2ProvidersInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ConfigList200ResponseOauth2ProvidersInner-objects as value to a dart map
  static Map<String, List<ConfigList200ResponseOauth2ProvidersInner>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ConfigList200ResponseOauth2ProvidersInner>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ConfigList200ResponseOauth2ProvidersInner.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'tokenUrl',
    'userinfoUrl',
    'clientId',
    'clientSecret',
  };
}

