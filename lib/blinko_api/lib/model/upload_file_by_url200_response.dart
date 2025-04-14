//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UploadFileByUrl200Response {
  /// Returns a new [UploadFileByUrl200Response] instance.
  UploadFileByUrl200Response({
    this.message,
    this.status,
    this.path,
    this.type,
    this.size,
    this.originalURL,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? message;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? path;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? type;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? size;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? originalURL;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UploadFileByUrl200Response &&
    other.message == message &&
    other.status == status &&
    other.path == path &&
    other.type == type &&
    other.size == size &&
    other.originalURL == originalURL;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (message == null ? 0 : message!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (path == null ? 0 : path!.hashCode) +
    (type == null ? 0 : type!.hashCode) +
    (size == null ? 0 : size!.hashCode) +
    (originalURL == null ? 0 : originalURL!.hashCode);

  @override
  String toString() => 'UploadFileByUrl200Response[message=$message, status=$status, path=$path, type=$type, size=$size, originalURL=$originalURL]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.message != null) {
      json[r'Message'] = this.message;
    } else {
      json[r'Message'] = null;
    }
    if (this.status != null) {
      json[r'status'] = this.status;
    } else {
      json[r'status'] = null;
    }
    if (this.path != null) {
      json[r'path'] = this.path;
    } else {
      json[r'path'] = null;
    }
    if (this.type != null) {
      json[r'type'] = this.type;
    } else {
      json[r'type'] = null;
    }
    if (this.size != null) {
      json[r'size'] = this.size;
    } else {
      json[r'size'] = null;
    }
    if (this.originalURL != null) {
      json[r'originalURL'] = this.originalURL;
    } else {
      json[r'originalURL'] = null;
    }
    return json;
  }

  /// Returns a new [UploadFileByUrl200Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UploadFileByUrl200Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "UploadFileByUrl200Response[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "UploadFileByUrl200Response[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return UploadFileByUrl200Response(
        message: mapValueOfType<String>(json, r'Message'),
        status: num.parse('${json[r'status']}'),
        path: mapValueOfType<String>(json, r'path'),
        type: mapValueOfType<String>(json, r'type'),
        size: num.parse('${json[r'size']}'),
        originalURL: mapValueOfType<String>(json, r'originalURL'),
      );
    }
    return null;
  }

  static List<UploadFileByUrl200Response> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UploadFileByUrl200Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UploadFileByUrl200Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UploadFileByUrl200Response> mapFromJson(dynamic json) {
    final map = <String, UploadFileByUrl200Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UploadFileByUrl200Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UploadFileByUrl200Response-objects as value to a dart map
  static Map<String, List<UploadFileByUrl200Response>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UploadFileByUrl200Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UploadFileByUrl200Response.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

