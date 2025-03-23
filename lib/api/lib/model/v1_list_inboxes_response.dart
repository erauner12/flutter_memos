//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class V1ListInboxesResponse {
  /// Returns a new [V1ListInboxesResponse] instance.
  V1ListInboxesResponse({
    this.inboxes = const [],
    this.nextPageToken,
  });

  List<V1Inbox> inboxes;

  /// A token, which can be sent as `page_token` to retrieve the next page. If this field is omitted, there are no subsequent pages.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? nextPageToken;

  @override
  bool operator ==(Object other) => identical(this, other) || other is V1ListInboxesResponse &&
    _deepEquality.equals(other.inboxes, inboxes) &&
    other.nextPageToken == nextPageToken;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (inboxes.hashCode) +
    (nextPageToken == null ? 0 : nextPageToken!.hashCode);

  @override
  String toString() => 'V1ListInboxesResponse[inboxes=$inboxes, nextPageToken=$nextPageToken]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'inboxes'] = this.inboxes;
    if (this.nextPageToken != null) {
      json[r'nextPageToken'] = this.nextPageToken;
    } else {
      json[r'nextPageToken'] = null;
    }
    return json;
  }

  /// Returns a new [V1ListInboxesResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static V1ListInboxesResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "V1ListInboxesResponse[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "V1ListInboxesResponse[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return V1ListInboxesResponse(
        inboxes: V1Inbox.listFromJson(json[r'inboxes']),
        nextPageToken: mapValueOfType<String>(json, r'nextPageToken'),
      );
    }
    return null;
  }

  static List<V1ListInboxesResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <V1ListInboxesResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = V1ListInboxesResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, V1ListInboxesResponse> mapFromJson(dynamic json) {
    final map = <String, V1ListInboxesResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = V1ListInboxesResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of V1ListInboxesResponse-objects as value to a dart map
  static Map<String, List<V1ListInboxesResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<V1ListInboxesResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = V1ListInboxesResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

