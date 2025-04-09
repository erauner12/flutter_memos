//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Due {
  /// Returns a new [Due] instance.
  Due({
    required this.string,
    required this.date,
    required this.isRecurring,
    this.datetime,
    this.timezone,
  });

  /// Human defined date in arbitrary format.
  String string;

  /// Date in format YYYY-MM-DD corrected to user's timezone.
  DateTime date;

  /// Whether the task has a recurring due date.
  bool isRecurring;

  /// Only returned if exact due time set (i.e. it's not a whole-day task), date and time in RFC3339 format in UTC.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? datetime;

  /// Only returned if exact due time set, user's timezone definition either in tzdata-compatible format (\"Europe/Berlin\") or as a string specifying east of UTC offset as \"UTC±HH:MM\" (i.e. \"UTC-01:00\").
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? timezone;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Due &&
    other.string == string &&
    other.date == date &&
    other.isRecurring == isRecurring &&
    other.datetime == datetime &&
    other.timezone == timezone;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (string.hashCode) +
    (date.hashCode) +
    (isRecurring.hashCode) +
    (datetime == null ? 0 : datetime!.hashCode) +
    (timezone == null ? 0 : timezone!.hashCode);

  @override
  String toString() => 'Due[string=$string, date=$date, isRecurring=$isRecurring, datetime=$datetime, timezone=$timezone]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'string'] = this.string;
      json[r'date'] = _dateFormatter.format(this.date.toUtc());
      json[r'is_recurring'] = this.isRecurring;
    if (this.datetime != null) {
      json[r'datetime'] = this.datetime!.toUtc().toIso8601String();
    } else {
      json[r'datetime'] = null;
    }
    if (this.timezone != null) {
      json[r'timezone'] = this.timezone;
    } else {
      json[r'timezone'] = null;
    }
    return json;
  }

  /// Returns a new [Due] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Due? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Due[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Due[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Due(
        string: mapValueOfType<String>(json, r'string')!,
        date: mapDateTime(json, r'date', r'')!,
        isRecurring: mapValueOfType<bool>(json, r'is_recurring')!,
        datetime: mapDateTime(json, r'datetime', r''),
        timezone: mapValueOfType<String>(json, r'timezone'),
      );
    }
    return null;
  }

  static List<Due> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Due>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Due.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Due> mapFromJson(dynamic json) {
    final map = <String, Due>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Due.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Due-objects as value to a dart map
  static Map<String, List<Due>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Due>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Due.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'string',
    'date',
    'is_recurring',
  };
}

