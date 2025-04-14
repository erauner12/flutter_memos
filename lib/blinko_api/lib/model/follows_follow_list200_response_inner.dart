//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class FollowsFollowList200ResponseInner {
  /// Returns a new [FollowsFollowList200ResponseInner] instance.
  FollowsFollowList200ResponseInner({
    required this.id,
    this.siteName,
    required this.siteUrl,
    this.siteAvatar,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.followType,
    required this.accountId,
  });

  int id;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? siteName;

  String siteUrl;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? siteAvatar;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? description;

  String createdAt;

  String updatedAt;

  String followType;

  int accountId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is FollowsFollowList200ResponseInner &&
    other.id == id &&
    other.siteName == siteName &&
    other.siteUrl == siteUrl &&
    other.siteAvatar == siteAvatar &&
    other.description == description &&
    other.createdAt == createdAt &&
    other.updatedAt == updatedAt &&
    other.followType == followType &&
    other.accountId == accountId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (siteName == null ? 0 : siteName!.hashCode) +
    (siteUrl.hashCode) +
    (siteAvatar == null ? 0 : siteAvatar!.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (createdAt.hashCode) +
    (updatedAt.hashCode) +
    (followType.hashCode) +
    (accountId.hashCode);

  @override
  String toString() => 'FollowsFollowList200ResponseInner[id=$id, siteName=$siteName, siteUrl=$siteUrl, siteAvatar=$siteAvatar, description=$description, createdAt=$createdAt, updatedAt=$updatedAt, followType=$followType, accountId=$accountId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
    if (this.siteName != null) {
      json[r'siteName'] = this.siteName;
    } else {
      json[r'siteName'] = null;
    }
      json[r'siteUrl'] = this.siteUrl;
    if (this.siteAvatar != null) {
      json[r'siteAvatar'] = this.siteAvatar;
    } else {
      json[r'siteAvatar'] = null;
    }
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
      json[r'createdAt'] = this.createdAt;
      json[r'updatedAt'] = this.updatedAt;
      json[r'followType'] = this.followType;
      json[r'accountId'] = this.accountId;
    return json;
  }

  /// Returns a new [FollowsFollowList200ResponseInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FollowsFollowList200ResponseInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "FollowsFollowList200ResponseInner[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "FollowsFollowList200ResponseInner[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return FollowsFollowList200ResponseInner(
        id: mapValueOfType<int>(json, r'id')!,
        siteName: mapValueOfType<String>(json, r'siteName'),
        siteUrl: mapValueOfType<String>(json, r'siteUrl')!,
        siteAvatar: mapValueOfType<String>(json, r'siteAvatar'),
        description: mapValueOfType<String>(json, r'description'),
        createdAt: mapValueOfType<String>(json, r'createdAt')!,
        updatedAt: mapValueOfType<String>(json, r'updatedAt')!,
        followType: mapValueOfType<String>(json, r'followType')!,
        accountId: mapValueOfType<int>(json, r'accountId')!,
      );
    }
    return null;
  }

  static List<FollowsFollowList200ResponseInner> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <FollowsFollowList200ResponseInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FollowsFollowList200ResponseInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FollowsFollowList200ResponseInner> mapFromJson(dynamic json) {
    final map = <String, FollowsFollowList200ResponseInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FollowsFollowList200ResponseInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FollowsFollowList200ResponseInner-objects as value to a dart map
  static Map<String, List<FollowsFollowList200ResponseInner>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<FollowsFollowList200ResponseInner>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FollowsFollowList200ResponseInner.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'siteUrl',
    'createdAt',
    'updatedAt',
    'followType',
    'accountId',
  };
}

