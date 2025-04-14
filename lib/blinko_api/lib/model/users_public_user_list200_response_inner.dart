//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UsersPublicUserList200ResponseInner {
  /// Returns a new [UsersPublicUserList200ResponseInner] instance.
  UsersPublicUserList200ResponseInner({
    required this.id,
    required this.name,
    required this.nickname,
    required this.role,
    required this.image,
    required this.loginType,
    required this.createdAt,
    required this.updatedAt,
    required this.description,
    required this.linkAccountId,
  });

  int id;

  String name;

  String nickname;

  String role;

  String? image;

  String loginType;

  String createdAt;

  String updatedAt;

  String? description;

  int? linkAccountId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UsersPublicUserList200ResponseInner &&
    other.id == id &&
    other.name == name &&
    other.nickname == nickname &&
    other.role == role &&
    other.image == image &&
    other.loginType == loginType &&
    other.createdAt == createdAt &&
    other.updatedAt == updatedAt &&
    other.description == description &&
    other.linkAccountId == linkAccountId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (nickname.hashCode) +
    (role.hashCode) +
    (image == null ? 0 : image!.hashCode) +
    (loginType.hashCode) +
    (createdAt.hashCode) +
    (updatedAt.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (linkAccountId == null ? 0 : linkAccountId!.hashCode);

  @override
  String toString() => 'UsersPublicUserList200ResponseInner[id=$id, name=$name, nickname=$nickname, role=$role, image=$image, loginType=$loginType, createdAt=$createdAt, updatedAt=$updatedAt, description=$description, linkAccountId=$linkAccountId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'nickname'] = this.nickname;
      json[r'role'] = this.role;
    if (this.image != null) {
      json[r'image'] = this.image;
    } else {
      json[r'image'] = null;
    }
      json[r'loginType'] = this.loginType;
      json[r'createdAt'] = this.createdAt;
      json[r'updatedAt'] = this.updatedAt;
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
    return json;
  }

  /// Returns a new [UsersPublicUserList200ResponseInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UsersPublicUserList200ResponseInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "UsersPublicUserList200ResponseInner[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "UsersPublicUserList200ResponseInner[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return UsersPublicUserList200ResponseInner(
        id: mapValueOfType<int>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        nickname: mapValueOfType<String>(json, r'nickname')!,
        role: mapValueOfType<String>(json, r'role')!,
        image: mapValueOfType<String>(json, r'image'),
        loginType: mapValueOfType<String>(json, r'loginType')!,
        createdAt: mapValueOfType<String>(json, r'createdAt')!,
        updatedAt: mapValueOfType<String>(json, r'updatedAt')!,
        description: mapValueOfType<String>(json, r'description'),
        linkAccountId: mapValueOfType<int>(json, r'linkAccountId'),
      );
    }
    return null;
  }

  static List<UsersPublicUserList200ResponseInner> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UsersPublicUserList200ResponseInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UsersPublicUserList200ResponseInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UsersPublicUserList200ResponseInner> mapFromJson(dynamic json) {
    final map = <String, UsersPublicUserList200ResponseInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UsersPublicUserList200ResponseInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UsersPublicUserList200ResponseInner-objects as value to a dart map
  static Map<String, List<UsersPublicUserList200ResponseInner>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UsersPublicUserList200ResponseInner>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UsersPublicUserList200ResponseInner.listFromJson(entry.value, growable: growable,);
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
    'image',
    'loginType',
    'createdAt',
    'updatedAt',
    'description',
    'linkAccountId',
  };
}

