//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UsersLogin200Response {
  /// Returns a new [UsersLogin200Response] instance.
  UsersLogin200Response({
    required this.id,
    required this.name,
    required this.nickname,
    required this.role,
    required this.token,
    required this.image,
    required this.loginType,
  });

  num id;

  String name;

  String nickname;

  String role;

  String token;

  String? image;

  String loginType;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UsersLogin200Response &&
    other.id == id &&
    other.name == name &&
    other.nickname == nickname &&
    other.role == role &&
    other.token == token &&
    other.image == image &&
    other.loginType == loginType;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (nickname.hashCode) +
    (role.hashCode) +
    (token.hashCode) +
    (image == null ? 0 : image!.hashCode) +
    (loginType.hashCode);

  @override
  String toString() => 'UsersLogin200Response[id=$id, name=$name, nickname=$nickname, role=$role, token=$token, image=$image, loginType=$loginType]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'nickname'] = this.nickname;
      json[r'role'] = this.role;
      json[r'token'] = this.token;
    if (this.image != null) {
      json[r'image'] = this.image;
    } else {
      json[r'image'] = null;
    }
      json[r'loginType'] = this.loginType;
    return json;
  }

  /// Returns a new [UsersLogin200Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UsersLogin200Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "UsersLogin200Response[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "UsersLogin200Response[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return UsersLogin200Response(
        id: num.parse('${json[r'id']}'),
        name: mapValueOfType<String>(json, r'name')!,
        nickname: mapValueOfType<String>(json, r'nickname')!,
        role: mapValueOfType<String>(json, r'role')!,
        token: mapValueOfType<String>(json, r'token')!,
        image: mapValueOfType<String>(json, r'image'),
        loginType: mapValueOfType<String>(json, r'loginType')!,
      );
    }
    return null;
  }

  static List<UsersLogin200Response> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UsersLogin200Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UsersLogin200Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UsersLogin200Response> mapFromJson(dynamic json) {
    final map = <String, UsersLogin200Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UsersLogin200Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UsersLogin200Response-objects as value to a dart map
  static Map<String, List<UsersLogin200Response>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UsersLogin200Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UsersLogin200Response.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'nickname',
    'role',
    'token',
    'image',
    'loginType',
  };
}

