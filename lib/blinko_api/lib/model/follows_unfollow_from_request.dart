//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class FollowsUnfollowFromRequest {
  /// Returns a new [FollowsUnfollowFromRequest] instance.
  FollowsUnfollowFromRequest({
    required this.siteUrl,
    required this.mySiteAccountId,
  });

  String siteUrl;

  num mySiteAccountId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is FollowsUnfollowFromRequest &&
    other.siteUrl == siteUrl &&
    other.mySiteAccountId == mySiteAccountId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (siteUrl.hashCode) +
    (mySiteAccountId.hashCode);

  @override
  String toString() => 'FollowsUnfollowFromRequest[siteUrl=$siteUrl, mySiteAccountId=$mySiteAccountId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'siteUrl'] = this.siteUrl;
      json[r'mySiteAccountId'] = this.mySiteAccountId;
    return json;
  }

  /// Returns a new [FollowsUnfollowFromRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FollowsUnfollowFromRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "FollowsUnfollowFromRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "FollowsUnfollowFromRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return FollowsUnfollowFromRequest(
        siteUrl: mapValueOfType<String>(json, r'siteUrl')!,
        mySiteAccountId: num.parse('${json[r'mySiteAccountId']}'),
      );
    }
    return null;
  }

  static List<FollowsUnfollowFromRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <FollowsUnfollowFromRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FollowsUnfollowFromRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FollowsUnfollowFromRequest> mapFromJson(dynamic json) {
    final map = <String, FollowsUnfollowFromRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FollowsUnfollowFromRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FollowsUnfollowFromRequest-objects as value to a dart map
  static Map<String, List<FollowsUnfollowFromRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<FollowsUnfollowFromRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FollowsUnfollowFromRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'siteUrl',
    'mySiteAccountId',
  };
}

