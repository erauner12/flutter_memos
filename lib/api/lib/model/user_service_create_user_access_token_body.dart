//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UserServiceCreateUserAccessTokenBody {
  /// Returns a new [UserServiceCreateUserAccessTokenBody] instance.
  UserServiceCreateUserAccessTokenBody({
    this.description,
    this.expiresAt,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? description;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? expiresAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UserServiceCreateUserAccessTokenBody &&
    other.description == description &&
    other.expiresAt == expiresAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (description == null ? 0 : description!.hashCode) +
    (expiresAt == null ? 0 : expiresAt!.hashCode);

  @override
  String toString() => 'UserServiceCreateUserAccessTokenBody[description=$description, expiresAt=$expiresAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
    if (this.expiresAt != null) {
      json[r'expiresAt'] = this.expiresAt!.toUtc().toIso8601String();
    } else {
      json[r'expiresAt'] = null;
    }
    return json;
  }

  /// Returns a new [UserServiceCreateUserAccessTokenBody] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UserServiceCreateUserAccessTokenBody? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "UserServiceCreateUserAccessTokenBody[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "UserServiceCreateUserAccessTokenBody[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return UserServiceCreateUserAccessTokenBody(
        description: mapValueOfType<String>(json, r'description'),
        expiresAt: mapDateTime(json, r'expiresAt', r''),
      );
    }
    return null;
  }

  static List<UserServiceCreateUserAccessTokenBody> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UserServiceCreateUserAccessTokenBody>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UserServiceCreateUserAccessTokenBody.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UserServiceCreateUserAccessTokenBody> mapFromJson(dynamic json) {
    final map = <String, UserServiceCreateUserAccessTokenBody>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UserServiceCreateUserAccessTokenBody.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UserServiceCreateUserAccessTokenBody-objects as value to a dart map
  static Map<String, List<UserServiceCreateUserAccessTokenBody>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UserServiceCreateUserAccessTokenBody>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UserServiceCreateUserAccessTokenBody.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

