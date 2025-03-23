//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ApiHttpBody {
  /// Returns a new [ApiHttpBody] instance.
  ApiHttpBody({
    this.contentType,
    this.data,
    this.extensions = const [],
  });

  /// The HTTP Content-Type header value specifying the content type of the body.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? contentType;

  /// The HTTP request/response body as raw binary.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? data;

  /// Application specific response metadata. Must be set in the first response for streaming APIs.
  List<ProtobufAny> extensions;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ApiHttpBody &&
    other.contentType == contentType &&
    other.data == data &&
    _deepEquality.equals(other.extensions, extensions);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (contentType == null ? 0 : contentType!.hashCode) +
    (data == null ? 0 : data!.hashCode) +
    (extensions.hashCode);

  @override
  String toString() => 'ApiHttpBody[contentType=$contentType, data=$data, extensions=$extensions]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.contentType != null) {
      json[r'contentType'] = this.contentType;
    } else {
      json[r'contentType'] = null;
    }
    if (this.data != null) {
      json[r'data'] = this.data;
    } else {
      json[r'data'] = null;
    }
      json[r'extensions'] = this.extensions;
    return json;
  }

  /// Returns a new [ApiHttpBody] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ApiHttpBody? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ApiHttpBody[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ApiHttpBody[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ApiHttpBody(
        contentType: mapValueOfType<String>(json, r'contentType'),
        data: mapValueOfType<String>(json, r'data'),
        extensions: ProtobufAny.listFromJson(json[r'extensions']),
      );
    }
    return null;
  }

  static List<ApiHttpBody> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ApiHttpBody>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ApiHttpBody.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ApiHttpBody> mapFromJson(dynamic json) {
    final map = <String, ApiHttpBody>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ApiHttpBody.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ApiHttpBody-objects as value to a dart map
  static Map<String, List<ApiHttpBody>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ApiHttpBody>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ApiHttpBody.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

