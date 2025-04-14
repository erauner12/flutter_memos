//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ErrorBADREQUESTIssuesInner {
  /// Returns a new [ErrorBADREQUESTIssuesInner] instance.
  ErrorBADREQUESTIssuesInner({
    required this.message,
  });

  String message;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ErrorBADREQUESTIssuesInner &&
    other.message == message;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (message.hashCode);

  @override
  String toString() => 'ErrorBADREQUESTIssuesInner[message=$message]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'message'] = this.message;
    return json;
  }

  /// Returns a new [ErrorBADREQUESTIssuesInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ErrorBADREQUESTIssuesInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ErrorBADREQUESTIssuesInner[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ErrorBADREQUESTIssuesInner[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ErrorBADREQUESTIssuesInner(
        message: mapValueOfType<String>(json, r'message')!,
      );
    }
    return null;
  }

  static List<ErrorBADREQUESTIssuesInner> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ErrorBADREQUESTIssuesInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ErrorBADREQUESTIssuesInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ErrorBADREQUESTIssuesInner> mapFromJson(dynamic json) {
    final map = <String, ErrorBADREQUESTIssuesInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ErrorBADREQUESTIssuesInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ErrorBADREQUESTIssuesInner-objects as value to a dart map
  static Map<String, List<ErrorBADREQUESTIssuesInner>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ErrorBADREQUESTIssuesInner>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ErrorBADREQUESTIssuesInner.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'message',
  };
}

