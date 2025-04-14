//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class FollowsFollowFromRequest {
  /// Returns a new [FollowsFollowFromRequest] instance.
  FollowsFollowFromRequest({
    required this.mySiteAccountId,
    required this.siteUrl,
    required this.siteName,
    required this.siteAvatar,
  });

  num mySiteAccountId;

  String siteUrl;

  String siteName;

  String siteAvatar;

  @override
  bool operator ==(Object other) => identical(this, other) || other is FollowsFollowFromRequest &&
    other.mySiteAccountId == mySiteAccountId &&
    other.siteUrl == siteUrl &&
    other.siteName == siteName &&
    other.siteAvatar == siteAvatar;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (mySiteAccountId.hashCode) +
    (siteUrl.hashCode) +
    (siteName.hashCode) +
    (siteAvatar.hashCode);

  @override
  String toString() => 'FollowsFollowFromRequest[mySiteAccountId=$mySiteAccountId, siteUrl=$siteUrl, siteName=$siteName, siteAvatar=$siteAvatar]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'mySiteAccountId'] = this.mySiteAccountId;
      json[r'siteUrl'] = this.siteUrl;
      json[r'siteName'] = this.siteName;
      json[r'siteAvatar'] = this.siteAvatar;
    return json;
  }

  /// Returns a new [FollowsFollowFromRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FollowsFollowFromRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "FollowsFollowFromRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "FollowsFollowFromRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return FollowsFollowFromRequest(
        mySiteAccountId: num.parse('${json[r'mySiteAccountId']}'),
        siteUrl: mapValueOfType<String>(json, r'siteUrl')!,
        siteName: mapValueOfType<String>(json, r'siteName')!,
        siteAvatar: mapValueOfType<String>(json, r'siteAvatar')!,
      );
    }
    return null;
  }

  static List<FollowsFollowFromRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <FollowsFollowFromRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FollowsFollowFromRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FollowsFollowFromRequest> mapFromJson(dynamic json) {
    final map = <String, FollowsFollowFromRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FollowsFollowFromRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FollowsFollowFromRequest-objects as value to a dart map
  static Map<String, List<FollowsFollowFromRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<FollowsFollowFromRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FollowsFollowFromRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'mySiteAccountId',
    'siteUrl',
    'siteName',
    'siteAvatar',
  };
}

