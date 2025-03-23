//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class V1ReferencedContentNode {
  /// Returns a new [V1ReferencedContentNode] instance.
  V1ReferencedContentNode({
    this.resourceName,
    this.params,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? resourceName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? params;

  @override
  bool operator ==(Object other) => identical(this, other) || other is V1ReferencedContentNode &&
    other.resourceName == resourceName &&
    other.params == params;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (resourceName == null ? 0 : resourceName!.hashCode) +
    (params == null ? 0 : params!.hashCode);

  @override
  String toString() => 'V1ReferencedContentNode[resourceName=$resourceName, params=$params]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.resourceName != null) {
      json[r'resourceName'] = this.resourceName;
    } else {
      json[r'resourceName'] = null;
    }
    if (this.params != null) {
      json[r'params'] = this.params;
    } else {
      json[r'params'] = null;
    }
    return json;
  }

  /// Returns a new [V1ReferencedContentNode] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static V1ReferencedContentNode? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "V1ReferencedContentNode[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "V1ReferencedContentNode[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return V1ReferencedContentNode(
        resourceName: mapValueOfType<String>(json, r'resourceName'),
        params: mapValueOfType<String>(json, r'params'),
      );
    }
    return null;
  }

  static List<V1ReferencedContentNode> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <V1ReferencedContentNode>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = V1ReferencedContentNode.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, V1ReferencedContentNode> mapFromJson(dynamic json) {
    final map = <String, V1ReferencedContentNode>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = V1ReferencedContentNode.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of V1ReferencedContentNode-objects as value to a dart map
  static Map<String, List<V1ReferencedContentNode>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<V1ReferencedContentNode>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = V1ReferencedContentNode.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

