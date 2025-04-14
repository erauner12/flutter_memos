//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UsersList200ResponseInner {
  /// Returns a new [UsersList200ResponseInner] instance.
  UsersList200ResponseInner({
    required this.id,
    required this.name,
    required this.nickname,
    required this.password,
    required this.image,
    required this.apiToken,
    required this.note,
    required this.role,
    this.loginType,
    this.description,
    this.linkAccountId,
    required this.createdAt,
    required this.updatedAt,
  });

  int id;

  String name;

  String nickname;

  String password;

  String image;

  String apiToken;

  int note;

  String role;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? loginType;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? description;

  int? linkAccountId;

  String createdAt;

  String updatedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UsersList200ResponseInner &&
    other.id == id &&
    other.name == name &&
    other.nickname == nickname &&
    other.password == password &&
    other.image == image &&
    other.apiToken == apiToken &&
    other.note == note &&
    other.role == role &&
    other.loginType == loginType &&
    other.description == description &&
    other.linkAccountId == linkAccountId &&
    other.createdAt == createdAt &&
    other.updatedAt == updatedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (nickname.hashCode) +
    (password.hashCode) +
    (image.hashCode) +
    (apiToken.hashCode) +
    (note.hashCode) +
    (role.hashCode) +
    (loginType == null ? 0 : loginType!.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (linkAccountId == null ? 0 : linkAccountId!.hashCode) +
    (createdAt.hashCode) +
    (updatedAt.hashCode);

  @override
  String toString() => 'UsersList200ResponseInner[id=$id, name=$name, nickname=$nickname, password=$password, image=$image, apiToken=$apiToken, note=$note, role=$role, loginType=$loginType, description=$description, linkAccountId=$linkAccountId, createdAt=$createdAt, updatedAt=$updatedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'nickname'] = this.nickname;
      json[r'password'] = this.password;
      json[r'image'] = this.image;
      json[r'apiToken'] = this.apiToken;
      json[r'note'] = this.note;
      json[r'role'] = this.role;
    if (this.loginType != null) {
      json[r'loginType'] = this.loginType;
    } else {
      json[r'loginType'] = null;
    }
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
    if (this.linkAccountId != null) {
      json[r'linkAccountId'] = this.linkAccountId;
    } else {
      json[r'linkAccountId'] = null;
    }
      json[r'createdAt'] = this.createdAt;
      json[r'updatedAt'] = this.updatedAt;
    return json;
  }

  /// Returns a new [UsersList200ResponseInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UsersList200ResponseInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "UsersList200ResponseInner[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "UsersList200ResponseInner[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return UsersList200ResponseInner(
        id: mapValueOfType<int>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        nickname: mapValueOfType<String>(json, r'nickname')!,
        password: mapValueOfType<String>(json, r'password')!,
        image: mapValueOfType<String>(json, r'image')!,
        apiToken: mapValueOfType<String>(json, r'apiToken')!,
        note: mapValueOfType<int>(json, r'note')!,
        role: mapValueOfType<String>(json, r'role')!,
        loginType: mapValueOfType<String>(json, r'loginType'),
        description: mapValueOfType<String>(json, r'description'),
        linkAccountId: mapValueOfType<int>(json, r'linkAccountId'),
        createdAt: mapValueOfType<String>(json, r'createdAt')!,
        updatedAt: mapValueOfType<String>(json, r'updatedAt')!,
      );
    }
    return null;
  }

  static List<UsersList200ResponseInner> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UsersList200ResponseInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UsersList200ResponseInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UsersList200ResponseInner> mapFromJson(dynamic json) {
    final map = <String, UsersList200ResponseInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UsersList200ResponseInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UsersList200ResponseInner-objects as value to a dart map
  static Map<String, List<UsersList200ResponseInner>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UsersList200ResponseInner>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UsersList200ResponseInner.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'nickname',
    'password',
    'image',
    'apiToken',
    'note',
    'role',
    'createdAt',
    'updatedAt',
  };
}

