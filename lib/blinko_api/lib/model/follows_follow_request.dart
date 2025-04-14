//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class FollowsFollowRequest {
  /// Returns a new [FollowsFollowRequest] instance.
  FollowsFollowRequest({
    required this.siteUrl,
    required this.mySiteUrl,
  });

  String siteUrl;

  String mySiteUrl;

  @override
  bool operator ==(Object other) => identical(this, other) || other is FollowsFollowRequest &&
    other.siteUrl == siteUrl &&
    other.mySiteUrl == mySiteUrl;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (siteUrl.hashCode) +
    (mySiteUrl.hashCode);

  @override
  String toString() => 'FollowsFollowRequest[siteUrl=$siteUrl, mySiteUrl=$mySiteUrl]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'siteUrl'] = this.siteUrl;
      json[r'mySiteUrl'] = this.mySiteUrl;
    return json;
  }

  /// Returns a new [FollowsFollowRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FollowsFollowRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "FollowsFollowRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "FollowsFollowRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return FollowsFollowRequest(
        siteUrl: mapValueOfType<String>(json, r'siteUrl')!,
        mySiteUrl: mapValueOfType<String>(json, r'mySiteUrl')!,
      );
    }
    return null;
  }

  static List<FollowsFollowRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <FollowsFollowRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FollowsFollowRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FollowsFollowRequest> mapFromJson(dynamic json) {
    final map = <String, FollowsFollowRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FollowsFollowRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FollowsFollowRequest-objects as value to a dart map
  static Map<String, List<FollowsFollowRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<FollowsFollowRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FollowsFollowRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'siteUrl',
    'mySiteUrl',
  };
}

