//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class V1MemoProperty {
  /// Returns a new [V1MemoProperty] instance.
  V1MemoProperty({
    this.hasLink,
    this.hasTaskList,
    this.hasCode,
    this.hasIncompleteTasks,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? hasLink;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? hasTaskList;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? hasCode;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? hasIncompleteTasks;

  @override
  bool operator ==(Object other) => identical(this, other) || other is V1MemoProperty &&
    other.hasLink == hasLink &&
    other.hasTaskList == hasTaskList &&
    other.hasCode == hasCode &&
    other.hasIncompleteTasks == hasIncompleteTasks;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (hasLink == null ? 0 : hasLink!.hashCode) +
    (hasTaskList == null ? 0 : hasTaskList!.hashCode) +
    (hasCode == null ? 0 : hasCode!.hashCode) +
    (hasIncompleteTasks == null ? 0 : hasIncompleteTasks!.hashCode);

  @override
  String toString() => 'V1MemoProperty[hasLink=$hasLink, hasTaskList=$hasTaskList, hasCode=$hasCode, hasIncompleteTasks=$hasIncompleteTasks]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.hasLink != null) {
      json[r'hasLink'] = this.hasLink;
    } else {
      json[r'hasLink'] = null;
    }
    if (this.hasTaskList != null) {
      json[r'hasTaskList'] = this.hasTaskList;
    } else {
      json[r'hasTaskList'] = null;
    }
    if (this.hasCode != null) {
      json[r'hasCode'] = this.hasCode;
    } else {
      json[r'hasCode'] = null;
    }
    if (this.hasIncompleteTasks != null) {
      json[r'hasIncompleteTasks'] = this.hasIncompleteTasks;
    } else {
      json[r'hasIncompleteTasks'] = null;
    }
    return json;
  }

  /// Returns a new [V1MemoProperty] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static V1MemoProperty? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "V1MemoProperty[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "V1MemoProperty[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return V1MemoProperty(
        hasLink: mapValueOfType<bool>(json, r'hasLink'),
        hasTaskList: mapValueOfType<bool>(json, r'hasTaskList'),
        hasCode: mapValueOfType<bool>(json, r'hasCode'),
        hasIncompleteTasks: mapValueOfType<bool>(json, r'hasIncompleteTasks'),
      );
    }
    return null;
  }

  static List<V1MemoProperty> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <V1MemoProperty>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = V1MemoProperty.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, V1MemoProperty> mapFromJson(dynamic json) {
    final map = <String, V1MemoProperty>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = V1MemoProperty.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of V1MemoProperty-objects as value to a dart map
  static Map<String, List<V1MemoProperty>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<V1MemoProperty>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = V1MemoProperty.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

