//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AnalyticsMonthlyStats200ResponseTagStatsInner {
  /// Returns a new [AnalyticsMonthlyStats200ResponseTagStatsInner] instance.
  AnalyticsMonthlyStats200ResponseTagStatsInner({
    required this.tagName,
    required this.count,
  });

  String tagName;

  num count;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AnalyticsMonthlyStats200ResponseTagStatsInner &&
    other.tagName == tagName &&
    other.count == count;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (tagName.hashCode) +
    (count.hashCode);

  @override
  String toString() => 'AnalyticsMonthlyStats200ResponseTagStatsInner[tagName=$tagName, count=$count]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'tagName'] = this.tagName;
      json[r'count'] = this.count;
    return json;
  }

  /// Returns a new [AnalyticsMonthlyStats200ResponseTagStatsInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AnalyticsMonthlyStats200ResponseTagStatsInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "AnalyticsMonthlyStats200ResponseTagStatsInner[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "AnalyticsMonthlyStats200ResponseTagStatsInner[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AnalyticsMonthlyStats200ResponseTagStatsInner(
        tagName: mapValueOfType<String>(json, r'tagName')!,
        count: num.parse('${json[r'count']}'),
      );
    }
    return null;
  }

  static List<AnalyticsMonthlyStats200ResponseTagStatsInner> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AnalyticsMonthlyStats200ResponseTagStatsInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AnalyticsMonthlyStats200ResponseTagStatsInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AnalyticsMonthlyStats200ResponseTagStatsInner> mapFromJson(dynamic json) {
    final map = <String, AnalyticsMonthlyStats200ResponseTagStatsInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AnalyticsMonthlyStats200ResponseTagStatsInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AnalyticsMonthlyStats200ResponseTagStatsInner-objects as value to a dart map
  static Map<String, List<AnalyticsMonthlyStats200ResponseTagStatsInner>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AnalyticsMonthlyStats200ResponseTagStatsInner>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AnalyticsMonthlyStats200ResponseTagStatsInner.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'tagName',
    'count',
  };
}

