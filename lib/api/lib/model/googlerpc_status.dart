//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GooglerpcStatus {
  /// Returns a new [GooglerpcStatus] instance.
  GooglerpcStatus({
    this.code,
    this.message,
    this.details = const [],
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? code;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? message;

  List<ProtobufAny> details;

  @override
  bool operator ==(Object other) => identical(this, other) || other is GooglerpcStatus &&
    other.code == code &&
    other.message == message &&
    _deepEquality.equals(other.details, details);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (code == null ? 0 : code!.hashCode) +
    (message == null ? 0 : message!.hashCode) +
    (details.hashCode);

  @override
  String toString() => 'GooglerpcStatus[code=$code, message=$message, details=$details]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.code != null) {
      json[r'code'] = this.code;
    } else {
      json[r'code'] = null;
    }
    if (this.message != null) {
      json[r'message'] = this.message;
    } else {
      json[r'message'] = null;
    }
      json[r'details'] = this.details;
    return json;
  }

  /// Returns a new [GooglerpcStatus] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GooglerpcStatus? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "GooglerpcStatus[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "GooglerpcStatus[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return GooglerpcStatus(
        code: mapValueOfType<int>(json, r'code'),
        message: mapValueOfType<String>(json, r'message'),
        details: ProtobufAny.listFromJson(json[r'details']),
      );
    }
    return null;
  }

  static List<GooglerpcStatus> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <GooglerpcStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GooglerpcStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GooglerpcStatus> mapFromJson(dynamic json) {
    final map = <String, GooglerpcStatus>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GooglerpcStatus.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GooglerpcStatus-objects as value to a dart map
  static Map<String, List<GooglerpcStatus>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<GooglerpcStatus>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GooglerpcStatus.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

