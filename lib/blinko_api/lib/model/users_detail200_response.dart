//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UsersDetail200Response {
  /// Returns a new [UsersDetail200Response] instance.
  UsersDetail200Response({
    required this.id,
    required this.name,
    required this.nickName,
    required this.token,
    required this.isLinked,
    required this.loginType,
    required this.image,
    required this.role,
  });

  num id;

  String name;

  String nickName;

  String token;

  bool isLinked;

  String loginType;

  String? image;

  String role;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UsersDetail200Response &&
    other.id == id &&
    other.name == name &&
    other.nickName == nickName &&
    other.token == token &&
    other.isLinked == isLinked &&
    other.loginType == loginType &&
    other.image == image &&
    other.role == role;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (nickName.hashCode) +
    (token.hashCode) +
    (isLinked.hashCode) +
    (loginType.hashCode) +
    (image == null ? 0 : image!.hashCode) +
    (role.hashCode);

  @override
  String toString() => 'UsersDetail200Response[id=$id, name=$name, nickName=$nickName, token=$token, isLinked=$isLinked, loginType=$loginType, image=$image, role=$role]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'nickName'] = this.nickName;
      json[r'token'] = this.token;
      json[r'isLinked'] = this.isLinked;
      json[r'loginType'] = this.loginType;
    if (this.image != null) {
      json[r'image'] = this.image;
    } else {
      json[r'image'] = null;
    }
      json[r'role'] = this.role;
    return json;
  }

  /// Returns a new [UsersDetail200Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UsersDetail200Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "UsersDetail200Response[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "UsersDetail200Response[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return UsersDetail200Response(
        id: num.parse('${json[r'id']}'),
        name: mapValueOfType<String>(json, r'name')!,
        nickName: mapValueOfType<String>(json, r'nickName')!,
        token: mapValueOfType<String>(json, r'token')!,
        isLinked: mapValueOfType<bool>(json, r'isLinked')!,
        loginType: mapValueOfType<String>(json, r'loginType')!,
        image: mapValueOfType<String>(json, r'image'),
        role: mapValueOfType<String>(json, r'role')!,
      );
    }
    return null;
  }

  static List<UsersDetail200Response> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UsersDetail200Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UsersDetail200Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UsersDetail200Response> mapFromJson(dynamic json) {
    final map = <String, UsersDetail200Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UsersDetail200Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UsersDetail200Response-objects as value to a dart map
  static Map<String, List<UsersDetail200Response>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UsersDetail200Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UsersDetail200Response.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'nickName',
    'token',
    'isLinked',
    'loginType',
    'image',
    'role',
  };
}

