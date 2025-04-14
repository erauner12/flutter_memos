//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AnalyticsMonthlyStats200Response {
  /// Returns a new [AnalyticsMonthlyStats200Response] instance.
  AnalyticsMonthlyStats200Response({
    required this.noteCount,
    required this.totalWords,
    required this.maxDailyWords,
    required this.activeDays,
    this.tagStats = const [],
  });

  num noteCount;

  num totalWords;

  num maxDailyWords;

  num activeDays;

  List<AnalyticsMonthlyStats200ResponseTagStatsInner> tagStats;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AnalyticsMonthlyStats200Response &&
    other.noteCount == noteCount &&
    other.totalWords == totalWords &&
    other.maxDailyWords == maxDailyWords &&
    other.activeDays == activeDays &&
    _deepEquality.equals(other.tagStats, tagStats);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (noteCount.hashCode) +
    (totalWords.hashCode) +
    (maxDailyWords.hashCode) +
    (activeDays.hashCode) +
    (tagStats.hashCode);

  @override
  String toString() => 'AnalyticsMonthlyStats200Response[noteCount=$noteCount, totalWords=$totalWords, maxDailyWords=$maxDailyWords, activeDays=$activeDays, tagStats=$tagStats]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'noteCount'] = this.noteCount;
      json[r'totalWords'] = this.totalWords;
      json[r'maxDailyWords'] = this.maxDailyWords;
      json[r'activeDays'] = this.activeDays;
      json[r'tagStats'] = this.tagStats;
    return json;
  }

  /// Returns a new [AnalyticsMonthlyStats200Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AnalyticsMonthlyStats200Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "AnalyticsMonthlyStats200Response[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "AnalyticsMonthlyStats200Response[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AnalyticsMonthlyStats200Response(
        noteCount: num.parse('${json[r'noteCount']}'),
        totalWords: num.parse('${json[r'totalWords']}'),
        maxDailyWords: num.parse('${json[r'maxDailyWords']}'),
        activeDays: num.parse('${json[r'activeDays']}'),
        tagStats: AnalyticsMonthlyStats200ResponseTagStatsInner.listFromJson(json[r'tagStats']),
      );
    }
    return null;
  }

  static List<AnalyticsMonthlyStats200Response> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AnalyticsMonthlyStats200Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AnalyticsMonthlyStats200Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AnalyticsMonthlyStats200Response> mapFromJson(dynamic json) {
    final map = <String, AnalyticsMonthlyStats200Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AnalyticsMonthlyStats200Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AnalyticsMonthlyStats200Response-objects as value to a dart map
  static Map<String, List<AnalyticsMonthlyStats200Response>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AnalyticsMonthlyStats200Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AnalyticsMonthlyStats200Response.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'noteCount',
    'totalWords',
    'maxDailyWords',
    'activeDays',
  };
}

