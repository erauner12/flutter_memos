//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ProtobufAny {
  /// Returns a new [ProtobufAny] instance.
  ProtobufAny({
    this.atType,
  });

  /// A URL/resource name that uniquely identifies the type of the serialized protocol buffer message. This string must contain at least one \"/\" character. The last segment of the URL's path must represent the fully qualified name of the type (as in `path/google.protobuf.Duration`). The name should be in a canonical form (e.g., leading \".\" is not accepted).  In practice, teams usually precompile into the binary all types that they expect it to use in the context of Any. However, for URLs which use the scheme `http`, `https`, or no scheme, one can optionally set up a type server that maps type URLs to message definitions as follows:  * If no scheme is provided, `https` is assumed. * An HTTP GET on the URL must yield a [google.protobuf.Type][]   value in binary format, or produce an error. * Applications are allowed to cache lookup results based on the   URL, or have them precompiled into a binary to avoid any   lookup. Therefore, binary compatibility needs to be preserved   on changes to types. (Use versioned type names to manage   breaking changes.)  Note: this functionality is not currently available in the official protobuf release, and it is not used for type URLs beginning with type.googleapis.com. As of May 2023, there are no widely used type server implementations and no plans to implement one.  Schemes other than `http`, `https` (or the empty scheme) might be used with implementation specific semantics.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? atType;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ProtobufAny &&
    other.atType == atType;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (atType == null ? 0 : atType!.hashCode);

  @override
  String toString() => 'ProtobufAny[atType=$atType]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.atType != null) {
      json[r'@type'] = this.atType;
    } else {
      json[r'@type'] = null;
    }
    return json;
  }

  /// Returns a new [ProtobufAny] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ProtobufAny? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ProtobufAny[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ProtobufAny[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ProtobufAny(
        atType: mapValueOfType<String>(json, r'@type'),
      );
    }
    return null;
  }

  static List<ProtobufAny> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ProtobufAny>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ProtobufAny.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ProtobufAny> mapFromJson(dynamic json) {
    final map = <String, ProtobufAny>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ProtobufAny.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ProtobufAny-objects as value to a dart map
  static Map<String, List<ProtobufAny>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ProtobufAny>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ProtobufAny.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

