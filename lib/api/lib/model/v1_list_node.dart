//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class V1ListNode {
  /// Returns a new [V1ListNode] instance.
  V1ListNode({
    this.kind,
    this.indent,
    this.children = const [],
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  ListNodeKind? kind;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? indent;

  List<V1Node> children;

  @override
  bool operator ==(Object other) => identical(this, other) || other is V1ListNode &&
    other.kind == kind &&
    other.indent == indent &&
    _deepEquality.equals(other.children, children);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (kind == null ? 0 : kind!.hashCode) +
    (indent == null ? 0 : indent!.hashCode) +
    (children.hashCode);

  @override
  String toString() => 'V1ListNode[kind=$kind, indent=$indent, children=$children]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.kind != null) {
      json[r'kind'] = this.kind;
    } else {
      json[r'kind'] = null;
    }
    if (this.indent != null) {
      json[r'indent'] = this.indent;
    } else {
      json[r'indent'] = null;
    }
      json[r'children'] = this.children;
    return json;
  }

  /// Returns a new [V1ListNode] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static V1ListNode? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "V1ListNode[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "V1ListNode[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return V1ListNode(
        kind: ListNodeKind.fromJson(json[r'kind']),
        indent: mapValueOfType<int>(json, r'indent'),
        children: V1Node.listFromJson(json[r'children']),
      );
    }
    return null;
  }

  static List<V1ListNode> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <V1ListNode>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = V1ListNode.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, V1ListNode> mapFromJson(dynamic json) {
    final map = <String, V1ListNode>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = V1ListNode.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of V1ListNode-objects as value to a dart map
  static Map<String, List<V1ListNode>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<V1ListNode>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = V1ListNode.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

