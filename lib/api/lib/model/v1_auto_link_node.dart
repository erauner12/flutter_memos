//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class V1AutoLinkNode {
  /// Returns a new [V1AutoLinkNode] instance.
  V1AutoLinkNode({
    this.url,
    this.isRawText,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? url;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? isRawText;

  @override
  bool operator ==(Object other) => identical(this, other) || other is V1AutoLinkNode &&
    other.url == url &&
    other.isRawText == isRawText;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (url == null ? 0 : url!.hashCode) +
    (isRawText == null ? 0 : isRawText!.hashCode);

  @override
  String toString() => 'V1AutoLinkNode[url=$url, isRawText=$isRawText]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.url != null) {
      json[r'url'] = this.url;
    } else {
      json[r'url'] = null;
    }
    if (this.isRawText != null) {
      json[r'isRawText'] = this.isRawText;
    } else {
      json[r'isRawText'] = null;
    }
    return json;
  }

  /// Returns a new [V1AutoLinkNode] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static V1AutoLinkNode? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "V1AutoLinkNode[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "V1AutoLinkNode[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return V1AutoLinkNode(
        url: mapValueOfType<String>(json, r'url'),
        isRawText: mapValueOfType<bool>(json, r'isRawText'),
      );
    }
    return null;
  }

  static List<V1AutoLinkNode> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <V1AutoLinkNode>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = V1AutoLinkNode.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, V1AutoLinkNode> mapFromJson(dynamic json) {
    final map = <String, V1AutoLinkNode>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = V1AutoLinkNode.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of V1AutoLinkNode-objects as value to a dart map
  static Map<String, List<V1AutoLinkNode>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<V1AutoLinkNode>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = V1AutoLinkNode.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

