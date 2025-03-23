//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UserStatsMemoTypeStats {
  /// Returns a new [UserStatsMemoTypeStats] instance.
  UserStatsMemoTypeStats({
    this.linkCount,
    this.codeCount,
    this.todoCount,
    this.undoCount,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? linkCount;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? codeCount;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? todoCount;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? undoCount;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UserStatsMemoTypeStats &&
    other.linkCount == linkCount &&
    other.codeCount == codeCount &&
    other.todoCount == todoCount &&
    other.undoCount == undoCount;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (linkCount == null ? 0 : linkCount!.hashCode) +
    (codeCount == null ? 0 : codeCount!.hashCode) +
    (todoCount == null ? 0 : todoCount!.hashCode) +
    (undoCount == null ? 0 : undoCount!.hashCode);

  @override
  String toString() => 'UserStatsMemoTypeStats[linkCount=$linkCount, codeCount=$codeCount, todoCount=$todoCount, undoCount=$undoCount]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.linkCount != null) {
      json[r'linkCount'] = this.linkCount;
    } else {
      json[r'linkCount'] = null;
    }
    if (this.codeCount != null) {
      json[r'codeCount'] = this.codeCount;
    } else {
      json[r'codeCount'] = null;
    }
    if (this.todoCount != null) {
      json[r'todoCount'] = this.todoCount;
    } else {
      json[r'todoCount'] = null;
    }
    if (this.undoCount != null) {
      json[r'undoCount'] = this.undoCount;
    } else {
      json[r'undoCount'] = null;
    }
    return json;
  }

  /// Returns a new [UserStatsMemoTypeStats] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UserStatsMemoTypeStats? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "UserStatsMemoTypeStats[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "UserStatsMemoTypeStats[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return UserStatsMemoTypeStats(
        linkCount: mapValueOfType<int>(json, r'linkCount'),
        codeCount: mapValueOfType<int>(json, r'codeCount'),
        todoCount: mapValueOfType<int>(json, r'todoCount'),
        undoCount: mapValueOfType<int>(json, r'undoCount'),
      );
    }
    return null;
  }

  static List<UserStatsMemoTypeStats> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UserStatsMemoTypeStats>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UserStatsMemoTypeStats.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UserStatsMemoTypeStats> mapFromJson(dynamic json) {
    final map = <String, UserStatsMemoTypeStats>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UserStatsMemoTypeStats.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UserStatsMemoTypeStats-objects as value to a dart map
  static Map<String, List<UserStatsMemoTypeStats>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UserStatsMemoTypeStats>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UserStatsMemoTypeStats.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

