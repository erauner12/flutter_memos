//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class V1ListMemoCommentsResponse {
  /// Returns a new [V1ListMemoCommentsResponse] instance.
  V1ListMemoCommentsResponse({
    this.memos = const [],
  });

  List<Apiv1Memo> memos;

  @override
  bool operator ==(Object other) => identical(this, other) || other is V1ListMemoCommentsResponse &&
    _deepEquality.equals(other.memos, memos);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (memos.hashCode);

  @override
  String toString() => 'V1ListMemoCommentsResponse[memos=$memos]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'memos'] = this.memos;
    return json;
  }

  /// Returns a new [V1ListMemoCommentsResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static V1ListMemoCommentsResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "V1ListMemoCommentsResponse[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "V1ListMemoCommentsResponse[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return V1ListMemoCommentsResponse(
        memos: Apiv1Memo.listFromJson(json[r'memos']),
      );
    }
    return null;
  }

  static List<V1ListMemoCommentsResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <V1ListMemoCommentsResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = V1ListMemoCommentsResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, V1ListMemoCommentsResponse> mapFromJson(dynamic json) {
    final map = <String, V1ListMemoCommentsResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = V1ListMemoCommentsResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of V1ListMemoCommentsResponse-objects as value to a dart map
  static Map<String, List<V1ListMemoCommentsResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<V1ListMemoCommentsResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = V1ListMemoCommentsResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

