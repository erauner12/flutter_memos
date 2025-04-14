//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ErrorFORBIDDEN {
  /// Returns a new [ErrorFORBIDDEN] instance.
  ErrorFORBIDDEN({
    required this.message,
    required this.code,
    this.issues = const [],
  });

  /// The error message
  String message;

  /// The error code
  String code;

  /// An array of issues that were responsible for the error
  List<ErrorBADREQUESTIssuesInner> issues;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ErrorFORBIDDEN &&
    other.message == message &&
    other.code == code &&
    _deepEquality.equals(other.issues, issues);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (message.hashCode) +
    (code.hashCode) +
    (issues.hashCode);

  @override
  String toString() => 'ErrorFORBIDDEN[message=$message, code=$code, issues=$issues]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'message'] = this.message;
      json[r'code'] = this.code;
      json[r'issues'] = this.issues;
    return json;
  }

  /// Returns a new [ErrorFORBIDDEN] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ErrorFORBIDDEN? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ErrorFORBIDDEN[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ErrorFORBIDDEN[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ErrorFORBIDDEN(
        message: mapValueOfType<String>(json, r'message')!,
        code: mapValueOfType<String>(json, r'code')!,
        issues: ErrorBADREQUESTIssuesInner.listFromJson(json[r'issues']),
      );
    }
    return null;
  }

  static List<ErrorFORBIDDEN> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ErrorFORBIDDEN>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ErrorFORBIDDEN.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ErrorFORBIDDEN> mapFromJson(dynamic json) {
    final map = <String, ErrorFORBIDDEN>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ErrorFORBIDDEN.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ErrorFORBIDDEN-objects as value to a dart map
  static Map<String, List<ErrorFORBIDDEN>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ErrorFORBIDDEN>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ErrorFORBIDDEN.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'message',
    'code',
  };
}

