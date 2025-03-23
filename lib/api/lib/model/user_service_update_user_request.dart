//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UserServiceUpdateUserRequest {
  /// Returns a new [UserServiceUpdateUserRequest] instance.
  UserServiceUpdateUserRequest({
    this.role,
    this.username,
    this.email,
    this.nickname,
    this.avatarUrl,
    this.description,
    this.password,
    this.state,
    this.createTime,
    this.updateTime,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  UserRole? role;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? username;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? email;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? nickname;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? avatarUrl;

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
  String? password;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  V1State? state;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? createTime;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? updateTime;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UserServiceUpdateUserRequest &&
    other.role == role &&
    other.username == username &&
    other.email == email &&
    other.nickname == nickname &&
    other.avatarUrl == avatarUrl &&
    other.description == description &&
    other.password == password &&
    other.state == state &&
    other.createTime == createTime &&
    other.updateTime == updateTime;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (role == null ? 0 : role!.hashCode) +
    (username == null ? 0 : username!.hashCode) +
    (email == null ? 0 : email!.hashCode) +
    (nickname == null ? 0 : nickname!.hashCode) +
    (avatarUrl == null ? 0 : avatarUrl!.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (password == null ? 0 : password!.hashCode) +
    (state == null ? 0 : state!.hashCode) +
    (createTime == null ? 0 : createTime!.hashCode) +
    (updateTime == null ? 0 : updateTime!.hashCode);

  @override
  String toString() => 'UserServiceUpdateUserRequest[role=$role, username=$username, email=$email, nickname=$nickname, avatarUrl=$avatarUrl, description=$description, password=$password, state=$state, createTime=$createTime, updateTime=$updateTime]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.role != null) {
      json[r'role'] = this.role;
    } else {
      json[r'role'] = null;
    }
    if (this.username != null) {
      json[r'username'] = this.username;
    } else {
      json[r'username'] = null;
    }
    if (this.email != null) {
      json[r'email'] = this.email;
    } else {
      json[r'email'] = null;
    }
    if (this.nickname != null) {
      json[r'nickname'] = this.nickname;
    } else {
      json[r'nickname'] = null;
    }
    if (this.avatarUrl != null) {
      json[r'avatarUrl'] = this.avatarUrl;
    } else {
      json[r'avatarUrl'] = null;
    }
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
    if (this.password != null) {
      json[r'password'] = this.password;
    } else {
      json[r'password'] = null;
    }
    if (this.state != null) {
      json[r'state'] = this.state;
    } else {
      json[r'state'] = null;
    }
    if (this.createTime != null) {
      json[r'createTime'] = this.createTime!.toUtc().toIso8601String();
    } else {
      json[r'createTime'] = null;
    }
    if (this.updateTime != null) {
      json[r'updateTime'] = this.updateTime!.toUtc().toIso8601String();
    } else {
      json[r'updateTime'] = null;
    }
    return json;
  }

  /// Returns a new [UserServiceUpdateUserRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UserServiceUpdateUserRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "UserServiceUpdateUserRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "UserServiceUpdateUserRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return UserServiceUpdateUserRequest(
        role: UserRole.fromJson(json[r'role']),
        username: mapValueOfType<String>(json, r'username'),
        email: mapValueOfType<String>(json, r'email'),
        nickname: mapValueOfType<String>(json, r'nickname'),
        avatarUrl: mapValueOfType<String>(json, r'avatarUrl'),
        description: mapValueOfType<String>(json, r'description'),
        password: mapValueOfType<String>(json, r'password'),
        state: V1State.fromJson(json[r'state']),
        createTime: mapDateTime(json, r'createTime', r''),
        updateTime: mapDateTime(json, r'updateTime', r''),
      );
    }
    return null;
  }

  static List<UserServiceUpdateUserRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UserServiceUpdateUserRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UserServiceUpdateUserRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UserServiceUpdateUserRequest> mapFromJson(dynamic json) {
    final map = <String, UserServiceUpdateUserRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UserServiceUpdateUserRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UserServiceUpdateUserRequest-objects as value to a dart map
  static Map<String, List<UserServiceUpdateUserRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UserServiceUpdateUserRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UserServiceUpdateUserRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

