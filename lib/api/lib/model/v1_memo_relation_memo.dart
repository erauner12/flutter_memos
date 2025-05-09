//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class V1MemoRelationMemo {
  /// Returns a new [V1MemoRelationMemo] instance.
  V1MemoRelationMemo({
    this.name,
    this.uid,
    this.snippet,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? uid;

  /// The snippet of the memo content. Plain text only.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? snippet;

  @override
  bool operator ==(Object other) => identical(this, other) || other is V1MemoRelationMemo &&
    other.name == name &&
    other.uid == uid &&
    other.snippet == snippet;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name == null ? 0 : name!.hashCode) +
    (uid == null ? 0 : uid!.hashCode) +
    (snippet == null ? 0 : snippet!.hashCode);

  @override
  String toString() => 'V1MemoRelationMemo[name=$name, uid=$uid, snippet=$snippet]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    if (this.uid != null) {
      json[r'uid'] = this.uid;
    } else {
      json[r'uid'] = null;
    }
    if (this.snippet != null) {
      json[r'snippet'] = this.snippet;
    } else {
      json[r'snippet'] = null;
    }
    return json;
  }

  /// Returns a new [V1MemoRelationMemo] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static V1MemoRelationMemo? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "V1MemoRelationMemo[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "V1MemoRelationMemo[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return V1MemoRelationMemo(
        name: mapValueOfType<String>(json, r'name'),
        uid: mapValueOfType<String>(json, r'uid'),
        snippet: mapValueOfType<String>(json, r'snippet'),
      );
    }
    return null;
  }

  static List<V1MemoRelationMemo> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <V1MemoRelationMemo>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = V1MemoRelationMemo.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, V1MemoRelationMemo> mapFromJson(dynamic json) {
    final map = <String, V1MemoRelationMemo>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = V1MemoRelationMemo.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of V1MemoRelationMemo-objects as value to a dart map
  static Map<String, List<V1MemoRelationMemo>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<V1MemoRelationMemo>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = V1MemoRelationMemo.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

