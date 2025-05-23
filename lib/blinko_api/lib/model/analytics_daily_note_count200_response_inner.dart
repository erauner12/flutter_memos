//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AnalyticsDailyNoteCount200ResponseInner {
  /// Returns a new [AnalyticsDailyNoteCount200ResponseInner] instance.
  AnalyticsDailyNoteCount200ResponseInner({
    required this.date,
    required this.count,
  });

  String date;

  num count;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AnalyticsDailyNoteCount200ResponseInner &&
    other.date == date &&
    other.count == count;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (date.hashCode) +
    (count.hashCode);

  @override
  String toString() => 'AnalyticsDailyNoteCount200ResponseInner[date=$date, count=$count]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'date'] = this.date;
      json[r'count'] = this.count;
    return json;
  }

  /// Returns a new [AnalyticsDailyNoteCount200ResponseInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AnalyticsDailyNoteCount200ResponseInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "AnalyticsDailyNoteCount200ResponseInner[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "AnalyticsDailyNoteCount200ResponseInner[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AnalyticsDailyNoteCount200ResponseInner(
        date: mapValueOfType<String>(json, r'date')!,
        count: num.parse('${json[r'count']}'),
      );
    }
    return null;
  }

  static List<AnalyticsDailyNoteCount200ResponseInner> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AnalyticsDailyNoteCount200ResponseInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AnalyticsDailyNoteCount200ResponseInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AnalyticsDailyNoteCount200ResponseInner> mapFromJson(dynamic json) {
    final map = <String, AnalyticsDailyNoteCount200ResponseInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AnalyticsDailyNoteCount200ResponseInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AnalyticsDailyNoteCount200ResponseInner-objects as value to a dart map
  static Map<String, List<AnalyticsDailyNoteCount200ResponseInner>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AnalyticsDailyNoteCount200ResponseInner>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AnalyticsDailyNoteCount200ResponseInner.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'date',
    'count',
  };
}

