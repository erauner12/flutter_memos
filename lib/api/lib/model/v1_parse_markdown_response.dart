//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class V1ParseMarkdownResponse {
  /// Returns a new [V1ParseMarkdownResponse] instance.
  V1ParseMarkdownResponse({
    this.nodes = const [],
  });

  List<V1Node> nodes;

  @override
  bool operator ==(Object other) => identical(this, other) || other is V1ParseMarkdownResponse &&
    _deepEquality.equals(other.nodes, nodes);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (nodes.hashCode);

  @override
  String toString() => 'V1ParseMarkdownResponse[nodes=$nodes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'nodes'] = this.nodes;
    return json;
  }

  /// Returns a new [V1ParseMarkdownResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static V1ParseMarkdownResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "V1ParseMarkdownResponse[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "V1ParseMarkdownResponse[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return V1ParseMarkdownResponse(
        nodes: V1Node.listFromJson(json[r'nodes']),
      );
    }
    return null;
  }

  static List<V1ParseMarkdownResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <V1ParseMarkdownResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = V1ParseMarkdownResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, V1ParseMarkdownResponse> mapFromJson(dynamic json) {
    final map = <String, V1ParseMarkdownResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = V1ParseMarkdownResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of V1ParseMarkdownResponse-objects as value to a dart map
  static Map<String, List<V1ParseMarkdownResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<V1ParseMarkdownResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = V1ParseMarkdownResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

