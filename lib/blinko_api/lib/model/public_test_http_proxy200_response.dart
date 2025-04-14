//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PublicTestHttpProxy200Response {
  /// Returns a new [PublicTestHttpProxy200Response] instance.
  PublicTestHttpProxy200Response({
    required this.success,
    required this.message,
    required this.responseTime,
    this.statusCode,
    this.error,
    this.errorCode,
    this.errorDetails,
  });

  bool success;

  String message;

  num responseTime;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? statusCode;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? error;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? errorCode;

  Object? errorDetails;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PublicTestHttpProxy200Response &&
    other.success == success &&
    other.message == message &&
    other.responseTime == responseTime &&
    other.statusCode == statusCode &&
    other.error == error &&
    other.errorCode == errorCode &&
    other.errorDetails == errorDetails;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (success.hashCode) +
    (message.hashCode) +
    (responseTime.hashCode) +
    (statusCode == null ? 0 : statusCode!.hashCode) +
    (error == null ? 0 : error!.hashCode) +
    (errorCode == null ? 0 : errorCode!.hashCode) +
    (errorDetails == null ? 0 : errorDetails!.hashCode);

  @override
  String toString() => 'PublicTestHttpProxy200Response[success=$success, message=$message, responseTime=$responseTime, statusCode=$statusCode, error=$error, errorCode=$errorCode, errorDetails=$errorDetails]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'success'] = this.success;
      json[r'message'] = this.message;
      json[r'responseTime'] = this.responseTime;
    if (this.statusCode != null) {
      json[r'statusCode'] = this.statusCode;
    } else {
      json[r'statusCode'] = null;
    }
    if (this.error != null) {
      json[r'error'] = this.error;
    } else {
      json[r'error'] = null;
    }
    if (this.errorCode != null) {
      json[r'errorCode'] = this.errorCode;
    } else {
      json[r'errorCode'] = null;
    }
    if (this.errorDetails != null) {
      json[r'errorDetails'] = this.errorDetails;
    } else {
      json[r'errorDetails'] = null;
    }
    return json;
  }

  /// Returns a new [PublicTestHttpProxy200Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PublicTestHttpProxy200Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PublicTestHttpProxy200Response[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PublicTestHttpProxy200Response[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PublicTestHttpProxy200Response(
        success: mapValueOfType<bool>(json, r'success')!,
        message: mapValueOfType<String>(json, r'message')!,
        responseTime: num.parse('${json[r'responseTime']}'),
        statusCode: num.parse('${json[r'statusCode']}'),
        error: mapValueOfType<String>(json, r'error'),
        errorCode: mapValueOfType<String>(json, r'errorCode'),
        errorDetails: mapValueOfType<Object>(json, r'errorDetails'),
      );
    }
    return null;
  }

  static List<PublicTestHttpProxy200Response> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PublicTestHttpProxy200Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PublicTestHttpProxy200Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PublicTestHttpProxy200Response> mapFromJson(dynamic json) {
    final map = <String, PublicTestHttpProxy200Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PublicTestHttpProxy200Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PublicTestHttpProxy200Response-objects as value to a dart map
  static Map<String, List<PublicTestHttpProxy200Response>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PublicTestHttpProxy200Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PublicTestHttpProxy200Response.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'success',
    'message',
    'responseTime',
  };
}

