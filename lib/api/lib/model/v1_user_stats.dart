//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class V1UserStats {
  /// Returns a new [V1UserStats] instance.
  V1UserStats({
    this.name,
    this.memoDisplayTimestamps = const [],
    this.memoTypeStats,
    this.tagCount = const {},
  });

  /// The name of the user.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? name;

  /// The timestamps when the memos were displayed.  We should return raw data to the client, and let the client format the data with the user's timezone.
  List<DateTime> memoDisplayTimestamps;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  UserStatsMemoTypeStats? memoTypeStats;

  Map<String, int> tagCount;

  @override
  bool operator ==(Object other) => identical(this, other) || other is V1UserStats &&
    other.name == name &&
    _deepEquality.equals(other.memoDisplayTimestamps, memoDisplayTimestamps) &&
    other.memoTypeStats == memoTypeStats &&
    _deepEquality.equals(other.tagCount, tagCount);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name == null ? 0 : name!.hashCode) +
    (memoDisplayTimestamps.hashCode) +
    (memoTypeStats == null ? 0 : memoTypeStats!.hashCode) +
    (tagCount.hashCode);

  @override
  String toString() => 'V1UserStats[name=$name, memoDisplayTimestamps=$memoDisplayTimestamps, memoTypeStats=$memoTypeStats, tagCount=$tagCount]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
      json[r'memoDisplayTimestamps'] = this.memoDisplayTimestamps;
    if (this.memoTypeStats != null) {
      json[r'memoTypeStats'] = this.memoTypeStats;
    } else {
      json[r'memoTypeStats'] = null;
    }
      json[r'tagCount'] = this.tagCount;
    return json;
  }

  /// Returns a new [V1UserStats] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static V1UserStats? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "V1UserStats[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "V1UserStats[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return V1UserStats(
        name: mapValueOfType<String>(json, r'name'),
        memoDisplayTimestamps: json[r'memoDisplayTimestamps'] is List
            ? (json[r'memoDisplayTimestamps'] as List)
                .map((item) => item is String ? DateTime.parse(item) : DateTime.fromMillisecondsSinceEpoch(0))
                .toList()
            : [],
        memoTypeStats: UserStatsMemoTypeStats.fromJson(json[r'memoTypeStats']),
        tagCount: mapCastOfType<String, int>(json, r'tagCount') ?? const {},
      );
    }
    return null;
  }

  static List<V1UserStats> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <V1UserStats>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = V1UserStats.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, V1UserStats> mapFromJson(dynamic json) {
    final map = <String, V1UserStats>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = V1UserStats.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of V1UserStats-objects as value to a dart map
  static Map<String, List<V1UserStats>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<V1UserStats>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = V1UserStats.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}