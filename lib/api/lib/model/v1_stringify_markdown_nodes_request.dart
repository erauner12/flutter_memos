//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class V1StringifyMarkdownNodesRequest {
  /// Returns a new [V1StringifyMarkdownNodesRequest] instance.
  V1StringifyMarkdownNodesRequest({
    this.nodes = const [],
  });

  List<V1Node> nodes;

  @override
  bool operator ==(Object other) => identical(this, other) || other is V1StringifyMarkdownNodesRequest &&
    _deepEquality.equals(other.nodes, nodes);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (nodes.hashCode);

  @override
  String toString() => 'V1StringifyMarkdownNodesRequest[nodes=$nodes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'nodes'] = this.nodes;
    return json;
  }

  /// Returns a new [V1StringifyMarkdownNodesRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static V1StringifyMarkdownNodesRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "V1StringifyMarkdownNodesRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "V1StringifyMarkdownNodesRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return V1StringifyMarkdownNodesRequest(
        nodes: V1Node.listFromJson(json[r'nodes']),
      );
    }
    return null;
  }

  static List<V1StringifyMarkdownNodesRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <V1StringifyMarkdownNodesRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = V1StringifyMarkdownNodesRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, V1StringifyMarkdownNodesRequest> mapFromJson(dynamic json) {
    final map = <String, V1StringifyMarkdownNodesRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = V1StringifyMarkdownNodesRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of V1StringifyMarkdownNodesRequest-objects as value to a dart map
  static Map<String, List<V1StringifyMarkdownNodesRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<V1StringifyMarkdownNodesRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = V1StringifyMarkdownNodesRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

