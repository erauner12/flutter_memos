//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class V1ListUserAccessTokensResponse {
  /// Returns a new [V1ListUserAccessTokensResponse] instance.
  V1ListUserAccessTokensResponse({
    this.accessTokens = const [],
  });

  List<V1UserAccessToken> accessTokens;

  @override
  bool operator ==(Object other) => identical(this, other) || other is V1ListUserAccessTokensResponse &&
    _deepEquality.equals(other.accessTokens, accessTokens);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (accessTokens.hashCode);

  @override
  String toString() => 'V1ListUserAccessTokensResponse[accessTokens=$accessTokens]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'accessTokens'] = this.accessTokens;
    return json;
  }

  /// Returns a new [V1ListUserAccessTokensResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static V1ListUserAccessTokensResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "V1ListUserAccessTokensResponse[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "V1ListUserAccessTokensResponse[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return V1ListUserAccessTokensResponse(
        accessTokens: V1UserAccessToken.listFromJson(json[r'accessTokens']),
      );
    }
    return null;
  }

  static List<V1ListUserAccessTokensResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <V1ListUserAccessTokensResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = V1ListUserAccessTokensResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, V1ListUserAccessTokensResponse> mapFromJson(dynamic json) {
    final map = <String, V1ListUserAccessTokensResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = V1ListUserAccessTokensResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of V1ListUserAccessTokensResponse-objects as value to a dart map
  static Map<String, List<V1ListUserAccessTokensResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<V1ListUserAccessTokensResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = V1ListUserAccessTokensResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

