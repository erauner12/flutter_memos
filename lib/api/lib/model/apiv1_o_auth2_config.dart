//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Apiv1OAuth2Config {
  /// Returns a new [Apiv1OAuth2Config] instance.
  Apiv1OAuth2Config({
    this.clientId,
    this.clientSecret,
    this.authUrl,
    this.tokenUrl,
    this.userInfoUrl,
    this.scopes = const [],
    this.fieldMapping,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? clientId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? clientSecret;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? authUrl;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? tokenUrl;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? userInfoUrl;

  List<String> scopes;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Apiv1FieldMapping? fieldMapping;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Apiv1OAuth2Config &&
    other.clientId == clientId &&
    other.clientSecret == clientSecret &&
    other.authUrl == authUrl &&
    other.tokenUrl == tokenUrl &&
    other.userInfoUrl == userInfoUrl &&
    _deepEquality.equals(other.scopes, scopes) &&
    other.fieldMapping == fieldMapping;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (clientId == null ? 0 : clientId!.hashCode) +
    (clientSecret == null ? 0 : clientSecret!.hashCode) +
    (authUrl == null ? 0 : authUrl!.hashCode) +
    (tokenUrl == null ? 0 : tokenUrl!.hashCode) +
    (userInfoUrl == null ? 0 : userInfoUrl!.hashCode) +
    (scopes.hashCode) +
    (fieldMapping == null ? 0 : fieldMapping!.hashCode);

  @override
  String toString() => 'Apiv1OAuth2Config[clientId=$clientId, clientSecret=$clientSecret, authUrl=$authUrl, tokenUrl=$tokenUrl, userInfoUrl=$userInfoUrl, scopes=$scopes, fieldMapping=$fieldMapping]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.clientId != null) {
      json[r'clientId'] = this.clientId;
    } else {
      json[r'clientId'] = null;
    }
    if (this.clientSecret != null) {
      json[r'clientSecret'] = this.clientSecret;
    } else {
      json[r'clientSecret'] = null;
    }
    if (this.authUrl != null) {
      json[r'authUrl'] = this.authUrl;
    } else {
      json[r'authUrl'] = null;
    }
    if (this.tokenUrl != null) {
      json[r'tokenUrl'] = this.tokenUrl;
    } else {
      json[r'tokenUrl'] = null;
    }
    if (this.userInfoUrl != null) {
      json[r'userInfoUrl'] = this.userInfoUrl;
    } else {
      json[r'userInfoUrl'] = null;
    }
      json[r'scopes'] = this.scopes;
    if (this.fieldMapping != null) {
      json[r'fieldMapping'] = this.fieldMapping;
    } else {
      json[r'fieldMapping'] = null;
    }
    return json;
  }

  /// Returns a new [Apiv1OAuth2Config] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Apiv1OAuth2Config? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Apiv1OAuth2Config[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Apiv1OAuth2Config[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Apiv1OAuth2Config(
        clientId: mapValueOfType<String>(json, r'clientId'),
        clientSecret: mapValueOfType<String>(json, r'clientSecret'),
        authUrl: mapValueOfType<String>(json, r'authUrl'),
        tokenUrl: mapValueOfType<String>(json, r'tokenUrl'),
        userInfoUrl: mapValueOfType<String>(json, r'userInfoUrl'),
        scopes: json[r'scopes'] is Iterable
            ? (json[r'scopes'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        fieldMapping: Apiv1FieldMapping.fromJson(json[r'fieldMapping']),
      );
    }
    return null;
  }

  static List<Apiv1OAuth2Config> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Apiv1OAuth2Config>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Apiv1OAuth2Config.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Apiv1OAuth2Config> mapFromJson(dynamic json) {
    final map = <String, Apiv1OAuth2Config>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Apiv1OAuth2Config.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Apiv1OAuth2Config-objects as value to a dart map
  static Map<String, List<Apiv1OAuth2Config>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Apiv1OAuth2Config>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Apiv1OAuth2Config.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

