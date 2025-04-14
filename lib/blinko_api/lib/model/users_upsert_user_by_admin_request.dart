//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UsersUpsertUserByAdminRequest {
  /// Returns a new [UsersUpsertUserByAdminRequest] instance.
  UsersUpsertUserByAdminRequest({
    this.id,
    this.name,
    this.password,
    this.nickname,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? id;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? password;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? nickname;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UsersUpsertUserByAdminRequest &&
    other.id == id &&
    other.name == name &&
    other.password == password &&
    other.nickname == nickname;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (name == null ? 0 : name!.hashCode) +
    (password == null ? 0 : password!.hashCode) +
    (nickname == null ? 0 : nickname!.hashCode);

  @override
  String toString() => 'UsersUpsertUserByAdminRequest[id=$id, name=$name, password=$password, nickname=$nickname]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    if (this.password != null) {
      json[r'password'] = this.password;
    } else {
      json[r'password'] = null;
    }
    if (this.nickname != null) {
      json[r'nickname'] = this.nickname;
    } else {
      json[r'nickname'] = null;
    }
    return json;
  }

  /// Returns a new [UsersUpsertUserByAdminRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UsersUpsertUserByAdminRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "UsersUpsertUserByAdminRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "UsersUpsertUserByAdminRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return UsersUpsertUserByAdminRequest(
        id: num.parse('${json[r'id']}'),
        name: mapValueOfType<String>(json, r'name'),
        password: mapValueOfType<String>(json, r'password'),
        nickname: mapValueOfType<String>(json, r'nickname'),
      );
    }
    return null;
  }

  static List<UsersUpsertUserByAdminRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UsersUpsertUserByAdminRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UsersUpsertUserByAdminRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UsersUpsertUserByAdminRequest> mapFromJson(dynamic json) {
    final map = <String, UsersUpsertUserByAdminRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UsersUpsertUserByAdminRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UsersUpsertUserByAdminRequest-objects as value to a dart map
  static Map<String, List<UsersUpsertUserByAdminRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UsersUpsertUserByAdminRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UsersUpsertUserByAdminRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

